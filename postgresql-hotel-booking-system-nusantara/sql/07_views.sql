-- ============================================
-- VIEWS UNTUK REPORTING & DASHBOARD
-- ============================================

-- 1. VIEW: Dashboard Ringkasan Harian
CREATE VIEW view_dashboard_harian AS
SELECT 
    CURRENT_DATE AS tanggal,
    -- Statistik Kamar
    (SELECT COUNT(*) FROM kamar WHERE status_kamar != 'tidak_aktif') AS total_kamar,
    (SELECT COUNT(*) FROM kamar WHERE status_kamar = 'tersedia') AS kamar_tersedia,
    (SELECT COUNT(*) FROM kamar WHERE status_kamar = 'dipesan') AS kamar_dipesan,
    (SELECT COUNT(*) FROM kamar WHERE status_kamar = 'dipakai') AS kamar_dipakai,
    (SELECT COUNT(*) FROM kamar WHERE status_kamar = 'maintenance') AS kamar_maintenance,
    
    -- Statistik Tamu
    (SELECT COUNT(DISTINCT id_tamu) FROM pemesanan 
     WHERE CURRENT_DATE BETWEEN check_in AND check_out - INTERVAL '1 day'
     AND status_pemesanan NOT IN ('dibatalkan', 'no_show')) AS tamu_in_house,
    
    -- Statistik Pemesanan
    (SELECT COUNT(*) FROM pemesanan 
     WHERE DATE(tanggal_pemesanan) = CURRENT_DATE) AS pemesanan_hari_ini,
    (SELECT COUNT(*) FROM pemesanan 
     WHERE check_in = CURRENT_DATE 
     AND status_pemesanan IN ('terkonfirmasi', 'check_in')) AS check_in_hari_ini,
    (SELECT COUNT(*) FROM pemesanan 
     WHERE check_out = CURRENT_DATE 
     AND status_pemesanan IN ('check_in', 'check_out')) AS check_out_hari_ini,
    
    -- Revenue
    COALESCE((SELECT SUM(total_harga) FROM pemesanan 
              WHERE DATE(tanggal_pemesanan) = CURRENT_DATE), 0) AS revenue_hari_ini,
    COALESCE((SELECT SUM(total_harga) FROM pemesanan 
              WHERE check_in = CURRENT_DATE), 0) AS revenue_check_in,
    
    -- Occupancy
    ROUND(
        (SELECT COUNT(DISTINCT dpk.id_kamar) 
         FROM detail_pemesanan_kamar dpk
         JOIN pemesanan p ON dpk.id_pemesanan = p.id_pemesanan
         WHERE CURRENT_DATE BETWEEN p.check_in AND p.check_out - INTERVAL '1 day'
         AND p.status_pemesanan NOT IN ('dibatalkan', 'no_show')
        )::NUMERIC / 
        NULLIF((SELECT COUNT(*) FROM kamar WHERE status_kamar != 'tidak_aktif'), 0) * 100,
        2
    ) AS occupancy_rate_hari_ini;

-- 2. VIEW: Laporan Pemesanan Bulanan
CREATE VIEW view_laporan_bulanan AS
WITH monthly_stats AS (
    SELECT 
        DATE_TRUNC('month', p.tanggal_pemesanan) AS bulan,
        -- Pemesanan
        COUNT(*) AS total_pemesanan,
        COUNT(*) FILTER (WHERE p.status_pemesanan = 'terkonfirmasi') AS pemesanan_terkonfirmasi,
        COUNT(*) FILTER (WHERE p.status_pemesanan = 'check_in') AS pemesanan_check_in,
        COUNT(*) FILTER (WHERE p.status_pemesanan = 'check_out') AS pemesanan_check_out,
        COUNT(*) FILTER (WHERE p.status_pemesanan = 'dibatalkan') AS pemesanan_dibatalkan,
        
        -- Tamu
        COUNT(DISTINCT p.id_tamu) AS unique_tamu,
        SUM(p.jumlah_tamu) AS total_tamu,
        
        -- Revenue
        SUM(p.total_harga) AS total_revenue,
        AVG(p.total_harga) AS avg_transaction_value,
        
        -- Kamar
        COUNT(DISTINCT dpk.id_kamar) AS unique_kamar_terpakai,
        SUM(p.jumlah_malam) AS total_malam
    FROM pemesanan p
    LEFT JOIN detail_pemesanan_kamar dpk ON p.id_pemesanan = dpk.id_pemesanan
    GROUP BY DATE_TRUNC('month', p.tanggal_pemesanan)
)
SELECT 
    TO_CHAR(bulan, 'YYYY-MM') AS bulan_format,
    bulan,
    total_pemesanan,
    pemesanan_terkonfirmasi,
    pemesanan_check_in,
    pemesanan_check_out,
    pemesanan_dibatalkan,
    ROUND(
        (pemesanan_dibatalkan::NUMERIC / NULLIF(total_pemesanan, 0) * 100)::NUMERIC,
        2
    ) AS cancellation_rate,
    unique_tamu,
    total_tamu,
    total_revenue,
    avg_transaction_value,
    unique_kamar_terpakai,
    total_malam,
    ROUND(
        (total_revenue / NULLIF(total_malam, 0))::NUMERIC,
        2
    ) AS revpar, -- Revenue Per Available Room
    ROUND(
        (total_revenue / NULLIF(unique_kamar_terpakai, 0))::NUMERIC,
        2
    ) AS adr -- Average Daily Rate
FROM monthly_stats
ORDER BY bulan DESC;

-- 3. VIEW: Kamar Tersedia Real-time
CREATE VIEW view_kamar_tersedia_realtime AS
WITH tanggal_sekarang AS (
    SELECT CURRENT_DATE AS tgl
)
SELECT 
    k.id_kamar,
    k.nomor_kamar,
    k.lantai,
    k.tipe_kamar,
    k.kapasitas,
    k.harga_standar,
    k.fasilitas,
    k.status_kamar,
    k.status_kebersihan,
    -- Ketersediaan 7 hari ke depan
   ARRAY[
    NOT EXISTS (
        SELECT 1
        FROM detail_pemesanan_kamar dpk
        JOIN pemesanan p ON p.id_pemesanan = dpk.id_pemesanan
        WHERE dpk.id_kamar = k.id_kamar
          AND CURRENT_DATE < p.check_out
          AND CURRENT_DATE >= p.check_in
          AND p.status_pemesanan NOT IN ('dibatalkan', 'no_show')
    ),
    NOT EXISTS (
        SELECT 1
        FROM detail_pemesanan_kamar dpk
        JOIN pemesanan p ON p.id_pemesanan = dpk.id_pemesanan
        WHERE dpk.id_kamar = k.id_kamar
          AND CURRENT_DATE + 1 < p.check_out
          AND CURRENT_DATE + 1 >= p.check_in
          AND p.status_pemesanan NOT IN ('dibatalkan', 'no_show')
    ),
    NOT EXISTS (
        SELECT 1
        FROM detail_pemesanan_kamar dpk
        JOIN pemesanan p ON p.id_pemesanan = dpk.id_pemesanan
        WHERE dpk.id_kamar = k.id_kamar
          AND CURRENT_DATE + 2 < p.check_out
          AND CURRENT_DATE + 2 >= p.check_in
          AND p.status_pemesanan NOT IN ('dibatalkan', 'no_show')
    ),
    NOT EXISTS (
        SELECT 1
        FROM detail_pemesanan_kamar dpk
        JOIN pemesanan p ON p.id_pemesanan = dpk.id_pemesanan
        WHERE dpk.id_kamar = k.id_kamar
          AND CURRENT_DATE + 3 < p.check_out
          AND CURRENT_DATE + 3 >= p.check_in
          AND p.status_pemesanan NOT IN ('dibatalkan', 'no_show')
    ),
    NOT EXISTS (
        SELECT 1
        FROM detail_pemesanan_kamar dpk
        JOIN pemesanan p ON p.id_pemesanan = p.id_pemesanan
        WHERE dpk.id_kamar = k.id_kamar
          AND CURRENT_DATE + 4 < p.check_out
          AND CURRENT_DATE + 4 >= p.check_in
          AND p.status_pemesanan NOT IN ('dibatalkan', 'no_show')
    ),
    NOT EXISTS (
        SELECT 1
        FROM detail_pemesanan_kamar dpk
        JOIN pemesanan p ON p.id_pemesanan = dpk.id_pemesanan
        WHERE dpk.id_kamar = k.id_kamar
          AND CURRENT_DATE + 5 < p.check_out
          AND CURRENT_DATE + 5 >= p.check_in
          AND p.status_pemesanan NOT IN ('dibatalkan', 'no_show')
    ),
    NOT EXISTS (
        SELECT 1
        FROM detail_pemesanan_kamar dpk
        JOIN pemesanan p ON p.id_pemesanan = dpk.id_pemesanan
        WHERE dpk.id_kamar = k.id_kamar
          AND CURRENT_DATE + 6 < p.check_out
          AND CURRENT_DATE + 6 >= p.check_in
          AND p.status_pemesanan NOT IN ('dibatalkan', 'no_show')
    )
] AS ketersediaan_7_hari

FROM kamar k
WHERE k.status_kamar IN ('tersedia', 'dipesan')
ORDER BY k.lantai, k.nomor_kamar;

-- 4. VIEW: Top 10 Tamu (Best Customers)
CREATE OR REPLACE VIEW view_top_tamu AS
SELECT 
    x.id_tamu,
    x.nama_lengkap,
    x.tipe_tamu,
    x.tier_member,
    x.poin_member,
    COUNT(DISTINCT x.id_pemesanan) AS total_kunjungan,
    SUM(x.total_harga) AS total_pengeluaran,
    MAX(x.tanggal_pemesanan) AS kunjungan_terakhir,
    AVG(x.total_harga) AS rata_rata_transaksi,
    SUM(x.jumlah_malam) AS total_malam_menginap,
    STRING_AGG(x.tipe_kamar, ', ' ORDER BY x.tipe_kamar) AS tipe_kamar_dipesan
FROM (
    SELECT DISTINCT
        t.id_tamu,
        t.nama_lengkap,
        t.tipe_tamu,
        t.tier_member,
        t.poin_member,
        p.id_pemesanan,
        p.total_harga,
        p.tanggal_pemesanan,
        p.jumlah_malam,
        k.tipe_kamar::TEXT AS tipe_kamar
    FROM tamu t
    JOIN pemesanan p ON t.id_tamu = p.id_tamu
    JOIN detail_pemesanan_kamar dpk ON p.id_pemesanan = dpk.id_pemesanan
    JOIN kamar k ON dpk.id_kamar = k.id_kamar
    WHERE p.status_pemesanan NOT IN ('dibatalkan', 'no_show')
) x
GROUP BY
    x.id_tamu,
    x.nama_lengkap,
    x.tipe_tamu,
    x.tier_member,
    x.poin_member
HAVING COUNT(DISTINCT x.id_pemesanan) >= 2
ORDER BY total_pengeluaran DESC, total_kunjungan DESC
LIMIT 10;



-- 5. VIEW: Pemesanan Hari Ini (Untuk Front Desk)
CREATE VIEW view_pemesanan_hari_ini AS
SELECT 
    p.kode_booking,
    p.id_pemesanan,
    t.nama_lengkap AS nama_tamu,
    t.no_telepon,
    p.check_in,
    p.check_out,
    p.jumlah_malam,
    p.jumlah_tamu,
    p.status_pemesanan,
    p.status_pembayaran,
    p.total_harga,
    p.total_dibayar,
    p.sisa_pembayaran,
    STRING_AGG(DISTINCT k.nomor_kamar, ', ') AS kamar_dipesan,
    STRING_AGG(DISTINCT k.tipe_kamar::TEXT, ', ') AS tipe_kamar,
    p.catatan_khusus
FROM pemesanan p
JOIN tamu t ON p.id_tamu = t.id_tamu
JOIN detail_pemesanan_kamar dpk ON p.id_pemesanan = dpk.id_pemesanan
JOIN kamar k ON dpk.id_kamar = k.id_kamar
WHERE p.check_in <= CURRENT_DATE 
AND p.check_out > CURRENT_DATE
AND p.status_pemesanan IN ('terkonfirmasi', 'check_in')
GROUP BY 
    p.kode_booking, p.id_pemesanan, t.nama_lengkap, t.no_telepon,
    p.check_in, p.check_out, p.jumlah_malam, p.jumlah_tamu,
    p.status_pemesanan, p.status_pembayaran, p.total_harga,
    p.total_dibayar, p.sisa_pembayaran, p.catatan_khusus
ORDER BY p.check_in, t.nama_lengkap;

-- 6. VIEW: Check-in List Hari Ini
CREATE VIEW view_checkin_hari_ini AS
SELECT 
    p.kode_booking,
    t.nama_lengkap,
    t.no_telepon,
    p.waktu_check_in_rencana,
    STRING_AGG(k.nomor_kamar, ', ') AS kamar,
    STRING_AGG(k.tipe_kamar::TEXT, ', ') AS tipe_kamar,
    p.jumlah_tamu,
    p.catatan_khusus,
    s.nama_lengkap AS staff_penerima
FROM pemesanan p
JOIN tamu t ON p.id_tamu = t.id_tamu
JOIN detail_pemesanan_kamar dpk ON p.id_pemesanan = dpk.id_pemesanan
JOIN kamar k ON dpk.id_kamar = k.id_kamar
LEFT JOIN staff s ON p.created_by = s.id_staff
WHERE p.check_in = CURRENT_DATE
AND p.status_pemesanan = 'terkonfirmasi'
GROUP BY 
    p.kode_booking, t.nama_lengkap, t.no_telepon, p.waktu_check_in_rencana,
    p.jumlah_tamu, p.catatan_khusus, s.nama_lengkap
ORDER BY p.waktu_check_in_rencana;

-- 7. VIEW: Check-out List Hari Ini
CREATE VIEW view_checkout_hari_ini AS
SELECT 
    p.kode_booking,
    t.nama_lengkap,
    t.no_telepon,
    p.waktu_check_out_rencana,
    STRING_AGG(k.nomor_kamar, ', ') AS kamar,
    STRING_AGG(k.tipe_kamar::TEXT, ', ') AS tipe_kamar,
    p.jumlah_tamu,
    COALESCE(rt.total_biaya_tambahan, 0) AS biaya_tambahan,
    p.deposit,
    p.catatan_khusus,
    s.nama_lengkap AS staff_penangani
FROM pemesanan p
JOIN tamu t ON p.id_tamu = t.id_tamu
JOIN detail_pemesanan_kamar dpk ON p.id_pemesanan = dpk.id_pemesanan
JOIN kamar k ON dpk.id_kamar = k.id_kamar
LEFT JOIN registrasi_tamu rt ON p.id_pemesanan = rt.id_pemesanan
LEFT JOIN staff s ON rt.staff_check_in = s.id_staff
WHERE p.check_out = CURRENT_DATE
AND p.status_pemesanan = 'check_in'
GROUP BY 
    p.kode_booking, t.nama_lengkap, t.no_telepon, p.waktu_check_out_rencana,
    p.jumlah_tamu, p.deposit, p.catatan_khusus, rt.total_biaya_tambahan,
    s.nama_lengkap
ORDER BY p.waktu_check_out_rencana;

-- 8. VIEW: Revenue Breakdown per Tipe Kamar
CREATE VIEW view_revenue_per_tipe_kamar AS
SELECT 
    k.tipe_kamar,
    COUNT(DISTINCT p.id_pemesanan) AS jumlah_pemesanan,
    COUNT(DISTINCT dpk.id_kamar) AS jumlah_kamar_terjual,
    SUM(p.jumlah_malam) AS total_malam,
    SUM(p.total_harga) AS total_revenue,
    AVG(p.total_harga) AS avg_revenue_per_booking,
    ROUND(
        (SUM(p.total_harga) / NULLIF(SUM(p.jumlah_malam), 0))::NUMERIC,
        2
    ) AS avg_rate_per_night,
    MIN(p.total_harga / NULLIF(p.jumlah_malam, 0)) AS min_rate,
    MAX(p.total_harga / NULLIF(p.jumlah_malam, 0)) AS max_rate,
    ROUND(
        (COUNT(DISTINCT dpk.id_kamar)::NUMERIC / 
        NULLIF((SELECT COUNT(*) FROM kamar k2 WHERE k2.tipe_kamar = k.tipe_kamar), 0) * 100)::NUMERIC,
        2
    ) AS market_penetration
FROM pemesanan p
JOIN detail_pemesanan_kamar dpk ON p.id_pemesanan = dpk.id_pemesanan
JOIN kamar k ON dpk.id_kamar = k.id_kamar
WHERE p.status_pemesanan NOT IN ('dibatalkan', 'no_show')
GROUP BY k.tipe_kamar
ORDER BY total_revenue DESC;

-- 9. VIEW: Staff Performance
CREATE VIEW view_staff_performance AS
SELECT 
    s.id_staff,
    s.nama_lengkap,
    s.jabatan,
    COUNT(DISTINCT p.id_pemesanan) AS total_pemesanan_diproses,
    SUM(p.total_harga) AS total_revenue_dihasilkan,
    COUNT(DISTINCT rt.id_registrasi) AS total_checkin_diproses,
    COUNT(DISTINCT CASE 
        WHEN p.status_pemesanan = 'dibatalkan' THEN p.id_pemesanan 
    END) AS pemesanan_dibatalkan,
    AVG(p.total_harga) AS avg_transaction_value,
    MIN(p.tanggal_pemesanan) AS pertama_kali_melayani,
    MAX(p.tanggal_pemesanan) AS terakhir_kali_melayani
FROM staff s
LEFT JOIN pemesanan p ON s.id_staff = p.created_by
LEFT JOIN registrasi_tamu rt ON s.id_staff = rt.staff_check_in
WHERE s.is_active = true
GROUP BY s.id_staff, s.nama_lengkap, s.jabatan
ORDER BY total_revenue_dihasilkan DESC;

-- 10. VIEW: Cancellation Analysis
CREATE VIEW view_cancellation_analysis AS
SELECT 
    DATE_TRUNC('month', p.tanggal_pemesanan) AS bulan,
    -- Reason analysis (dari history)
    hs.alasan_perubahan,
    COUNT(*) AS jumlah_pembatalan,
    SUM(p.total_harga) AS potential_revenue_lost,
    AVG(p.total_harga) AS avg_value_pembatalan,
    -- Time to cancellation
    AVG(EXTRACT(DAY FROM hs.created_at - p.tanggal_pemesanan)) AS avg_hari_sebelum_pembatalan,
    -- Kamar type affected
    STRING_AGG(DISTINCT k.tipe_kamar::TEXT, ', ') AS tipe_kamar_terbatal
FROM pemesanan p
JOIN history_status hs ON p.id_pemesanan = hs.id_pemesanan
JOIN detail_pemesanan_kamar dpk ON p.id_pemesanan = dpk.id_pemesanan
JOIN kamar k ON dpk.id_kamar = k.id_kamar
WHERE hs.status_baru = 'dibatalkan'
GROUP BY DATE_TRUNC('month', p.tanggal_pemesanan), hs.alasan_perubahan
ORDER BY bulan DESC, jumlah_pembatalan DESC;

-- 11. VIEW: Tamu dengan Special Request/Preference
CREATE VIEW view_tamu_preferensi AS
SELECT 
    t.id_tamu,
    t.nama_lengkap,
    t.tier_member,
    -- Extract preferences
    (t.preferensi->>'merokok')::boolean AS merokok,
    (t.preferensi->>'lantai_tinggi')::boolean AS lantai_tinggi,
    (t.preferensi->>'dekat_lift')::boolean AS dekat_lift,
    (t.preferensi->>'kamar_pedas')::boolean AS kamar_pedas,
    t.preferensi->>'tipe_bed' AS tipe_bed,
    (t.preferensi->>'sarapan')::boolean AS sarapan,
    -- Booking history
    COUNT(DISTINCT p.id_pemesanan) AS total_kunjungan,
    STRING_AGG(DISTINCT k.tipe_kamar::TEXT, ', ') AS tipe_kamar_dipesan
FROM tamu t
LEFT JOIN pemesanan p ON t.id_tamu = p.id_tamu
LEFT JOIN detail_pemesanan_kamar dpk ON p.id_pemesanan = dpk.id_pemesanan
LEFT JOIN kamar k ON dpk.id_kamar = k.id_kamar
WHERE t.preferensi IS NOT NULL
GROUP BY t.id_tamu, t.nama_lengkap, t.tier_member, t.preferensi
HAVING COUNT(DISTINCT p.id_pemesanan) > 0
ORDER BY total_kunjungan DESC;

-- 12. VIEW: Inventory & Maintenance Schedule
CREATE VIEW view_maintenance_schedule AS
SELECT 
    k.id_kamar,
    k.nomor_kamar,
    k.tipe_kamar,
    k.status_kamar,
    k.status_kebersihan,
    -- Last cleaning
    MAX(rt.waktu_check_out_aktual) AS terakhir_check_out,
    -- Next available booking
    MIN(p.check_in) AS pemesanan_berikutnya,
    -- Maintenance needed?
    CASE 
        WHEN k.status_kamar = 'maintenance' THEN 'Dalam perbaikan'
        WHEN k.status_kebersihan = 'kotor' THEN 'Perlu dibersihkan'
        WHEN k.status_kebersihan = 'perlu_perbaikan' THEN 'Perlu perbaikan'
        ELSE 'Ready'
    END AS status_tindakan,
    -- Days since last occupancy
    EXTRACT(DAY FROM CURRENT_DATE - MAX(rt.waktu_check_out_aktual)) AS hari_sejak_terakhir_dipakai
FROM kamar k
LEFT JOIN detail_pemesanan_kamar dpk ON k.id_kamar = dpk.id_kamar
LEFT JOIN pemesanan p ON dpk.id_pemesanan = p.id_pemesanan
LEFT JOIN registrasi_tamu rt ON dpk.id_pemesanan = rt.id_pemesanan
GROUP BY k.id_kamar, k.nomor_kamar, k.tipe_kamar, k.status_kamar, k.status_kebersihan
ORDER BY 
    CASE k.status_kamar
        WHEN 'maintenance' THEN 1
        WHEN 'dipakai' THEN 2
        WHEN 'dipesan' THEN 3
        ELSE 4
    END,
    k.lantai, k.nomor_kamar;

DO $$
BEGIN
    RAISE NOTICE '✅ Views untuk reporting berhasil dibuat';
    RAISE NOTICE '📊 Total views: 12 views utama';
END $$;