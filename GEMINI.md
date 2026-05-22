# Project Instructions: TA M-Banking (Enterprise Grade)

Dokumen ini berisi aturan main dan standar arsitektur yang wajib diikuti oleh Gemini CLI dalam mengelola database project ini.

## 🏗️ Arsitektur Database
- **Schema Isolation:** Menggunakan dua database terpisah:
  - `authentication`: Khusus kredensial dan keamanan akses.
  - `dsi_mb_srd`: Data operasional, nasabah, dan transaksi.
- **Relasi Lintas Database:** Dijaga via **Logical Business Key** (`cif_number`).

## 📏 Standar Penamaan Tabel (Naming Convention)
Wajib menggunakan prefix berikut untuk setiap tabel baru:
- **`M_` (Master):** Data referensi statis/semi-statis. (Contoh: `M_CUSTOMER`, `M_FEATURE`).
- **`T_` (Transaction):** Data operasional/finansial yang sedang berjalan. (Contoh: `T_TRANSACTION`).
- **`H_` (History):** Data arsip, audit trail, atau log historis. (Contoh: `H_USER_LOGIN`).

## 🛠️ Standar Teknis & Tipe Data
- **Primary Key:** Selalu gunakan `BIGINT AUTO_INCREMENT` untuk tabel dengan volume data tinggi.
- **Mata Uang:** Wajib menggunakan `DECIMAL(15,2)` untuk semua field nominal.
- **Audit Columns:** Setiap tabel Master (`M_`) wajib memiliki kolom:
  - `created_at` (TIMESTAMP)
  - `created_by` (VARCHAR)
  - `updated_at` (TIMESTAMP)
  - `updated_by` (VARCHAR)
- **Constraint:** Selalu gunakan `InnoDB` engine untuk mendukung Foreign Key dan Transaksi.

## 🛡️ Standar Domain Perbankan (Business Logic)
Agar sesuai dengan pengalaman real-world lu di industri banking, setiap implementasi wajib mengikuti prinsip ini:

1.  **Data Persistence (No Hard Deletes):**
    - Jangan pernah menghapus data nasabah atau transaksi secara permanen (`DELETE`).
    - Gunakan flag status (misal: `is_deleted`, `status = 'INACTIVE'`) atau pindahkan ke tabel `H_` (History).
2.  **PII Handling (Personally Identifiable Information):**
    - Data sensitif seperti `client_pin` atau `password` wajib di-hash (Bcrypt/Argon2).
    - Data seperti `customer_phone` atau `customer_email` harus diperlakukan secara hati-hati (siapkan opsi masking jika nanti ada kueri pelaporan).
3.  **Audit Integrity:**
    - Setiap kegagalan sistem atau transaksi harus tercatat di `response_code` yang jelas (ISO 8583).
    - Log audit (`created_by`, `updated_by`) harus mencatat aktor aslinya (bisa ID user atau nama sistem).
4.  **Transaction Consistency:**
    - Gunakan `TRANSACTION` block (Begin...Commit/Rollback) untuk operasi yang melibatkan lebih dari satu tabel (misal: insert ke `t_transaction` dan update saldo/limit).
5.  **Multi-Account Binding:**
    - Satu `cif_number` bisa memiliki banyak `registration_account_number`. Pastikan kueri selalu mempertimbangkan relasi 1:N ini.

## 🤝 Team Collaboration & Audit
Project ini dikerjakan oleh tim yang terdiri dari **2 orang**. Untuk menjaga integritas data dan kemudahan debugging, aturan berikut wajib diikuti:
1.  **Strict Audit Logging:** Kolom `created_by` dan `updated_by` wajib diisi dengan inisial atau nama anggota tim yang melakukan perubahan data (bukan sekadar 'SYSTEM').
2.  **Shared Memory:** Segala perubahan skema atau logic yang disepakati bersama harus segera diupdate ke `GEMINI.md` agar seluruh tim (dan gw sebagai asisten) tetap sinkron.

## 💡 Prinsip Pengembangan
- **CIF-Centric:** Nasabah diidentifikasi unik melalui `cif_number`.
- **ISO 8583 Compliance:** Response code dan flow transaksi harus berkiblat pada standar perbankan.
- **Surgical Update:** Setiap perubahan pada `.sql` harus dibarengi dengan update pada `BLUEPRINT.md`.
