-- =============================================================================
-- SQL TEST SCENARIOS: END-TO-END DEMONSTRATION
-- Project: TA M-Banking (Enterprise Grade)
-- =============================================================================
-- Deskripsi: Script ini digunakan untuk menguji seluruh objek database
-- (Procedures, Functions, Triggers, Views) dalam urutan flow bisnis yang logis.
--
-- CATATAN: Semua objek dipanggil pakai nama DB (db.object), jadi TIDAK perlu USE.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PHASE 1: REGISTRATION & ONBOARDING
-- -----------------------------------------------------------------------------
-- Menguji sp_register_customer (Atomic: Customer + User + CIF Auto-gen)
-- -----------------------------------------------------------------------------

-- Daftarkan nasabah baru: "BUDI SUDARSONO"
-- CATATAN: Password & PIN dikirim plain text (hashing dilakukan di app layer)
CALL dsi_mb_srd.sp_register_customer(
    'BUDI SUDARSONO',
    '081299887766',
    'budi.sudarsono@email.com',
    '123456',           -- PIN plain (app layer yg hash sebelum kirim ke DB)
    'budi_s',           -- Username
    'PasswordBudi123!', -- Password plain
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

-- 2.1 Login Sukses (Check Metadata)
CALL authentication.sp_login_user('budi_s', 'PasswordBudi123!', '192.168.1.10', 'ANDROID-S24', 'M-Banking/v1.0', @res_login);
SELECT @res_login AS res_login_success;
SELECT * FROM authentication.h_login_log
WHERE cif_number = (SELECT cif_number FROM authentication.m_user WHERE username = 'budi_s')
ORDER BY login_time DESC LIMIT 1;

-- 2.2 Ganti Password (sp_change_password)
CALL authentication.sp_change_password('budi_s', 'PasswordBudi123!', 'NewPassword789!', @res_pwd);
SELECT @res_pwd AS res_change_password;
SELECT * FROM authentication.m_password_history WHERE username = 'budi_s';

-- 2.3 Simulasi Brute Force (Trigger: trg_login_failed)
-- Salah Password 1
CALL authentication.sp_login_user('budi_s', 'salah_pw', '192.168.1.10', 'ANDROID-S24', 'M-Banking/v1.0', @res_f1);
-- Salah Password 2
CALL authentication.sp_login_user('budi_s', 'salah_pw', '192.168.1.10', 'ANDROID-S24', 'M-Banking/v1.0', @res_f2);
-- Salah Password 3 (Harusnya Auto-Lock)
CALL authentication.sp_login_user('budi_s', 'salah_pw', '192.168.1.10', 'ANDROID-S24', 'M-Banking/v1.0', @res_f3);
SELECT @res_f1 AS res_fail_1, @res_f2 AS res_fail_2, @res_f3 AS res_fail_3;

-- Verifikasi Akun Terkunci
SELECT username, status, failed_attempts FROM authentication.m_user WHERE username = 'budi_s';

-- 2.4 Login pada Akun Terkunci
CALL authentication.sp_login_user('budi_s', 'NewPassword789!', '192.168.1.10', 'ANDROID-S24', 'M-Banking/v1.0', @res_locked);
SELECT @res_locked AS res_locked_account; -- Harusnya 02


-- -----------------------------------------------------------------------------
-- PHASE 3: FINANCIAL CORE & OPERATIONAL
-- -----------------------------------------------------------------------------
-- Menguji sp_fund_transfer (Saldo, Limit, Fee), sp_mutasi, & sp_tutup_buku
-- -----------------------------------------------------------------------------

-- Aktifkan kembali user Budi buat transaksi (Manual oleh Admin)
UPDATE authentication.m_user SET status = 'ACTIVE', failed_attempts = 0 WHERE username = 'budi_s';

-- 3.1 Transfer Sesama Bank (Check Fee & Balance)
-- Budi (1001003) transfer ke Siti (2001001) Rp 50.000
CALL dsi_mb_srd.sp_fund_transfer('1001003', '2001001', 50000.00, '101', @cif_reg, '192.168.1.10', @res_trx, @ref_trx);
SELECT @res_trx AS res_transfer, @ref_trx AS ref_number;

-- 3.2 Cek Audit Trail (Trigger: trg_audit_account)
SELECT * FROM dsi_mb_srd.h_audit_trail ORDER BY action_at DESC LIMIT 2;

-- 3.3 Mutasi Hari Ini (sp_mutasi) -> nominal IDR & rekening di-mask
CALL dsi_mb_srd.sp_mutasi(@cif_reg);

-- 3.4 Tutup Buku (sp_tutup_buku) -> total transaksi diformat IDR
CALL dsi_mb_srd.sp_tutup_buku();


-- -----------------------------------------------------------------------------
-- PHASE 4: UTILITY FUNCTIONS (Formatting & Calculation)
-- -----------------------------------------------------------------------------
-- Menguji fn_format_idr, fn_get_current_balance, & fn_mask_account
-- -----------------------------------------------------------------------------
SELECT
    dsi_mb_srd.fn_mask_account('1001003')          AS masked_account,
    dsi_mb_srd.fn_get_current_balance('1001003')   AS current_balance_formatted,
    dsi_mb_srd.fn_format_idr(500000.00)            AS sample_idr_format;


-- -----------------------------------------------------------------------------
-- PHASE 5: ANALYTICAL VIEWS (Reporting)
-- -----------------------------------------------------------------------------
-- Menguji vw_lihat_transaksi, vw_customer_portfolio,
-- vw_daily_transaction_report, & vw_user_security_status
-- -----------------------------------------------------------------------------
-- 5.1 Portfolio Nasabah (Summary kekayaan -> total_balance IDR)
SELECT * FROM dsi_mb_srd.vw_customer_portfolio WHERE cif_number = @cif_reg;

-- 5.2 Laporan Transaksi Harian (Audit perbankan -> nominal IDR & rekening di-mask)
SELECT * FROM dsi_mb_srd.vw_daily_transaction_report;

-- 5.3 Lihat Transaksi 7 Hari Terakhir (nominal IDR)
SELECT * FROM dsi_mb_srd.vw_lihat_transaksi WHERE cif_number = @cif_reg;

-- 5.4 Status Keamanan User (Monitoring Satpam)
SELECT * FROM authentication.vw_user_security_status WHERE username = 'budi_s';

-- =============================================================================
-- END OF TEST SCENARIOS
-- =============================================================================
