# 📖 NARASI BISNIS: EKOSISTEM M-BANKING (ENTERPRISE GRADE)

Dokumen ini berisi narasi lengkap mengenai alur bisnis dan fitur unggulan sistem untuk keperluan presentasi, demonstrasi, atau penjelasan kepada stakeholder (Dosen/Penguji).

---

## 🚀 1. ONBOARDING: Registrasi Terintegrasi
"Perjalanan nasabah dimulai dengan proses pendaftaran yang menggunakan prinsip **Atomic Transaction**. Saat nasabah mendaftar, sistem tidak hanya membuat akun login, tetapi secara otomatis melakukan tiga hal sekaligus dalam satu detik:"
*   **Generate CIF (Customer Information File):** Memberikan identitas tunggal nasabah yang berlaku seumur hidup di bank.
*   **Sinkronisasi Keamanan & Bisnis:** Membuat data diri di database operasional dan kredensial login di database keamanan secara bersamaan.
*   **Single Source of Truth:** Memastikan tidak ada data yang 'gantung' (misal: punya akun login tapi tidak punya nomor rekening).

## 🛡️ 2. AKSES: Keamanan & CCTV Digital (Full Audit)
"Setiap kali nasabah mencoba mengakses aplikasi, sistem kita bertindak seperti satpam digital dengan pengawasan ketat melalui fitur **Full Audit Trail**:"
*   **Metadata Tracking:** Sistem mencatat alamat IP, jenis perangkat (Device ID), hingga versi aplikasi yang digunakan nasabah.
*   **Triple-State Logging:** Kita mencatat tiga kondisi akses: **Success** (berhasil), **Failed** (salah password), dan **Locked** (percobaan pada akun yang sudah terblokir).
*   **Tujuan:** Memberikan bukti otentik bagi bank jika suatu saat terjadi sengketa transaksi atau upaya peretasan akun.

## ⚡ 3. PERTAHANAN: Proteksi Otomatis (Self-Defense)
"Sistem kita memiliki 'Otak' keamanan yang bekerja secara mandiri tanpa menunggu instruksi admin:"
*   **Auto-Lock Mechanism:** Jika sistem mendeteksi kesalahan password sebanyak **3 kali berturut-turut**, akun nasabah akan otomatis diubah statusnya menjadi **LOCKED**.
*   **Brute-Force Protection:** Fitur ini memastikan akun nasabah aman dari upaya penebakan password oleh pihak tidak bertanggung jawab.
*   **Reset Logic:** Keamanan ini juga cerdas; jika nasabah berhasil login, hitungan kesalahan sebelumnya akan otomatis di-reset menjadi nol.

## 💎 4. FITUR UNGGULAN: Smart Banking Experience
"Di dalam aplikasi, nasabah disuguhi berbagai fitur cerdas yang dirancang untuk skala perusahaan besar:"
*   **Multi-Account Portfolio:** Berkat nomor CIF, satu nasabah bisa mengelola banyak rekening (Tabungan, Giro, Deposito) hanya dalam satu akses login.
*   **Smart Limit Management:** Penerapan kasta nasabah (Reguler, Gold, Platinum). Setiap kasta memiliki batas transaksi harian yang berbeda untuk meminimalkan risiko kerugian besar jika terjadi penyalahgunaan akun.
*   **Automatic Fee Engine:** Perhitungan biaya admin (misal: biaya transfer antar bank) dilakukan secara otomatis dan transparan saat transaksi terjadi.
*   **Anti-Reuse Password:** Sistem menyimpan riwayat password lama agar nasabah tidak bisa menggunakan kembali password yang sama, menjaga kunci akses tetap segar dan aman.

## 📊 5. TRANSPARANSI: Integritas & Pelaporan
"Bagian akhir dari ekosistem kita adalah menjamin bahwa setiap rupiah dapat dipertanggungjawabkan:"
*   **Audit Trail Data Sensitif:** Setiap perubahan saldo atau PIN akan dicatat (nilai lama vs nilai baru), sehingga bank memiliki rekam jejak jika ada 'orang dalam' yang mencoba memanipulasi data.
*   **Intelligent Reporting:** Melalui sistem **Views**, bank bisa mendapatkan laporan transaksi harian secara instan, sementara nasabah bisa melihat mutasi rekening dengan data yang aman (nomor rekening disensor sebagian).

---
> **Kesimpulan:** Sistem ini bukan sekadar penyimpan data, melainkan sebuah ekosistem yang dirancang untuk menjaga **Integritas, Keamanan, dan Transparansi** sesuai standar industri perbankan nasional.
