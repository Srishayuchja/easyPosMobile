<?php

namespace EasyPos\Models;

use PDO;
use RuntimeException;
use Throwable;

class ApprovalModel
{
    private PDO $db;

    public function __construct(PDO $db)
    {
        $this->db = $db;
    }

    /** Inserts a pending request and returns it mapped for the API response. */
    public function create(
        int    $businessId,
        string $type,
        array  $payload,
        string $summary,
        int    $requestedBy,
        string $requestedByName
    ): array {
        $now = date('Y-m-d H:i:s');

        $stmt = $this->db->prepare(
            "INSERT INTO approval_requests
                (business_id, type, payload, summary, requested_by, requested_by_name, status, created_at, updated_at)
             VALUES
                (:bid, :type, :payload, :summary, :by, :byname, 'pending', :now1, :now2)"
        );
        $stmt->execute([
            ':bid' => $businessId, ':type' => $type, ':payload' => json_encode($payload),
            ':summary' => $summary, ':by' => $requestedBy, ':byname' => $requestedByName,
            ':now1' => $now, ':now2' => $now,
        ]);
        $id = (int)$this->db->lastInsertId();

        return $this->mapRow([
            'id' => $id, 'type' => $type, 'summary' => $summary,
            'requested_by_name' => $requestedByName, 'created_at' => $now,
            'status' => 'pending',
        ]);
    }

    public function getPendingByBusiness(int $businessId): array
    {
        $stmt = $this->db->prepare(
            "SELECT id, type, summary, requested_by_name, created_at, status, payload
               FROM approval_requests
              WHERE business_id = :bid AND status = 'pending'
              ORDER BY created_at ASC"
        );
        $stmt->execute([':bid' => $businessId]);

        $product = new ProductModel($this->db);
        return array_map(fn(array $r) => $this->mapRow($r, $product), $stmt->fetchAll());
    }

    /** Pending + rejected requests submitted by one cashier (approved ones are omitted). */
    public function getMineByBusiness(int $businessId, int $requestedBy): array
    {
        $stmt = $this->db->prepare(
            "SELECT id, type, summary, requested_by_name, created_at, status
               FROM approval_requests
              WHERE business_id = :bid AND requested_by = :by AND status IN ('pending', 'rejected')
              ORDER BY created_at DESC"
        );
        $stmt->execute([':bid' => $businessId, ':by' => $requestedBy]);

        return array_map([$this, 'mapRow'], $stmt->fetchAll());
    }

    private function mapRow(array $r, ?ProductModel $product = null): array
    {
        $mapped = [
            'id'              => (int)$r['id'],
            'type'            => (string)$r['type'],
            'summary'         => (string)$r['summary'],
            'requestedByName' => (string)$r['requested_by_name'],
            'requestedAt'     => str_replace(' ', 'T', (string)$r['created_at']),
            'status'          => (string)$r['status'],
        ];

        // For pending restock requests, surface the product's current buying price so
        // the admin can see it and optionally change it (buying prices drift over time).
        if ($product !== null && $r['type'] === 'stock_add' && isset($r['payload'])) {
            $payload   = json_decode((string)$r['payload'], true) ?: [];
            $productId = (int)($payload['productId'] ?? 0);
            if ($productId > 0) {
                $mapped['productId']  = $productId;
                $mapped['currentBuy'] = $product->findBuyPrice($productId);
            }
        }

        return $mapped;
    }

    /**
     * Approves a pending request: applies it via ProductModel, then marks it approved.
     *
     * $buyOverride is required for 'new_product' requests since cashiers don't set a
     * buying price themselves — the admin supplies it here at approval time. For
     * 'stock_add' requests it's optional: pass it when the buying price changed since
     * the last restock, or omit it to keep the product's current price.
     *
     * @throws RuntimeException if the request doesn't exist, isn't pending, business_id
     *         mismatches, or a 'new_product' request is approved without a buy price
     */
    public function approve(int $id, int $businessId, int $locationId, int $reviewerId, ?float $buyOverride = null): void
    {
        $stmt = $this->db->prepare(
            "SELECT * FROM approval_requests WHERE id = :id AND business_id = :bid LIMIT 1"
        );
        $stmt->execute([':id' => $id, ':bid' => $businessId]);
        $row = $stmt->fetch();
        if (!$row) {
            throw new RuntimeException("Approval request {$id} not found");
        }
        if ($row['status'] !== 'pending') {
            throw new RuntimeException("Approval request {$id} is already {$row['status']}");
        }

        $payload = json_decode((string)$row['payload'], true) ?: [];
        $product = new ProductModel($this->db);

        if ($row['type'] === 'new_product') {
            $buy = $buyOverride ?? (float)($payload['buy'] ?? 0);
            if ($buy <= 0) {
                throw new RuntimeException('A buying price greater than 0 is required to approve this product');
            }

            $product->create(
                (string)($payload['name'] ?? ''),
                (string)($payload['barcode'] ?? ''),
                (string)($payload['unit'] ?? ''),
                $buy,
                (float)($payload['sell'] ?? 0),
                (int)($payload['stock'] ?? 0),
                (string)($payload['brand'] ?? ''),
                (int)($payload['alertQty'] ?? 0),
                $businessId,
                $locationId,
                (int)$row['requested_by']
            );
        } elseif ($row['type'] === 'stock_add') {
            $product->addStock((int)($payload['productId'] ?? 0), (float)($payload['qty'] ?? 0), $locationId, $buyOverride);
        } else {
            throw new RuntimeException("Unknown approval type: {$row['type']}");
        }

        $this->setStatus($id, 'approved', $reviewerId);
    }

    public function reject(int $id, int $businessId, int $reviewerId): void
    {
        $stmt = $this->db->prepare(
            "SELECT status FROM approval_requests WHERE id = :id AND business_id = :bid LIMIT 1"
        );
        $stmt->execute([':id' => $id, ':bid' => $businessId]);
        $status = $stmt->fetchColumn();
        if ($status === false) {
            throw new RuntimeException("Approval request {$id} not found");
        }
        if ($status !== 'pending') {
            throw new RuntimeException("Approval request {$id} is already {$status}");
        }

        $this->setStatus($id, 'rejected', $reviewerId);
    }

    /** Approves every pending request for the business; returns [approved, failed] counts. */
    public function approveAll(int $businessId, int $locationId, int $reviewerId): array
    {
        $ids = $this->db->prepare("SELECT id FROM approval_requests WHERE business_id = :bid AND status = 'pending'");
        $ids->execute([':bid' => $businessId]);

        $approved = 0;
        $failed   = 0;
        foreach ($ids->fetchAll(PDO::FETCH_COLUMN) as $id) {
            try {
                $this->approve((int)$id, $businessId, $locationId, $reviewerId);
                $approved++;
            } catch (Throwable $e) {
                $failed++;
            }
        }

        return ['approved' => $approved, 'failed' => $failed];
    }

    private function setStatus(int $id, string $status, int $reviewerId): void
    {
        $now = date('Y-m-d H:i:s');
        $stmt = $this->db->prepare(
            "UPDATE approval_requests
                SET status = :status, reviewed_by = :by, reviewed_at = :now1, updated_at = :now2
              WHERE id = :id"
        );
        $stmt->execute([
            ':status' => $status, ':by' => $reviewerId, ':now1' => $now, ':now2' => $now, ':id' => $id,
        ]);
    }
}
