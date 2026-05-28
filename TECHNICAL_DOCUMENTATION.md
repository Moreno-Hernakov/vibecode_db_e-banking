# 🏦 DOKUMENTASI TEKNIS: SISTEM MOBILE BANKING (ENTERPRISE GRADE)

> **Tentang Dokumen Ini:** Panduan lengkap buat lu, temen-temen tim, atau siapapun yang pengen tau gimana "jeroan" database bank ini bekerja. Dibikin detail tapi tetep asik dibaca biar gak pusing.

---

## 💡 1. KONSEP UTAMA (Analogi Sederhana)

Biar temen-temen lu yang awam paham, sistem ini pake dua prinsip utama:

### A. Konsep "Dua Rumah" (Schema Isolation)
Bayangin bank ini punya dua rumah terpisah:
1.  **Rumah Keamanan (`authentication`)**: Isinya cuma kunci pintu, username, sama password. Kalau ada maling yang berhasil bobol rumah ini, dia cuma dapet kunci, tapi gak bisa langsung nemu brankas duitnya.
2.  **Rumah Brankas (`dsi_mb_srd`)**: Isinya semua duit nasabah, data rekening, sama catatan transaksi. Rumah ini gak kenal password lu, dia cuma kenal nomor identitas unik lu (CIF).
*   **Kenapa begini?** Biar kalau satu rumah bocor, rumah satunya tetep aman. Ini standar bank beneran!

### B. CIF (KTP-nya Bank)
**CIF** itu singkatan dari *Customer Information File*. 
*   **Analoginya:** Kalau lu punya 3 rekening di bank yang sama, bank gak bakal nyatet lu sebagai 3 orang beda. Lu tetep satu orang (satu nomor CIF), tapi nomor rekeningnya aja yang banyak. Jadi, CIF itu "pengikat" semua aset lu di bank.

---

## 🏃‍♂️ 2. CERITA FLOW BISNIS (Gimana Sistem Bekerja)

### A. Flow Registrasi (Bikin Akun Baru)
1.  Sistem minta data diri lu (Nama, HP, Email).
2.  Sistem bakal nanya: "Mau pake Username & Password apa?".
3.  **Di Balik Layar:** Prosedur `sp_register_customer` bakal jalanin tugas:
    *   Nulis data lu ke `m_customer` (Rumah Brankas).
    *   Otomatis bikin nomor CIF unik buat lu.
    *   Nulis username & password lu ke `m_user` (Rumah Keamanan).
    *   **Hasilnya:** Lu langsung punya akun login dan identitas nasabah secara bersamaan (Atomic).

### B. Keamanan Login (Anti-Maling)
Sistem ini punya "Security Guard" otomatis:
1.  Kalau lu login sukses, sistem bakal senyum dan ngereset hitungan salah password lu jadi 0.
2.  Kalau lu salah password, sistem bakal nyatet: "Eh, ini orang salah 1x".
3.  Kalau lu salah sampe **3x berturut-turut**, sistem bakal marah dan otomatis ganti status akun lu jadi **LOCKED**.
4.  **Efeknya:** Akun lu gak bisa dipake login sampe di-reset. Ini buat cegah orang nebak-nebak password lu (Brute Force).

### C. Flow Transfer Duit (Pindah Saldo)
Pas lu transfer duit lewat `sp_fund_transfer`, sistem bakal cek 4 hal:
1.  **Status Akun**: Lu lagi di-lock gak? Rekening tujuan aktif gak?
2.  **Saldo**: Duit lu cukup gak buat (Nominal Transfer + Biaya Admin)?
3.  **Limit Harian**: Lu udah jajan kebanyakan belum hari ini? (Sistem bakal cek ke tabel `m_limit`).
4.  **Atomicity**: Ini yang paling penting. Sistem bakal pastiin kalau saldo lu dipotong, saldo temen lu **PASTI** nambah. Gak boleh ada kejadian saldo lu udah kepotong tapi duitnya ilang di jalan.

---

## 🏦 3. KAMUS DATA (Table Dictionary)

Di sini kita bedah semua tabel (total 11 tabel) yang ada di sistem kita. Gak boleh ada yang kelewat!

### 🔑 A. Database: `authentication` (Rumah Keamanan)

1.  **`m_user`**: Master data pengguna yang punya akses login.
    *   `username`: ID unik buat login.
    *   `password`: Password yang udah di-hash (biar aman).
    *   `cif_number`: Kunci buat nyambungin ke data nasabah di brankas.
    *   `status`: Status akun (`ACTIVE` atau `LOCKED`).
    *   `failed_attempts`: Counter berapa kali salah password.
2.  **`m_password_history`**: Catatan "mantan" password.
    *   Fungsinya biar lu gak bisa pake password yang sama berulang kali. Standar keamanan bank (PCI-DSS).
3.  **`h_login_log`**: Catatan CCTV setiap ada yang mau masuk pintu login.
    *   Nyatet `ip_address`, `device_id`, sampe `status` (sukses/gagal). Penting buat audit kalau ada akun dibobol.

### 💰 B. Database: `dsi_mb_srd` (Rumah Brankas)

4.  **`m_customer`**: Profil lengkap nasabah.
    *   `cif_number`: KTP-nya bank (ID unik nasabah).
    *   `classification`: Kasta nasabah (1: Reguler, 2: Gold, 3: Platinum). Makin tinggi kastanya, makin gede limit jajannya.
    *   `client_pin`: PIN transaksi (beda ama password login ya!).
5.  **`m_account`**: Daftar rekening tabungan yang dipunya nasabah.
    *   Satu nasabah (satu CIF) bisa punya banyak rekening di sini.
    *   `balance`: Nominal duit yang lu punya.
6.  **`m_product_type`**: Jenis produk tabungan.
    *   Isinya kategori kayak: TABUNGAN, GIRO, atau DEPOSITO.
7.  **`m_feature`**: Katalog fitur m-banking.
    *   Daftar apa aja yang bisa dilakuin (Transfer, Bayar PLN, dll) plus biaya adminnya (`fee`).
8.  **`m_limit`**: Polisi limit transaksi.
    *   Isinya aturan: "Kasta Reguler cuma boleh transfer maksimal 10 Juta per hari". Ini buat jaga-gaga kalau akun lu dibobol, duit lu gak langsung ludes semua.
9. **`m_response_code`**: Kamus kode pesan sistem.
    *   `response_code`: Kode angka status transaksi (misal: `00`, `51`).
    *   `response_message`: Pesan manusiawi yang bakal muncul di layar HP nasabah (misal: "Saldo Tidak Cukup" atau "Sukses"). Jadi nasabah gak bingung cuma liat angka doang.
10. **`t_transaction`**: Buku besar mutasi duit.
    *   Semua kejadian pindah duit dicatat di sini secara permanen. Gak boleh ada yang dihapus!
    *   `reference_number`: Nomor unik bukti transfer.
11. **`h_audit_trail`**: Rekaman CCTV "orang dalem".
    *   Nyatet kalau ada orang dalem (admin) yang ngerubah data master (misal admin ngerubah nomor HP nasabah). Biar ketahuan kalau ada oknum admin yang nakal.

---

## 🤖 4. OTAK SISTEM (Logic Database)

### ⚙️ Stored Procedures (Instruksi Kerja)
*   **`sp_login_user`**: Satpam yang ngecek kunci pintu lu.
*   **`sp_fund_transfer`**: Kasir yang mindahin duit antar brankas.
*   **`sp_mutasi`**: Tukang rekap yang nyatet lu belanja apa aja hari ini.

### ⚡ Triggers (Alarm Otomatis)
*   **`trg_login_failed`**: Alarm yang bunyi kalau ada orang salah password 3x (langsung nge-lock akun).
*   **`trg_audit_account`**: Kamera yang otomatis motret kalau ada saldo yang berubah secara gak wajar.

### 🛠️ Functions (Alat Bantu)
*   **`fn_format_idr`**: Tukang bungkus angka biar jadi format Rupiah (e.g., Rp 1.000.000).
*   **`fn_mask_account`**: Tukang sensor biar nomor rekening lu gak kelihatan full (e.g., 123xxxx89).

### 📊 Views (Laporan Otomatis)
*   **`vw_lihat_transaksi`**: Monitoring transaksi seminggu terakhir. Biar lu tau duit lu lari ke mana aja selama 7 hari ke belakang.
*   **`vw_customer_portfolio`**: Ringkasan kekayaan nasabah. Lu bisa liat total saldo dari semua rekening yang lu punya dalam satu baris.
*   **`vw_daily_transaction_report`**: Laporan harian buat bank. Isinya rekap transaksi yang terjadi hari ini (siapa, beli apa, nominalnya berapa).
*   **`vw_user_security_status`**: Monitoring keamanan. Satpam digital yang nge-list siapa aja user yang lagi di-lock atau bermasalah.

---

## 🚩 5. TABEL KODE RESPON (Status Transaksi)

Kalau aplikasi lu munculin angka aneh, ini artinya:
*   **`00`**: Sukses! Duit pindah, hati tenang.
*   **`51`**: Saldo gak cukup (Duit lu tiris, Bos!).
*   **`61`**: Melewati limit harian (Jajan lu udah kebanyakan hari ini).
*   **`02`**: Akun Terkunci (Gara-gara salah password 3x).
*   **`99`**: Sistem Error (Lagi ada masalah di server).

---

## 🎓 6. FAQ PRESENTASI (Tips Sidang)

**Q: Kenapa saldonya gak ditaruh di tabel User aja?**
*   **Jawaban Pro:** "Karena prinsip *Separation of Duties*. Data kredensial (login) harus terpisah dari data finansial untuk meningkatkan keamanan dan performa kueri."

**Q: Kalau server mati pas transaksi, saldonya gimana?**
*   **Jawaban Pro:** "Kita pake Engine **InnoDB** dengan fitur **TRANSACTION**. Kalau sistem mati di tengah jalan, database bakal otomatis *Rollback* (batalin semua), jadi saldo gak bakal ilang di jalan."

**Q: CIF itu buat apa sih?**
*   **Jawaban Pro:** "CIF itu *Single Source of Truth* buat nasabah. Jadi satu nasabah punya banyak rekening pun, profilnya tetep satu dan konsisten."

---
*Dokumentasi ini di-generate otomatis oleh Gemini CLI (28 Mei 2026).*
