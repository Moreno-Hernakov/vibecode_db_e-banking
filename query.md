// --- QUERY SCRATCHPAD ---
// File ini digunakan untuk mencoba query sebelum dimasukkan ke database utama atau blueprint.

// 1. CEK MUTASI & REKAP
CALL dsi_mb_srd.mutasi('CIF001');
CALL dsi_mb_srd.tutup_buku();

// 2. LOGIN & AUTH
CALL authentication.sp_login_user('budi_hartono', '$2a$12$eImiTxAk4vmMZdG84IXtneX', @res);
SELECT @res;

// 3. REGISTRASI NASABAH BARU (FLOW BARU)
-- Params: Name, Phone, Email, Pin, Username, Password, @out_res, @out_cif
CALL dsi_mb_srd.sp_register_customer(
    'VALEN RIFQI', 
    '08999999999', 
    'valen@gmail.com', 
    '123456', 
    'valen_rifqi', 
    'pass123', 
    @res, 
    @cif
);
SELECT @res, @cif;

// 4. FUND TRANSFER (INTERNAL)
-- Params: From, To, Amount, FeatureCode, CIF, IP, @res, @ref
CALL dsi_mb_srd.sp_fund_transfer(
    '1001001', 
    '2001001', 
    50000.00, 
    '101', 
    'CIF001', 
    '127.0.0.1', 
    @res, 
    @ref
);
SELECT @res, @ref;

// 5. CHANGE PASSWORD (ANTI-REUSE)
-- Params: Username, OldPwd, NewPwd, @res
CALL authentication.sp_change_password('budi_hartono', '$2a$12$eImiTxAk4vmMZdG84IXtneX', 'new_secure_pwd_123', @res);
SELECT @res;

// 6. VIEW TESTING
SELECT * FROM dsi_mb_srd.lihat_transaksi;
SELECT * FROM dsi_mb_srd.vw_customer_portfolio;
SELECT * FROM authentication.vw_user_security_status;
