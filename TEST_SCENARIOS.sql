-- =============================================================================
-- SQL TEST SCENARIOS: END-TO-END DEMONSTRATION
-- Project: TA M-Banking (Enterprise Grade)
-- =============================================================================
-- Deskripsi: Script ini digunakan untuk menguji seluruh objek database 
-- (Procedures, Functions, Triggers, Views) dalam urutan flow bisnis yang logis.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PHASE 1: REGISTRATION & ONBOARDING
-- -----------------------------------------------------------------------------
-- Menguji sp_register_customer (Atomic: Customer + User + CIF Auto-gen)
-- -----------------------------------------------------------------------------
USE dsi_mb_srd;

-- Daftarkan nasabah baru: "BUDI SUDARSONO"
CALL sp_register_customer(
    'BUDI SUDARSONO', 
    '081299887766', 
    'budi.sudarsono@email.com', 
    '$2a$12$hashedpinbudi', -- PIN
    'budi_s',               -- Username
    'PasswordBudi123!',     -- Password Plain (Harusnya Hash di App)
    @res_reg, 
    @cif_reg
);

SELECT @res_reg AS response_reg, @cif_reg AS new_cif;

-- Verifikasi Data di Kedua Database
SELECT * FROM dsi_mb_srd.m_customer WHERE cif_number = @cif_reg;
SELECT * FROM authentication.m_user WHERE username = 'budi_s';

-- Setup saldo awal buat Budi (Manual untuk Testing)
INSERT INTO dsi_mb_srd.m_account (account_number, cif_number, product_type_id, balance) 
VALUES ('1001003', @cif_reg, 1, 10000000.00);


-- -----------------------------------------------------------------------------
-- PHASE 2: AUTHENTICATION & SECURITY AUDIT
-- -----------------------------------------------------------------------------
-- Menguji sp_login_user, sp_change_password, h_login_log, & Auto-lock
-- -----------------------------------------------------------------------------
USE authentication;

-- 2.1 Login Sukses (Check Metadata)
CALL sp_login_user('budi_s', 'PasswordBudi123!', '192.168.1.10', 'ANDROID-S24', 'M-Banking/v1.0', @res_login);
SELECT @res_login AS res_login_success;
SELECT * FROM h_login_log WHERE cif_number = (SELECT cif_number FROM m_user WHERE username = 'budi_s') ORDER BY login_time DESC LIMIT 1;

-- 2.2 Ganti Password (sp_change_password)
CALL sp_change_password('budi_s', 'PasswordBudi123!', 'NewPassword789!', @res_pwd);
SELECT @res_pwd AS res_change_password;
SELECT * FROM m_password_history WHERE username = 'budi_s';

-- 2.3 Simulasi Brute Force (Trigger: trg_login_failed)
-- Salah Password 1
CALL sp_login_user('budi_s', 'salah_pw', '192.168.1.10', 'ANDROID-S24', 'M-Banking/v1.0', @res_f1);
-- Salah Password 2
CALL sp_login_user('budi_s', 'salah_pw', '192.168.1.10', 'ANDROID-S24', 'M-Banking/v1.0', @res_f2);
-- Salah Password 3 (Harusnya Auto-Lock)
CALL sp_login_user('budi_s', 'salah_pw', '192.168.1.10', 'ANDROID-S24', 'M-Banking/v1.0', @res_f3);

-- Verifikasi Akun Terkunci
SELECT username, status, failed_attempts FROM m_user WHERE username = 'budi_s';

-- 2.4 Login pada Akun Terkunci
CALL sp_login_user('budi_s', 'NewPassword789!', '192.168.1.10', 'ANDROID-S24', 'M-Banking/v1.0', @res_locked);
SELECT @res_locked AS res_locked_account; -- Harusnya 02


-- -----------------------------------------------------------------------------
-- PHASE 3: FINANCIAL CORE & OPERATIONAL
-- -----------------------------------------------------------------------------
-- Menguji sp_fund_transfer (Saldo, Limit, Fee), sp_mutasi, & sp_tutup_buku
-- -----------------------------------------------------------------------------
USE dsi_mb_srd;

-- Aktifkan kembali user Budi buat transaksi (Manual oleh Admin)
UPDATE authentication.m_user SET status = 'ACTIVE', failed_attempts = 0 WHERE username = 'budi_s';

-- 3.1 Transfer Sesama Bank (Check Fee & Balance)
-- Budi (1001003) transfer ke Siti (2001001) Rp 50.000
CALL sp_fund_transfer('1001003', '2001001', 50000.00, '101', 'CIF000003', '192.168.1.10', @res_trx, @ref_trx);
SELECT @res_trx AS res_transfer, @ref_trx AS ref_number;

-- 3.2 Cek Audit Trail (Trigger: trg_audit_account)
SELECT * FROM h_audit_trail ORDER BY action_at DESC LIMIT 2;

-- 3.3 Mutasi Hari Ini (sp_mutasi)
CALL sp_mutasi('CIF000003');

-- 3.4 Tutup Buku (sp_tutup_buku)
CALL sp_tutup_buku();


-- -----------------------------------------------------------------------------
-- PHASE 4: UTILITY FUNCTIONS (Formatting & Calculation)
-- -----------------------------------------------------------------------------
-- Menguji fn_format_idr, fn_get_current_balance, & fn_mask_account
-- -----------------------------------------------------------------------------
SELECT 
    fn_mask_account('1001003') AS masked_account,
    fn_get_current_balance('1001003') AS current_balance_formatted,
    fn_format_idr(500000.00) AS sample_idr_format;


-- -----------------------------------------------------------------------------
-- PHASE 5: ANALYTICAL VIEWS (Reporting)
-- -----------------------------------------------------------------------------
-- Menguji vw_customer_portfolio, vw_daily_transaction_report, & vw_user_security_status
-- -----------------------------------------------------------------------------
-- 5.1 Portfolio Nasabah (Summary kekayaan)
SELECT * FROM vw_customer_portfolio WHERE cif_number = 'CIF000003';

-- 5.2 Laporan Transaksi Harian (Audit perbankan)
SELECT * FROM vw_daily_transaction_report;

-- 5.3 Status Keamanan User (Monitoring Satpam)
SELECT * FROM authentication.vw_user_security_status WHERE username = 'budi_s';

-- =============================================================================
-- END OF TEST SCENARIOS
-- =============================================================================
