-- ============================================
-- SIMPLE & LEGAL CONSTRAINTS
-- ============================================

-- 1. Validasi tanggal pemesanan
ALTER TABLE pemesanan
ADD CONSTRAINT chk_tanggal_valid
CHECK (
    check_in < check_out
    AND check_in >= CURRENT_DATE - INTERVAL '1 year'
);

-- 2. Validasi periode tarif kamar
ALTER TABLE tarif_kamar
ADD CONSTRAINT chk_periode_tarif
CHECK (tanggal_mulai <= tanggal_selesai);

-- 3. Deposit valid
ALTER TABLE pemesanan
ADD CONSTRAINT chk_deposit_valid
CHECK (
    deposit >= 0
    AND deposit <= total_harga
);

-- 4. Total pembayaran valid
ALTER TABLE pemesanan
ADD CONSTRAINT chk_total_dibayar_valid
CHECK (
    total_dibayar >= 0
    AND total_dibayar <= total_harga
);

-- 5. Total harga tidak boleh negatif
ALTER TABLE pemesanan
ADD CONSTRAINT chk_total_harga_positif
CHECK (total_harga >= 0);

-- 6. Kapasitas kamar minimal 1
ALTER TABLE kamar
ADD CONSTRAINT chk_kapasitas_kamar
CHECK (kapasitas >= 1);

-- 7. Unique NIK tamu (partial unique index)
CREATE UNIQUE INDEX IF NOT EXISTS ux_tamu_nik
ON tamu (nik)
WHERE nik IS NOT NULL;

DO $$
BEGIN
    RAISE NOTICE '✅ Constraints dasar berhasil diterapkan';
END $$;
