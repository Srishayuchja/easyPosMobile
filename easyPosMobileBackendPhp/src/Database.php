<?php
// Database.php — PHP equivalent of AppDbContext.
// Wraps a single shared PDO connection to the MySQL/MariaDB database.

namespace EasyPos;

use PDO;
use PDOException;

class Database
{
    private static ?PDO $pdo = null;

    public static function connection(array $cfg): PDO
    {
        if (self::$pdo instanceof PDO) {
            return self::$pdo;
        }

        $dsn = sprintf(
            'mysql:host=%s;port=%s;dbname=%s;charset=%s',
            $cfg['host'],
            $cfg['port'],
            $cfg['database'],
            $cfg['charset']
        );

        try {
            self::$pdo = new PDO($dsn, $cfg['username'], $cfg['password'], [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ]);
        } catch (PDOException $e) {
            Response::json(['error' => 'Database connection failed', 'detail' => $e->getMessage()], 500);
        }

        return self::$pdo;
    }
}
