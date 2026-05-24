-- Orders tablosuna fatura_kodu alanını ekle (eğer yoksa)
ALTER TABLE orders ADD COLUMN IF NOT EXISTS fatura_kodu VARCHAR(20) UNIQUE;

-- fatura_kodu alanını NOT NULL yap
ALTER TABLE orders ALTER COLUMN fatura_kodu SET NOT NULL;

-- Fatura kodu oluşturma fonksiyonunu ekle
CREATE OR REPLACE FUNCTION generate_fatura_kodu(p_table_id INTEGER)
RETURNS VARCHAR(20) AS $$
DECLARE
    table_name VARCHAR(50);
    current_date_str VARCHAR(8);
    sequence_number INTEGER;
    fatura_kodu VARCHAR(20);
BEGIN
    -- Masa adını al
    SELECT name INTO table_name FROM tables WHERE id = p_table_id;
    
    -- Bugünün tarihini al (YYYYMMDD formatında)
    current_date_str := TO_CHAR(CURRENT_DATE, 'YYYYMMDD');
    
    -- Bugün bu masa için kaç sipariş var
    SELECT COALESCE(COUNT(*), 0) + 1 INTO sequence_number
    FROM orders 
    WHERE table_id = p_table_id 
    AND DATE(created_at) = CURRENT_DATE;
    
    -- Fatura kodunu oluştur: TABLO_ADI + TARIH + SIRA_NO
    fatura_kodu := table_name || current_date_str || LPAD(sequence_number::TEXT, 3, '0');
    
    RETURN fatura_kodu;
END;
$$ LANGUAGE plpgsql;

-- Fatura kodu otomatik oluşturma trigger fonksiyonu
CREATE OR REPLACE FUNCTION set_fatura_kodu()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.fatura_kodu IS NULL THEN
        NEW.fatura_kodu := generate_fatura_kodu(NEW.table_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ı oluştur
DROP TRIGGER IF EXISTS set_orders_fatura_kodu ON orders;
CREATE TRIGGER set_orders_fatura_kodu BEFORE INSERT ON orders
    FOR EACH ROW EXECUTE FUNCTION set_fatura_kodu(); 