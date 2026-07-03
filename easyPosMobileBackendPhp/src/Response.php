<?php
// Response.php — small JSON response helper (≈ ControllerBase.Ok / IActionResult).

namespace EasyPos;

class Response
{
    /** Send a JSON response and stop execution. */
    public static function json($data, int $status = 200): void
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    public static function error(string $message, int $status = 400, $detail = null): void
    {
        $body = ['error' => $message];
        if ($detail !== null) {
            $body['detail'] = $detail;
        }
        self::json($body, $status);
    }
}
