# Penjelasan Aplikasi Internet Banking

Dokumen ini menjelaskan cara kerja aplikasi internet banking ini secara detail dan apa adanya, mengikuti urutan perjalanan seorang nasabah: mulai dari mendaftar sendiri, masuk ke aplikasi, mengelola rekening, melakukan transaksi, hingga melihat laporan. Penjelasan ditulis dari sisi alur dan perilaku sistem, bukan dari sisi struktur penyimpanan datanya.

---

## 1. Pendahuluan

Aplikasi ini adalah layanan **internet banking**: sebuah aplikasi yang memungkinkan nasabah mengakses dan mengelola rekeningnya secara mandiri melalui perangkat sendiri (ponsel/komputer), tanpa harus datang ke kantor cabang.

**Siapa penggunanya?** Nasabah perorangan yang ingin melakukan aktivitas perbankan sehari-hari, seperti memeriksa saldo, melakukan transfer, membayar tagihan, dan melihat riwayat transaksi.

**Apa yang bisa dilakukan?**
- Mendaftar sendiri untuk membuat akun (menu Register).
- Masuk ke aplikasi dengan username dan password (menu Login).
- Mengelola satu atau beberapa rekening sekaligus dalam satu akun.
- Melakukan transfer antar rekening dan pembayaran tagihan.
- Melihat mutasi (riwayat transaksi) dan informasi saldo.

**Ringkasan perjalanan nasabah.** Nasabah pertama-tama membuka aplikasi dan mendaftar secara mandiri lewat menu Register; saat itu juga sistem membuatkan identitas nasabah dan akun login sekaligus. Setelah punya akun, nasabah masuk lewat menu Login. Bila login berhasil, nasabah dapat melihat rekening-rekeningnya, menggunakan fitur transaksi (transfer/pembayaran) yang dibatasi oleh aturan saldo dan limit harian, lalu memantau hasilnya melalui mutasi dan laporan.

---

## 2. Registrasi Mandiri (Menu Register)

Nasabah baru dapat membuat akun sendiri melalui menu **Register**, tanpa bantuan petugas. Berikut langkah-langkahnya.

**Langkah 1 — Mengisi data diri.** Nasabah memasukkan:
- Nama lengkap
- Nomor telepon (HP)
- Alamat email

**Langkah 2 — Membuat kredensial akun.** Nasabah menentukan:
- **Username** untuk login
- **Password** untuk login

**Langkah 3 — Menetapkan PIN transaksi.** Nasabah menetapkan **PIN**, yaitu kode rahasia yang dipakai untuk mengamankan transaksi. PIN ini berbeda dari password login: password untuk masuk aplikasi, PIN untuk mengesahkan transaksi.

**Langkah 4 — Sistem memproses pendaftaran.** Setelah data dikirim, sistem melakukan beberapa hal secara otomatis dalam **satu proses yang utuh**:
1. Menyimpan data diri nasabah.
2. Membuat **identitas nasabah unik (CIF)** secara otomatis. CIF adalah nomor identitas tunggal nasabah di bank ini (contoh format: `CIF000003`). Satu nasabah hanya punya satu CIF seumur hidupnya, dan inilah yang mengikat seluruh rekening serta data nasabah menjadi satu kesatuan.
3. Membuat **akun login** (username & password) yang langsung terhubung ke identitas nasabah tadi.

**Sifat "sekali jalan" (atomic).** Ketiga hal di atas dikerjakan sebagai satu kesatuan. Bila ada satu bagian yang gagal di tengah jalan, **seluruh proses dibatalkan** dan dikembalikan seperti semula. Tujuannya agar tidak pernah ada data yang "menggantung" — misalnya punya akun login tetapi tidak punya identitas nasabah, atau sebaliknya.

**Hasil akhir.** Begitu registrasi selesai, nasabah **langsung memiliki identitas nasabah sekaligus akun login yang siap dipakai**. Nasabah bisa langsung lanjut ke menu Login.

---

## 3. Login (Alur Normal)

Setelah punya akun, nasabah masuk ke aplikasi melalui menu **Login**.

**Langkah 1 — Memasukkan kredensial.** Nasabah mengetik **username** dan **password**.

**Langkah 2 — Sistem mencatat informasi akses.** Setiap kali ada upaya login, sistem mencatat informasi teknis dari perangkat yang digunakan:
- **Alamat IP** (lokasi jaringan asal akses)
- **Perangkat** yang dipakai (device, mis. tipe ponsel)
- **Versi aplikasi** yang digunakan

Pencatatan ini berguna sebagai bukti dan jejak bila suatu saat terjadi sengketa atau dugaan upaya pembobolan akun.

**Langkah 3 — Sistem memeriksa kredensial.** Sistem mencocokkan username dan password yang dimasukkan dengan data akun nasabah. Hasil pemeriksaan ini bisa berupa salah satu dari **empat kemungkinan**: berhasil, akun tidak ditemukan, password salah, atau akun sedang terkunci. Bila kredensial benar dan akun dalam keadaan normal, nasabah **berhasil masuk** ke aplikasi dan dapat menggunakan seluruh fitur.

Rincian keempat kemungkinan hasil dan aturan main login dijelaskan lengkap pada bagian berikutnya.

---

## 4. Aturan Login (Bagian Inti)

Bagian ini menjelaskan secara rinci aturan main saat nasabah mencoba masuk ke aplikasi.

### 4.1 Empat Kemungkinan Hasil Login

Setiap upaya login akan menghasilkan tepat satu dari empat kondisi berikut:

| Kondisi | Penyebab | Pesan/arti bagi pengguna |
|---|---|---|
| **Berhasil** | Username ditemukan, akun aktif, dan password benar | "Login berhasil" — nasabah masuk ke aplikasi |
| **Akun tidak ditemukan** | Username yang dimasukkan tidak terdaftar | "Pengguna tidak ditemukan / kredensial tidak valid" |
| **Password salah** | Username terdaftar, akun aktif, tetapi password tidak cocok | "Password salah" |
| **Akun terkunci** | Username terdaftar, tetapi status akun sedang terkunci | "Akun terkunci" |

### 4.2 Penguncian Otomatis Setelah 3x Salah (Auto-Lock)

Sistem menghitung berapa kali password dimasukkan salah secara berturut-turut:
- Setiap kali password salah, hitungan kesalahan **bertambah satu**.
- Bila password salah mencapai **3 kali berturut-turut**, status akun secara otomatis diubah menjadi **TERKUNCI (LOCKED)**.
- Setelah terkunci, akun **tidak bisa dipakai login** meskipun nasabah kemudian memasukkan password yang benar — selama akun masih dalam status terkunci, hasilnya tetap "Akun terkunci".

Aturan ini melindungi nasabah dari upaya menebak-nebak password oleh pihak yang tidak berhak (brute force).

### 4.3 Reset Hitungan Saat Login Berhasil

Hitungan kesalahan tidak menumpuk selamanya. Begitu nasabah **berhasil login**, hitungan kesalahan sebelumnya **otomatis dikembalikan ke nol**. Jadi, misalnya nasabah sempat salah 2 kali lalu berhasil login di percobaan ketiga, hitungannya kembali bersih dari nol — bukan tinggal satu langkah menuju terkunci.

### 4.4 Pencatatan Setiap Percobaan Login

Sistem mencatat **semua** upaya login, bukan hanya yang berhasil. Ada tiga jenis catatan yang disimpan beserta informasi akses (IP, perangkat, versi aplikasi):
- **Berhasil** — login sukses.
- **Gagal** — password salah.
- **Terkunci** — ada upaya login pada akun yang memang sudah dalam status terkunci.

Dengan begitu, bank punya rekam jejak lengkap "siapa mencoba masuk, kapan, dan dari perangkat apa".

### 4.5 Aturan Ganti Password

Nasabah dapat mengganti passwordnya. Aturannya:
- Nasabah harus memasukkan **password lama** dengan benar terlebih dahulu. Bila password lama salah, penggantian ditolak.
- Password baru **tidak boleh sama dengan password yang pernah dipakai sebelumnya**. Sistem menyimpan riwayat password lama dan akan menolak bila password baru ternyata pernah digunakan. Tujuannya menjaga agar kunci akses selalu segar dan tidak didaur ulang.
- Bila kedua syarat terpenuhi, password berhasil diganti dan password lama dipindahkan ke riwayat.

| Hasil ganti password | Arti |
|---|---|
| Berhasil | Password berhasil diperbarui |
| Gagal — password lama salah | Password lama yang dimasukkan tidak cocok |
| Gagal — password pernah dipakai | Password baru sama dengan salah satu password yang pernah digunakan |

---

## 5. Rekening Nasabah: Satu Nasabah, Banyak Rekening

Berkat identitas nasabah tunggal (CIF), **satu nasabah dapat memiliki lebih dari satu rekening** dalam satu akun login. Hubungannya bersifat satu-ke-banyak: satu identitas nasabah menaungi satu atau beberapa rekening sekaligus.

**Contoh ilustrasi.** Seorang nasabah bisa memiliki dua rekening tabungan sekaligus — misalnya satu untuk kebutuhan harian dan satu untuk tabungan terpisah. Keduanya berada di bawah satu identitas nasabah dan dapat diakses dengan satu kali login.

**Setiap rekening berdiri sendiri.** Tiap rekening memiliki:
- **Nomor rekening** sendiri yang unik,
- **Saldo** sendiri,
- **Status** sendiri (aktif atau tidak aktif).

### Tipe Rekening

Aplikasi menyediakan beberapa **tipe rekening**:

| Tipe Rekening | Keterangan |
|---|---|
| **Tabungan** | Rekening untuk menyimpan dana dan transaksi sehari-hari |
| **Giro** | Rekening untuk kebutuhan transaksi yang lebih besar/bisnis |
| **Deposito** | Rekening simpanan berjangka |

Saat membuka rekening, setiap rekening dikaitkan dengan salah satu tipe di atas.

---

## 6. Tingkatan Nasabah & Fitur Transaksi

### 6.1 Tingkatan (Kelas) Nasabah

Setiap nasabah memiliki **tingkatan** atau kelas yang menentukan **batas (limit) transaksi hariannya**. Semakin tinggi kelasnya, semakin besar limit transaksi yang diperbolehkan dalam satu hari:

| Kelas | Nama Tingkatan |
|---|---|
| 1 | Reguler |
| 2 | Gold |
| 3 | Platinum |

Tingkatan ini berfungsi membatasi potensi kerugian: bila terjadi penyalahgunaan akun, jumlah dana yang bisa berpindah dalam sehari tetap dibatasi sesuai kelas nasabah.

### 6.2 Fitur Transaksi yang Tersedia

Aplikasi menyediakan beberapa fitur transaksi, masing-masing dengan **biaya admin** yang dihitung otomatis dan transparan saat transaksi terjadi:

| Fitur | Biaya Admin |
|---|---|
| **Transfer Sesama Bank** | Rp 0 (gratis) |
| **Transfer Antar Bank** | Rp 6.500 |
| **Pembayaran PLN** | Rp 3.000 |

Katalog fitur ini dirancang agar dapat diperluas — artinya, jenis pembayaran atau pembelian lain dapat ditambahkan ke dalam daftar fitur di kemudian hari mengikuti pola yang sama (nama fitur + biaya adminnya).

### 6.3 Limit Harian per Kelas

Limit harian ditentukan oleh **kombinasi fitur dan kelas nasabah**. Sebagai contoh nyata:

| Fitur | Kelas | Limit Harian |
|---|---|---|
| Transfer Sesama Bank | Reguler | Rp 10.000.000 / hari |
| Transfer Sesama Bank | Gold | Rp 50.000.000 / hari |
| Transfer Antar Bank | Reguler | Rp 5.000.000 / hari |

Limit dihitung berdasarkan **total nominal transaksi berhasil pada fitur tersebut di hari yang sama**. Jadi, batas ini berlaku per fitur per hari, dan akan mereset di hari berikutnya.

---

## 7. Alur Transaksi & Pengecekan (Transfer / Pembayaran)

Ketika nasabah melakukan transaksi (misalnya transfer), sistem tidak langsung memindahkan dana. Sistem terlebih dahulu melakukan **serangkaian pengecekan secara berurutan**. Bila ada satu pengecekan yang tidak lolos, transaksi langsung ditolak dengan alasan yang jelas.

### 7.1 Urutan Pengecekan

1. **Cek status rekening.** Rekening asal dan rekening tujuan harus sama-sama **aktif**. Bila salah satu tidak ditemukan atau tidak aktif, transaksi ditolak dengan alasan *status rekening tidak valid*.
2. **Cek kecukupan saldo.** Saldo rekening asal harus cukup untuk menutup **nominal transaksi + biaya admin**. Bila kurang, transaksi ditolak dengan alasan *saldo tidak cukup*.
3. **Cek limit harian.** Total transaksi pada fitur tersebut hari ini ditambah nominal transaksi baru tidak boleh melebihi **limit harian sesuai kelas nasabah**. Bila melebihi, transaksi ditolak dengan alasan *melewati limit harian*.

### 7.2 Bila Semua Pengecekan Lolos

- **Nomor referensi unik** dibuat sebagai bukti transaksi.
- Saldo rekening asal **dikurangi** sebesar (nominal + biaya admin).
- Saldo rekening tujuan **ditambah** sebesar nominal.
- Kedua perubahan saldo ini dilakukan dalam **satu transaksi utuh**: bila salah satu langkah gagal, seluruh perubahan dibatalkan, sehingga tidak akan pernah terjadi "saldo terpotong tetapi dana tidak sampai".
- Transaksi dicatat sebagai **berhasil**.

### 7.3 Bila Ada Pengecekan yang Gagal

Transaksi **tetap dicatat**, tetapi berstatus **GAGAL**, lengkap dengan **alasan kegagalannya**. Dengan begitu, riwayat percobaan transaksi yang gagal pun tetap terekam untuk keperluan penelusuran.

### 7.4 Daftar Kode/Alasan Respon

Setiap transaksi atau upaya akses menghasilkan kode status. Berikut artinya dalam bahasa sehari-hari:

| Kode | Arti / Pesan |
|---|---|
| 00 | Sukses |
| 51 | Saldo tidak cukup |
| 61 | Melewati limit harian |
| 68 | Waktu tunggu sistem eksternal habis (timeout) |
| 99 | Terjadi kesalahan sistem |
| 01 | Pengguna tidak ditemukan / kredensial tidak valid |
| 02 | Akun terkunci |
| 03 | Password salah |
| 14 | Status rekening tidak valid |

---

## 8. Mutasi, Rekap Harian, Audit & Keamanan Tampilan

### 8.1 Mutasi Harian (untuk Nasabah)

Nasabah dapat melihat **mutasi**, yaitu daftar transaksi miliknya pada hari berjalan. Mutasi menampilkan informasi seperti nomor referensi, nominal, biaya, status/keterangan, waktu, dan lokasi transaksi. Ini membantu nasabah memantau ke mana saja dananya bergerak.

### 8.2 Rekap Harian / Tutup Buku (untuk Bank)

Di sisi bank, tersedia **rekap harian** yang merangkum seluruh transaksi pada hari berjalan — menampilkan **jumlah transaksi dan total nominal per nasabah**. Laporan ini berguna untuk pemantauan operasional dan kontrol harian.

### 8.3 Pencatatan Otomatis Perubahan Data Sensitif (Jejak Audit)

Sistem secara otomatis merekam setiap perubahan pada data sensitif tertentu, dengan menyimpan **nilai lama dan nilai baru**:
- **Perubahan saldo rekening** — setiap kali saldo berubah, nilai sebelum dan sesudah dicatat.
- **Perubahan PIN nasabah** — perubahan PIN juga direkam jejaknya.

Pencatatan ini memberi bank rekam jejak yang dapat ditelusuri bila ada perubahan data yang mencurigakan, termasuk bila perubahan dilakukan oleh pihak internal.

### 8.4 Keamanan Tampilan Data

Untuk melindungi data nasabah saat ditampilkan:
- **Nomor rekening disensor sebagian**, sehingga tidak tampil utuh (contoh tampilan: `12xxx03`).
- **Nominal ditampilkan dalam format Rupiah** yang mudah dibaca (contoh: `Rp 1.000.000`).

---

## Kesimpulan

Aplikasi internet banking ini menuntun nasabah melalui alur yang jelas dan berlapis: registrasi mandiri yang membuat identitas nasabah dan akun login sekaligus, login dengan aturan keamanan yang ketat (penguncian otomatis setelah 3x salah, reset saat berhasil, dan pencatatan setiap percobaan), pengelolaan banyak rekening dengan beragam tipe, fitur transaksi dengan biaya dan limit yang dihitung otomatis sesuai tingkatan nasabah, serta pemantauan melalui mutasi, rekap harian, dan jejak audit. Setiap langkah dirancang untuk menjaga konsistensi data, keamanan akses, dan keterlacakan transaksi.
