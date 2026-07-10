-- Custom table (not part of the base UltimatePOS schema).
-- Backs the cashier-submits / admin-approves workflow for new products and stock adds.
-- Run this once against the target database (local WAMP and, separately, Hostinger).

CREATE TABLE IF NOT EXISTS approval_requests (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    business_id INT UNSIGNED NOT NULL,
    type ENUM('new_product','stock_add') NOT NULL,
    payload TEXT NOT NULL,
    summary VARCHAR(255) NOT NULL,
    requested_by INT UNSIGNED NOT NULL,
    requested_by_name VARCHAR(191) NOT NULL,
    status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
    reviewed_by INT UNSIGNED DEFAULT NULL,
    reviewed_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NULL DEFAULT NULL,
    updated_at TIMESTAMP NULL DEFAULT NULL,
    KEY approval_requests_business_status_idx (business_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
