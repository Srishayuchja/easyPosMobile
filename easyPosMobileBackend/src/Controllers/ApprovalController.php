<?php
// GET  /api/approvals               → list pending approval requests
// GET  /api/approvals/mine          → list the caller's own pending + rejected requests
// POST /api/approvals/:id/approve   → approve one (applies it); body may include { buy } for new_product
// POST /api/approvals/:id/reject    → reject one
// POST /api/approvals/approve-all   → approve every pending request

namespace EasyPos\Controllers;

use EasyPos\Models\ApprovalModel;
use EasyPos\Response;
use PDO;
use Throwable;

class ApprovalController
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
        $model = new ApprovalModel($this->db);
        $rows  = $model->getPendingByBusiness((int)$this->config['pos']['business_id']);

        Response::json($rows);
    }

    public function mine(?array $authPayload): void
    {
        $requestedBy = (int)($authPayload['uid'] ?? 1);

        $model = new ApprovalModel($this->db);
        $rows  = $model->getMineByBusiness((int)$this->config['pos']['business_id'], $requestedBy);

        Response::json($rows);
    }

    public function approve(int $id, array $body, ?array $authPayload): void
    {
        $reviewerId = (int)($authPayload['uid'] ?? 1);
        $buy        = isset($body['buy']) ? (float)$body['buy'] : null;

        try {
            $model = new ApprovalModel($this->db);
            $model->approve(
                $id,
                (int)$this->config['pos']['business_id'],
                (int)$this->config['pos']['location_id'],
                $reviewerId,
                $buy
            );
        } catch (Throwable $e) {
            Response::error('Failed to approve request', 422, $e->getMessage());
        }

        Response::json(['status' => 'approved']);
    }

    public function reject(int $id, ?array $authPayload): void
    {
        $reviewerId = (int)($authPayload['uid'] ?? 1);

        try {
            $model = new ApprovalModel($this->db);
            $model->reject($id, (int)$this->config['pos']['business_id'], $reviewerId);
        } catch (Throwable $e) {
            Response::error('Failed to reject request', 422, $e->getMessage());
        }

        Response::json(['status' => 'rejected']);
    }

    public function approveAll(?array $authPayload): void
    {
        $reviewerId = (int)($authPayload['uid'] ?? 1);

        $model  = new ApprovalModel($this->db);
        $result = $model->approveAll(
            (int)$this->config['pos']['business_id'],
            (int)$this->config['pos']['location_id'],
            $reviewerId
        );

        Response::json($result);
    }
}
