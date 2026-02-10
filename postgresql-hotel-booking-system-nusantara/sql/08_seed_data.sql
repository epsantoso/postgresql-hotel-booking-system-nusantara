-- ============================================
-- SAMPLE DATA UNTUK TESTING & DEVELOPMENT
-- ============================================

-- 1. HAPUS SEMUA DATA DENGAN URUTAN YANG BENAR
-- Nonaktifkan trigger sementara untuk menghindari konflik
ALTER TABLE IF EXISTS pemesanan DISABLE TRIGGER ALL;

-- Hapus data dari child tables terlebih dahulu
DELETE FROM history_status;
DELETE FROM pembayaran;
DELETE FROM registrasi_tamu;
DELETE FROM detail_pemesanan_kamar;
DELETE FROM tarif_kamar;
DELETE FROM laporan_harian;
DELETE FROM program_loyalty;
DELETE FROM fasilitas_tambahan;
DELETE FROM staff;
DELETE FROM tamu;
DELETE FROM kamar;
DELETE FROM pemesanan;

-- 2. RESET SEMUA SEQUENCES
DO $$
DECLARE
    seq_name RECORD;
BEGIN
    FOR seq_name IN 
        SELECT sequence_name 
        FROM information_schema.sequences 
        WHERE sequence_schema = 'public'
    LOOP
        EXECUTE 'ALTER SEQUENCE ' || seq_name.sequence_name || ' RESTART WITH 1;';
        RAISE NOTICE 'Reset sequence: %', seq_name.sequence_name;
    END LOOP;
END $$;

-- 3. INSERT DATA KAMAR
INSERT INTO kamar (nomor_kamar, lantai, tipe_kamar, kapasitas, harga_standar, fasilitas, status_kamar) VALUES
('101', 1, 'standard', 2, 450000, '{"ac": true, "tv": true, "kulkas": false, "bathub": false, "wifi": true, "breakfast": true, "hot_water": true}', 'tersedia'),
('102', 1, 'standard', 2, 450000, '{"ac": true, "tv": true, "kulkas": false, "bathub": false, "wifi": true, "breakfast": true, "hot_water": true}', 'tersedia'),
('103', 1, 'standard', 2, 450000, '{"ac": true, "tv": true, "kulkas": false, "bathub": false, "wifi": true, "breakfast": true, "hot_water": true}', 'dipesan'),
('104', 1, 'standard', 3, 500000, '{"ac": true, "tv": true, "kulkas": true, "bathub": false, "wifi": true, "breakfast": true, "hot_water": true, "extra_bed": true}', 'tersedia'),
('201', 2, 'deluxe', 2, 650000, '{"ac": true, "tv": true, "kulkas": true, "bathub": true, "wifi": true, "breakfast": true, "hot_water": true, "safe_deposit": true}', 'dipakai'),
('202', 2, 'deluxe', 2, 650000, '{"ac": true, "tv": true, "kulkas": true, "bathub": true, "wifi": true, "breakfast": true, "hot_water": true, "safe_deposit": true}', 'tersedia'),
('203', 2, 'deluxe', 2, 650000, '{"ac": true, "tv": true, "kulkas": true, "bathub": true, "wifi": true, "breakfast": true, "hot_water": true, "safe_deposit": true}', 'dipesan'),
('204', 2, 'deluxe', 2, 650000, '{"ac": true, "tv": true, "kulkas": true, "bathub": true, "wifi": true, "breakfast": true, "hot_water": true, "safe_deposit": true}', 'maintenance'),
('301', 3, 'suite', 3, 850000, '{"ac": true, "tv": true, "kulkas": true, "bathub": true, "wifi": true, "breakfast": true, "hot_water": true, "safe_deposit": true, "living_room": true, "minibar": true}', 'tersedia'),
('302', 3, 'suite', 3, 850000, '{"ac": true, "tv": true, "kulkas": true, "bathub": true, "wifi": true, "breakfast": true, "hot_water": true, "safe_deposit": true, "living_room": true, "minibar": true}', 'dipesan'),
('303', 3, 'suite', 3, 850000, '{"ac": true, "tv": true, "kulkas": true, "bathub": true, "wifi": true, "breakfast": true, "hot_water": true, "safe_deposit": true, "living_room": true, "minibar": true}', 'dipakai'),
('401', 4, 'keluarga', 4, 1200000, '{"ac": true, "tv": true, "kulkas": true, "bathub": true, "wifi": true, "breakfast": true, "hot_water": true, "safe_deposit": true, "extra_bed": true, "kitchenette": true}', 'tersedia'),
('402', 4, 'keluarga', 4, 1200000, '{"ac": true, "tv": true, "kulkas": true, "bathub": true, "wifi": true, "breakfast": true, "hot_water": true, "safe_deposit": true, "extra_bed": true, "kitchenette": true}', 'dipesan'),
('403', 4, 'keluarga', 6, 1500000, '{"ac": true, "tv": true, "kulkas": true, "bathub": true, "wifi": true, "breakfast": true, "hot_water": true, "safe_deposit": true, "extra_bed": true, "kitchenette": true, "teras": true}', 'tersedia'),
('501', 5, 'presiden', 2, 2500000, '{"ac": true, "tv": true, "kulkas": true, "bathub": true, "wifi": true, "breakfast": true, "hot_water": true, "safe_deposit": true, "living_room": true, "minibar": true, "jacuzzi": true, "kitchen": true, "teras": true, "butler_service": true}', 'tersedia'),
('502', 5, 'presiden', 2, 2500000, '{"ac": true, "tv": true, "kulkas": true, "bathub": true, "wifi": true, "breakfast": true, "hot_water": true, "safe_deposit": true, "living_room": true, "minibar": true, "jacuzzi": true, "kitchen": true, "teras": true, "butler_service": true}', 'dipakai');

-- 4. INSERT DATA TAMU
INSERT INTO tamu (nik, nama_lengkap, nama_panggilan, jenis_kelamin, tanggal_lahir, no_telepon, email, alamat, kota, tipe_tamu, preferensi, poin_member, tier_member) VALUES
('3273010101010001', 'Budi Santoso', 'Budi', 'L', '1985-05-15', '08123456789', 'budi.santoso@gmail.com', 'Jl. Merdeka No. 123', 'Jakarta', 'reguler', '{"merokok": false, "lantai_tinggi": true, "dekat_lift": false, "kamar_pedas": false, "tipe_bed": "double", "sarapan": true}', 150, 'silver'),
('3273010202020002', 'Sari Dewi', 'Sari', 'P', '1990-08-20', '08234567890', 'sari.dewi@yahoo.com', 'Jl. Sudirman No. 456', 'Bandung', 'reguler', '{"merokok": false, "lantai_tinggi": false, "dekat_lift": true, "kamar_pedas": false, "tipe_bed": "twin", "sarapan": true}', 80, 'bronze'),
('3273010303030003', 'Ahmad Hidayat', 'Ahmad', 'L', '1982-11-30', '08345678901', 'ahmad.hidayat@company.com', 'Jl. Thamrin No. 789', 'Surabaya', 'corporate', '{"merokok": true, "lantai_tinggi": true, "dekat_lift": true, "kamar_pedas": true, "tipe_bed": "king", "sarapan": false}', 300, 'gold'),
('3273010404040004', 'Dewi Lestari', 'Dewi', 'P', '1978-03-25', '08456789012', 'dewi.lestari@vip.com', 'Jl. Gatot Subroto No. 101', 'Jakarta', 'vip', '{"merokok": false, "lantai_tinggi": true, "dekat_lift": false, "kamar_pedas": false, "tipe_bed": "king", "sarapan": true, "koran_pagi": true, "wifi_priority": true}', 1200, 'platinum'),
('3273010505050005', 'Hendra Wijaya', 'Hendra', 'L', '1988-07-12', '08567890123', 'hendra.wijaya@business.com', 'Jl. Asia Afrika No. 202', 'Bandung', 'member', '{"merokok": false, "lantai_tinggi": false, "dekat_lift": true, "kamar_pedas": false, "tipe_bed": "double", "sarapan": true}', 450, 'silver'),
('3273010606060006', 'PT. Travelindo Jaya', 'Travelindo', NULL, NULL, '02155667788', 'booking@travelindo.com', 'Jl. Kebon Sirih No. 50', 'Jakarta', 'travel_agent', '{}', 0, 'bronze'),
(NULL, 'John Smith', 'John', 'L', '1975-12-10', '+44123456789', 'john.smith@email.com', '123 Oxford Street', 'London', 'reguler', '{"merokok": false, "lantai_tinggi": true, "dekat_lift": true, "kamar_pedas": false, "tipe_bed": "king", "sarapan": true}', 0, 'bronze'),
(NULL, 'Yuki Tanaka', 'Yuki', 'P', '1992-04-18', '+81312345678', 'yuki.tanaka@japan.com', '1-2-3 Shibuya', 'Tokyo', 'reguler', '{"merokok": false, "lantai_tinggi": false, "dekat_lift": false, "kamar_pedas": false, "tipe_bed": "double", "sarapan": false}', 0, 'bronze');

-- 5. INSERT DATA STAFF
INSERT INTO staff (nik, nama_lengkap, nama_panggilan, jabatan, departemen, no_telepon, email, username, role_sistem, shift_default, status_kerja) VALUES
('3273010707070007', 'Rina Wulandari', 'Rina', 'resepsionis', 'front_office', '08111222333', 'rina.wulandari@hotelnusantara.id', 'rina.front', 'user', 'pagi', 'aktif'),
('3273010808080008', 'Agus Supriyadi', 'Agus', 'resepsionis', 'front_office', '08222333444', 'agus.supriyadi@hotelnusantara.id', 'agus.front', 'user', 'sore', 'aktif'),
('3273010909090009', 'Siti Fatimah', 'Siti', 'resepsionis', 'front_office', '08333444555', 'siti.fatimah@hotelnusantara.id', 'siti.front', 'user', 'malam', 'aktif'),
('3273011010100010', 'Mulyadi', 'Mulya', 'housekeeping', 'housekeeping', '08444555666', 'mulyadi@hotelnusantara.id', 'mulya.hk', 'user', 'pagi', 'aktif'),
('3273011111110011', 'Sri Wahyuni', 'Sri', 'housekeeping', 'housekeeping', '08555666777', 'sri.wahyuni@hotelnusantara.id', 'sri.hk', 'user', 'sore', 'aktif'),
('3273011212120012', 'Bambang Sulistyo', 'Bambang', 'manager', 'management', '08666777888', 'bambang@hotelnusantara.id', 'bambang.mgr', 'admin', 'pagi', 'aktif'),
('3273011313130013', 'Lisa Setiawati', 'Lisa', 'supervisor', 'front_office', '08777888999', 'lisa@hotelnusantara.id', 'lisa.spv', 'supervisor', 'sore', 'aktif'),
('3273011414140014', 'Dian Pratama', 'Dian', 'keuangan', 'finance', '08888999000', 'dian@hotelnusantara.id', 'dian.fin', 'user', 'pagi', 'aktif');

-- 6. INSERT FASILITAS TAMBAHAN
INSERT INTO fasilitas_tambahan (kode_fasilitas, nama_fasilitas, deskripsi, harga, satuan, kategori, subkategori, is_active) VALUES
('FNB-001', 'Breakfast Buffet', 'Paket breakfast buffet untuk 1 orang', 75000, 'per_orang', 'makanan', 'breakfast', true),
('FNB-002', 'Indonesian Dinner Set', 'Paket makan malam masakan Indonesia', 120000, 'per_paket', 'makanan', 'dinner', true),
('FNB-003', 'Room Service - Nasi Goreng', 'Nasi goreng spesial room service', 65000, 'per_item', 'makanan', 'room_service', true),
('FNB-004', 'Minibar - Coca Cola', 'Coca Cola 330ml', 25000, 'per_item', 'minuman', 'minibar', true),
('FNB-005', 'Minibar - Air Mineral', 'Air mineral 600ml', 15000, 'per_item', 'minuman', 'minibar', true),
('LDY-001', 'Laundry Kiloan', 'Laundry kiloan (min 2kg)', 35000, 'per_item', 'laundry', 'regular', true),
('LDY-002', 'Express Laundry', 'Laundry express 4 jam', 75000, 'per_item', 'laundry', 'express', true),
('LDY-003', 'Dry Cleaning - Jas', 'Dry cleaning untuk jas', 85000, 'per_item', 'laundry', 'dry_clean', true),
('TRN-001', 'Airport Transfer', 'Transfer bandara (1-3 orang)', 200000, 'per_paket', 'transport', 'airport', true),
('TRN-002', 'City Tour 4 Hours', 'Tour kota dengan mobil', 350000, 'per_paket', 'transport', 'tour', true),
('SPA-001', 'Traditional Massage 60min', 'Pijat tradisional 60 menit', 300000, 'per_paket', 'spa', 'massage', true),
('SPA-002', 'Aromatherapy Package', 'Paket aromaterapi lengkap', 450000, 'per_paket', 'spa', 'package', true),
('BUS-001', 'Meeting Room 4 Hours', 'Sewa meeting room 4 jam', 500000, 'per_paket', 'business', 'meeting', true),
('BUS-002', 'Photocopy per Page', 'Fotokopi hitam putih', 1000, 'per_item', 'business', 'document', true),
('OTH-001', 'Extra Bed', 'Tambah tempat tidur', 150000, 'per_malam', 'lainnya', 'bed', true),
('OTH-002', 'Late Check-out (2 hours)', 'Check-out tambahan 2 jam', 200000, 'per_paket', 'lainnya', 'late_checkout', true),
('OTH-003', 'Early Check-in (2 hours)', 'Check-in lebih awal 2 jam', 150000, 'per_paket', 'lainnya', 'early_checkin', true);

-- 7. INSERT TARIF KAMAR KHUSUS
INSERT INTO tarif_kamar (id_kamar, tanggal_mulai, tanggal_selesai, harga_dasar, harga_akhir_minggu, harga_libur_nasional, min_malam) VALUES
(1, '2026-12-20', '2027-01-10', 550000, 660000, 715000, 2),
(2, '2026-12-20', '2027-01-10', 550000, 660000, 715000, 2),
(9, '2026-12-20', '2027-01-10', 1000000, 1200000, 1300000, 3),
(13, '2026-12-20', '2027-01-10', 1500000, 1800000, 1950000, 3),
(1, '2026-03-28', '2026-04-02', 600000, 720000, 780000, 3),
(2, '2026-03-28', '2026-04-02', 600000, 720000, 780000, 3),
(11, '2026-03-28', '2026-04-02', 1400000, 1680000, 1820000, 4),
(5, '2026-03-01', '2026-12-31', 600000, 720000, NULL, 2),
(6, '2026-03-01', '2026-12-31', 600000, 720000, NULL, 2);

-- 8. INSERT PROGRAM LOYALTY
INSERT INTO program_loyalty (nama_program, tier, min_stay, min_spend, benefits, tanggal_mulai, tanggal_selesai) VALUES
('Bronze Member', 'bronze', 1, 0, '{"diskon": 0, "late_checkout": false, "welcome_drink": false, "room_upgrade": false, "free_breakfast": false}', '2026-01-01', NULL),
('Silver Member', 'silver', 5, 2000000, '{"diskon": 5, "late_checkout": true, "welcome_drink": true, "room_upgrade": false, "free_breakfast": false}', '2026-01-01', NULL),
('Gold Member', 'gold', 10, 5000000, '{"diskon": 10, "late_checkout": true, "welcome_drink": true, "room_upgrade": true, "free_breakfast": true}', '2026-01-01', NULL),
('Platinum Member', 'platinum', 20, 10000000, '{"diskon": 15, "late_checkout": true, "welcome_drink": true, "room_upgrade": true, "free_breakfast": true, "airport_transfer": true}', '2026-01-01', NULL);

-- 9. INSERT PEMESANAN DENGAN KODE_BOOKING MANUAL (karena trigger disabled)
-- Note: Setelah disable trigger, kita bisa insert dengan kode_booking manual
INSERT INTO pemesanan (kode_booking, id_tamu, check_in, check_out, jumlah_tamu, jumlah_tamu_dewasa, jumlah_tamu_anak, total_harga, deposit, total_dibayar, status_pemesanan, status_pembayaran, metode_pembayaran, created_by) VALUES
('NUS-20260315-00001', 1, '2026-03-15', '2026-03-18', 2, 2, 0, 1350000, 500000, 1350000, 'check_in', 'lunas', 'transfer', 1),
('NUS-20260314-00001', 3, '2026-03-14', '2026-03-16', 1, 1, 0, 1300000, 650000, 1300000, 'check_in', 'lunas', 'kartu_kredit', 2),
('NUS-20260316-00001', 4, '2026-03-16', '2026-03-20', 2, 2, 0, 10000000, 3000000, 10000000, 'check_in', 'lunas', 'transfer', 1),
('NUS-20260320-00001', 2, '2026-03-20', '2026-03-22', 2, 2, 0, 900000, 450000, 450000, 'terkonfirmasi', 'dp', 'qris', 2),
('NUS-20260325-00001', 5, '2026-03-25', '2026-03-27', 3, 2, 1, 2400000, 1200000, 1200000, 'terkonfirmasi', 'dp', 'transfer', 1),
('NUS-20260210-00001', 1, '2026-02-10', '2026-02-12', 2, 2, 0, 900000, 900000, 900000, 'check_out', 'lunas', 'tunai', 2),
('NUS-20260215-00001', 3, '2026-02-15', '2026-02-17', 1, 1, 0, 1300000, 1300000, 1300000, 'check_out', 'lunas', 'kartu_kredit', 1),
('NUS-20260305-00001', 2, '2026-03-05', '2026-03-07', 2, 2, 0, 900000, 200000, 200000, 'dibatalkan', 'refund', 'transfer', 2);

-- 10. AKTIFKAN KEMBALI TRIGGER
ALTER TABLE IF EXISTS pemesanan ENABLE TRIGGER ALL;

-- 11. INSERT DETAIL PEMESANAN KAMAR
INSERT INTO detail_pemesanan_kamar (id_pemesanan, id_kamar, harga_per_malam, sub_total, tamu_tambahan) VALUES
(1, 5, 650000, 1950000, 0),
(2, 9, 850000, 1700000, 0),
(3, 15, 2500000, 10000000, 0),
(4, 1, 450000, 900000, 0),
(5, 13, 1200000, 2400000, 1),
(6, 6, 650000, 1300000, 0),
(7, 10, 850000, 1700000, 0),
(8, 2, 450000, 900000, 0);

-- 12. INSERT REGISTRASI TAMU
INSERT INTO registrasi_tamu (id_pemesanan, id_kamar, waktu_check_in_aktual, waktu_check_out_aktual, staff_check_in, deposit_digunakan, total_biaya_tambahan) VALUES
(1, 5, '2026-03-15 14:30:00+07', NULL, 1, 0, 125000),
(2, 9, '2026-03-14 15:45:00+07', NULL, 2, 0, 0),
(3, 15, '2026-03-16 16:15:00+07', NULL, 1, 0, 350000),
(6, 6, '2026-02-10 15:00:00+07', '2026-02-12 11:30:00+07', 2, 1, 75000),
(7, 10, '2026-02-15 14:15:00+07', '2026-02-17 12:45:00+07', 1, 2, 150000);

-- 13. INSERT PEMBAYARAN
INSERT INTO pembayaran (id_pemesanan, jumlah_bayar, tanggal_bayar, metode_bayar, nama_bank, nomor_referensi, status_bayar, created_by) VALUES
(1, 500000, '2026-03-10 10:30:00+07', 'transfer', 'BCA', 'TRX00123456', 'sukses', 1),
(1, 850000, '2026-03-14 14:20:00+07', 'transfer', 'BCA', 'TRX00123457', 'sukses', 1),
(2, 650000, '2026-03-05 11:15:00+07', 'kartu_kredit', NULL, 'CC123456789', 'sukses', 2),
(2, 650000, '2026-03-13 09:45:00+07', 'kartu_kredit', NULL, 'CC123456790', 'sukses', 2),
(3, 3000000, '2026-03-01 16:30:00+07', 'transfer', 'Mandiri', 'TRX00123458', 'sukses', 1),
(3, 7000000, '2026-03-10 10:00:00+07', 'transfer', 'Mandiri', 'TRX00123459', 'sukses', 1),
(4, 450000, '2026-03-12 13:20:00+07', 'qris', NULL, 'QRIS123456', 'sukses', 2),
(5, 1200000, '2026-03-18 15:45:00+07', 'transfer', 'BNI', 'TRX00123460', 'sukses', 1),
(6, 900000, '2026-02-05 14:30:00+07', 'tunai', NULL, 'CASH001', 'sukses', 2),
(7, 1300000, '2026-02-10 11:20:00+07', 'kartu_kredit', NULL, 'CC123456791', 'sukses', 1),
(8, 200000, '2026-02-28 10:15:00+07', 'transfer', 'BCA', 'TRX00123461', 'sukses', 2);

-- 14. INSERT HISTORY STATUS
INSERT INTO history_status (id_pemesanan, status_lama, status_baru, diubah_oleh, tipe_perubahan, alasan_perubahan) VALUES
(1, NULL, 'menunggu', 1, 'sistem', 'Pemesanan dibuat'),
(1, 'menunggu', 'terkonfirmasi', 1, 'manual', 'DP diterima'),
(1, 'terkonfirmasi', 'check_in', 1, 'manual', 'Tamu check-in'),
(2, NULL, 'menunggu', 2, 'sistem', 'Pemesanan dibuat'),
(2, 'menunggu', 'terkonfirmasi', 2, 'manual', 'Pembayaran lunas'),
(2, 'terkonfirmasi', 'check_in', 2, 'manual', 'Tamu check-in'),
(8, NULL, 'menunggu', 2, 'sistem', 'Pemesanan dibuat'),
(8, 'menunggu', 'terkonfirmasi', 2, 'manual', 'DP diterima'),
(8, 'terkonfirmasi', 'dibatalkan', 2, 'manual', 'Tamu membatalkan');

-- 15. INSERT LAPORAN HARIAN
INSERT INTO laporan_harian (tanggal, total_kamar, kamar_terisi, tamu_check_in, tamu_check_out, tamu_in_house, pendapatan_kamar, pendapatan_fnb, pendapatan_lainnya, generated_by) VALUES
('2026-03-15', 15, 3, 2, 1, 5, 4250000, 475000, 0, 1),
('2026-03-14', 15, 2, 1, 0, 3, 2600000, 150000, 0, 2),
('2026-03-13', 15, 1, 0, 1, 2, 1300000, 0, 0, 1);

-- 16. TAMPILKAN PESAN SUKSES
DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ SAMPLE DATA BERHASIL DIINSERT!';
    RAISE NOTICE '============================================';
    RAISE NOTICE '📊 STATISTIK DATA:';
    RAISE NOTICE '   - Kamar: 15 kamar';
    RAISE NOTICE '   - Tamu: 8 tamu';
    RAISE NOTICE '   - Staff: 8 staff';
    RAISE NOTICE '   - Fasilitas: 17 fasilitas';
    RAISE NOTICE '   - Pemesanan: 8 pemesanan';
    RAISE NOTICE '   - Pembayaran: 11 transaksi';
    RAISE NOTICE '   - Tarif khusus: 9 tarif';
    RAISE NOTICE '   - Laporan: 3 laporan harian';
    RAISE NOTICE '============================================';
    RAISE NOTICE '🎯 CATATAN:';
    RAISE NOTICE '   - Trigger telah dinonaktifkan sementara';
    RAISE NOTICE '   - Semua sequence telah direset ke 1';
    RAISE NOTICE '   - Data siap untuk testing & development';
    RAISE NOTICE '============================================';
END $$;