-- =====================================================
-- SHOWCASE QUERIES (FINAL, SAFE, EXPLICIT CAST)
-- =====================================================

-- ============================================
-- 1. Cek kamar tersedia (function)
-- ============================================
SELECT *
FROM view_kamar_tersedia_realtime;


-- ============================================
-- 2. Top tamu berdasarkan transaksi
-- ============================================
SELECT *
FROM view_top_tamu;

-- ============================================
-- 3. Dashboard harian
-- ============================================
SELECT *
FROM view_dashboard_harian;

-- ============================================
-- 4. Laporan bulanan
-- ============================================
SELECT *
FROM view_laporan_bulanan
ORDER BY bulan DESC
LIMIT 6;

-- ============================================
-- 5. Kamar tersedia realtime
-- ============================================
SELECT *
FROM view_kamar_tersedia_realtime;

-- ============================================
-- 6. Pemesanan hari ini
-- ============================================
SELECT *
FROM view_pemesanan_hari_ini;

-- ============================================
-- 7. Check-in hari ini
-- ============================================
SELECT *
FROM view_checkin_hari_ini;

-- ============================================
-- 8. Check-out hari ini
-- ============================================
SELECT *
FROM view_checkout_hari_ini;

-- ============================================
-- 9. Revenue per tipe kamar
-- ============================================
SELECT *
FROM view_revenue_per_tipe_kamar
ORDER BY total_revenue DESC;

-- ============================================
-- 10. Staff performance
-- ============================================
SELECT *
FROM view_staff_performance
ORDER BY  total_revenue_dihasilkan
 DESC;

-- ============================================
-- 11. Analisis pembatalan
-- ============================================
SELECT *
FROM view_cancellation_analysis;

-- ============================================
-- 12. Preferensi tamu
-- ============================================
SELECT *
FROM view_tamu_preferensi;

-- ============================================
-- 13. Maintenance schedule
-- ============================================
SELECT *
FROM view_maintenance_schedule
ORDER BY terakhir_check_out;

-- ============================================
-- SHOWCASE QUERIES - MENGGUNAKAN FUNCTIONS 
-- ============================================




-- 14. DEMO: Proses check-in tamu (gunakan ID pemesanan yang valid)
SELECT * FROM fn_proses_checkin(
    4,                      -- ID Pemesanan yang valid (lihat di tabel pemesanan)
    1,                      -- ID Staff Rina
    NULL,                   -- Waktu check-in (default now)
    'Tamu check-in sesuai jadwal'
);

-- 15. DEMO: Proses check-out tamu (gunakan ID pemesanan yang sedang check-in)
SELECT * FROM fn_proses_checkout(
    1,                      -- ID Pemesanan yang sedang check-in
    2,                      -- ID Staff Agus
    NULL,                   -- Waktu check-out (default now)
    'baik',                 -- Kondisi kamar
    'Kamar dalam kondisi baik',
    '[{"nama": "Minibar Coca Cola", "jumlah": 2, "harga": 25000}, {"nama": "Laundry Kiloan", "jumlah": 1, "harga": 35000}]'::jsonb
);

-- 16. DEMO: Update harga massal
SELECT * FROM fn_update_harga_massal(
    'deluxe',              -- Tipe kamar
    '2026-12-20',         -- Mulai
    '2027-01-10',         -- Selesai
    15,                   -- Naik 15% (bukan 25% agar lebih realistis)
    1                     -- ID Staff
);





-- 17. DEMO: Batalkan pemesanan (gunakan ID pemesanan yang bisa dibatalkan)
SELECT * FROM fn_batalkan_pemesanan(
    8,                     -- ID Pemesanan yang statusnya menunggu atau terkonfirmasi
    1,                     -- ID Staff
    'Perubahan jadwal perjalanan' -- Alasan
);

-- 18. DEMO: Quick check-in dengan kode booking yang valid
-- Cari dulu kode booking yang ada
SELECT kode_booking FROM pemesanan WHERE status_pemesanan = 'terkonfirmasi' LIMIT 1;

-- Kemudian gunakan kode tersebut
SELECT * FROM fn_quick_checkin(
    'NUS-20260315-00001',  -- Ganti dengan kode booking yang valid
    2                      -- ID Staff
);



-- 19. DEMO: Lihat hasil dari function yang dijalankan
SELECT 
    'fn_proses_pemesanan_lengkap' as function_name,
    COUNT(*) as total_pemesanan_baru
FROM pemesanan 
WHERE created_at > CURRENT_TIMESTAMP - INTERVAL '5 minutes';

-- 20. DEMO: Tampilkan semua functions yang berhasil dibuat
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE 'fn_%'
ORDER BY routine_name;