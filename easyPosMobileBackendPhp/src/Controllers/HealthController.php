<?php
// HealthController.php — port of HealthController.cs
// GET /api/health  →  { "status": "ok", "service": "EasyPosMobileBackend" }

namespace EasyPos\Controllers;

use EasyPos\Response;

class HealthController
{
    public function get(): void
    {
        Response::json(['status' => 'ok', 'service' => 'EasyPosMobileBackend']);
    }
}
