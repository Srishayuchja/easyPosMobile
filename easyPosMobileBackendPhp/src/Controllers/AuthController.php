<?php
// POST /api/auth/login   → { token, user: { id, name, username, role } }  or 401

namespace EasyPos\Controllers;

use EasyPos\Auth;
use EasyPos\Models\UserModel;
use EasyPos\Response;
use PDO;

class AuthController
{
    private PDO $db;
    private array $config;

    public function __construct(PDO $db, array $config)
    {
        $this->db     = $db;
        $this->config = $config;
    }

    public function login(array $body): void
    {
        $username = trim((string)($body['username'] ?? ''));
        $password = (string)($body['password'] ?? '');
        $role     = strtolower(trim((string)($body['role'] ?? '')));

        if ($username === '' || $password === '') {
            Response::error('Username and password are required', 422);
        }

        $model = new UserModel($this->db);
        $u     = $model->findActiveByUsername($username);

        if (!$u || !password_verify($password, (string)$u['password'])) {
            Response::error('Invalid username or password', 401);
        }

        $resolvedRole = (stripos((string)$u['role_name'], 'admin') !== false) ? 'admin' : 'cashier';

        if ($role !== '' && $role !== $resolvedRole) {
            Response::error("This account is not a {$role} account", 403);
        }

        $name = trim($u['first_name'] . ' ' . (string)$u['last_name']);
        $user = [
            'id'       => (string)$u['id'],
            'name'     => $name !== '' ? $name : $u['username'],
            'username' => (string)$u['username'],
            'role'     => $resolvedRole,
        ];

        $token = Auth::issueToken(
            ['uid' => (int)$u['id'], 'role' => $resolvedRole, 'bid' => (int)$u['business_id']],
            $this->config['app']['token_secret']
        );

        Response::json(['token' => $token, 'user' => $user]);
    }

    public function logout(): void
    {
        Response::json(['status' => 'ok']);
    }
}
