-- ============================================
-- FUNCTIONS UNTUK COMPLEX OPERATIONS (FIXED VERSION)
-- Menggunakan RETURN TABLE tanpa transaction issues
-- ============================================

-- 1. FUNCTION: Proses pemesanan lengkap (FIXED VERSION)
CREATE OR REPLACE FUNCTION fn_proses_pemesanan_lengkap(
    p_id_tamu INTEGER,
    p_check_in DATE,
    p_check_out DATE,
    p_jumlah_tamu INTEGER,
    p_jumlah_tamu_dewasa INTEGER,
    p_id_staff INTEGER,
    p_id_kamar INTEGER[],
    p_metode_pembayaran tipe_pembayaran,
    p_jumlah_dp NUMERIC DEFAULT NULL,
    p_catatan_khusus TEXT DEFAULT NULL,
    p_jumlah_tamu_anak INTEGER DEFAULT 0
)
RETURNS TABLE (
    kode_booking VARCHAR,
    id_pemesanan BIGINT,
    total_harga NUMERIC,
    pesan TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_pemesanan BIGINT;
    v_kode_booking VARCHAR;
    v_total_harga NUMERIC(12,2) := 0;
    v_masa_inap INTEGER;
    v_id_kamar INTEGER;
    v_harga_kamar NUMERIC(10,2);
    v_kamar_tersedia BOOLEAN;
    v_error_message TEXT;
BEGIN
    -- Validasi input
    IF p_check_in >= p_check_out THEN
        kode_booking := NULL;
        id_pemesanan := NULL;
        total_harga := NULL;
        pesan := 'Tanggal check-out harus setelah check-in';
        RETURN NEXT;
        RETURN;
    END IF;
    
    IF p_jumlah_tamu_dewasa + p_jumlah_tamu_anak != p_jumlah_tamu THEN
        kode_booking := NULL;
        id_pemesanan := NULL;
        total_harga := NULL;
        pesan := 'Jumlah tamu dewasa + anak harus sama dengan total tamu';
        RETURN NEXT;
        RETURN;
    END IF;
    
    IF array_length(p_id_kamar, 1) IS NULL THEN
        kode_booking := NULL;
        id_pemesanan := NULL;
        total_harga := NULL;
        pesan := 'Pilih minimal 1 kamar';
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Hitung masa inap
    v_masa_inap := p_check_out - p_check_in;
    
    -- Cek ketersediaan semua kamar SEBELUM transaction
    FOREACH v_id_kamar IN ARRAY p_id_kamar LOOP
        SELECT cek_ketersediaan_kamar(v_id_kamar, p_check_in, p_check_out) 
        INTO v_kamar_tersedia;
        
        IF NOT v_kamar_tersedia THEN
            kode_booking := NULL;
            id_pemesanan := NULL;
            total_harga := NULL;
            pesan := format('Kamar %s tidak tersedia pada tanggal yang diminta', v_id_kamar);
            RETURN NEXT;
            RETURN;
        END IF;
    END LOOP;
    
    -- Mulai transaction block
    BEGIN
        -- Hitung total harga
        FOREACH v_id_kamar IN ARRAY p_id_kamar LOOP
            SELECT hitung_harga_kamar(v_id_kamar, p_check_in) INTO v_harga_kamar;
            v_total_harga := v_total_harga + (v_harga_kamar * v_masa_inap);
        END LOOP;
        
        -- Buat pemesanan
        INSERT INTO pemesanan (
            id_tamu, check_in, check_out, jumlah_tamu,
            jumlah_tamu_dewasa, jumlah_tamu_anak,
            total_harga, status_pemesanan, metode_pembayaran,
            catatan_khusus, created_by
        ) VALUES (
            p_id_tamu, p_check_in, p_check_out, p_jumlah_tamu,
            p_jumlah_tamu_dewasa, p_jumlah_tamu_anak,
            v_total_harga, 
            CASE 
                WHEN COALESCE(p_jumlah_dp, 0) >= v_total_harga * 0.5 THEN 'terkonfirmasi'
                ELSE 'menunggu'
            END,
            p_metode_pembayaran, p_catatan_khusus, p_id_staff
        ) RETURNING id_pemesanan, kode_booking 
        INTO v_id_pemesanan, v_kode_booking;
        
        -- Buat detail pemesanan untuk setiap kamar
        FOREACH v_id_kamar IN ARRAY p_id_kamar LOOP
            SELECT hitung_harga_kamar(v_id_kamar, p_check_in) INTO v_harga_kamar;
            
            INSERT INTO detail_pemesanan_kamar (
                id_pemesanan, id_kamar, harga_per_malam, sub_total
            ) VALUES (
                v_id_pemesanan, v_id_kamar, v_harga_kamar,
                v_harga_kamar * v_masa_inap
            );
        END LOOP;
        
        -- Jika ada DP, proses pembayaran
        IF COALESCE(p_jumlah_dp, 0) > 0 THEN
            INSERT INTO pembayaran (
                id_pemesanan, jumlah_bayar, metode_bayar,
                status_bayar, created_by
            ) VALUES (
                v_id_pemesanan, p_jumlah_dp, p_metode_pembayaran,
                'sukses', p_id_staff
            );
            
            -- Update status pembayaran di pemesanan
            UPDATE pemesanan 
            SET 
                deposit = COALESCE(p_jumlah_dp, 0),
                total_dibayar = COALESCE(p_jumlah_dp, 0),
                status_pembayaran = CASE 
                    WHEN COALESCE(p_jumlah_dp, 0) >= v_total_harga THEN 'lunas'
                    ELSE 'dp'
                END
            WHERE id_pemesanan = v_id_pemesanan;
        END IF;
        
        -- Log history
        INSERT INTO history_status (
            id_pemesanan, status_lama, status_baru,
            diubah_oleh, alasan_perubahan
        ) VALUES (
            v_id_pemesanan, NULL, 
            CASE 
                WHEN COALESCE(p_jumlah_dp, 0) >= v_total_harga * 0.5 THEN 'terkonfirmasi'
                ELSE 'menunggu'
            END,
            p_id_staff, 'Pemesanan baru dibuat'
        );
        
        -- Return success
        kode_booking := v_kode_booking;
        id_pemesanan := v_id_pemesanan;
        total_harga := v_total_harga;
        pesan := format('Pemesanan berhasil dibuat. Kode: %s, Total: Rp %s', 
                       v_kode_booking, v_total_harga);
        RETURN NEXT;
        
    EXCEPTION WHEN OTHERS THEN
        -- Jika terjadi error, rollback otomatis oleh PostgreSQL
        kode_booking := NULL;
        id_pemesanan := NULL;
        total_harga := NULL;
        pesan := 'Error: ' || SQLERRM;
        RETURN NEXT;
    END;
    
    RETURN;
END;
$$;

-- 2. FUNCTION: Check-in tamu (FIXED VERSION)
CREATE OR REPLACE FUNCTION fn_proses_checkin(
    p_id_pemesanan BIGINT,
    p_id_staff INTEGER,
    p_waktu_check_in TIMESTAMP DEFAULT NULL,
    p_catatan TEXT DEFAULT NULL
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_pemesanan RECORD;
    v_detail RECORD;
    v_id_registrasi INTEGER;
BEGIN
    -- Set default waktu check-in
    IF p_waktu_check_in IS NULL THEN
        p_waktu_check_in := CURRENT_TIMESTAMP;
    END IF;
    
    -- Ambil data pemesanan
    SELECT * INTO v_pemesanan
    FROM pemesanan 
    WHERE id_pemesanan = p_id_pemesanan;
    
    IF NOT FOUND THEN
        success := false;
        message := 'Pemesanan tidak ditemukan';
        RETURN NEXT;
        RETURN;
    END IF;
    
    IF v_pemesanan.status_pemesanan != 'terkonfirmasi' THEN
        success := false;
        message := 'Pemesanan belum terkonfirmasi';
        RETURN NEXT;
        RETURN;
    END IF;
    
    IF v_pemesanan.check_in != CURRENT_DATE THEN
        success := false;
        message := format('Check-in hanya bisa dilakukan pada tanggal %s', 
                         v_pemesanan.check_in);
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Mulai transaction
    BEGIN
        -- Proses check-in untuk setiap kamar
        FOR v_detail IN 
            SELECT dpk.id_kamar 
            FROM detail_pemesanan_kamar dpk
            WHERE dpk.id_pemesanan = p_id_pemesanan
        LOOP
            INSERT INTO registrasi_tamu (
                id_pemesanan, id_kamar, 
                waktu_check_in_aktual, staff_check_in,
                catatan_check_in
            ) VALUES (
                p_id_pemesanan, v_detail.id_kamar,
                p_waktu_check_in, p_id_staff,
                p_catatan
            ) RETURNING id_registrasi INTO v_id_registrasi;
            
            -- Update status kamar
            UPDATE kamar 
            SET status_kamar = 'dipakai',
                updated_at = CURRENT_TIMESTAMP
            WHERE id_kamar = v_detail.id_kamar;
        END LOOP;
        
        -- Update status pemesanan
        UPDATE pemesanan 
        SET 
            status_pemesanan = 'check_in',
            updated_at = CURRENT_TIMESTAMP,
            updated_by = p_id_staff
        WHERE id_pemesanan = p_id_pemesanan;
        
        -- Log history
        INSERT INTO history_status (
            id_pemesanan, status_lama, status_baru,
            diubah_oleh, alasan_perubahan
        ) VALUES (
            p_id_pemesanan, 'terkonfirmasi', 'check_in',
            p_id_staff, 'Tamu check-in'
        );
        
        success := true;
        message := format('Check-in berhasil. %s kamar telah di-check-in',
                         (SELECT COUNT(*) FROM detail_pemesanan_kamar 
                          WHERE id_pemesanan = p_id_pemesanan));
        RETURN NEXT;
        
    EXCEPTION WHEN OTHERS THEN
        success := false;
        message := 'Error: ' || SQLERRM;
        RETURN NEXT;
    END;
    
    RETURN;
END;
$$;

-- 3. FUNCTION: Check-out tamu (FIXED VERSION)
CREATE OR REPLACE FUNCTION fn_proses_checkout(
    p_id_pemesanan BIGINT,
    p_id_staff INTEGER,
    p_waktu_check_out TIMESTAMP DEFAULT NULL,
    p_kondisi_kamar VARCHAR DEFAULT 'baik',
    p_catatan TEXT DEFAULT NULL,
    p_biaya_tambahan JSONB DEFAULT '[]'
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    total_biaya NUMERIC,
    sisa_deposit NUMERIC
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_pemesanan RECORD;
    v_detail RECORD;
    v_total_tambahan NUMERIC(10,2) := 0;
    v_item JSONB;
    v_deposit_digunakan NUMERIC(10,2) := 0;
BEGIN
    -- Set default waktu check-out
    IF p_waktu_check_out IS NULL THEN
        p_waktu_check_out := CURRENT_TIMESTAMP;
    END IF;
    
    -- Ambil data pemesanan
    SELECT * INTO v_pemesanan
    FROM pemesanan 
    WHERE id_pemesanan = p_id_pemesanan;
    
    IF NOT FOUND THEN
        success := false;
        message := 'Pemesanan tidak ditemukan';
        total_biaya := NULL;
        sisa_deposit := NULL;
        RETURN NEXT;
        RETURN;
    END IF;
    
    IF v_pemesanan.status_pemesanan != 'check_in' THEN
        success := false;
        message := 'Tamu belum check-in';
        total_biaya := NULL;
        sisa_deposit := NULL;
        RETURN NEXT;
        RETURN;
    END IF;
    
    IF v_pemesanan.check_out != CURRENT_DATE THEN
        success := false;
        message := 'Check-out hanya bisa dilakukan pada tanggal check-out';
        total_biaya := NULL;
        sisa_deposit := NULL;
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Mulai transaction
    BEGIN
        -- Hitung biaya tambahan
        IF p_biaya_tambahan IS NOT NULL AND p_biaya_tambahan != '[]'::jsonb THEN
            FOR v_item IN SELECT * FROM jsonb_array_elements(p_biaya_tambahan)
            LOOP
                v_total_tambahan := v_total_tambahan + 
                                   COALESCE((v_item->>'jumlah')::INTEGER, 0) * 
                                   COALESCE((v_item->>'harga')::NUMERIC, 0);
            END LOOP;
        END IF;
        
        -- Hitung deposit yang digunakan
        v_deposit_digunakan := LEAST(COALESCE(v_pemesanan.deposit, 0), v_total_tambahan);
        
        -- Update registrasi untuk setiap kamar
        FOR v_detail IN 
            SELECT dpk.id_kamar 
            FROM detail_pemesanan_kamar dpk
            WHERE dpk.id_pemesanan = p_id_pemesanan
        LOOP
            UPDATE registrasi_tamu 
            SET 
                waktu_check_out_aktual = p_waktu_check_out,
                staff_check_out = p_id_staff,
                kondisi_kamar = p_kondisi_kamar,
                biaya_tambahan = p_biaya_tambahan,
                total_biaya_tambahan = v_total_tambahan,
                deposit_digunakan = v_deposit_digunakan,
                catatan_check_out = p_catatan
            WHERE id_pemesanan = p_id_pemesanan 
            AND id_kamar = v_detail.id_kamar;
            
            -- Update status kamar
            UPDATE kamar 
            SET 
                status_kamar = 'tersedia',
                status_kebersihan = CASE 
                    WHEN p_kondisi_kamar = 'baik' THEN 'kotor'
                    ELSE 'perlu_perbaikan'
                END,
                updated_at = CURRENT_TIMESTAMP
            WHERE id_kamar = v_detail.id_kamar;
        END LOOP;
        
        -- Update status pemesanan dan pembayaran
        UPDATE pemesanan 
        SET 
            status_pemesanan = 'check_out',
            updated_at = CURRENT_TIMESTAMP,
            updated_by = p_id_staff
        WHERE id_pemesanan = p_id_pemesanan;
        
        -- Jika ada biaya tambahan, buat pembayaran
        IF v_total_tambahan > 0 THEN
            INSERT INTO pembayaran (
                id_pemesanan, jumlah_bayar, metode_bayar,
                status_bayar, created_by, keterangan
            ) VALUES (
                p_id_pemesanan, v_total_tambahan, 'tunai',
                'sukses', p_id_staff, 'Biaya tambahan saat check-out'
            );
            
            -- Update total dibayar
            UPDATE pemesanan 
            SET total_dibayar = COALESCE(total_dibayar, 0) + v_total_tambahan
            WHERE id_pemesanan = p_id_pemesanan;
        END IF;
        
        -- Log history
        INSERT INTO history_status (
            id_pemesanan, status_lama, status_baru,
            diubah_oleh, alasan_perubahan
        ) VALUES (
            p_id_pemesanan, 'check_in', 'check_out',
            p_id_staff, 'Tamu check-out'
        );
        
        -- Set output values
        success := true;
        total_biaya := v_total_tambahan;
        sisa_deposit := COALESCE(v_pemesanan.deposit, 0) - v_deposit_digunakan;
        message := format('Check-out berhasil. Biaya tambahan: Rp %s, Deposit dikembalikan: Rp %s',
                         v_total_tambahan, sisa_deposit);
        RETURN NEXT;
        
    EXCEPTION WHEN OTHERS THEN
        success := false;
        message := 'Error: ' || SQLERRM;
        total_biaya := NULL;
        sisa_deposit := NULL;
        RETURN NEXT;
    END;
    
    RETURN;
END;
$$;

-- 4. FUNCTION: Update harga massal (FIXED VERSION)
CREATE OR REPLACE FUNCTION fn_update_harga_massal(
    p_tipe_kamar tipe_kamar,
    p_tanggal_mulai DATE,
    p_tanggal_selesai DATE,
    p_persen_naikan NUMERIC,
    p_id_staff INTEGER
)
RETURNS TABLE (
    jumlah_terupdate INTEGER,
    message TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_kamar RECORD;
    v_counter INTEGER := 0;
BEGIN
    -- Validasi input
    IF p_persen_naikan NOT BETWEEN -50 AND 100 THEN
        jumlah_terupdate := 0;
        message := 'Persentase kenaikan harus antara -50% sampai 100%';
        RETURN NEXT;
        RETURN;
    END IF;
    
    IF p_tanggal_mulai > p_tanggal_selesai THEN
        jumlah_terupdate := 0;
        message := 'Tanggal mulai harus sebelum tanggal selesai';
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Mulai transaction
    BEGIN
        -- Update tarif existing
        UPDATE tarif_kamar 
        SET 
            harga_dasar = harga_dasar * (1 + p_persen_naikan/100),
            harga_akhir_minggu = COALESCE(harga_akhir_minggu, harga_dasar * 1.2) * (1 + p_persen_naikan/100),
            harga_libur_nasional = COALESCE(harga_libur_nasional, harga_dasar * 1.3) * (1 + p_persen_naikan/100),
            updated_at = CURRENT_TIMESTAMP
        WHERE id_kamar IN (
            SELECT id_kamar FROM kamar WHERE tipe_kamar = p_tipe_kamar
        )
        AND daterange(tanggal_mulai, tanggal_selesai, '[]') && 
            daterange(p_tanggal_mulai, p_tanggal_selesai, '[]');
        
        GET DIAGNOSTICS v_counter = ROW_COUNT;
        
        -- Buat tarif baru untuk kamar yang belum punya tarif di periode tersebut
        FOR v_kamar IN 
            SELECT k.id_kamar, k.harga_standar
            FROM kamar k
            WHERE k.tipe_kamar = p_tipe_kamar
            AND NOT EXISTS (
                SELECT 1 FROM tarif_kamar tk
                WHERE tk.id_kamar = k.id_kamar
                AND daterange(tk.tanggal_mulai, tk.tanggal_selesai, '[]') && 
                    daterange(p_tanggal_mulai, p_tanggal_selesai, '[]')
            )
        LOOP
            INSERT INTO tarif_kamar (
                id_kamar, tanggal_mulai, tanggal_selesai,
                harga_dasar, harga_akhir_minggu, harga_libur_nasional
            ) VALUES (
                v_kamar.id_kamar, p_tanggal_mulai, p_tanggal_selesai,
                v_kamar.harga_standar * (1 + p_persen_naikan/100),
                v_kamar.harga_standar * 1.2 * (1 + p_persen_naikan/100),
                v_kamar.harga_standar * 1.3 * (1 + p_persen_naikan/100)
            );
            
            v_counter := v_counter + 1;
        END LOOP;
        
        jumlah_terupdate := v_counter;
        message := format('Berhasil update %s tarif kamar tipe %s', 
                         v_counter, p_tipe_kamar);
        RETURN NEXT;
        
    EXCEPTION WHEN OTHERS THEN
        jumlah_terupdate := 0;
        message := 'Error: ' || SQLERRM;
        RETURN NEXT;
    END;
    
    RETURN;
END;
$$;

-- 5. FUNCTION: Generate monthly report (FIXED VERSION)
CREATE OR REPLACE FUNCTION fn_generate_laporan_bulanan(
    p_bulan DATE,
    p_id_staff INTEGER
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_tanggal_mulai DATE;
    v_tanggal_selesai DATE;
    v_total_pendapatan NUMERIC;
    v_occupancy_rate NUMERIC;
    v_days_in_month INTEGER;
BEGIN
    -- Hitung periode bulan
    v_tanggal_mulai := DATE_TRUNC('month', p_bulan)::DATE;
    v_tanggal_selesai := (DATE_TRUNC('month', p_bulan) + INTERVAL '1 month' - INTERVAL '1 day')::DATE;
    v_days_in_month := EXTRACT(DAY FROM v_tanggal_selesai - v_tanggal_mulai) + 1;
    
    -- Mulai transaction
    BEGIN
        -- Delete existing report for the month
        DELETE FROM laporan_harian 
        WHERE tanggal BETWEEN v_tanggal_mulai AND v_tanggal_selesai;
        
        -- Generate daily reports for the month
        FOR i IN 0..(v_days_in_month - 1) LOOP
            INSERT INTO laporan_harian (
                tanggal,
                total_kamar,
                kamar_terisi,
                tamu_check_in,
                tamu_check_out,
                tamu_in_house,
                pendapatan_kamar,
                pendapatan_fnb,
                pendapatan_lainnya,
                generated_by
            )
            SELECT 
                v_tanggal_mulai + i,
                COUNT(DISTINCT k.id_kamar) AS total_kamar,
                COUNT(DISTINCT dpk.id_kamar) AS kamar_terisi,
                COUNT(DISTINCT CASE 
                    WHEN DATE(rt.waktu_check_in_aktual) = v_tanggal_mulai + i 
                    THEN rt.id_registrasi 
                END) AS check_in,
                COUNT(DISTINCT CASE 
                    WHEN DATE(rt.waktu_check_out_aktual) = v_tanggal_mulai + i 
                    THEN rt.id_registrasi 
                END) AS check_out,
                COUNT(DISTINCT CASE 
                    WHEN DATE(rt.waktu_check_in_aktual) <= v_tanggal_mulai + i 
                    AND (rt.waktu_check_out_aktual IS NULL OR DATE(rt.waktu_check_out_aktual) > v_tanggal_mulai + i)
                    THEN rt.id_registrasi 
                END) AS in_house,
                COALESCE(SUM(p.total_harga), 0) AS revenue_kamar,
                COALESCE(SUM(rt.total_biaya_tambahan), 0) AS revenue_tambahan,
                0 AS revenue_lainnya,
                p_id_staff
            FROM kamar k
            LEFT JOIN detail_pemesanan_kamar dpk ON k.id_kamar = dpk.id_kamar
            LEFT JOIN pemesanan p ON dpk.id_pemesanan = p.id_pemesanan
            LEFT JOIN registrasi_tamu rt ON p.id_pemesanan = rt.id_pemesanan
            WHERE k.status_kamar != 'tidak_aktif'
            AND (
                (v_tanggal_mulai + i) BETWEEN p.check_in AND p.check_out - INTERVAL '1 day'
                OR p.id_pemesanan IS NULL
            )
            AND p.status_pemesanan NOT IN ('dibatalkan', 'no_show')
            GROUP BY v_tanggal_mulai + i;
        END LOOP;
        
        -- Calculate monthly totals
        SELECT 
            COALESCE(SUM(total_pendapatan), 0),
            COALESCE(AVG(occupancy_rate), 0)
        INTO 
            v_total_pendapatan,
            v_occupancy_rate
        FROM laporan_harian 
        WHERE tanggal BETWEEN v_tanggal_mulai AND v_tanggal_selesai;
        
        success := true;
        message := format('Laporan bulan %s berhasil digenerate. Total pendapatan: Rp %s, Avg Occupancy: %s%%',
                         TO_CHAR(p_bulan, 'YYYY-MM'),
                         v_total_pendapatan,
                         ROUND(v_occupancy_rate, 2));
        RETURN NEXT;
        
    EXCEPTION WHEN OTHERS THEN
        success := false;
        message := 'Error: ' || SQLERRM;
        RETURN NEXT;
    END;
    
    RETURN;
END;
$$;

-- 6. FUNCTION: Proses pembayaran (FIXED VERSION)
CREATE OR REPLACE FUNCTION fn_proses_pembayaran(
    p_id_pemesanan BIGINT,
    p_jumlah_bayar NUMERIC,
    p_metode_bayar tipe_pembayaran,
    p_id_staff INTEGER,
    p_no_referensi VARCHAR DEFAULT NULL,
    p_keterangan TEXT DEFAULT NULL
)
RETURNS TABLE (
    id_pembayaran INTEGER,
    status_bayar VARCHAR,
    total_dibayar NUMERIC,
    sisa_pembayaran NUMERIC,
    message TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_harga NUMERIC;
    v_total_dibayar NUMERIC;
    v_status VARCHAR;
    v_id_pembayaran INTEGER;
BEGIN
    -- Validasi input
    IF p_jumlah_bayar <= 0 THEN
        id_pembayaran := NULL;
        status_bayar := NULL;
        total_dibayar := NULL;
        sisa_pembayaran := NULL;
        message := 'Jumlah pembayaran harus lebih dari 0';
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Mulai transaction
    BEGIN
        -- Ambil data pemesanan
        SELECT total_harga, total_dibayar, status_pembayaran
        INTO v_total_harga, v_total_dibayar, v_status
        FROM pemesanan 
        WHERE id_pemesanan = p_id_pemesanan;
        
        -- Validasi
        IF v_total_harga IS NULL THEN
            id_pembayaran := NULL;
            status_bayar := NULL;
            total_dibayar := NULL;
            sisa_pembayaran := NULL;
            message := 'Pemesanan tidak ditemukan';
            RETURN NEXT;
            RETURN;
        END IF;
        
        IF v_status = 'lunas' THEN
            id_pembayaran := NULL;
            status_bayar := NULL;
            total_dibayar := NULL;
            sisa_pembayaran := NULL;
            message := 'Pemesanan sudah lunas';
            RETURN NEXT;
            RETURN;
        END IF;
        
        -- Insert pembayaran
        INSERT INTO pembayaran (
            id_pemesanan, jumlah_bayar, metode_bayar,
            nomor_referensi, created_by, status_bayar, keterangan
        ) VALUES (
            p_id_pemesanan, p_jumlah_bayar, p_metode_bayar,
            p_no_referensi, p_id_staff, 'sukses', p_keterangan
        ) RETURNING id_pembayaran INTO v_id_pembayaran;
        
        -- Hitung status baru
        v_total_dibayar := COALESCE(v_total_dibayar, 0) + p_jumlah_bayar;
        v_status := CASE 
            WHEN v_total_dibayar >= v_total_harga THEN 'lunas'
            WHEN v_total_dibayar >= v_total_harga * 0.5 THEN 'dp'
            ELSE 'belum_lunas'
        END;
        
        -- Update pemesanan
        UPDATE pemesanan 
        SET 
            total_dibayar = v_total_dibayar,
            status_pembayaran = v_status,
            updated_at = CURRENT_TIMESTAMP,
            updated_by = p_id_staff
        WHERE id_pemesanan = p_id_pemesanan;
        
        -- Return results
        id_pembayaran := v_id_pembayaran;
        status_bayar := v_status;
        total_dibayar := v_total_dibayar;
        sisa_pembayaran := GREATEST(v_total_harga - v_total_dibayar, 0);
        message := 'Pembayaran berhasil diproses';
        RETURN NEXT;
        
    EXCEPTION WHEN OTHERS THEN
        id_pembayaran := NULL;
        status_bayar := NULL;
        total_dibayar := NULL;
        sisa_pembayaran := NULL;
        message := 'Error: ' || SQLERRM;
        RETURN NEXT;
    END;
    
    RETURN;
END;
$$;

-- 7. FUNCTION: Batalkan pemesanan (FIXED VERSION)
CREATE OR REPLACE FUNCTION fn_batalkan_pemesanan(
    p_id_pemesanan BIGINT,
    p_id_staff INTEGER,
    p_alasan TEXT DEFAULT NULL
)
RETURNS TABLE (
    success BOOLEAN,
    refund_amount NUMERIC,
    message TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_pemesanan RECORD;
    v_refund_amount NUMERIC := 0;
    v_days_before_checkin INTEGER;
BEGIN
    -- Ambil data pemesanan
    SELECT * INTO v_pemesanan
    FROM pemesanan 
    WHERE id_pemesanan = p_id_pemesanan;
    
    IF NOT FOUND THEN
        success := false;
        refund_amount := 0;
        message := 'Pemesanan tidak ditemukan';
        RETURN NEXT;
        RETURN;
    END IF;
    
    IF v_pemesanan.status_pemesanan IN ('dibatalkan', 'check_out') THEN
        success := false;
        refund_amount := 0;
        message := 'Pemesanan sudah dibatalkan atau selesai';
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Mulai transaction
    BEGIN
        -- Calculate days before check-in
        v_days_before_checkin := EXTRACT(DAY FROM 
            (v_pemesanan.check_in - CURRENT_DATE)
        );
        
        -- Calculate refund based on policy
        v_refund_amount := CASE
            WHEN v_days_before_checkin > 30 THEN COALESCE(v_pemesanan.total_dibayar, 0)  -- Full refund
            WHEN v_days_before_checkin > 7 THEN COALESCE(v_pemesanan.total_dibayar, 0) * 0.50  -- 50%
            WHEN v_days_before_checkin > 2 THEN COALESCE(v_pemesanan.total_dibayar, 0) * 0.25  -- 25%
            ELSE 0  -- No refund
        END;
        
        -- Update booking status
        UPDATE pemesanan 
        SET 
            status_pemesanan = 'dibatalkan',
            cancelled_at = CURRENT_TIMESTAMP,
            cancellation_reason = p_alasan,
            updated_at = CURRENT_TIMESTAMP
        WHERE id_pemesanan = p_id_pemesanan;
        
        -- Update kamar status
        UPDATE kamar k
        SET status_kamar = 'tersedia',
            updated_at = CURRENT_TIMESTAMP
        FROM detail_pemesanan_kamar dpk
        WHERE dpk.id_pemesanan = p_id_pemesanan
        AND dpk.id_kamar = k.id_kamar;
        
        -- Log history
        INSERT INTO history_status (
            id_pemesanan, status_lama, status_baru,
            diubah_oleh, alasan_perubahan
        ) VALUES (
            p_id_pemesanan, v_pemesanan.status_pemesanan, 'dibatalkan',
            p_id_staff, p_alasan
        );
        
        -- If refund, create payment record
        IF v_refund_amount > 0 THEN
            INSERT INTO pembayaran (
                id_pemesanan, jumlah_bayar, metode_bayar,
                status_bayar, created_by, keterangan
            ) VALUES (
                p_id_pemesanan, -v_refund_amount, 'transfer',
                'dikembalikan', p_id_staff, 'Refund pembatalan pemesanan'
            );
        END IF;
        
        success := true;
        refund_amount := v_refund_amount;
        message := format('Pemesanan dibatalkan. Jumlah refund: Rp %s', v_refund_amount);
        RETURN NEXT;
        
    EXCEPTION WHEN OTHERS THEN
        success := false;
        refund_amount := 0;
        message := 'Error: ' || SQLERRM;
        RETURN NEXT;
    END;
    
    RETURN;
END;
$$;

-- 8. FUNCTION: Quick check-in (FIXED VERSION)
CREATE OR REPLACE FUNCTION fn_quick_checkin(
    p_kode_booking VARCHAR,
    p_id_staff INTEGER
)
RETURNS TABLE (
    success BOOLEAN,
    nama_tamu TEXT,
    nomor_kamar TEXT,
    message TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_pemesanan RECORD;
    v_kamar_list TEXT[];
BEGIN
    -- Cari pemesanan berdasarkan kode booking
    SELECT p.* INTO v_pemesanan
    FROM pemesanan p
    WHERE p.kode_booking = p_kode_booking;
    
    IF NOT FOUND THEN
        success := false;
        nama_tamu := NULL;
        nomor_kamar := NULL;
        message := 'Kode booking tidak ditemukan';
        RETURN NEXT;
        RETURN;
    END IF;
    
    IF v_pemesanan.status_pemesanan != 'terkonfirmasi' THEN
        success := false;
        nama_tamu := NULL;
        nomor_kamar := NULL;
        message := 'Pemesanan belum terkonfirmasi';
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Mulai transaction
    BEGIN
        -- Get kamar list
        SELECT ARRAY_AGG(k.nomor_kamar) INTO v_kamar_list
        FROM detail_pemesanan_kamar dpk
        JOIN kamar k ON dpk.id_kamar = k.id_kamar
        WHERE dpk.id_pemesanan = v_pemesanan.id_pemesanan;
        
        -- Update status pemesanan
        UPDATE pemesanan 
        SET status_pemesanan = 'check_in',
            updated_at = CURRENT_TIMESTAMP,
            updated_by = p_id_staff
        WHERE id_pemesanan = v_pemesanan.id_pemesanan;
        
        -- Update kamar
        UPDATE kamar k
        SET status_kamar = 'dipakai',
            updated_at = CURRENT_TIMESTAMP
        FROM detail_pemesanan_kamar dpk
        WHERE dpk.id_pemesanan = v_pemesanan.id_pemesanan
        AND dpk.id_kamar = k.id_kamar;
        
        -- Create registrasi
        INSERT INTO registrasi_tamu (id_pemesanan, id_kamar, waktu_check_in_aktual, staff_check_in)
        SELECT v_pemesanan.id_pemesanan, dpk.id_kamar, CURRENT_TIMESTAMP, p_id_staff
        FROM detail_pemesanan_kamar dpk
        WHERE dpk.id_pemesanan = v_pemesanan.id_pemesanan;
        
        success := true;
        nama_tamu := (SELECT nama_lengkap FROM tamu WHERE id_tamu = v_pemesanan.id_tamu);
        nomor_kamar := ARRAY_TO_STRING(COALESCE(v_kamar_list, ARRAY[]::TEXT[]), ', ');
        message := 'Check-in berhasil';
        RETURN NEXT;
        
    EXCEPTION WHEN OTHERS THEN
        success := false;
        nama_tamu := NULL;
        nomor_kamar := NULL;
        message := 'Error: ' || SQLERRM;
        RETURN NEXT;
    END;
    
    RETURN;
END;
$$;

-- 9. FUNCTION: Cek ketersediaan kamar cepat (simplified)
CREATE OR REPLACE FUNCTION fn_cek_ketersediaan_cepat(
    p_check_in DATE,
    p_check_out DATE,
    p_tipe_kamar tipe_kamar DEFAULT NULL
)
RETURNS TABLE (
    id_kamar INTEGER,
    nomor_kamar VARCHAR,
    tipe_kamar tipe_kamar,
    kapasitas INTEGER,
    harga_standar NUMERIC,
    tersedia BOOLEAN,
    pesan TEXT
) 
LANGUAGE plpgsql
AS $$
BEGIN
    FOR id_kamar, nomor_kamar, tipe_kamar, kapasitas, harga_standar IN
        SELECT k.id_kamar, k.nomor_kamar, k.tipe_kamar, k.kapasitas, k.harga_standar
        FROM kamar k
        WHERE k.status_kamar IN ('tersedia', 'dipesan')
        AND (p_tipe_kamar IS NULL OR k.tipe_kamar = p_tipe_kamar)
    LOOP
        -- Cek ketersediaan
        tersedia := NOT EXISTS (
            SELECT 1 
            FROM detail_pemesanan_kamar dpk
            JOIN pemesanan p ON dpk.id_pemesanan = p.id_pemesanan
            WHERE dpk.id_kamar = id_kamar
            AND p_check_in < p.check_out
            AND p_check_out > p.check_in
            AND p.status_pemesanan NOT IN ('dibatalkan', 'no_show')
        );
        
        pesan := CASE 
            WHEN tersedia THEN 'Tersedia'
            ELSE 'Sudah dipesan'
        END;
        
        RETURN NEXT;
    END LOOP;
    
    RETURN;
END;
$$;

DO $$
BEGIN
    RAISE NOTICE 'Functions parameters berhasil dibuat';
    RAISE NOTICE 'Total functions: 9 functions utama';
END $$;