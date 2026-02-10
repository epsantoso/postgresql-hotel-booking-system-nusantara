-- ============================================
-- INDEXES UNTUK PERFORMANCE OPTIMAL
-- ============================================

-- 1. INDEX untuk pencarian cepat kamar tersedia
CREATE INDEX idx_kamar_tipe_status ON kamar(tipe_kamar, status_kamar) 
WHERE status_kamar IN ('tersedia', 'dipesan');

CREATE INDEX idx_kamar_fasilitas_gin ON kamar USING gin(fasilitas);

-- 2. INDEX untuk pencarian tamu
CREATE INDEX idx_tamu_nama ON tamu(nama_lengkap);
CREATE INDEX idx_tamu_telepon ON tamu(no_telepon);
CREATE INDEX idx_tamu_email ON tamu(email) WHERE email IS NOT NULL;
CREATE INDEX idx_tamu_nik ON tamu(nik) WHERE nik IS NOT NULL;

-- 3. INDEX untuk pemesanan (paling critical untuk performance)
CREATE INDEX idx_pemesanan_tamu ON pemesanan(id_tamu);
CREATE INDEX idx_pemesanan_tanggal ON pemesanan(check_in, check_out);
CREATE INDEX idx_pemesanan_status ON pemesanan(status_pemesanan) 
WHERE status_pemesanan NOT IN ('dibatalkan', 'no_show');

CREATE INDEX idx_pemesanan_kode ON pemesanan(kode_booking);
CREATE INDEX idx_pemesanan_created ON pemesanan(created_at DESC);

-- BRIN Index untuk range queries pada tanggal (optimal untuk data besar)
CREATE INDEX idx_pemesanan_brin_checkin ON pemesanan USING brin(check_in);
CREATE INDEX idx_pemesanan_brin_created ON pemesanan USING brin(created_at);

-- 4. INDEX untuk detail pemesanan kamar
CREATE INDEX idx_detail_kamar ON detail_pemesanan_kamar(id_kamar);
CREATE INDEX idx_detail_pemesanan ON detail_pemesanan_kamar(id_pemesanan);
CREATE INDEX idx_detail_kamar_pemesanan ON detail_pemesanan_kamar(id_kamar, id_pemesanan);

-- 5. INDEX untuk tarif kamar
CREATE INDEX idx_tarif_kamar ON tarif_kamar(id_kamar);
CREATE INDEX idx_tarif_tanggal ON tarif_kamar(tanggal_mulai, tanggal_selesai);
CREATE INDEX idx_tarif_range ON tarif_kamar USING gist(daterange(tanggal_mulai, tanggal_selesai));

-- 6. INDEX untuk pembayaran
CREATE INDEX idx_pembayaran_pemesanan ON pembayaran(id_pemesanan);
CREATE INDEX idx_pembayaran_tanggal ON pembayaran(tanggal_bayar DESC);
CREATE INDEX idx_pembayaran_status ON pembayaran(status_bayar);

-- 7. INDEX untuk registrasi tamu
CREATE INDEX idx_registrasi_pemesanan ON registrasi_tamu(id_pemesanan);
CREATE INDEX idx_registrasi_kamar ON registrasi_tamu(id_kamar);
CREATE INDEX idx_registrasi_checkin ON registrasi_tamu(waktu_check_in_aktual DESC);
CREATE INDEX idx_registrasi_checkout ON registrasi_tamu(waktu_check_out_aktual DESC NULLS LAST);

-- 8. INDEX untuk history
CREATE INDEX idx_history_pemesanan ON history_status(id_pemesanan);
CREATE INDEX idx_history_timestamp ON history_status(created_at DESC);
CREATE INDEX idx_history_status ON history_status(status_baru, created_at);

-- 9. INDEX untuk staff
CREATE INDEX idx_staff_jabatan ON staff(jabatan) WHERE is_active = true;
CREATE INDEX idx_staff_username ON staff(username) WHERE username IS NOT NULL;

-- 10. INDEX untuk laporan
CREATE INDEX idx_laporan_tanggal ON laporan_harian(tanggal DESC);

-- 11. Partial indexes untuk query yang sering digunakan
CREATE INDEX idx_pemesanan_aktif ON pemesanan(id_pemesanan) 
WHERE status_pemesanan IN ('terkonfirmasi', 'check_in');

CREATE INDEX idx_kamar_aktif ON kamar(id_kamar) 
WHERE status_kamar IN ('tersedia', 'dipesan') AND status_kebersihan = 'bersih';

CREATE INDEX idx_tamu_aktif ON tamu(id_tamu) 
WHERE is_blacklisted = false;

-- 12. Composite indexes untuk join yang sering
CREATE INDEX idx_pemesanan_detail_join ON pemesanan(id_pemesanan, id_tamu, check_in, check_out);
CREATE INDEX idx_kamar_tipe_harga ON kamar(tipe_kamar, harga_standar, status_kamar);

-- 13. Index untuk text search
CREATE INDEX idx_tamu_search ON tamu USING gin(
    to_tsvector('indonesian', 
        COALESCE(nama_lengkap, '') || ' ' || 
        COALESCE(no_telepon, '') || ' ' || 
        COALESCE(email, '')
    )
);

-- 14. Index untuk JSONB queries
CREATE INDEX idx_kamar_fasilitas_ac ON kamar((fasilitas->>'ac')) 
WHERE (fasilitas->>'ac')::boolean = true;

CREATE INDEX idx_tamu_preferensi ON tamu USING gin(preferensi);

-- Log message dengan statistik
DO $$
DECLARE
    total_indexes INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_indexes 
    FROM pg_indexes 
    WHERE schemaname = 'public';
    
    RAISE NOTICE '✅ Indexes berhasil dibuat';
    RAISE NOTICE '📈 Total indexes: %', total_indexes;
    RAISE NOTICE '⚡ Performance optimization complete';
END $$;