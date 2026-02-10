-- ============================================
-- TABEL-TABEL UTAMA SISTEM HOTEL NUSANTARA
-- ============================================

-- 🏨 TABEL: KAMAR (Master data kamar)
CREATE TABLE kamar (
    id_kamar SERIAL PRIMARY KEY,
    nomor_kamar VARCHAR(10) NOT NULL UNIQUE,
    lantai INTEGER NOT NULL CHECK (lantai BETWEEN 1 AND 20),
    blok VARCHAR(2) DEFAULT 'A', -- Blok A, B, C untuk hotel besar
    tipe_kamar tipe_kamar NOT NULL,
    kapasitas INTEGER NOT NULL CHECK (kapasitas BETWEEN 1 AND 6),
    
    -- Fasilitas dalam JSONB untuk fleksibilitas
    fasilitas JSONB DEFAULT '{
        "ac": true,
        "tv": true,
        "kulkas": false,
        "bathub": false,
        "wifi": true,
        "breakfast": false,
        "hot_water": true,
        "safe_deposit": false,
        "teras": false
    }'::jsonb,
    
    status_kamar VARCHAR(20) DEFAULT 'tersedia' CHECK (
        status_kamar IN ('tersedia', 'dipesan', 'dipakai', 'maintenance', 'tidak_aktif')
    ),
    status_kebersihan status_kebersihan DEFAULT 'bersih',
    harga_standar NUMERIC(10,2) NOT NULL CHECK (harga_standar > 0),
    harga_weekend NUMERIC(10,2) GENERATED ALWAYS AS (harga_standar * 1.2) STORED,
    deskripsi TEXT,
    
    -- Audit trail
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by INTEGER,
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 👥 TABEL: TAMU (Master data tamu)
CREATE TABLE tamu (
    id_tamu SERIAL PRIMARY KEY,
    nik VARCHAR(20) UNIQUE, -- Nomor Induk Kependudukan
    nama_lengkap VARCHAR(100) NOT NULL,
    nama_panggilan VARCHAR(50),
    jenis_kelamin CHAR(1) CHECK (jenis_kelamin IN ('L', 'P')),
    tempat_lahir VARCHAR(50),
    tanggal_lahir DATE,
    
    -- Kontak
    no_telepon VARCHAR(20),
    no_telepon_alternatif VARCHAR(20),
    email VARCHAR(100),
    alamat TEXT,
    kota VARCHAR(50),
    provinsi VARCHAR(50),
    kode_pos VARCHAR(10),
    
    -- Identifikasi
    tipe_tamu tipe_tamu DEFAULT 'reguler',
    poin_member INTEGER DEFAULT 0,
    tier_member VARCHAR(20) DEFAULT 'bronze' CHECK (
        tier_member IN ('bronze', 'silver', 'gold', 'platinum')
    ),
    
    -- Preferensi tamu (khas Indonesia)
    preferensi JSONB DEFAULT '{
        "merokok": false,
        "lantai_tinggi": false,
        "dekat_lift": false,
        "kamar_pedas": false,
        "tipe_bed": "double",
        "sarapan": true,
        "koran_pagi": false,
        "wifi_priority": false
    }'::jsonb,
    
    -- Data pendukung
    perusahaan VARCHAR(100),
    jabatan VARCHAR(50),
    nama_kontak_darurat VARCHAR(100),
    telepon_darurat VARCHAR(20),
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    diupdate_oleh INTEGER,
    
    -- Flag
    is_blacklisted BOOLEAN DEFAULT false,
    catatan_blacklist TEXT
);

-- 📅 TABEL: PEMESANAN (Transaksi utama)
CREATE TABLE pemesanan (
    id_pemesanan BIGSERIAL PRIMARY KEY,
    kode_booking VARCHAR(20) UNIQUE NOT NULL,
    id_tamu INTEGER NOT NULL REFERENCES tamu(id_tamu),
    
    -- Periode menginap
    tanggal_pemesanan TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    waktu_check_in_rencana TIME DEFAULT '14:00:00',
    waktu_check_out_rencana TIME DEFAULT '12:00:00',
    jumlah_malam INTEGER GENERATED ALWAYS AS (check_out - check_in) STORED,
    
    -- Detail tamu
    jumlah_tamu INTEGER NOT NULL CHECK (jumlah_tamu BETWEEN 1 AND 10),
    jumlah_tamu_dewasa INTEGER NOT NULL,
    jumlah_tamu_anak INTEGER DEFAULT 0,
    nama_tamu_tambahan TEXT[], -- Array untuk tamu tambahan
    
    -- Status & Pembayaran
    status_pemesanan tipe_status_pesan DEFAULT 'menunggu',
    metode_pembayaran tipe_pembayaran,
    status_pembayaran VARCHAR(20) DEFAULT 'belum_lunas' CHECK (
        status_pembayaran IN ('belum_lunas', 'dp', 'lunas', 'refund')
    ),
    
    -- Harga
    total_harga NUMERIC(12,2) NOT NULL CHECK (total_harga >= 0),
    deposit NUMERIC(10,2) DEFAULT 0,
    total_dibayar NUMERIC(12,2) DEFAULT 0,
    sisa_pembayaran NUMERIC(12,2) GENERATED ALWAYS AS (total_harga - total_dibayar) STORED,
    
    -- Referensi
    referral_code VARCHAR(50), -- Kode referral jika ada
    sumber_pemesanan VARCHAR(30) DEFAULT 'website' CHECK (
        sumber_pemesanan IN ('website', 'phone', 'walk_in', 'travel_agent', 'ota')
    ),
    
    -- Catatan
    catatan_khusus TEXT,
    catatan_internal TEXT,
    
    -- Audit
    created_by INTEGER, -- ID staff yang membuat
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by INTEGER,
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 🛌 TABEL: DETAIL PEMESANAN KAMAR
CREATE TABLE detail_pemesanan_kamar (
    id_detail SERIAL PRIMARY KEY,
    id_pemesanan BIGINT NOT NULL REFERENCES pemesanan(id_pemesanan) ON DELETE CASCADE,
    id_kamar INTEGER NOT NULL REFERENCES kamar(id_kamar),
    
    -- Harga untuk kamar ini
    harga_per_malam NUMERIC(10,2) NOT NULL CHECK (harga_per_malam > 0),
    sub_total NUMERIC(12,2) NOT NULL CHECK (sub_total >= 0),
    
    -- Tambahan
    tamu_tambahan INTEGER DEFAULT 0 CHECK (tamu_tambahan >= 0),
    biaya_tambahan_per_malam NUMERIC(10,2) DEFAULT 0,
    
    -- Status khusus kamar dalam pemesanan
    status_kamar VARCHAR(20) DEFAULT 'dipesan' CHECK (
        status_kamar IN ('dipesan', 'check_in', 'check_out', 'dibatalkan')
    ),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 💰 TABEL: TARIF KAMAR (Harga dinamis per tanggal)
CREATE TABLE tarif_kamar (
    id_tarif SERIAL PRIMARY KEY,
    id_kamar INTEGER REFERENCES kamar(id_kamar),
    
    -- Periode berlaku
    tanggal_mulai DATE NOT NULL,
    tanggal_selesai DATE NOT NULL,
    
    -- Harga
    harga_dasar NUMERIC(10,2) NOT NULL CHECK (harga_dasar > 0),
    harga_akhir_minggu NUMERIC(10,2),
    harga_libur_nasional NUMERIC(10,2),
    
    -- Kuota & restrictions
    kuota_kamar INTEGER DEFAULT 1 CHECK (kuota_kamar >= 0),
    min_malam INTEGER DEFAULT 1,
    max_malam INTEGER,
    
    -- Kondisi khusus
    hanya_weekend BOOLEAN DEFAULT false,
    hanya_weekday BOOLEAN DEFAULT false,
    khusus_paket BOOLEAN DEFAULT false,
    
    -- Validasi tanggal
    CONSTRAINT cek_tanggal_valid CHECK (tanggal_mulai <= tanggal_selesai),
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Metadata
    catatan TEXT
);

-- 💸 TABEL: PEMBAYARAN
CREATE TABLE pembayaran (
    id_pembayaran SERIAL PRIMARY KEY,
    id_pemesanan BIGINT NOT NULL REFERENCES pemesanan(id_pemesanan),
    
    -- Detail pembayaran
    jumlah_bayar NUMERIC(12,2) NOT NULL CHECK (jumlah_bayar > 0),
    tanggal_bayar TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metode_bayar tipe_pembayaran NOT NULL,
    
    -- Referensi bank/transaksi
    nama_bank VARCHAR(50),
    nomor_referensi VARCHAR(100),
    nama_pemilik_rekening VARCHAR(100),
    
    -- Status
    status_bayar VARCHAR(20) DEFAULT 'sukses' CHECK (
        status_bayar IN ('pending', 'sukses', 'gagal', 'dikembalikan')
    ),
    verified_by INTEGER, -- Staff yang verifikasi
    
    -- Catatan
    keterangan TEXT,
    bukti_bayar_url TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER
);

-- 📝 TABEL: REGISTRASI TAMU (Check-in/out)
CREATE TABLE registrasi_tamu (
    id_registrasi SERIAL PRIMARY KEY,
    id_pemesanan BIGINT NOT NULL REFERENCES pemesanan(id_pemesanan),
    id_kamar INTEGER NOT NULL REFERENCES kamar(id_kamar),
    
    -- Waktu aktual
    waktu_check_in_aktual TIMESTAMP WITH TIME ZONE,
    waktu_check_out_aktual TIMESTAMP WITH TIME ZONE,
    durasi_aktual INTERVAL GENERATED ALWAYS AS (
        waktu_check_out_aktual - waktu_check_in_aktual
    ) STORED,
    
    -- Staff yang menangani
    staff_check_in INTEGER,
    staff_check_out INTEGER,
    
    -- Deposit & biaya tambahan
    deposit_digunakan NUMERIC(10,2) DEFAULT 0,
    biaya_tambahan JSONB DEFAULT '[]'::jsonb,
    total_biaya_tambahan NUMERIC(10,2) DEFAULT 0,
    
    -- Status kamar setelah check-out
    kondisi_kamar VARCHAR(20) DEFAULT 'baik' CHECK (
        kondisi_kamar IN ('baik', 'rusak_ringan', 'rusak_berat', 'hilang')
    ),
    
    -- Catatan
    catatan_check_in TEXT,
    catatan_check_out TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 🍽️ TABEL: FASILITAS TAMBAHAN
CREATE TABLE fasilitas_tambahan (
    id_fasilitas SERIAL PRIMARY KEY,
    kode_fasilitas VARCHAR(20) UNIQUE NOT NULL,
    nama_fasilitas VARCHAR(100) NOT NULL,
    deskripsi TEXT,
    
    -- Harga
    harga NUMERIC(10,2) NOT NULL CHECK (harga >= 0),
    satuan VARCHAR(20) NOT NULL CHECK (
        satuan IN ('per_item', 'per_paket', 'per_hari', 'per_orang', 'per_malam')
    ),
    
    -- Kategori khas Indonesia
    kategori VARCHAR(30) NOT NULL CHECK (
        kategori IN (
            'makanan', 'minuman', 'laundry', 'transport', 
            'spa', 'olahraga', 'business', 'wisata', 'lainnya'
        )
    ),
    subkategori VARCHAR(50),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    stok_tersedia INTEGER,
    
    -- Metadata
    gambar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 🔄 TABEL: HISTORY STATUS PEMESANAN
CREATE TABLE history_status (
    id_history SERIAL PRIMARY KEY,
    id_pemesanan BIGINT NOT NULL REFERENCES pemesanan(id_pemesanan),
    
    -- Status perubahan
    status_lama tipe_status_pesan,
    status_baru tipe_status_pesan NOT NULL,
    
    -- Pelaku
    diubah_oleh INTEGER, -- ID staff atau sistem
    tipe_perubahan VARCHAR(20) DEFAULT 'manual' CHECK (
        tipe_perubahan IN ('manual', 'sistem', 'automatic')
    ),
    
    -- Detail
    alasan_perubahan TEXT,
    deskripsi_perubahan TEXT,
    
    -- Data perubahan (JSON diff)
    perubahan_data JSONB,
    
    -- Timestamp
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 👨‍💼 TABEL: STAFF/HOTEL KARYAWAN
CREATE TABLE staff (
    id_staff SERIAL PRIMARY KEY,
    nik VARCHAR(20) UNIQUE NOT NULL,
    nama_lengkap VARCHAR(100) NOT NULL,
    nama_panggilan VARCHAR(50),
    
    -- Posisi di hotel
    jabatan VARCHAR(50) NOT NULL CHECK (
        jabatan IN (
            'resepsionis', 'housekeeping', 'manager', 'supervisor', 
            'admin', 'keuangan', 'f&b', 'security', 'maintenance'
        )
    ),
    departemen VARCHAR(50),
    
    -- Kontak
    no_telepon VARCHAR(20),
    email VARCHAR(100),
    alamat TEXT,
    
    -- Login (jika punya akses sistem)
    username VARCHAR(50) UNIQUE,
    password_hash VARCHAR(255),
    role_sistem VARCHAR(30) DEFAULT 'user' CHECK (
        role_sistem IN ('user', 'supervisor', 'admin', 'owner')
    ),
    
    -- Status kerja
    tanggal_mulai_kerja DATE,
    tanggal_selesai_kerja DATE,
    status_kerja VARCHAR(20) DEFAULT 'aktif' CHECK (
        status_kerja IN ('aktif', 'cuti', 'resign', 'dibekukan')
    ),
    
    -- Shift
    shift_default tipe_shift,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Flag
    is_active BOOLEAN DEFAULT true
);

-- 🎯 TABEL: LOYALTY PROGRAM
CREATE TABLE program_loyalty (
    id_program SERIAL PRIMARY KEY,
    nama_program VARCHAR(100) NOT NULL,
    tier VARCHAR(20) NOT NULL CHECK (
        tier IN ('bronze', 'silver', 'gold', 'platinum')
    ),
    
    -- Requirements
    min_stay INTEGER DEFAULT 0,
    min_spend NUMERIC(12,2) DEFAULT 0,
    
    -- Benefits (dalam JSON untuk fleksibilitas)
    benefits JSONB DEFAULT '{
        "diskon": 0,
        "late_checkout": false,
        "welcome_drink": false,
        "room_upgrade": false,
        "free_breakfast": false
    }'::jsonb,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Validitas
    tanggal_mulai DATE NOT NULL,
    tanggal_selesai DATE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 📊 TABEL: LAPORAN HARIAN (Snapshot untuk reporting)
CREATE TABLE laporan_harian (
    id_laporan SERIAL PRIMARY KEY,
    tanggal DATE NOT NULL UNIQUE,
    
    -- Statistik
    total_kamar INTEGER NOT NULL,
    kamar_terisi INTEGER DEFAULT 0,
    kamar_tersedia INTEGER GENERATED ALWAYS AS (total_kamar - kamar_terisi) STORED,
    
    -- Tamu
    tamu_check_in INTEGER DEFAULT 0,
    tamu_check_out INTEGER DEFAULT 0,
    tamu_in_house INTEGER DEFAULT 0,
    
    -- Revenue
    pendapatan_kamar NUMERIC(12,2) DEFAULT 0,
    pendapatan_fnb NUMERIC(12,2) DEFAULT 0,
    pendapatan_lainnya NUMERIC(12,2) DEFAULT 0,
    total_pendapatan NUMERIC(12,2) GENERATED ALWAYS AS (
        pendapatan_kamar + pendapatan_fnb + pendapatan_lainnya
    ) STORED,
    
    -- Occupancy
    occupancy_rate NUMERIC(5,2) GENERATED ALWAYS AS (
        (kamar_terisi::NUMERIC / NULLIF(total_kamar, 0) * 100)
    ) STORED,
    
    -- Audit
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    generated_by INTEGER
);

-- Log message
DO $$
BEGIN
    RAISE NOTICE '✅ Semua tabel utama berhasil dibuat';
    RAISE NOTICE '📊 Total tabel: 12 tabel utama';
END $$;