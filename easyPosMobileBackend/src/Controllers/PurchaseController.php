<?php
// POST /api/purchases  → add stock directly (admin) or submit for approval (cashier)

namespace EasyPos\Controllers;

use EasyPos\Models\ApprovalModel;
use EasyPos\Models\ProductModel;
use EasyPos\Models\UserModel;
use EasyPos\Response;
use PDO;
use Throwable;

class PurchaseController
{
    private PDO $db;
    private array $config;

    public function __construct(PDO $db, array $config)
    {
        $this->db     = $db;
        $this->config = $config;
    }

    public function store(array $body, ?array $authPayload): void
    {
        $productId = (int)($body['productId'] ?? 0);
        $qty       = (float)($body['qty'] ?? 0);

        if ($productId <= 0 || $qty <= 0) {
            Response::error('productId and qty (> 0) are required', 422);
        }

        $requestedBy = (int)($authPayload['uid'] ?? 1);
        $role        = (string)($authPayload['role'] ?? 'admin');

        if ($role === 'cashier') {
            $productModel = new ProductModel($this->db);
            $info = $productModel->findNameAndUnit($productId);
            if (!$info) {
                Response::error('Product not found', 404);
                return;
            }

            $userModel     = new UserModel($this->db);
            $requesterName = $userModel->findNameById($requestedBy) ?: 'Cashier';

            $qtyLabel = $qty == (int)$qty ? (string)(int)$qty : (string)$qty;

            $approvalModel = new ApprovalModel($this->db);
            $request = $approvalModel->create(
                (int)$this->config['pos']['business_id'],
                'stock_add',
                ['productId' => $productId, 'qty' => $qty],
                "Add {$qtyLabel} {$info['unit']} stock to {$info['name']}",
                $requestedBy,
                $requesterName
            );

            Response::json($request, 202);
            return;
        }

        try {
            $model = new ProductModel($this->db);
            $model->addStock($productId, $qty, (int)$this->config['pos']['location_id']);
        } catch (Throwable $e) {
            Response::error('Failed to record purchase', 500, $e->getMessage());
        }

        Response::json(['status' => 'ok'], 201);
    }
}
