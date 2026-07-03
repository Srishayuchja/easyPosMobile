<?php
// GET /api/products  → array of ProductModel { id, name, barcode, unit, buy, sell, stock }

namespace EasyPos\Controllers;

use EasyPos\Models\ProductModel;
use EasyPos\Response;
use PDO;

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
}
