# Database Logic Roadmap (Enterprise Grade)

Dokumen ini mencatat status implementasi logic database (Stored Procedures, Triggers, Functions, & Views).

---

## ⚙️ Stored Procedures (Bisnis & Operasional)
*Logic utama untuk manipulasi data dan alur bisnis.*

- [x] **`sp_register_customer`**: Registrasi Atomic (Customer + User + CIF Auto-gen).
- [x] **`sp_login_user`**: Autentikasi user dan pengelolaan session/status login.
- [x] **`sp_fund_transfer`**: Transfer dana antar rekening (Validasi saldo, limit harian, & atomic).
- [x] **`sp_change_password`**: Ganti password dengan validasi history (Anti-reuse).
- [x] **`sp_mutasi`**: Menarik history transaksi hari ini.
- [x] **`sp_tutup_buku`**: Rekapitulasi transaksi harian.
- [x] **`sp_generate_reference`**: Dedicated generator nomor referensi transaksi unik.
- [~] *`sp_create_user` & `sp_create_customer` (Legacy: Digantikan oleh `sp_register_customer`)*.

---

## ⚡ Triggers (Otomasi & Audit)
*Logic otomatis yang berjalan berdasarkan event (Insert/Update).*

- [x] **`trg_login_success`**: Reset failed attempts saat login berhasil.
- [x] **`trg_login_failed`**: Increment attempts & auto-lock akun (3x gagal).
- [ ] **`trg_audit_customer`**: Log setiap perubahan data nasabah ke `h_audit_trail`.
- [ ] **`trg_audit_account`**: Log perubahan data/status rekening ke `h_audit_trail`.
- [ ] **`trg_update_balance`**: Sinkronisasi saldo otomatis setelah transaksi (Opsional).

---

## 🛠️ Functions (Utility & Formatting)
*Logic pendukung untuk pengolahan nilai atau tampilan.*

- [ ] **`fn_format_idr`**: Ubah angka `DECIMAL` jadi format Rupiah (e.g., Rp 1.500.000).
- [ ] **`fn_mask_account`**: Sensor nomor rekening (e.g., 123xxxx890) untuk PII handling.
- [ ] **`fn_get_current_balance`**: Shortcut ambil saldo terakhir rekening tertentu.

---

## 📊 Views (Pelaporan & Monitoring)
*Query yang disimpan untuk mempermudah pembacaan data.*

- [x] **`vw_lihat_transaksi`**: Monitoring transaksi seminggu terakhir.
- [x] **`vw_customer_portfolio`**: Ringkasan nasabah beserta total saldo.
- [x] **`vw_daily_transaction_report`**: Laporan harian gabungan (manusiawi).
- [x] **`vw_user_security_status`**: Monitoring user locked/bermasalah.

---
*Terakhir diupdate: Sab, 23 Mei 2026 oleh Gemini CLI.*
