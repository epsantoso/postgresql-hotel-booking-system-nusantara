-- ============================================
-- FUNCTIONS UNTUK BUSINESS LOGIC
-- ============================================

-- 1. Generate kode booking (TRIGGER)
CREATE OR REPLACE FUNCTION fn_generate_kode_booking()
RETURNS trigger AS $$
DECLARE
    counter INT;
BEGIN
    SELECT COALESCE(
        MAX(SUBSTRING(kode_booking FROM '-(\\d{5})$')::INT),
        0
    ) + 1
    INTO counter
    FROM pemesanan
    WHERE kode_booking LIKE
        'NUS-' || TO_CHAR(CURRENT_DATE,'YYYYMMDD') || '-%';

    NEW.kode_booking :=
        'NUS-' || TO_CHAR(CURRENT_DATE,'YYYYMMDD')
        || '-' || LPAD(counter::TEXT, 5, '0');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------

-- 2. Hitung total pemesanan (UTILITY FUNCTION)
CREATE OR REPLACE FUNCTION fn_hitung_total_pemesanan(p_id BIGINT)
RETURNS NUMERIC AS $$
DECLARE
    total NUMERIC := 0;
    malam INT;
BEGIN
    SELECT check_out - check_in
    INTO malam
    FROM pemesanan
    WHERE id_pemesanan = p_id;

    SELECT COALESCE(
        SUM(harga_per_malam * malam),
        0
    )
    INTO total
    FROM detail_pemesanan_kamar
    WHERE id_pemesanan = p_id;

    RETURN total;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------

-- 3. Update total pemesanan otomatis (TRIGGER)
CREATE OR REPLACE FUNCTION fn_update_total_pemesanan()
RETURNS trigger AS $$
BEGIN
    UPDATE pemesanan
    SET total_harga = fn_hitung_total_pemesanan(NEW.id_pemesanan),
        updated_at = CURRENT_TIMESTAMP
    WHERE id_pemesanan = NEW.id_pemesanan;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------

-- 4. Cek double booking kamar (TRIGGER)
CREATE OR REPLACE FUNCTION fn_cek_double_booking()
RETURNS trigger AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM detail_pemesanan_kamar d
        JOIN pemesanan p ON p.id_pemesanan = d.id_pemesanan
        WHERE d.id_kamar = NEW.id_kamar
          AND daterange(p.check_in, p.check_out, '[]')
              && daterange(
                    (SELECT check_in FROM pemesanan WHERE id_pemesanan = NEW.id_pemesanan),
                    (SELECT check_out FROM pemesanan WHERE id_pemesanan = NEW.id_pemesanan),
                    '[]'
                 )
          AND p.status_pemesanan <> 'CANCELLED'
    ) THEN
        RAISE EXCEPTION
            'Kamar % sudah dibooking pada tanggal tersebut',
            NEW.id_kamar;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------

-- 5. Update status kamar otomatis (TRIGGER)
CREATE OR REPLACE FUNCTION update_status_kamar_otomatis()
RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE kamar
        SET status_kamar = 'DIPESAN',
            updated_at = CURRENT_TIMESTAMP
        WHERE id_kamar IN (
            SELECT id_kamar
            FROM detail_pemesanan_kamar
            WHERE id_pemesanan = NEW.id_pemesanan
        );

    ELSIF TG_OP = 'UPDATE'
          AND NEW.status_pemesanan = 'CHECKED_OUT'
          AND OLD.status_pemesanan <> 'CHECKED_OUT' THEN

        UPDATE kamar
        SET status_kamar = 'TERSEDIA',
            updated_at = CURRENT_TIMESTAMP
        WHERE id_kamar IN (
            SELECT id_kamar
            FROM detail_pemesanan_kamar
            WHERE id_pemesanan = NEW.id_pemesanan
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------

-- 6. Update poin loyalty tamu (TRIGGER)
CREATE OR REPLACE FUNCTION fn_update_poin_loyalty()
RETURNS trigger AS $$
DECLARE
    poin INT;
BEGIN
    IF NEW.status_pemesanan = 'CHECKED_OUT'
       AND OLD.status_pemesanan <> 'CHECKED_OUT'
       AND NEW.status_pembayaran = 'lunas' THEN

        poin := FLOOR(NEW.total_harga / 100000);

        UPDATE tamu
        SET poin_member = poin_member + poin,
            updated_at = CURRENT_TIMESTAMP
        WHERE id_tamu = NEW.id_tamu;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------

-- 7. Update kolom updated_at otomatis (GENERIC)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    RAISE NOTICE ' Functions business logic berhasil dibuat';
END $$;
