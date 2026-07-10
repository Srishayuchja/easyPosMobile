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
        ]);
    }

    public function getPendingByBusiness(int $businessId): array
    {
        $stmt = $this->db->prepare(
            "SELECT id, type, summary, requested_by_name, created_at
               FROM approval_requests
              WHERE business_id = :bid AND status = 'pending'
              ORDER BY created_at ASC"
        );
        $stmt->execute([':bid' => $businessId]);

        return array_map([$this, 'mapRow'], $stmt->fetchAll());
    }

    private function mapRow(array $r): array
    {
        return [
            'id'              => (int)$r['id'],
            'type'            => (string)$r['type'],
            'summary'         => (string)$r['summary'],
            'requestedByName' => (string)$r['requested_by_name'],
            'requestedAt'     => str_replace(' ', 'T', (string)$r['created_at']),
        ];
    }

    /**
     * Approves a pending request: applies it via ProductModel, then marks it approved.
     * @throws RuntimeException if the request doesn't exist, isn't pending, or business_id mismatches
     */
    public function approve(int $id, int $businessId, int $locationId, int $reviewerId): void
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
            $product->create(
                (string)($payload['name'] ?? ''),
                (string)($payload['barcode'] ?? ''),
                (string)($payload['unit'] ?? ''),
                (float)($payload['buy'] ?? 0),
                (float)($payload['sell'] ?? 0),
                (int)($payload['stock'] ?? 0),
                (string)($payload['brand'] ?? ''),
                (int)($payload['alertQty'] ?? 0),
                $businessId,
                $locationId,
                (int)$row['requested_by']
            );
        } elseif ($row['type'] === 'stock_add') {
            $product->addStock((int)($payload['productId'] ?? 0), (float)($payload['qty'] ?? 0), $locationId);
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
