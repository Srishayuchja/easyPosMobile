<?php
// Auth.php — lightweight stateless token helper (no external JWT dependency).
// Token format: base64url(payload).base64url(hmac_sha256(payload, secret))

namespace EasyPos;

class Auth
{
    public static function issueToken(array $payload, string $secret, int $ttlSeconds = 86400): string
    {
        $payload['iat'] = time();
        $payload['exp'] = time() + $ttlSeconds;
        $json = json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        $body = self::b64url($json);
        $sig  = self::b64url(hash_hmac('sha256', $body, $secret, true));
        return $body . '.' . $sig;
    }

    /** Returns decoded payload array, or null if invalid/expired. */
    public static function verifyToken(?string $token, string $secret): ?array
    {
        if (!$token) {
            return null;
        }
        $parts = explode('.', $token);
        if (count($parts) !== 2) {
            return null;
        }
        [$body, $sig] = $parts;
        $expected = self::b64url(hash_hmac('sha256', $body, $secret, true));
        if (!hash_equals($expected, $sig)) {
            return null;
        }
        $payload = json_decode(self::b64urlDecode($body), true);
        if (!is_array($payload) || (isset($payload['exp']) && $payload['exp'] < time())) {
            return null;
        }
        return $payload;
    }

    /** Reads the Bearer token from the Authorization header, if present. */
    public static function bearerFromHeaders(): ?string
    {
        $headers = function_exists('getallheaders') ? getallheaders() : [];
        $auth = $headers['Authorization'] ?? $headers['authorization'] ?? ($_SERVER['HTTP_AUTHORIZATION'] ?? '');
        if (preg_match('/Bearer\s+(.+)/i', (string)$auth, $m)) {
            return trim($m[1]);
        }
        return null;
    }

    private static function b64url(string $bin): string
    {
        return rtrim(strtr(base64_encode($bin), '+/', '-_'), '=');
    }

    private static function b64urlDecode(string $s): string
    {
        return base64_decode(strtr($s, '-_', '+/'));
    }
}
