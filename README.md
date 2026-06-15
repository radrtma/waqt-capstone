# WAQT - Prayer & Community Companion

WAQT adalah aplikasi pendamping ibadah komprehensif yang dirancang untuk membantu umat Muslim memantau dan meningkatkan kualitas ibadah harian mereka. Proyek ini menyelaraskan aplikasi Mobile (Flutter) dengan Web Companion Client menggunakan arsitektur modern berorientasi layanan.

---

## 1. Arsitektur & Tech Stack Akhir

Proyek ini terbagi menjadi beberapa komponen utama di dalam repository:

```txt
WAQT/
├── waqt_ci4/          # Web Frontend (PHP CodeIgniter 4 MVC)
├── waqt_backend/      # REST API Backend (Express + SQLite)
├── mobile_app/        # Flutter Mobile App (existing)
└── README.md          # Dokumentasi Utama Workspace
```

### Tech Stack Per Layer:

*   **Web Frontend (`waqt_ci4/`):**
    *   Framework: PHP CodeIgniter 4 (MVC Pattern)
    *   Client Scripting: Vanilla JavaScript & AJAX
    *   Styling: Vanilla CSS (Custom HSL theme variables & fluid grid layout)
    *   Session: Native PHP Session Authentication
*   **Backend API Service (`waqt_backend/`):**
    *   Runtime: Node.js
    *   Framework: Express.js
    *   Database: SQLite3 (persistence layer)
    *   Security: Password hashing (bcryptjs) & Session Token (bearer auth middleware)
*   **Mobile App (`mobile_app/` / Flutter files):**
    *   Framework: Dart & Flutter SDK
    *   Local DB: SQLite (untuk penyimpanan offline-first)

---

## 2. Cara Menjalankan Proyek (Demo Guide)

### Langkah 1: Jalankan Backend API
1. Masuk ke direktori backend:
   ```bash
   cd waqt_backend
   ```
2. Instal dependensi:
   ```bash
   npm install
   ```
3. Jalankan server backend:
   ```bash
   node index.js
   ```
   *Expected Output:*
   ```txt
   WAQT Backend API Server running on port 3000
   Connected to SQLite server database.
   Database tables initialized.
   ```

---

### Langkah 2: Jalankan Web Companion (CodeIgniter 4)
1. Masuk ke direktori frontend:
   ```bash
   cd waqt_ci4
   ```
2. Instal dependensi PHP (jika diperlukan):
   ```bash
   composer install
   ```
3. Nyalakan local PHP development server:
   ```bash
   php spark serve
   ```
   *Expected Output:*
   ```txt
   CodeIgniter development server started on http://localhost:8080
   ```

---

### Langkah 3: Buka Browser
Akses dashboard web companion di browser Anda melalui tautan:
```txt
http://localhost:8080
```

---

## 3. Alur Pengujian / Test Flow (Demo Presentasi)

Ikuti alur demo berikut untuk mempresentasikan fitur-fitur utama kepada dosen:

### A. Registrasi & Login (Authentication)
1. Buka `http://localhost:8080/login`.
2. Klik link **"Daftar Sekarang"** untuk mengubah form menjadi mode Registrasi.
3. Masukkan username dan password pilihan Anda, lalu tekan **"Daftar Akun"**.
4. Sesi PHP akan dibuat secara otomatis dan mengarahkan Anda ke halaman Dashboard.

### B. Prayer Tracking & Sync (Dashboard)
1. Pada **Dashboard**, Anda akan melihat ringkasan tracker check-in shalat (Subuh, Dzuhur, Ashar, Maghrib, Isya) hari ini.
2. Ceklis shalat yang sudah dilakukan. Tiap kali diceklis, data akan di-sync secara asinkron (AJAX) ke backend SQLite API.
3. Klik ikon streak di kanan greeting card untuk membuka sub-view **Spiritual Streak**.
4. Jika streak Anda beku/frozen, Anda dapat membayar hutang shalat di daftar **Qada Sholat** dengan menekan tombol **"Qada Now"**. Ini akan meng-update database dan memulihkan streak Anda secara instan.

### C. Komunitas 3-Kolom (Community Board)
1. Masuk ke tab **Komunitas** di navigasi sidebar kiri.
2. Di **Kolom Kiri**, pilih kategori postingan (Refleksi, Masjid, atau Diskusi) lalu isi postingan Anda. Khusus tipe **Masjid**, Anda dapat mengisi checklist review fasilitas (Kebersihan Wudhu, AC, Ramah Perempuan).
3. Setelah klik **"Posting"**, kiriman Anda akan ter-render di **Kolom Tengah** secara otomatis.
4. Klik tombol emoji reaksi (**Inspiring**, **Helpful**, **Useful**) di bawah tiap post card. Total reaksi akan bertambah secara asinkron (AJAX) tanpa perlu memuat ulang halaman.
5. Di **Kolom Kanan**, lihat widget rekomendasi masjid dan statistik aktif komunitas.

### D. Pengaturan & Kustomisasi Profil
1. Masuk ke tab **Profile** di sidebar.
2. Klik avatar sirkular untuk mengunggah foto profil kustom. Foto profil Anda akan di-encode ke base64, disimpan secara persisten di `localStorage`, dan langsung diperbarui di header topbar dan profil.
3. Buka accordion **"Ubah Kredensial Akun"** untuk mengganti username atau password Anda secara dinamis.
