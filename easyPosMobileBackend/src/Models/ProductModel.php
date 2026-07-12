<?php

namespace EasyPos\Models;

use PDO;
use Throwable;

class ProductModel
{
    private PDO $db;

    public function __construct(PDO $db)
    {
        $this->db = $db;
    }

    /** Returns ['name' => ..., 'unit' => ...] or null if the product doesn't exist. */
    public function findNameAndUnit(int $productId): ?array
    {
        $stmt = $this->db->prepare(
            "SELECT p.name, COALESCE(un.short_name, '') AS unit
               FROM products p
               LEFT JOIN units un ON un.id = p.unit_id
              WHERE p.id = :pid
              LIMIT 1"
        );
        $stmt->execute([':pid' => $productId]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    public function getAllByBusiness(int $businessId): array
    {
        $sql = "SELECT p.id,
                       p.name,
                       p.sku                               AS barcode,
                       COALESCE(un.short_name, '')         AS unit,
                       v.default_purchase_price            AS buy,
                       v.default_sell_price                AS sell,
                       COALESCE(SUM(vld.qty_available), 0) AS stock,
                       COALESCE(b.name, '')                AS brand,
                       COALESCE(p.alert_quantity, 0)        AS alert_qty
                FROM products p
                JOIN variations v
                     ON v.product_id = p.id AND v.deleted_at IS NULL
                LEFT JOIN units un ON un.id = p.unit_id
                LEFT JOIN brands b ON b.id = p.brand_id
                LEFT JOIN variation_location_details vld ON vld.variation_id = v.id
                WHERE p.business_id = :bid
                  AND p.is_inactive = 0
                  AND p.type = 'single'
                GROUP BY p.id, v.id, b.name
                ORDER BY p.name ASC";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([':bid' => $businessId]);

        return array_map([$this, 'mapRow'], $stmt->fetchAll());
    }

    private function mapRow(array $r): array
    {
        return [
            'id'       => (string)$r['id'],
            'name'     => (string)$r['name'],
            'barcode'  => (string)($r['barcode'] ?? ''),
            'unit'     => (string)($r['unit'] ?? ''),
            'buy'      => (float)$r['buy'],
            'sell'     => (float)$r['sell'],
            'stock'    => (int)round((float)$r['stock']),
            'brand'    => (string)($r['brand'] ?? ''),
            'alertQty' => (int)round((float)($r['alert_qty'] ?? 0)),
        ];
    }

    /**
     * Creates a single-variation product (product + product_variations + variations +
     * variation_location_details), matching how UltimatePOS stores "single" type products.
     *
     * @throws Throwable on DB failure (transaction rolled back)
     */
    public function create(
        string $name,
        string $barcode,
        string $unitName,
        float  $buy,
        float  $sell,
        int    $stock,
        string $brandName,
        int    $alertQty,
        int    $businessId,
        int    $locationId,
        int    $createdBy
    ): array {
        $now = date('Y-m-d H:i:s');

        $this->db->beginTransaction();

        try {
            $unitId  = $this->findOrCreateUnit($businessId, $unitName, $createdBy, $now);
            $brandId = $brandName !== '' ? $this->findOrCreateBrand($businessId, $brandName, $createdBy, $now) : null;

            $stmt = $this->db->prepare(
                "INSERT INTO products
                    (name, business_id, type, unit_id, brand_id, tax_type, enable_stock,
                     alert_quantity, sku, barcode_type, created_by, is_inactive, not_for_selling,
                     created_at, updated_at)
                 VALUES
                    (:name, :bid, 'single', :unit_id, :brand_id, 'exclusive', 1,
                     :alert, :sku, 'C128', :by, 0, 0,
                     :now1, :now2)"
            );
            $stmt->execute([
                ':name' => $name, ':bid' => $businessId, ':unit_id' => $unitId, ':brand_id' => $brandId,
                ':alert' => $alertQty, ':sku' => $barcode, ':by' => $createdBy, ':now1' => $now, ':now2' => $now,
            ]);
            $productId = (int)$this->db->lastInsertId();

            $stmt = $this->db->prepare(
                "INSERT INTO product_variations (variation_template_id, name, product_id, is_dummy, created_at, updated_at)
                 VALUES (NULL, 'DUMMY', :pid, 1, :now1, :now2)"
            );
            $stmt->execute([':pid' => $productId, ':now1' => $now, ':now2' => $now]);
            $productVariationId = (int)$this->db->lastInsertId();

            $profitPercent = $buy > 0 ? round((($sell - $buy) / $buy) * 100, 4) : 0;
            $stmt = $this->db->prepare(
                "INSERT INTO variations
                    (name, product_id, sub_sku, product_variation_id, default_purchase_price, dpp_inc_tax,
                     profit_percent, default_sell_price, sell_price_inc_tax, created_at, updated_at)
                 VALUES
                    ('DUMMY', :pid, :sku, :pvid, :buy1, :buy2, :profit, :sell1, :sell2, :now1, :now2)"
            );
            $stmt->execute([
                ':pid' => $productId, ':sku' => $barcode, ':pvid' => $productVariationId,
                ':buy1' => $buy, ':buy2' => $buy, ':profit' => $profitPercent,
                ':sell1' => $sell, ':sell2' => $sell, ':now1' => $now, ':now2' => $now,
            ]);
            $variationId = (int)$this->db->lastInsertId();

            $stmt = $this->db->prepare(
                "INSERT INTO variation_location_details
                    (product_id, product_variation_id, variation_id, location_id, qty_available, created_at, updated_at)
                 VALUES
                    (:pid, :pvid, :vid, :loc, :qty, :now1, :now2)"
            );
            $stmt->execute([
                ':pid' => $productId, ':pvid' => $productVariationId, ':vid' => $variationId,
                ':loc' => $locationId, ':qty' => $stock, ':now1' => $now, ':now2' => $now,
            ]);

            $this->db->commit();
        } catch (Throwable $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            throw $e;
        }

        return [
            'id'       => (string)$productId,
            'name'     => $name,
            'barcode'  => $barcode,
            'unit'     => $unitName,
            'buy'      => $buy,
            'sell'     => $sell,
            'stock'    => $stock,
            'brand'    => $brandName,
            'alertQty' => $alertQty,
        ];
    }

    private function findOrCreateUnit(int $businessId, string $unitName, int $createdBy, string $now): int
    {
        $unitName = trim($unitName);

        $stmt = $this->db->prepare(
            "SELECT id FROM units WHERE business_id = :bid AND deleted_at IS NULL
               AND (short_name = :name1 OR actual_name = :name2) LIMIT 1"
        );
        $stmt->execute([':bid' => $businessId, ':name1' => $unitName, ':name2' => $unitName]);
        $id = $stmt->fetchColumn();
        if ($id) {
            return (int)$id;
        }

        $stmt = $this->db->prepare(
            "INSERT INTO units (business_id, actual_name, short_name, allow_decimal, created_by, created_at, updated_at)
             VALUES (:bid, :name1, :name2, 0, :by, :now1, :now2)"
        );
        $stmt->execute([
            ':bid' => $businessId, ':name1' => $unitName, ':name2' => $unitName,
            ':by' => $createdBy, ':now1' => $now, ':now2' => $now,
        ]);
        return (int)$this->db->lastInsertId();
    }

    private function findOrCreateBrand(int $businessId, string $brandName, int $createdBy, string $now): int
    {
        $brandName = trim($brandName);

        $stmt = $this->db->prepare(
            "SELECT id FROM brands WHERE business_id = :bid AND deleted_at IS NULL AND name = :name LIMIT 1"
        );
        $stmt->execute([':bid' => $businessId, ':name' => $brandName]);
        $id = $stmt->fetchColumn();
        if ($id) {
            return (int)$id;
        }

        $stmt = $this->db->prepare(
            "INSERT INTO brands (business_id, name, created_by, created_at, updated_at)
             VALUES (:bid, :name, :by, :now1, :now2)"
        );
        $stmt->execute([':bid' => $businessId, ':name' => $brandName, ':by' => $createdBy, ':now1' => $now, ':now2' => $now]);
        return (int)$this->db->lastInsertId();
    }

    /** Returns the current default buying price for a product's variation, or null if not found. */
    public function findBuyPrice(int $productId): ?float
    {
        $stmt = $this->db->prepare(
            "SELECT default_purchase_price FROM variations WHERE product_id = :pid AND deleted_at IS NULL LIMIT 1"
        );
        $stmt->execute([':pid' => $productId]);
        $value = $stmt->fetchColumn();
        return $value === false ? null : (float)$value;
    }

    /**
     * Increments on-hand stock for a product's (single) variation at a location,
     * creating the variation_location_details row if one doesn't exist yet.
     * If $buyPrice is given (buying price sometimes changes between restocks), the
     * variation's purchase price is updated to it; otherwise the existing price is kept.
     *
     * @throws \RuntimeException if the product has no variation
     */
    public function addStock(int $productId, float $qty, int $locationId, ?float $buyPrice = null): void
    {
        $now = date('Y-m-d H:i:s');

        $stmt = $this->db->prepare(
            "SELECT id, product_variation_id, default_sell_price
               FROM variations WHERE product_id = :pid AND deleted_at IS NULL LIMIT 1"
        );
        $stmt->execute([':pid' => $productId]);
        $variation = $stmt->fetch();
        if (!$variation) {
            throw new \RuntimeException("No variation found for product {$productId}");
        }
        $variationId        = (int)$variation['id'];
        $productVariationId = (int)$variation['product_variation_id'];

        $stmt = $this->db->prepare(
            "UPDATE variation_location_details
                SET qty_available = qty_available + :qty, updated_at = :now
              WHERE variation_id = :vid AND location_id = :loc"
        );
        $stmt->execute([':qty' => $qty, ':now' => $now, ':vid' => $variationId, ':loc' => $locationId]);

        if ($stmt->rowCount() === 0) {
            $stmt = $this->db->prepare(
                "INSERT INTO variation_location_details
                    (product_id, product_variation_id, variation_id, location_id, qty_available, created_at, updated_at)
                 VALUES
                    (:pid, :pvid, :vid, :loc, :qty, :now1, :now2)"
            );
            $stmt->execute([
                ':pid' => $productId, ':pvid' => $productVariationId, ':vid' => $variationId,
                ':loc' => $locationId, ':qty' => $qty, ':now1' => $now, ':now2' => $now,
            ]);
        }

        if ($buyPrice !== null && $buyPrice > 0) {
            $sell          = (float)$variation['default_sell_price'];
            $profitPercent = round((($sell - $buyPrice) / $buyPrice) * 100, 4);

            $stmt = $this->db->prepare(
                "UPDATE variations
                    SET default_purchase_price = :buy1, dpp_inc_tax = :buy2,
                        profit_percent = :profit, updated_at = :now
                  WHERE id = :vid"
            );
            $stmt->execute([
                ':buy1' => $buyPrice, ':buy2' => $buyPrice, ':profit' => $profitPercent,
                ':now' => $now, ':vid' => $variationId,
            ]);
        }
    }
}
