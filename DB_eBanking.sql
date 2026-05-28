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
CREATE OR REPLACE VIEW vw_lihat_transaksi AS
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
-- 5. DML DATA DUMMY (Master Data & Samples)
-- =============================================================================
USE dsi_mb_srd;

INSERT INTO m_product_type (id, product_name) VALUES 
(1, 'TABUNGAN'), 
(2, 'GIRO'), 
(3, 'DEPOSITO');

INSERT INTO m_feature (feature_code, feature_name, fee) VALUES
('101', 'Transfer Sesama Bank', 0.00),
('102', 'Transfer Antar Bank', 6500.00),
('201', 'Pembayaran PLN', 3000.00);

INSERT INTO m_response_code (response_code, response_message) VALUES
('00', 'Success'),
('51', 'Insufficient Fund'),
('61', 'Exceeds Daily Limit'),
('68', 'External Timeout'),
('99', 'System Error'),
('01', 'User Not Found / Invalid Credentials'),
('02', 'Account Locked'),
('03', 'Wrong Password'),
('14', 'Invalid Account Status');

INSERT INTO m_limit (feature_code, classification, limit_amount) VALUES
('101', 1, 10000000.00),
('101', 2, 50000000.00),
('102', 1, 5000000.00);

INSERT INTO m_customer (cif_number, customer_name, customer_phone, customer_email, classification, client_pin) VALUES
('CIF001', 'BUDI HARTONO', '081234567890', 'budi@gmail.com', 1, '$2a$12$hashedpin1'),
('CIF002', 'SITI AMINAH', '081122334455', 'siti@gmail.com', 2, '$2a$12$hashedpin2');

INSERT INTO m_account (account_number, cif_number, product_type_id, balance) VALUES
('1001001', 'CIF001', 1, 5000000.00),
('1001002', 'CIF001', 1, 1000000.00),
('2001001', 'CIF002', 2, 75000000.00);

USE authentication;

INSERT INTO m_user (username, password, cif_number, status) VALUES
('budi_hartono', '$2a$12$eImiTxAk4vmMZdG84IXtneX', 'CIF001', 'ACTIVE'),
('siti_aminah', '$2a$12$L8b0VbXOnW1vN9oI2K2OueE', 'CIF002', 'ACTIVE');

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
    DECLARE v_db_password VARCHAR(255);
    DECLARE v_cif VARCHAR(20);

    SELECT status, password, cif_number 
    INTO v_status, v_db_password, v_cif
    FROM m_user WHERE username = p_username;

    IF v_status IS NULL THEN
        SET r_response_code = "01"; -- Not Found
    ELSEIF v_status = "LOCKED" THEN
        SET r_response_code = "02"; -- Locked
    ELSE
        IF v_db_password = p_password THEN
            INSERT INTO h_login_log (cif_number, status) VALUES (v_cif, 'SUCCESS');
            SET r_response_code = "00";
        ELSE
            INSERT INTO h_login_log (cif_number, status) VALUES (v_cif, 'FAILED');
            SET r_response_code = "03"; -- Wrong Password
        END IF;
    END IF;
END //

CREATE PROCEDURE sp_change_password(
    IN p_username VARCHAR(50),
    IN p_old_password VARCHAR(255),
    IN p_new_password VARCHAR(255),
    OUT r_response_code VARCHAR(5)
)
BEGIN
    DECLARE v_current_password VARCHAR(255);
    DECLARE v_history_count INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET r_response_code = '99';
    END;

    SELECT password INTO v_current_password 
    FROM m_user WHERE username = p_username;

    IF v_current_password IS NULL OR v_current_password != p_old_password THEN
        SET r_response_code = '01';
    ELSE
        SELECT COUNT(*) INTO v_history_count 
        FROM m_password_history 
        WHERE username = p_username AND password_hash = p_new_password;

        IF v_history_count > 0 OR v_current_password = p_new_password THEN
            SET r_response_code = '02'; -- Password recently used
        ELSE
            START TRANSACTION;
            INSERT INTO m_password_history (username, password_hash)
            VALUES (p_username, v_current_password);
            UPDATE m_user SET password = p_new_password, updated = NOW() 
            WHERE username = p_username;
            COMMIT;
            SET r_response_code = '00';
        END IF;
    END IF;
END //

DELIMITER ;

-- =============================================================================
-- 7. STORED PROCEDURES - DATABASE: dsi_mb_srd
-- =============================================================================
USE dsi_mb_srd;
DELIMITER //

CREATE PROCEDURE sp_generate_reference(
    IN p_prefix VARCHAR(10),
    OUT r_reference_number VARCHAR(50)
)
BEGIN
    SET r_reference_number = CONCAT(p_prefix, '-', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'), '-', LPAD(FLOOR(RAND() * 1000), 3, '0'));
END //

CREATE PROCEDURE sp_register_customer(
    IN p_customer_name VARCHAR(100),
    IN p_customer_phone VARCHAR(20),
    IN p_customer_email VARCHAR(100),
    IN p_client_pin VARCHAR(255),
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(255),
    OUT r_response_code VARCHAR(5),
    OUT r_cif_number VARCHAR(20)
)
BEGIN
    DECLARE v_new_id BIGINT;
    DECLARE v_new_cif VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET r_response_code = '99';
    END;
    START TRANSACTION;
    INSERT INTO m_customer (customer_name, customer_phone, customer_email, cif_number, client_pin)
    VALUES (p_customer_name, p_customer_phone, p_customer_email, 'TEMP_CIF', p_client_pin);
    SET v_new_id = LAST_INSERT_ID();
    SET v_new_cif = CONCAT('CIF', LPAD(v_new_id, 6, '0'));
    UPDATE m_customer SET cif_number = v_new_cif WHERE id = v_new_id;
    INSERT INTO authentication.m_user (username, password, cif_number, status)
    VALUES (p_username, p_password, v_new_cif, 'ACTIVE');
    COMMIT;
    SET r_response_code = '00';
    SET r_cif_number = v_new_cif;
END //

CREATE PROCEDURE sp_fund_transfer(
    IN p_from_account VARCHAR(20),
    IN p_to_account VARCHAR(20),
    IN p_amount DECIMAL(15, 2),
    IN p_feature_code VARCHAR(10),
    IN p_cif_number VARCHAR(20),
    IN p_ip_address VARCHAR(50),
    OUT r_response_code VARCHAR(5),
    OUT r_reference_number VARCHAR(50)
)
BEGIN
    DECLARE v_from_balance, v_fee, v_daily_limit, v_total_today DECIMAL(15, 2);
    DECLARE v_from_status, v_to_status, v_ref_no VARCHAR(50);
    DECLARE v_classification INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET r_response_code = '99';
    END;
    
    CALL sp_generate_reference('TRX', v_ref_no);
    SET r_reference_number = v_ref_no;
    
    SELECT balance, status INTO v_from_balance, v_from_status FROM m_account WHERE account_number = p_from_account;
    SELECT status INTO v_to_status FROM m_account WHERE account_number = p_to_account;
    SELECT fee INTO v_fee FROM m_feature WHERE feature_code = p_feature_code;
    SELECT classification INTO v_classification FROM m_customer WHERE cif_number = p_cif_number;

    IF v_from_status IS NULL OR v_to_status IS NULL THEN SET r_response_code = '14';
    ELSEIF v_from_status != 'ACTIVE' OR v_to_status != 'ACTIVE' THEN SET r_response_code = '14';
    ELSEIF v_from_balance < (p_amount + v_fee) THEN SET r_response_code = '51';
    ELSE
        SELECT limit_amount INTO v_daily_limit FROM m_limit WHERE feature_code = p_feature_code AND classification = v_classification;
        SELECT IFNULL(SUM(transaction_amount), 0) INTO v_total_today FROM t_transaction WHERE cif_number = p_cif_number AND feature_code = p_feature_code AND transaction_status = 'SUCCESS' AND DATE(transaction_date) = CURDATE();
        
        IF (v_total_today + p_amount) > v_daily_limit THEN 
            SET r_response_code = '61';
        ELSE
            START TRANSACTION;
            UPDATE m_account SET balance = balance - (p_amount + v_fee) WHERE account_number = p_from_account;
            UPDATE m_account SET balance = balance + p_amount WHERE account_number = p_to_account;
            INSERT INTO t_transaction (reference_number, cif_number, from_account_number, customer_reference, transaction_amount, fee, transaction_status, feature_code, response_code, ipaddress, location)
            VALUES (v_ref_no, p_cif_number, p_from_account, p_to_account, p_amount, v_fee, 'SUCCESS', p_feature_code, '00', p_ip_address, 'MOBILE-APPS');
            COMMIT;
            SET r_response_code = '00';
        END IF;
    END IF;

    IF r_response_code != '00' AND r_response_code != '99' THEN
        INSERT INTO t_transaction (reference_number, cif_number, from_account_number, customer_reference, transaction_amount, fee, transaction_status, feature_code, response_code, ipaddress, location)
        VALUES (v_ref_no, p_cif_number, p_from_account, p_to_account, p_amount, IFNULL(v_fee, 0), 'FAILED', p_feature_code, r_response_code, p_ip_address, 'MOBILE-APPS');
    END IF;
END //

CREATE PROCEDURE sp_mutasi(IN nomor_cif VARCHAR(20))
BEGIN
    SELECT mc.cif_number, mc.customer_name, t.reference_number, t.transaction_amount,
           mf.fee, mr.response_message, t.transaction_date, t.location 
    FROM t_transaction t
    JOIN m_customer mc ON mc.cif_number = t.cif_number
    JOIN m_feature mf ON mf.feature_code = t.feature_code
    JOIN m_response_code mr ON mr.response_code = t.response_code
    WHERE mc.cif_number = nomor_cif AND DATE(t.transaction_date) = CURDATE()
    ORDER BY t.transaction_date DESC;
END //

CREATE PROCEDURE sp_tutup_buku()
BEGIN
    SELECT mc.cif_number, mc.customer_name, COUNT(*) AS 'Total', SUM(transaction_amount) AS 'Jumlah Transaksi' 
    FROM t_transaction t
    JOIN m_customer mc ON mc.cif_number = t.cif_number
    WHERE DATE(t.transaction_date) = CURDATE()
    GROUP BY mc.cif_number, mc.customer_name;
END //

DELIMITER ;

-- =============================================================================
-- 8. TRIGGERS
-- =============================================================================
USE authentication;
DELIMITER //

CREATE TRIGGER trg_login_success AFTER INSERT ON h_login_log FOR EACH ROW 
BEGIN
    IF NEW.status = 'SUCCESS' THEN 
        UPDATE m_user SET failed_attempts = 0, updated = NOW() WHERE cif_number = NEW.cif_number; 
    END IF;
END //

CREATE TRIGGER trg_login_failed AFTER INSERT ON h_login_log FOR EACH ROW
BEGIN
    IF NEW.status = 'FAILED' THEN
        UPDATE m_user 
        SET failed_attempts = failed_attempts + 1, 
            last_failed_login = NOW(), 
            status = CASE WHEN failed_attempts + 1 >= 3 THEN 'LOCKED' ELSE status END, 
            updated = NOW() 
        WHERE cif_number = NEW.cif_number;
    END IF;
END //

DELIMITER ;

USE dsi_mb_srd;
DELIMITER //

CREATE TRIGGER trg_audit_account AFTER UPDATE ON m_account FOR EACH ROW 
BEGIN
    IF NOT (OLD.balance <=> NEW.balance) THEN
        INSERT INTO h_audit_trail (table_name, action_type, record_id, old_value, new_value, action_by)
        VALUES ('m_account', 'UPDATE', OLD.account_number, OLD.balance, NEW.balance, 'SYSTEM');
    END IF;
END //

CREATE TRIGGER trg_audit_customer AFTER UPDATE ON m_customer FOR EACH ROW 
BEGIN
    IF NOT (OLD.client_pin <=> NEW.client_pin) THEN
        INSERT INTO h_audit_trail (table_name, action_type, record_id, old_value, new_value, action_by)
        VALUES ('m_customer', 'UPDATE', OLD.cif_number, OLD.client_pin, NEW.client_pin, CURRENT_USER());
    END IF;
END //

DELIMITER ;

-- =============================================================================
-- 9. FUNCTIONS
-- =============================================================================
USE dsi_mb_srd;
DELIMITER //

CREATE FUNCTION fn_format_idr(rupiah DECIMAL(15,2)) RETURNS VARCHAR(30)
    DETERMINISTIC
BEGIN
    RETURN CONCAT('Rp ', FORMAT(rupiah, 0, 'id_ID'));
END //

CREATE FUNCTION fn_get_current_balance(param_acc_number VARCHAR(20)) RETURNS VARCHAR(30)
    DETERMINISTIC
BEGIN
    DECLARE v_balance DECIMAL(15,2);
    SELECT balance INTO v_balance FROM m_account WHERE account_number = param_acc_number LIMIT 1;
    RETURN CONCAT('Rp ', FORMAT(v_balance, 0, 'id_ID'));
END //

CREATE FUNCTION fn_mask_account(param_acc_number VARCHAR(20)) RETURNS VARCHAR(20)
    DETERMINISTIC
BEGIN
    RETURN CONCAT(SUBSTRING(param_acc_number, 1, 2), 'xxx', SUBSTRING(param_acc_number, 6, 2));   
END //

DELIMITER ;

-- =============================================================================
-- 10. VIEWS
-- =============================================================================
USE dsi_mb_srd;

CREATE OR REPLACE VIEW vw_customer_portfolio AS
SELECT mc.cif_number, mc.customer_name, COUNT(ma.account_number) AS total_accounts, SUM(ma.balance) AS total_balance,
       CASE WHEN mc.classification = 1 THEN 'REGULER' WHEN mc.classification = 2 THEN 'GOLD' ELSE 'UNKNOWN' END AS classification_name
FROM m_customer mc 
LEFT JOIN m_account ma ON mc.cif_number = ma.cif_number 
GROUP BY mc.cif_number, mc.customer_name, mc.classification;

CREATE OR REPLACE VIEW vw_daily_transaction_report AS
SELECT t.transaction_date, t.reference_number, mc.customer_name, mf.feature_name, t.transaction_amount, t.fee, t.transaction_status AS status, rc.response_message
FROM t_transaction t 
JOIN m_customer mc ON t.cif_number = mc.cif_number 
JOIN m_feature mf ON t.feature_code = mf.feature_code
JOIN m_response_code rc ON t.response_code = rc.response_code
WHERE DATE(t.transaction_date) = CURDATE();

USE authentication;
CREATE OR REPLACE VIEW vw_user_security_status AS
SELECT u.username, u.cif_number, u.status, u.failed_attempts, u.last_failed_login, 
       (SELECT MAX(login_time) FROM h_login_log l WHERE l.cif_number = u.cif_number AND l.status = 'SUCCESS') AS last_login_success
FROM m_user u;
