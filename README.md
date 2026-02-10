# PostgreSQL-Hotel-Booking-System-Nusantara

Project ini berisi **implementasi database sistem booking hotel menggunakan PostgreSQL**, dibuat sebagai **project pembelajaran dan portofolio pribadi**.

Fokus utama repository ini adalah pada:
- perancangan database relasional,
- penerapan constraint dan relasi,
- penggunaan function, trigger, dan view,
- serta menjaga integritas data di level database.

Project ini tidak terikat pada framework backend tertentu dan dapat digunakan sebagai basis untuk berbagai aplikasi.

---

## Gambaran Umum

Sistem ini memodelkan kebutuhan dasar operasional hotel, meliputi:
- reservasi kamar,
- pengelolaan data tamu dan kamar,
- pencatatan pembayaran,
- serta penyajian data untuk kebutuhan laporan sederhana.

Beberapa aturan bisnis penting (seperti validasi tanggal dan pencegahan double booking) diterapkan langsung di PostgreSQL agar data tetap konsisten walaupun diakses dari aplikasi yang berbeda.

---

## Tujuan Project

Repository ini dibuat untuk:
- Melatih dan menunjukkan pemahaman **PostgreSQL dan SQL**
- Menerapkan konsep **relational database design**
- Menggunakan fitur PostgreSQL seperti **ENUM, constraint, index, function, trigger, dan view**
- Menyusun struktur database yang rapi dan mudah dipahami

---

## Struktur Repository

postgreSQL-hotel-booking-system-nusantara/
├── readme.md
├── setup.sh
├── .gitignore
├── LICENSE
└── sql/
    ├── 00_database_setup.sql
    ├── 01_types.sql
    ├── 02_tables.sql
    ├── 03_constraints.sql
    ├── 04_indexes.sql
    ├── 05_functions.sql
    ├── 06_triggers.sql
    ├── 07_views.sql
    ├── 08_seed_data.sql
    ├── 09_stored_procedures.sql
    └── 10_showcase_queries.sql



## Author

Eko Puji Santoso
