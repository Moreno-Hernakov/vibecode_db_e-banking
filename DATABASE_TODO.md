# Database Logic Roadmap (Enterprise Grade)

Dokumen ini mencatat progres dan rencana pengembangan logic database (Trigger, Function, Procedure, View) untuk project M-Banking.

## ✅ Completed (Sudah Terimplementasi)

### Stored Procedures
- [x] **`sp_register_customer`**: Registrasi Atomic (Customer + User) - **(New & Recommended)**.
- [x] **`sp_login_user`**: Autentikasi user dan pengelolaan session/status login.
- [x] **`sp_fund_transfer`**: Prosedur transfer dana (Validasi saldo, limit, & atomic trx).
- [x] **`sp_mutasi`**: Menarik history transaksi hari ini.
- [x] **`sp_tutup_buku`**: Rekapitulasi transaksi harian.
- [~] *`sp_create_user` & `sp_create_customer` (Legacy: Digantikan oleh `sp_register_customer`)*.

### Triggers
- [x] **`trg_login_success`**: Reset failed attempts saat login berhasil.
- [x] **`trg_login_failed`**: Increment attempts & auto-lock akun (3x gagal).

### Views
- [x] **`vw_lihat_transaksi`**: Monitoring transaksi seminggu terakhir.
- [x] **`vw_customer_portfolio`**: Ringkasan nasabah beserta total saldo.
- [x] **`vw_daily_transaction_report`**: Laporan harian gabungan (manusiawi).
- [x] **`vw_user_security_status`**: Monitoring user locked/bermasalah.

---

## 🚀 To-Do (Rencana Selanjutnya)

### ⚡ 1. Triggers (Keamanan & Audit)
- [ ] **`trg_audit_customer`**: Log setiap perubahan data nasabah ke `h_audit_trail`.
- [ ] **`trg_audit_account`**: Log perubahan data/status rekening.
- [ ] **`trg_update_balance`**: Sinkronisasi saldo otomatis setelah transaksi (Opsional).

### 🛠️ 2. Functions (Utility & Formatting)
- [ ] **`fn_format_idr`**: Ubah angka `DECIMAL` jadi format Rupiah (e.g., Rp 1.500.000).
- [ ] **`fn_mask_account`**: Sensor nomor rekening (e.g., 123xxxx890).
- [ ] **`fn_get_current_balance`**: Shortcut ambil saldo terakhir rekening.

### ⚙️ 3. Stored Procedures (Business Logic)
- [x] **`sp_change_password`**: Ganti password & simpan ke history.
- [ ] **`sp_generate_reference`**: Generator nomor referensi transaksi unik.

---
*Terakhir diupdate: Sab, 23 Mei 2026 oleh Gemini CLI.*
