<?php

namespace EasyPos\Models;

use PDO;
use Throwable;

class SaleModel
{
    private PDO $db;

    public function __construct(PDO $db)
    {
        $this->db = $db;
    }

    public function getRecentByBusiness(int $businessId): array
    {
        $sql = "SELECT t.invoice_no                              AS id,
                       t.total_before_tax                       AS subtotal,
                       t.tax_amount                             AS tax,
                       t.final_total                            AS total,
                       t.transaction_date                       AS ts,
                       TRIM(CONCAT(u.first_name, ' ', COALESCE(u.last_name, ''))) AS cashier,
                       (SELECT COALESCE(SUM(tsl.quantity), 0)
                          FROM transaction_sell_lines tsl
                         WHERE tsl.transaction_id = t.id)       AS item_count
                FROM transactions t
                LEFT JOIN users u ON u.id = t.created_by
                WHERE t.business_id = :bid
                  AND t.type = 'sell'
                  AND t.status = 'final'
                ORDER BY t.transaction_date DESC
                LIMIT 100";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([':bid' => $businessId]);

        return array_map(function (array $r): array {
            return [
                'id'        => (string)$r['id'],
                'itemCount' => (int)round((float)$r['item_count']),
                'subtotal'  => (float)$r['subtotal'],
                'tax'       => (float)$r['tax'],
                'total'     => (float)$r['total'],
                'timestamp' => str_replace(' ', 'T', (string)$r['ts']),
                'cashier'   => (string)($r['cashier'] ?? ''),
            ];
        }, $stmt->fetchAll());
    }

    /**
     * @throws \RuntimeException on invalid line items
     * @throws Throwable on DB failure (transaction rolled back)
     */
    public function create(
        string $invoice,
        float  $subtotal,
        float  $tax,
        float  $total,
        string $paymentMethod,
        int    $createdBy,
        array  $items,
        int    $businessId,
        int    $locationId,
        int    $contactId
    ): array {
        $now = date('Y-m-d H:i:s');

        $this->db->beginTransaction();

        try {
            // 1) transaction header
            $stmt = $this->db->prepare(
                "INSERT INTO transactions
                    (business_id, location_id, type, status, payment_status, contact_id,
                     invoice_no, transaction_date, total_before_tax, tax_amount, final_total,
                     created_by, created_at, updated_at)
                 VALUES
                    (:bid, :loc, 'sell', 'final', 'paid', :contact,
                     :inv, :tdate, :sub, :tax, :total,
                     :by, :now1, :now2)"
            );
            $stmt->execute([
                ':bid' => $businessId, ':loc' => $locationId, ':contact' => $contactId,
                ':inv' => $invoice, ':tdate' => $now, ':sub' => $subtotal,
                ':tax' => $tax, ':total' => $total, ':by' => $createdBy, ':now1' => $now, ':now2' => $now,
            ]);
            $transactionId = (int)$this->db->lastInsertId();

            $findVariation = $this->db->prepare(
                "SELECT id FROM variations WHERE product_id = :pid AND deleted_at IS NULL LIMIT 1"
            );
            $insertLine = $this->db->prepare(
                "INSERT INTO transaction_sell_lines
                    (transaction_id, product_id, variation_id, quantity,
                     unit_price_before_discount, unit_price, unit_price_inc_tax, item_tax,
                     created_at, updated_at)
                 VALUES
                    (:tid, :pid, :vid, :qty, :price1, :price2, :price3, 0, :now1, :now2)"
            );
            $reduceStock = $this->db->prepare(
                "UPDATE variation_location_details
                    SET qty_available = qty_available - :qty, updated_at = :now
                  WHERE variation_id = :vid AND location_id = :loc"
            );

            // 2) sell lines + stock decrement
            foreach ($items as $item) {
                $productId = (int)($item['productId'] ?? 0);
                $qty       = (float)($item['qty'] ?? 0);
                $price     = (float)($item['price'] ?? 0);

                if ($productId <= 0 || $qty <= 0) {
                    throw new \RuntimeException('Invalid line item (productId/qty)');
                }

                $findVariation->execute([':pid' => $productId]);
                $variationId = (int)$findVariation->fetchColumn();
                if ($variationId <= 0) {
                    throw new \RuntimeException("No variation found for product {$productId}");
                }

                $insertLine->execute([
                    ':tid' => $transactionId, ':pid' => $productId, ':vid' => $variationId,
                    ':qty' => $qty, ':price1' => $price, ':price2' => $price, ':price3' => $price,
                    ':now1' => $now, ':now2' => $now,
                ]);
                $reduceStock->execute([
                    ':qty' => $qty, ':vid' => $variationId, ':loc' => $locationId, ':now' => $now,
                ]);
            }

            // 3) payment
            $pay = $this->db->prepare(
                "INSERT INTO transaction_payments
                    (transaction_id, business_id, amount, method, paid_on, created_by, created_at, updated_at)
                 VALUES
                    (:tid, :bid, :amount, :method, :now1, :by, :now2, :now3)"
            );
            $pay->execute([
                ':tid' => $transactionId, ':bid' => $businessId, ':amount' => $total,
                ':method' => $paymentMethod, ':now1' => $now, ':by' => $createdBy, ':now2' => $now, ':now3' => $now,
            ]);

            $this->db->commit();
        } catch (Throwable $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            throw $e;
        }

        return [
            'id'        => $invoice,
            'itemCount' => array_sum(array_map(fn($i) => (int)($i['qty'] ?? 0), $items)),
            'subtotal'  => $subtotal,
            'tax'       => $tax,
            'total'     => $total,
            'timestamp' => str_replace(' ', 'T', $now),
        ];
    }
}
