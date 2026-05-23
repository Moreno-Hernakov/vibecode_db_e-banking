# KAMUS DATA (FIELD DICTIONARY) - TA M-BANKING (ENTERPRISE GRADE)

Dokumen ini berisi penjelasan detail mengenai setiap field dalam database project M-Banking. Struktur ini telah disesuaikan dengan standar industri perbankan (CIF-Centric & Schema Isolation).

---

## 🛡️ Database: `authentication`
*Fokus: Mengelola kredensial login, keamanan akun, dan audit akses.*

### 1. Tabel `m_user` (Master User)
| Field | Tipe Data | Penjelasan |
| :--- | :--- | :--- |
| `id` | BIGINT (PK) | ID unik internal sistem (Auto Increment). |
| `username` | VARCHAR(50) | Username unik untuk login aplikasi. |
| `password` | VARCHAR(255) | Hash password user (keamanan tingkat tinggi). |
| `cif_number` | VARCHAR(20) | **Logical Business Key**. Penghubung ke data nasabah di database bisnis. |
| `status` | VARCHAR(20) | Kondisi akun (`ACTIVE`, `LOCKED`, `SUSPEND`). |
| `failed_attempts` | INT | Counter kesalahan password (Otomatis lock jika >= 3). |
| `last_failed_login` | TIMESTAMP | Catatan waktu terakhir kali user gagal login. |
| `suspend_until` | TIMESTAMP | Masa berlaku suspend akun (jika ada). |
| `created` | TIMESTAMP | Waktu akun dibuat. |
| `updated` | TIMESTAMP | Waktu terakhir data akun di-update. |

### 2. Tabel `m_password_history` (History Password)
| Field | Tipe Data | Penjelasan |
| :--- | :--- | :--- |
| `username` | VARCHAR(50) | Referensi ke username terkait. |
| `password_hash` | VARCHAR(255) | Jejak password lama untuk mencegah penggunaan ulang password yang sama. |

### 3. Tabel `h_login_log` (Log Login)
| Field | Tipe Data | Penjelasan |
| :--- | :--- | :--- |
| `cif_number` | VARCHAR(20) | Identifikasi nasabah yang melakukan percobaan login. |
| `login_time` | TIMESTAMP | Waktu eksekusi login. |
| `ip_address` | VARCHAR(50) | Alamat IP perangkat yang digunakan. |
| `device_id` | VARCHAR(100) | ID unik perangkat (misal: IPHONE-15, SM-G99). |
| `status` | ENUM | Hasil login (`SUCCESS`, `FAILED`, `LOCKED`). |

---

## 💰 Database: `dsi_mb_srd`
*Fokus: Data nasabah, rekening, fitur, dan log transaksi finansial.*

### 1. Tabel `m_customer` (Master Nasabah)
| Field | Tipe Data | Penjelasan |
| :--- | :--- | :--- |
| `cif_number` | VARCHAR(20) (PK) | ID Unik Nasabah (CIF = Customer Information File). |
| `customer_name` | VARCHAR(100) | Nama lengkap nasabah sesuai identitas. |
| `classification` | INT | Kasta nasabah (1: Reguler, 2: Gold, 3: Platinum). |
| `client_pin` | VARCHAR(255) | PIN khusus untuk otorisasi transaksi finansial. |
| `created` | TIMESTAMP | Waktu profil nasabah dibuat. |

### 2. Tabel `m_account` (Master Rekening)
| Field | Tipe Data | Penjelasan |
| :--- | :--- | :--- |
| `account_number` | VARCHAR(20) (PK) | Nomor rekening unik. |
| `cif_number` | VARCHAR(20) | Pemilik rekening (Relasi 1 Nasabah : N Rekening). |
| `product_type_id` | INT | Jenis tabungan (Tabungan, Giro, Deposito). |
| `balance` | DECIMAL(15,2) | Saldo real-time nasabah. |

### 3. Tabel `m_limit` (Master Limit)
| Field | Tipe Data | Penjelasan |
| :--- | :--- | :--- |
| `feature_code` | VARCHAR(10) | Kode fitur (misal: Transfer). |
| `classification` | INT | Level nasabah yang terkena limit. |
| `limit_amount` | DECIMAL(15,2) | Batas maksimal nominal transaksi per hari. |

### 4. Tabel `m_feature` (Master Fitur)
| Field | Tipe Data | Penjelasan |
| :--- | :--- | :--- |
| `feature_code` | VARCHAR(10) (PK) | Kode unik fitur aplikasi. |
| `feature_name` | VARCHAR(100) | Nama layanan (misal: Transfer Sesama Bank). |
| `fee` | DECIMAL(15,2) | Biaya admin default untuk layanan tersebut. |

### 5. Tabel `t_transaction` (Tabel Transaksi / Mutasi)
| Field | Tipe Data | Penjelasan |
| :--- | :--- | :--- |
| `reference_number` | VARCHAR(50) (UK) | ID transaksi unik (Audit Key). |
| `cif_number` | VARCHAR(20) | Nasabah pelaku transaksi. |
| `from_account_number` | VARCHAR(20) | Rekening sumber dana. |
| `customer_reference` | VARCHAR(50) | Nomor tujuan (Rekening tujuan atau ID Pelanggan). |
| `transaction_amount` | DECIMAL(15,2) | Nominal dana yang dipindah/dibayar. |
| `fee` | DECIMAL(15,2) | Biaya admin yang dikenakan saat transaksi terjadi. |
| `transaction_status` | VARCHAR(20) | Status operasional (`SUCCESS`, `FAILED`). |
| `response_code` | VARCHAR(5) | Kode respon standar (00: Success, 51: Insufficient Fund, dll). |
| `biller_name` | VARCHAR(100) | Nama penyedia layanan (untuk transaksi PPOB/Bayar). |
| `location` | VARCHAR(100) | Channel transaksi (Default: 'MOBILE-APPS'). |
| `transaction_date` | TIMESTAMP | Waktu eksekusi transaksi. |

### 6. Tabel `h_audit_trail` (Audit Internal)
| Field | Tipe Data | Penjelasan |
| :--- | :--- | :--- |
| `table_name` | VARCHAR(50) | Nama tabel yang datanya diubah manual. |
| `action_type` | ENUM | Jenis perubahan (`INSERT`, `UPDATE`, `DELETE`). |
| `old_value` | TEXT | Data sebelum diubah. |
| `new_value` | TEXT | Data sesudah diubah. |
| `action_by` | VARCHAR(50) | Aktor/User yang melakukan perubahan. |

---

## 🏛️ Prinsip Arsitektur (Untuk Sidang)
1. **Schema Isolation**: Memisahkan kredensial (`authentication`) dari data operasional (`dsi_mb_srd`) untuk keamanan.
2. **CIF-Centric**: Menjadikan `cif_number` sebagai pengikat utama seluruh data nasabah.
3. **Data Integrity**: Menggunakan `InnoDB` engine untuk menjamin konsistensi saldo lewat Foreign Keys dan Transactional Block.
