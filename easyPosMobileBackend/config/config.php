<?php
// config.php — PHP equivalent of appsettings.json
// Edit the DB credentials here for your environment.
//
// On Hostinger: use the database name/user/password shown in
// hPanel → Databases → MySQL Databases (e.g. u383264767_EasyPOS).

return [
    // ── Database (≈ ConnectionStrings:DefaultConnection) ──────────────────
    'db' => [
        'host'     => getenv('DB_HOST')     ?: 'localhost',
        'port'     => getenv('DB_PORT')     ?: '3306',
        'database' => getenv('DB_DATABASE') ?: 'easypos_local',
        'username' => getenv('DB_USERNAME') ?: 'root',
        'password' => getenv('DB_PASSWORD') ?: '',
        'charset'  => 'utf8mb4',
    ],

    // ── App ───────────────────────────────────────────────────────────────
    'app' => [
        'name'  => 'EasyPosMobileBackend',
        'debug' => filter_var(getenv('APP_DEBUG') ?: 'true', FILTER_VALIDATE_BOOLEAN),

        // Secret used to sign login tokens. CHANGE THIS in production.
        'token_secret' => getenv('TOKEN_SECRET') ?: 'change-this-secret-in-production',

        // When false, read endpoints work without a Bearer token (keeps the
        // current Flutter app working as-is). Set true once the app sends tokens.
        'auth_required' => filter_var(getenv('AUTH_REQUIRED') ?: 'false', FILTER_VALIDATE_BOOLEAN),
    ],

    // ── UltimatePOS context defaults (from your database) ─────────────────
    'pos' => [
        'business_id'        => (int)(getenv('POS_BUSINESS_ID') ?: 1),
        'location_id'        => (int)(getenv('POS_LOCATION_ID') ?: 1),
        'default_contact_id' => (int)(getenv('POS_CONTACT_ID') ?: 1), // Walk-In Customer
    ],
];
