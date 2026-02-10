-- ============================================
-- CUSTOM TYPES (ENUMS) UNTUK HOTEL NUSANTARA
-- ============================================

-- Tipe status pemesanan
CREATE TYPE tipe_status_pesan AS ENUM (
    'menunggu',      -- Pemesanan dibuat tapi belum bayar
    'terkonfirmasi', -- Sudah bayar DP atau full
    'check_in',      -- Tamu sudah check-in
    'check_out',     -- Tamu sudah check-out
    'dibatalkan',    -- Pemesanan dibatalkan
    'no_show'        -- Tamu tidak datang
);

-- Tipe kamar sesuai standar hotel Indonesia
CREATE TYPE tipe_kamar AS ENUM (
    'standard',      -- Kamar standar (AC, TV, WiFi)
    'deluxe',        -- Kamar deluxe (AC, TV, WiFi, Bathub)
    'suite',         -- Suite room (Living area kecil)
    'keluarga',      -- Family room (2 double bed)
    'presiden',      -- President suite (Luxury)
    'villa',         -- Villa terpisah
    'bungalow'       -- Bungalow
);

-- Tipe tamu untuk segmentasi
CREATE TYPE tipe_tamu AS ENUM (
    'reguler',       -- Tamu biasa
    'corporate',     -- Tamu dari perusahaan
    'member',        -- Member loyalty program
    'vip',           -- Very Important Person
    'travel_agent'   -- Agen travel
);

-- Tipe pembayaran yang umum di Indonesia
CREATE TYPE tipe_pembayaran AS ENUM (
    'tunai',         -- Cash
    'transfer',      -- Bank transfer
    'kartu_kredit',  -- Credit card
    'debit',         -- Debit card
    'qris',          -- QRIS (Indonesia)
    'edc',           -- EDC machine
    'virtual_account'-- Virtual account
);

-- Tipe shift untuk staff
CREATE TYPE tipe_shift AS ENUM (
    'pagi',          -- 07:00 - 15:00
    'sore',          -- 15:00 - 23:00
    'malam'          -- 23:00 - 07:00
);

-- Status kebersihan kamar
CREATE TYPE status_kebersihan AS ENUM (
    'bersih',
    'kotor',
    'dalam_pembersihan',
    'perlu_perbaikan'
);

-- Log message
DO $$
BEGIN
    RAISE NOTICE '✅ Custom types created successfully';
END $$;