-- =============================================================================
-- 1. PEMBERSIHAN & PEMBUATAN DATABASE
-- =============================================================================
DROP DATABASE IF EXISTS authentication;
DROP DATABASE IF EXISTS dsi_mb_srd;

CREATE DATABASE authentication;
CREATE DATABASE dsi_mb_srd;

-- =============================================================================
-- 2. DDL PEMBUATAN TABEL - DATABASE: authentication
-- =============================================================================
USE authentication;

CREATE TABLE m_user (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    cif_number VARCHAR(20) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    failed_attempts INT DEFAULT 0,
    last_failed_login TIMESTAMP NULL,
    suspend_until TIMESTAMP NULL,
    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Kepatuhan PCI-DSS: Mencegah penggunaan password lama
CREATE TABLE m_password_history (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (username) REFERENCES m_user(username)
) ENGINE=InnoDB;

-- Audit Akses: Siapa, Kapan, Pake apa
CREATE TABLE h_login_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cif_number VARCHAR(20) NOT NULL,
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(50),
    device_id VARCHAR(100),
    user_agent TEXT,
    status ENUM('SUCCESS', 'FAILED', 'LOCKED') DEFAULT 'SUCCESS'
) ENGINE=InnoDB;

-- =============================================================================
-- 3. DDL PEMBUATAN TABEL - DATABASE: dsi_mb_srd
-- =============================================================================
USE dsi_mb_srd;

CREATE TABLE m_product_type (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(50) NOT NULL -- TABUNGAN, GIRO, DEPOSITO
) ENGINE=InnoDB;

CREATE TABLE m_customer (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cif_number VARCHAR(20) UNIQUE NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    customer_phone VARCHAR(20),
    customer_email VARCHAR(100),
    classification INT DEFAULT 1, -- 1: Reguler, 2: Gold, 3: Platinum
    client_pin VARCHAR(255) NOT NULL,
    need_authorized_unblock BOOLEAN DEFAULT FALSE,
    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE m_account (
    account_number VARCHAR(20) PRIMARY KEY,
    cif_number VARCHAR(20) NOT NULL,
    product_type_id INT NOT NULL,
    balance DECIMAL(15, 2) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_account_customer FOREIGN KEY (cif_number) REFERENCES m_customer(cif_number),
    CONSTRAINT fk_account_product FOREIGN KEY (product_type_id) REFERENCES m_product_type(id)
) ENGINE=InnoDB;

-- (Tabel lainnya tetap sama seperti sebelumnya...)
-- [M_LIMIT, M_FEATURE, M_RESPONSE_CODE, M_FAVORITE_TRANSFER, T_NOTIFICATION, T_OTP_LOG, T_TRANSACTION, H_AUDIT_TRAIL]
-- (Ketik ulang atau gunakan struktur yang sudah ada sebelumnya)

-- Manajemen Limit Harian (Feature Based)
CREATE TABLE m_limit (
    id INT AUTO_INCREMENT PRIMARY KEY,
    feature_code VARCHAR(10) NOT NULL,
    classification INT NOT NULL,
    limit_amount DECIMAL(15, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE m_feature (
    feature_code VARCHAR(10) PRIMARY KEY,
    feature_name VARCHAR(100) NOT NULL,
    fee DECIMAL(15, 2) DEFAULT 0.00
) ENGINE=InnoDB;

-- Daftar Response Code
CREATE TABLE m_response_code (
    response_code VARCHAR(5) PRIMARY KEY,
    response_message VARCHAR(150) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE t_transaction (
    id_transaction BIGINT AUTO_INCREMENT PRIMARY KEY,
    reference_number VARCHAR(50) UNIQUE NOT NULL,
    cif_number VARCHAR(20) NOT NULL,
    from_account_number VARCHAR(20) NOT NULL,
    customer_reference VARCHAR(50) NOT NULL,
    transaction_amount DECIMAL(15, 2) NOT NULL,
    fee DECIMAL(15, 2) NOT NULL,
    transaction_status VARCHAR(20) NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    feature_code VARCHAR(10),
    response_code VARCHAR(5),
    ipaddress VARCHAR(50),
    biller_name VARCHAR(100),
    location VARCHAR(100),
    
    CONSTRAINT fk_trx_customer FOREIGN KEY (cif_number) REFERENCES m_customer(cif_number),
    CONSTRAINT fk_trx_account FOREIGN KEY (from_account_number) REFERENCES m_account(account_number),
    CONSTRAINT fk_trx_feature FOREIGN KEY (feature_code) REFERENCES m_feature(feature_code),
    CONSTRAINT fk_trx_response FOREIGN KEY (response_code) REFERENCES m_response_code(response_code)
) ENGINE=InnoDB;

CREATE TABLE h_audit_trail (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50),
    action_type ENUM('INSERT', 'UPDATE', 'DELETE'),
    record_id VARCHAR(50),
    old_value TEXT,
    new_value TEXT,
    action_by VARCHAR(50),
    action_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =============================================================================
-- 4. VIEWS - DATABASE: dsi_mb_srd
-- =============================================================================
USE dsi_mb_srd;

-- View Lihat Transaksi Seminggu Sebelumnya
CREATE OR REPLACE VIEW lihat_transaksi AS
SELECT 
    t.cif_number,
    mc.customer_name,
    t.transaction_amount,
    mf.feature_name,
    mf.fee 
FROM t_transaction t
JOIN m_customer mc ON mc.cif_number = t.cif_number
JOIN m_feature mf ON mf.feature_code = t.feature_code
WHERE t.transaction_date >= DATE_SUB(NOW(), INTERVAL 7 DAY);

-- =============================================================================
-- 5. DML DATA DUMMY (Comprehensive Scenarios)
-- =============================================================================

-- --- DATABASE: dsi_mb_srd ---
USE dsi_mb_srd;

-- 1. Master Product Type
INSERT INTO m_product_type (product_name) VALUES ('TABUNGAN'), ('GIRO'), ('DEPOSITO');

-- 2. Master Feature & Fees
INSERT INTO m_feature (feature_code, feature_name, fee) VALUES
('101', 'Transfer Sesama Bank', 0.00),
('102', 'Transfer Antar Bank', 6500.00),
('201', 'Pembayaran PLN', 3000.00);

-- 3. Master Response Code (ISO 8583 Based)
INSERT INTO m_response_code (response_code, response_message) VALUES
('00', 'Success'),
('51', 'Insufficient Fund'),
('61', 'Exceeds Daily Limit'),
('68', 'External Timeout'),
('99', 'System Error');

-- 4. Master Limit (Based on Feature & Classification)
-- Classification: 1=Reguler, 2=Gold
INSERT INTO m_limit (feature_code, classification, limit_amount) VALUES
('101', 1, 10000000.00), -- Reguler: 10jt
('101', 2, 50000000.00), -- Gold: 50jt
('102', 1, 5000000.00);   -- Reguler: 5jt

-- 5. Customer Profiles
INSERT INTO m_customer (cif_number, customer_name, customer_phone, customer_email, classification, client_pin) VALUES
('CIF001', 'BUDI HARTONO', '081234567890', 'budi@gmail.com', 1, '$2a$12$hashedpin1'),
('CIF002', 'SITI AMINAH', '081122334455', 'siti@gmail.com', 2, '$2a$12$hashedpin2');

-- 6. Accounts (One-to-Many with Customer)
INSERT INTO m_account (account_number, cif_number, product_type_id, balance) VALUES
('1001001', 'CIF001', 1, 5000000.00), -- Budi Tabungan 1
('1001002', 'CIF001', 1, 1000000.00), -- Budi Tabungan 2
('2001001', 'CIF002', 2, 75000000.00); -- Siti Giro Gold

-- 7. Audit Trail (Log Perubahan Master)
INSERT INTO h_audit_trail (table_name, action_type, record_id, new_value, action_by) VALUES
('m_customer', 'INSERT', 'CIF001', 'New Customer: Budi', 'ADMIN_HQ'),
('m_account', 'UPDATE', '1001001', 'Initial Deposit 5jt', 'SYSTEM');

-- 8. Transactions (Success, Failure, etc.)
INSERT INTO t_transaction 
(reference_number, cif_number, from_account_number, customer_reference, transaction_amount, fee, transaction_status, feature_code, response_code, ipaddress, biller_name, location)
VALUES
-- Scenario: Success Transfer
('TRX-001', 'CIF001', '1001001', '2001001', 500000.00, 0.00, 'SUCCESS', '101', '00', '192.168.1.10', NULL, 'MOBILE-APPS'),
-- Scenario: Failed (Insufficient Fund)
('TRX-002', 'CIF001', '1001002', '2001001', 2000000.00, 0.00, 'FAILED', '101', '51', '192.168.1.10', NULL, 'MOBILE-APPS'),
-- Scenario: Transfer Antar Bank + Fee
('TRX-003', 'CIF002', '2001001', '900800700', 1000000.00, 6500.00, 'SUCCESS', '102', '00', '10.20.30.45', NULL, 'MOBILE-APPS'),
-- Scenario: PLN Payment
('TRX-004', 'CIF001', '1001001', '5432109876', 150000.00, 3000.00, 'SUCCESS', '201', '00', '192.168.1.10', 'PLN PRABAYAR', 'MOBILE-APPS');


-- --- DATABASE: authentication ---
USE authentication;

-- 9. User Authentication
INSERT INTO m_user (username, password, cif_number, status) VALUES
('budi_hartono', '$2a$12$eImiTxAk4vmMZdG84IXtneX', 'CIF001', 'ACTIVE'),
('siti_aminah', '$2a$12$L8b0VbXOnW1vN9oI2K2OueE', 'CIF002', 'ACTIVE'),
('john_doe', 'dummy_hash', 'CIF003', 'LOCKED');

-- 10. Password History
INSERT INTO m_password_history (username, password_hash) VALUES
('budi_hartono', '$2a$12$old_password_hash_budi');

-- 11. Login Log
INSERT INTO h_login_log (cif_number, ip_address, device_id, status) VALUES
('CIF001', '192.168.1.10', 'IPHONE-15', 'SUCCESS'),
('CIF002', '10.20.30.45', 'SAMSUNG-S24', 'SUCCESS'),
('CIF001', '192.168.1.10', 'IPHONE-15', 'FAILED');

-- =============================================================================
-- 6. STORED PROCEDURES - DATABASE: authentication
-- =============================================================================
USE authentication;

DELIMITER //

CREATE PROCEDURE sp_login_user(
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(255),
    OUT r_response_code VARCHAR(5)
)
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_failed_attempts INT;
    DECLARE v_db_password VARCHAR(255);

    -- 1. Check if user exists and get status
    SELECT status, failed_attempts, password 
    INTO v_status, v_failed_attempts, v_db_password
    FROM m_user WHERE username = p_username;

    IF v_status IS NULL THEN
        SET r_response_code = "01"; -- User Not Found
    ELSEIF v_status = "LOCKED" THEN
        SET r_response_code = "02"; -- Account Locked
    ELSE
        -- 2. Check Password
        IF v_db_password = p_password THEN
            UPDATE m_user SET failed_attempts = 0 WHERE username = p_username;
            SET r_response_code = "00"; -- Success
        ELSE
            -- 3. Wrong Password Logic
            SET v_failed_attempts = v_failed_attempts + 1;
            IF v_failed_attempts >= 3 THEN
                UPDATE m_user SET status = "LOCKED", failed_attempts = v_failed_attempts WHERE username = p_username;
                SET r_response_code = "02"; -- Just locked now
            ELSE
                UPDATE m_user SET failed_attempts = v_failed_attempts WHERE username = p_username;
                SET r_response_code = "03"; -- Wrong Password
            END IF;
        END IF;
    END IF;
END //

DELIMITER ;

-- =============================================================================
-- 7. STORED PROCEDURES - DATABASE: dsi_mb_srd
-- =============================================================================
USE dsi_mb_srd;

DELIMITER //

-- Procedure Mutasi (Cek Transaksi Hari Ini)
CREATE PROCEDURE mutasi(IN nomor_cif VARCHAR(20))
BEGIN
    SELECT 
        mc.cif_number,
        mc.customer_name,
        t.reference_number, 
        t.transaction_amount,
        t.biller_name, 
        mf.fee, 
        mr.response_message, 
        t.transaction_date, 
        t.location 
    FROM t_transaction t
    JOIN m_customer mc ON mc.cif_number = t.cif_number
    JOIN m_feature mf ON mf.feature_code = t.feature_code
    JOIN m_response_code mr ON mr.response_code = t.response_code
    WHERE mc.cif_number = nomor_cif 
    AND DATE(t.transaction_date) = CURDATE()
    ORDER BY t.transaction_date DESC;
END //

-- Procedure Tutup Buku (Rekap Transaksi Hari Ini)
CREATE PROCEDURE tutup_buku()
BEGIN
    SELECT 
        mc.cif_number,
        mc.customer_name,
        COUNT(*) AS 'Total', 
        SUM(transaction_amount) AS 'Jumlah Transaksi' 
    FROM t_transaction t
    JOIN m_customer mc ON mc.cif_number = t.cif_number
    WHERE DATE(t.transaction_date) = CURDATE()
    GROUP BY mc.cif_number, mc.customer_name;
END //

DELIMITER ;

-- =============================================================================
-- 8. TRIGGERS - DATABASE: authentication
-- =============================================================================
USE authentication;

DELIMITER //

-- Trigger Log In Sukses: Reset Failed Attempts
CREATE TRIGGER trg_login_success AFTER INSERT ON h_login_log
FOR EACH ROW 
BEGIN
    IF NEW.status = 'SUCCESS' THEN
        UPDATE m_user
        SET failed_attempts = 0,
            updated = NOW()
        WHERE cif_number = NEW.cif_number;
    END IF;
END //

-- Trigger Log In Gagal: Increment Attempts & Lock Account
CREATE TRIGGER trg_login_failed AFTER INSERT ON h_login_log
FOR EACH ROW 
BEGIN
    IF NEW.status = 'FAILED' THEN
        UPDATE m_user
        SET 
            failed_attempts = failed_attempts + 1,
            last_failed_login = NOW(),
            status = CASE
                WHEN failed_attempts + 1 >= 3 THEN 'LOCKED'
                ELSE status
            END,
            updated = NOW()
        WHERE cif_number = NEW.cif_number;
    END IF;
END //

DELIMITER ;

-- =============================================================================
-- 9. EXAMPLE USAGE QUERIES (FOR TESTING)
-- =============================================================================

/*
-- A. VIEW: Cek transaksi seminggu terakhir
SELECT * FROM dsi_mb_srd.lihat_transaksi;

-- B. PROCEDURE: Cek mutasi hari ini untuk Budi
CALL dsi_mb_srd.mutasi('CIF001');

-- C. PROCEDURE: Rekap tutup buku hari ini
CALL dsi_mb_srd.tutup_buku();

-- D. AUTH: Simulasi Login Sukses (Trigger bakal reset failed_attempts)
INSERT INTO authentication.h_login_log (cif_number, ip_address, status) 
VALUES ('CIF001', '127.0.0.1', 'SUCCESS');

-- E. AUTH: Simulasi Suspend Manual
UPDATE authentication.m_user
SET status = 'SUSPEND', suspend_until = DATE_ADD(NOW(), INTERVAL 6 MONTH)
WHERE cif_number = 'CIF001';

-- F. AUTH: Auto Reactivate Suspend (Kalo waktu udah lewat)
UPDATE authentication.m_user
SET status = 'ACTIVE', suspend_until = NULL
WHERE status = 'SUSPEND' AND suspend_until <= NOW();
*/

