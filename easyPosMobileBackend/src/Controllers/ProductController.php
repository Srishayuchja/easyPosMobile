<?php
// GET  /api/products  → array of ProductModel { id, name, barcode, unit, buy, sell, stock }
// POST /api/products  → create a product directly (admin) or submit for approval (cashier)

namespace EasyPos\Controllers;

use EasyPos\Models\ApprovalModel;
use EasyPos\Models\ProductModel;
use EasyPos\Models\UserModel;
use EasyPos\Response;
use PDO;
use Throwable;

class ProductController
{
    private PDO $db;
    private array $config;

    public function __construct(PDO $db, array $config)
    {
        $this->db     = $db;
        $this->config = $config;
    }

    public function index(): void
    {
        $model    = new ProductModel($this->db);
        $products = $model->getAllByBusiness((int)$this->config['pos']['business_id']);

        Response::json($products);
    }

    public function store(array $body, ?array $authPayload): void
    {
        $name    = trim((string)($body['name'] ?? ''));
        $barcode = trim((string)($body['barcode'] ?? ''));
        $unit    = trim((string)($body['unit'] ?? ''));
        $buy     = (float)($body['buy'] ?? 0);
        $sell    = (float)($body['sell'] ?? 0);

        if ($name === '' || $barcode === '' || $unit === '') {
            Response::error('name, barcode and unit are required', 422);
        }
        if ($buy <= 0 || $sell <= 0) {
            Response::error('buy and sell prices must be greater than 0', 422);
        }

        $createdBy = (int)($authPayload['uid'] ?? 1);
        $role      = (string)($authPayload['role'] ?? 'admin');
        $stock     = (int)($body['stock'] ?? 0);
        $brand     = trim((string)($body['brand'] ?? ''));
        $alertQty  = (int)($body['alertQty'] ?? 0);

        if ($role === 'cashier') {
            $userModel   = new UserModel($this->db);
            $requesterName = $userModel->findNameById($createdBy) ?: 'Cashier';

            $approvalModel = new ApprovalModel($this->db);
            $request = $approvalModel->create(
                (int)$this->config['pos']['business_id'],
                'new_product',
                [
                    'name' => $name, 'barcode' => $barcode, 'unit' => $unit,
                    'buy' => $buy, 'sell' => $sell, 'stock' => $stock,
                    'brand' => $brand, 'alertQty' => $alertQty,
                ],
                "New product: {$name} ({$unit}) · LKR " . number_format($sell, 0),
                $createdBy,
                $requesterName
            );

            Response::json($request, 202);
            return;
        }

        try {
            $model   = new ProductModel($this->db);
            $product = $model->create(
                $name,
                $barcode,
                $unit,
                $buy,
                $sell,
                $stock,
                $brand,
                $alertQty,
                (int)$this->config['pos']['business_id'],
                (int)$this->config['pos']['location_id'],
                $createdBy
            );
        } catch (Throwable $e) {
            Response::error('Failed to create product', 500, $e->getMessage());
        }

        Response::json($product, 201);
    }
}
