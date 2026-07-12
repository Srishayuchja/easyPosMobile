<?php
// index.php — front controller and router.
// PHP equivalent of Program.cs: wires config, DB, CORS, and maps routes.

declare(strict_types=1);

use EasyPos\Auth;
use EasyPos\Database;
use EasyPos\Response;
use EasyPos\Controllers\ApprovalController;
use EasyPos\Controllers\AuthController;
use EasyPos\Controllers\HealthController;
use EasyPos\Controllers\ProductController;
use EasyPos\Controllers\PurchaseController;
use EasyPos\Controllers\SaleController;

// ── Autoload (simple PSR-4-ish loader for the EasyPos namespace) ─────────────
spl_autoload_register(function (string $class): void {
    $prefix = 'EasyPos\\';
    if (strncmp($class, $prefix, strlen($prefix)) === 0) {
        $rel  = substr($class, strlen($prefix));
        $path = __DIR__ . '/../src/' . str_replace('\\', '/', $rel) . '.php';
        if (is_file($path)) {
            require $path;
        }
    }
});

$config = require __DIR__ . '/../config/config.php';

if ($config['app']['debug']) {
    ini_set('display_errors', '1');
    error_reporting(E_ALL);
}

// ── CORS (so the Flutter web/dev client can call the API) ────────────────────
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// ── Resolve method, path and JSON body ───────────────────────────────────────
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$uri    = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';

// Normalise: strip any leading folder up to and including "/api/", keep the rest.
$path = '/' . ltrim($uri, '/');
if (($pos = strpos($path, '/api/')) !== false) {
    $path = substr($path, $pos + 4); // keep from "/..." after /api
} elseif (preg_match('#/api$#', $path)) {
    $path = '/';
}
$path = '/' . trim($path, '/');

$rawBody = file_get_contents('php://input') ?: '';
$body    = json_decode($rawBody, true);
if (!is_array($body)) {
    $body = [];
}

// Connect lazily — health checks must work even when the DB is unreachable.
$db = function () use ($config): \PDO {
    return Database::connection($config['db']);
};
$authPayload = Auth::verifyToken(Auth::bearerFromHeaders(), $config['app']['token_secret']);

// Enforce auth only when configured to (keeps current Flutter app working).
$requireAuth = function () use ($authPayload, $config): void {
    if ($config['app']['auth_required'] && $authPayload === null) {
        Response::error('Unauthorized', 401);
    }
};

// ── Routes (mirror the REST endpoints in api_service.dart) ───────────────────
$route = $method . ' ' . $path;

switch (true) {
    case $route === 'GET /' || $route === 'GET /health':
        (new HealthController())->get();
        break;

    case $route === 'POST /auth/login':
        (new AuthController($db(), $config))->login($body);
        break;

    case $route === 'POST /auth/logout':
        (new AuthController($db(), $config))->logout();
        break;

    case $route === 'GET /products':
        $requireAuth();
        (new ProductController($db(), $config))->index();
        break;

    case $route === 'POST /products':
        $requireAuth();
        (new ProductController($db(), $config))->store($body, $authPayload);
        break;

    case $route === 'POST /purchases':
        $requireAuth();
        (new PurchaseController($db(), $config))->store($body, $authPayload);
        break;

    case $route === 'GET /approvals':
        $requireAuth();
        (new ApprovalController($db(), $config))->index();
        break;

    case $route === 'GET /approvals/mine':
        $requireAuth();
        (new ApprovalController($db(), $config))->mine($authPayload);
        break;

    case $route === 'POST /approvals/approve-all':
        $requireAuth();
        (new ApprovalController($db(), $config))->approveAll($authPayload);
        break;

    case $method === 'POST' && preg_match('#^/approvals/(\d+)/approve$#', $path, $m) === 1:
        $requireAuth();
        (new ApprovalController($db(), $config))->approve((int)$m[1], $body, $authPayload);
        break;

    case $method === 'POST' && preg_match('#^/approvals/(\d+)/reject$#', $path, $m) === 1:
        $requireAuth();
        (new ApprovalController($db(), $config))->reject((int)$m[1], $authPayload);
        break;

    case $route === 'GET /sales':
        $requireAuth();
        (new SaleController($db(), $config))->index();
        break;

    case $route === 'POST /sales':
        $requireAuth();
        (new SaleController($db(), $config))->store($body, $authPayload);
        break;

    default:
        Response::error('Not found: ' . $route, 404);
}
