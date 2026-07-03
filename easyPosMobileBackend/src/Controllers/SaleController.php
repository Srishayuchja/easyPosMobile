<?php
// GET  /api/sales  → list of recent final sales (Flutter SaleModel)
// POST /api/sales  → create a sale (transaction + sell lines + stock + payment)

namespace EasyPos\Controllers;

use EasyPos\Models\SaleModel;
use EasyPos\Response;
use PDO;
use Throwable;

class SaleController
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
        $model = new SaleModel($this->db);
        $sales = $model->getRecentByBusiness((int)$this->config['pos']['business_id']);

        Response::json($sales);
    }

    public function store(array $body, ?array $authPayload): void
    {
        $items = $body['items'] ?? [];
        if (!is_array($items) || count($items) === 0) {
            Response::error('A sale must contain at least one item', 422);
        }

        $createdBy = (int)($body['cashierId'] ?? ($authPayload['uid'] ?? 0));
        if ($createdBy <= 0) {
            Response::error('cashierId (or a valid token) is required', 422);
        }

        $invoice       = trim((string)($body['invoiceId'] ?? '')) ?: ('INV-' . time());
        $subtotal      = (float)($body['subtotal'] ?? 0);
        $tax           = (float)($body['tax'] ?? 0);
        $total         = (float)($body['total'] ?? 0);
        $paymentMethod = strtolower((string)($body['paymentMethod'] ?? 'cash'));

        try {
            $model = new SaleModel($this->db);
            $sale  = $model->create(
                $invoice,
                $subtotal,
                $tax,
                $total,
                $paymentMethod,
                $createdBy,
                $items,
                (int)$this->config['pos']['business_id'],
                (int)$this->config['pos']['location_id'],
                (int)$this->config['pos']['default_contact_id']
            );
        } catch (\RuntimeException $e) {
            Response::error($e->getMessage(), 422);
        } catch (Throwable $e) {
            Response::error('Failed to record sale', 500, $e->getMessage());
        }

        $sale['cashier'] = (string)($body['cashier'] ?? '');

        Response::json($sale, 201);
    }
}
