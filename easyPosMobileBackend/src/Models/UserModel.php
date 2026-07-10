<?php

namespace EasyPos\Models;

use PDO;

class UserModel
{
    private PDO $db;

    public function __construct(PDO $db)
    {
        $this->db = $db;
    }

    public function findActiveByUsername(string $username): ?array
    {
        $sql = "SELECT u.id, u.first_name, u.last_name, u.username, u.password,
                       u.business_id, r.name AS role_name
                FROM users u
                LEFT JOIN model_has_roles mhr
                       ON mhr.model_id = u.id AND mhr.model_type = :modelType
                LEFT JOIN roles r ON r.id = mhr.role_id
                WHERE u.username = :username
                  AND u.allow_login = 1
                  AND u.status = 'active'
                LIMIT 1";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([':username' => $username, ':modelType' => 'App\\User']);
        $row = $stmt->fetch();

        return $row ?: null;
    }

    public function findNameById(int $id): string
    {
        $stmt = $this->db->prepare(
            "SELECT first_name, last_name, username FROM users WHERE id = :id LIMIT 1"
        );
        $stmt->execute([':id' => $id]);
        $row = $stmt->fetch();
        if (!$row) {
            return '';
        }
        $name = trim((string)$row['first_name'] . ' ' . (string)($row['last_name'] ?? ''));
        return $name !== '' ? $name : (string)$row['username'];
    }
}
