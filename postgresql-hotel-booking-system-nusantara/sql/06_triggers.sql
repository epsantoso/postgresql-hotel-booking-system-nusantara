-- ============================================
-- TRIGGERS (CLEAN & LEGAL POSTGRESQL)
-- ============================================

-- 1. Generate kode booking
CREATE TRIGGER trg_generate_kode_booking
BEFORE INSERT ON pemesanan
FOR EACH ROW
EXECUTE FUNCTION fn_generate_kode_booking();

-- 2. Update status kamar otomatis
CREATE TRIGGER trg_update_status_kamar
AFTER INSERT OR UPDATE OF status_pemesanan ON pemesanan
FOR EACH ROW
EXECUTE FUNCTION update_status_kamar_otomatis();

-- 3. Update total harga jika detail berubah
CREATE TRIGGER trg_update_total_pemesanan
AFTER INSERT OR UPDATE OR DELETE ON detail_pemesanan_kamar
FOR EACH ROW
EXECUTE FUNCTION fn_update_total_pemesanan();

-- 4. Update poin loyalty setelah check-out
CREATE TRIGGER trg_update_poin_loyalty
AFTER UPDATE OF status_pemesanan ON pemesanan
FOR EACH ROW
WHEN (
    NEW.status_pemesanan = 'check_out'
    AND OLD.status_pemesanan <> 'check_out'
)
EXECUTE FUNCTION fn_update_poin_loyalty();

-- 5. Auto-update updated_at
CREATE TRIGGER trg_update_kamar_updated_at
BEFORE UPDATE ON kamar
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_update_tamu_updated_at
BEFORE UPDATE ON tamu
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_update_pemesanan_updated_at
BEFORE UPDATE ON pemesanan
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 6. Log history perubahan status
CREATE OR REPLACE FUNCTION fn_log_history_status()
RETURNS trigger AS $$
BEGIN
    IF NEW.status_pemesanan IS DISTINCT FROM OLD.status_pemesanan THEN
        INSERT INTO history_status (
            id_pemesanan,
            status_lama,
            status_baru,
            diubah_oleh,
            tipe_perubahan,
            alasan_perubahan
        ) VALUES (
            NEW.id_pemesanan,
            OLD.status_pemesanan,
            NEW.status_pemesanan,
            NEW.updated_by,
            'system',
            'Perubahan status pemesanan'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_history_status
AFTER UPDATE OF status_pemesanan ON pemesanan
FOR EACH ROW
EXECUTE FUNCTION fn_log_history_status();

-- 7. Validasi kapasitas kamar
CREATE OR REPLACE FUNCTION fn_validate_kamar_capacity()
RETURNS trigger AS $$
DECLARE
    kapasitas INT;
    jumlah_tamu INT;
BEGIN
    SELECT k.kapasitas INTO kapasitas
    FROM kamar k WHERE k.id_kamar = NEW.id_kamar;

    SELECT p.jumlah_tamu INTO jumlah_tamu
    FROM pemesanan p WHERE p.id_pemesanan = NEW.id_pemesanan;

    IF jumlah_tamu > kapasitas THEN
        RAISE EXCEPTION
            'Kapasitas kamar % hanya % orang (diminta %)',
            NEW.id_kamar, kapasitas, jumlah_tamu;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_kamar_capacity
BEFORE INSERT ON detail_pemesanan_kamar
FOR EACH ROW
EXECUTE FUNCTION fn_validate_kamar_capacity();

-- 8. Cegah booking tanggal lampau
CREATE OR REPLACE FUNCTION fn_prevent_past_booking()
RETURNS trigger AS $$
BEGIN
    IF NEW.check_in < CURRENT_DATE THEN
        RAISE EXCEPTION 'Tidak bisa booking tanggal lampau';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_past_booking
BEFORE INSERT OR UPDATE OF check_in ON pemesanan
FOR EACH ROW
EXECUTE FUNCTION fn_prevent_past_booking();

-- 9. Set default jam check-in / out
CREATE OR REPLACE FUNCTION fn_set_default_check_time()
RETURNS trigger AS $$
BEGIN
    NEW.waktu_check_in_rencana :=
        COALESCE(NEW.waktu_check_in_rencana, '14:00');
    NEW.waktu_check_out_rencana :=
        COALESCE(NEW.waktu_check_out_rencana, '12:00');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_default_check_time
BEFORE INSERT ON pemesanan
FOR EACH ROW
EXECUTE FUNCTION fn_set_default_check_time();

-- 10. Validasi NIK
CREATE OR REPLACE FUNCTION fn_validate_nik()
RETURNS trigger AS $$
BEGIN
    IF NEW.nik IS NOT NULL AND LENGTH(NEW.nik) <> 16 THEN
        RAISE EXCEPTION 'NIK harus 16 digit';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_nik
BEFORE INSERT OR UPDATE OF nik ON tamu
FOR EACH ROW
EXECUTE FUNCTION fn_validate_nik();

DO $$
BEGIN
    RAISE NOTICE 'Triggers berhasil dibuat';
END $$;
