# Database Logic Roadmap (Enterprise Grade)

Dokumen ini mencatat status implementasi logic database (Stored Procedures, Triggers, Functions, & Views).

---

## ⚙️ Stored Procedures (Bisnis & Operasional)
*Logic utama untuk manipulasi data dan alur bisnis.*

- [x] **`sp_register_customer`** (Reno): Registrasi Atomic (Customer + User + CIF Auto-gen).
- [x] **`sp_login_user`** (Reno): Autentikasi user dan pengelolaan session/status login.
- [x] **`sp_fund_transfer`** (Reno): Transfer dana antar rekening (Validasi saldo, limit harian, & atomic).
- [x] **`sp_change_password`** (Reno): Ganti password dengan validasi history (Anti-reuse).
- [x] **`sp_mutasi`** (Valen): Menarik history transaksi hari ini.
- [x] **`sp_tutup_buku`** (Valen): Rekapitulasi transaksi harian.
- [x] **`sp_generate_reference`** (Reno): Dedicated generator nomor referensi transaksi unik.
- [~] *`sp_create_user` & `sp_create_customer` (Legacy: Digantikan oleh `sp_register_customer`)*.

---

## ⚡ Triggers (Otomasi & Audit)
*Logic otomatis yang berjalan berdasarkan event (Insert/Update).*

- [x] **`trg_login_success`** (Reno): Reset failed attempts saat login berhasil.
- [x] **`trg_login_failed`** (Reno): Increment attempts & auto-lock akun (3x gagal).
- [x] **`trg_audit_customer`** (Valen): Log setiap perubahan data nasabah ke `h_audit_trail`.
- [x] **`trg_audit_account`** (Valen): Log perubahan data/status rekening ke `h_audit_trail`.

---

## 🛠️ Functions (Utility & Formatting)
*Logic pendukung untuk pengolahan nilai atau tampilan.*

- [x] **`fn_format_idr`** (Valen): Ubah angka `DECIMAL` jadi format Rupiah (e.g., Rp 1.500.000).
- [x] **`fn_mask_account`** (Valen): Sensor nomor rekening (e.g., 123xxxx890) untuk PII handling.
- [x] **`fn_get_current_balance`** (Valen): Shortcut ambil saldo terakhir rekening tertentu.

---

## 📊 Views (Pelaporan & Monitoring)
*Query yang disimpan untuk mempermudah pembacaan data.*

- [x] **`vw_lihat_transaksi`** (Valen): Monitoring transaksi seminggu terakhir.
- [x] **`vw_customer_portfolio`** (Reno): Ringkasan nasabah beserta total saldo.
- [x] **`vw_daily_transaction_report`** (Reno): Laporan harian gabungan (manusiawi).
- [x] **`vw_user_security_status`** (Reno): Monitoring user locked/bermasalah.

---
*Terakhir diupdate: Selasa, 2 Juni 2026 oleh Gemini CLI.*
