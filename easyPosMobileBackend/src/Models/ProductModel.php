<?php

namespace EasyPos\Models;

use PDO;

class ProductModel
{
    private PDO $db;

    public function __construct(PDO $db)
    {
        $this->db = $db;
    }

    public function getAllByBusiness(int $businessId): array
    {
        $sql = "SELECT p.id,
                       p.name,
                       p.sku                               AS barcode,
                       COALESCE(un.short_name, '')         AS unit,
                       v.default_purchase_price            AS buy,
                       v.default_sell_price                AS sell,
                       COALESCE(SUM(vld.qty_available), 0) AS stock
                FROM products p
                JOIN variations v
                     ON v.product_id = p.id AND v.deleted_at IS NULL
                LEFT JOIN units un ON un.id = p.unit_id
                LEFT JOIN variation_location_details vld ON vld.variation_id = v.id
                WHERE p.business_id = :bid
                  AND p.is_inactive = 0
                  AND p.type = 'single'
                GROUP BY p.id, v.id
                ORDER BY p.name ASC";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([':bid' => $businessId]);

        return array_map([$this, 'mapRow'], $stmt->fetchAll());
    }

    private function mapRow(array $r): array
    {
        return [
            'id'      => (string)$r['id'],
            'name'    => (string)$r['name'],
            'barcode' => (string)($r['barcode'] ?? ''),
            'unit'    => (string)($r['unit'] ?? ''),
            'buy'     => (float)$r['buy'],
            'sell'    => (float)$r['sell'],
            'stock'   => (int)round((float)$r['stock']),
        ];
    }
}
