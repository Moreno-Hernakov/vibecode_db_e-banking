# 📝 Sesi Brainstorming & Planning

Halaman ini digunakan untuk mencatat ide, alur kerja, dan rencana pengembangan sebelum diimplementasikan ke dalam kode atau skema database.

---

## 🔐 Modul 1: Keamanan Akun & Kredensial nasabah

### 1.1. Mekanisme Password Hashing
**Ide:** Membuat function di SQL untuk menangani enkripsi/hashing password saat registrasi atau ganti password.

**Analisis Standar Banking:**
- **Hashing vs Encryption:** Di perbankan, kita pake **Hashing** (One-way) bukan enkripsi (reversible). Password kaga boleh bisa didekrip balik, bahkan oleh admin database sekalipun.
- **Algoritma:** 
  - Standar modern: `Bcrypt`, `Argon2`, atau minimal `SHA-256` dengan *Salt*.
  - Di MySQL/MariaDB: Ada function bawaan `SHA2()`, tapi untuk `Bcrypt` biasanya butuh plugin atau dihandle di level API (Backend).

**Rencana Implementasi:**
1.  **Opsi A (SQL Function):** Bikin function `fn_hash_password(raw_password)` yang nge-return string hasil hash.
2.  **Opsi B (Verification):** Verifikasi kaga bisa pake `WHERE password = 'string_baru'`, tapi harus `WHERE password = fn_hash_password('string_input')`.

### 1.2. Tabel Pendukung Keamanan (Rencana)
- `M_PASSWORD_HISTORY`: Simpan hash 3-5 password terakhir biar user kaga bisa pake password yang lama (Compliance PCI-DSS).
- `H_LOGIN_ATTEMPT`: Catat gagal login buat proteksi *Brute Force*.

---

## 🔒 Modul 2: Account Locking Mechanism (3x Fail)

### 2.1. Logic Workflow
1.  **Input:** User memasukkan username & password.
2.  **Validation:**
    - Jika Username TIDAK ADA: Return error umum (Demi keamanan, jangan kasih tau username salah atau password salah).
    - Jika Akun Terkunci (`status = 'LOCKED'`): Tolak login langsung.
3.  **Password Match Check:**
    - **Jika SALAH:**
        - Increment `failed_attempts` di `M_USER`.
        - Jika `failed_attempts` >= 3, set `status = 'LOCKED'`.
        - Record ke `H_LOGIN_ATTEMPT` dengan status 'FAILED'.
    - **Jika BENAR:**
        - Reset `failed_attempts = 0`.
        - Record ke `H_LOGIN_ATTEMPT` dengan status 'SUCCESS'.
### 2.2. Kebijakan Unlock (Final)
- **Manual Unlock:** Akun yang terkunci (`LOCKED`) TIDAK AKAN terbuka otomatis.
- **Prosedur:** Nasabah harus melapor ke CS/Admin. Admin akan mengubah `status = 'ACTIVE'` dan **WAJIB** mereset `failed_attempts = 0`.
- **Audit:** Setiap aksi unlock wajib dicatat di `H_AUDIT_TRAIL` (Siapa adminnya, kapan, alasan unlock).

### 2.3. Tabel Audit: `H_LOGIN_ATTEMPT`
Setiap percobaan login (baik sukses maupun gagal) WAJIB dicatat di sini.
- `id`: BIGINT PK AI.
- `username`: VARCHAR(50).
- `attempt_time`: TIMESTAMP DEFAULT CURRENT_TIMESTAMP.
- `status`: ENUM('SUCCESS', 'FAILED', 'LOCKED').
- `ip_address`: VARCHAR(50).
- `user_agent`: TEXT (Browser/Device Info).
- `error_message`: VARCHAR(255) (Opsional: misal "Invalid Password", "Account Locked").

---
### 3.1. Konsep Relasi 1:N (One-to-Many)
- **`M_CUSTOMER` (Profile):** Menyimpan identitas tunggal nasabah (Nama, Alamat, No HP). **1 CIF = 1 Row.** Ini adalah **Golden Record** (Single Source of Truth).
- **`M_CUSTOMER_ACCOUNT` (Accounts):** Menyimpan daftar rekening yang dimiliki nasabah. **1 CIF = Many Rows.**

### 3.3. Prinsip Anti-Redundansi (Normalization)
- **Data Ngikut Master:** Data statis seperti alamat, tempat tanggal lahir, dan no HP **TIDAK BOLEH** ada di tabel `M_CUSTOMER_ACCOUNT`.
- **Join Strategy:** Untuk menampilkan alamat nasabah di tiap rekening, gunakan `JOIN` antara `M_CUSTOMER_ACCOUNT` dan `M_CUSTOMER` berdasarkan `cif_number`.
- **Update Behavior:** Jika nasabah update No HP, cukup update di `M_CUSTOMER`. Perubahan otomatis tercermin di seluruh produk/rekening terkait.

---

### 3.2. Struktur Tabel Multi-Product
#### 1. `M_PRODUCT_TYPE` (Master Kategori)
- `id`: INT PK.
- `product_name`: VARCHAR (TABUNGAN, GIRO, DEPOSITO, LOAN).

#### 2. `M_CUSTOMER_ACCOUNT` (Daftar Rekening)
- `account_number`: VARCHAR(20) PK.
- `cif_number`: VARCHAR(20) FK (Ke `M_CUSTOMER.cif_number`).
- `product_type_id`: INT FK.
- `balance`: DECIMAL(15,2).
- `status`: VARCHAR(20) (ACTIVE, CLOSED).

---

## ⚖️ Modul 4: Daily Limit & Transaction Validation

### 4.1. Konfigurasi Limit (Tabel `M_LIMIT`)
Limit diatur berdasarkan jenis fitur dan klasifikasi nasabah (Reguler, Gold, dsb).
- `id`: INT PK.
- `feature_code`: VARCHAR(10) FK.
- `classification`: INT (Reference to nasabah segment).
- `limit_amount`: DECIMAL(15,2) (Batas maksimal per hari).

### 4.2. Validation Workflow
Setiap kali nasabah melakukan transaksi:
1.  **Check Status:** Pastikan rekening asal `ACTIVE` dan saldo cukup.
2.  **Aggregate Daily:** Hitung total transaksi sukses untuk fitur tersebut hari ini dari `T_TRANSACTION`.
3.  **Compare:** 
    - Jika `(Total_Hari_Ini + Transaksi_Baru) > limit_amount` -> REJECT (Response Code: 61 - Exceeds Daily Limit).
4.  **Execute:** Jika lolos, kurangi saldo dan record transaksi.

### 4.3. Failure Logging Strategy
Setiap kegagalan validasi (Limit, Saldo, Status Akun) **WAJIB** tetap di-record ke `T_TRANSACTION`:
- `transaction_status`: 'FAILED'.
- `response_code`: Kode yang sesuai dari `M_RESPONSE_CODE` (e.g., '51' untuk Saldo Kurang, '61' untuk Limit).
- **Tujuan:** Audit trail untuk Customer Support dan analisis perilaku nasabah.

---

## 🛡️ Modul 5: Transaction Authorization (MPIN & OTP)

### 5.1. MPIN (Mobile PIN)
- **Storage:** Disimpan di `M_CUSTOMER.client_pin`.
- **Validation:** Wajib di-hash (Bcrypt/SHA-2). Berbeda dengan password login.
- **Locking:** Salah MPIN 3x beruntun akan memicu:
    - `need_authorized_unblock = TRUE` di `M_CUSTOMER`.
    - **`status = 'LOCKED'` di `authentication.M_USER`** (Nasabah tidak bisa login total).
    - **Note:** Unlock hanya bisa dilakukan oleh Admin via Back-Office.

### 5.2. OTP (One-Time Password) - Tabel `T_OTP_LOG`
Digunakan untuk validasi aksi sensitif (Ganti Device, Registrasi).
- `id`: BIGINT PK.
- `cif_number`: VARCHAR(20).
- `otp_code`: VARCHAR(10) (Hashed).
- `expired_at`: TIMESTAMP.
- `is_used`: BOOLEAN DEFAULT FALSE.
- `channel`: VARCHAR(10) (SMS, EMAIL).

### 5.3. Authorization Flow
1. User input MPIN/OTP.
2. Sistem validasi hash & expiration.
3. Jika valid, jalankan prosedur transaksi/registrasi.
4. Jika tidak valid 3x, kunci akses fitur terkait.

---

## 📜 Modul 6: Statement & Mutation (MB-Focused)

### 6.1. Konsep Transaction-Based Mutation
Karena fokus pada M-Banking, mutasi diambil langsung dari history transaksi yang tercatat.

#### Logic Kueri
Mutasi ditentukan berdasarkan posisi nomor rekening pada transaksi:
- **Debit (DB):** Jika nomor rekening nasabah ada di kolom `from_account_number`.
- **Kredit (CR):** Jika nomor rekening nasabah ada di kolom `customer_reference` (sebagai tujuan transfer dari sesama pengguna M-Banking).

### 6.2. Business Rules
1. **Query Strategy:** Menggunakan `OR` pada kolom pengirim dan penerima untuk mendapatkan history lengkap (Uang masuk & keluar).
2. **Display Limit:** Menampilkan 10-20 transaksi terbaru untuk kecepatan loading aplikasi.
3. **Status Filter:** Hanya menampilkan transaksi dengan status 'SUCCESS' di menu mutasi standar (Transaksi 'FAILED' masuk ke menu lain/log audit).

---

## 📈 Backlog Fitur (Ide Lu)
- [ ] Implementasi Function Hashing Password.
- [ ] Sinkronisasi `M_USER` status saat salah PIN 3x di `M_CUSTOMER`.
- [ ] Implementasi Stored Procedure untuk Login Logic.
- [ ] Tambah kolom `failed_attempts` di `M_USER`.
- [ ] Implementasi Master Produk (`M_PRODUCT_TYPE`).
- [ ] Refactor `M_CUSTOMER` agar fokus ke Profil Nasabah.
- [ ] Buat Tabel `M_CUSTOMER_ACCOUNT` untuk mapping multi-rekening.
- [ ] Implementasi Tabel `M_LIMIT` (Limit per Feature & Classification).
- [ ] Implementasi Tabel `T_OTP_LOG` untuk keamanan tambahan.
- [ ] Optimasi `T_TRANSACTION` untuk kueri mutasi DB/CR.
- [ ] (Lanjutkan ide lu di sini...)
