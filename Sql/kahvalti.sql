-- EXFIN REST - Kahvaltı Kategorisi
-- Bu script kahvaltı kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 5);
DELETE FROM products WHERE category_id = 5;

-- =====================================================
-- KAHVALTI KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(5, 'Kahvaltı', 'Breakfast', 'فطور', 'Taştê', 'تاشتێ', 'Kahvaltı menüsü', 'Breakfast menu', 'قائمة الفطور', 'Menûya taştê', 'مێنووی تاشتێ', 'breakfast_dining', '#FF9800', 5, true)
ON CONFLICT (id) DO UPDATE SET
name = EXCLUDED.name,
name_en = EXCLUDED.name_en,
name_ar = EXCLUDED.name_ar,
name_ku = EXCLUDED.name_ku,
name_sr = EXCLUDED.name_sr,
description = EXCLUDED.description,
description_en = EXCLUDED.description_en,
description_ar = EXCLUDED.description_ar,
description_ku = EXCLUDED.description_ku,
description_sr = EXCLUDED.description_sr,
icon = EXCLUDED.icon,
color = EXCLUDED.color,
sort_order = EXCLUDED.sort_order,
is_featured = EXCLUDED.is_featured;

-- =====================================================
-- KAHVALTI ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Turkish Breakfast', 'Turkish Breakfast', 'فطور تركي', 'Taştê Tirk', 'تاشتێ تورک', 'Türk kahvaltısı', 'Turkish breakfast', 'فطور تركي', 'Taştê tirk', 'تاشتێ تورک', 45.00, 5, 0, false, false, false, false, 480, 'Turkey', true),
('English Breakfast', 'English Breakfast', 'فطور إنجليزي', 'Taştê Îngilîz', 'تاشتێ ئینگلیز', 'İngiliz kahvaltısı', 'English breakfast', 'فطور إنجليزي', 'Taştê îngilîz', 'تاشتێ ئینگلیز', 38.00, 5, 0, false, false, false, true, 520, 'UK', true),
('American Breakfast', 'American Breakfast', 'فطور أمريكي', 'Taştê Amerîkî', 'تاشتێ ئەمریکی', 'Amerikan kahvaltısı', 'American breakfast', 'فطور أمريكي', 'Taştê amerîkî', 'تاشتێ ئەمریکی', 42.00, 5, 0, false, false, false, true, 450, 'USA', true),
('Omelette', 'Omelette', 'عجة', 'Omlet', 'ئۆمڵەت', 'Omlet', 'Omelette', 'عجة', 'Omlet', 'ئۆمڵەت', 28.00, 5, 0, false, false, true, true, 320, 'France', true),
('Pancakes', 'Pancakes', 'فطائر', 'Pankek', 'پەنکەک', 'Krepler', 'Pancakes', 'فطائر', 'Pankek', 'پەنکەک', 24.00, 5, 0, true, false, false, false, 280, 'USA', true),
('French Toast', 'French Toast', 'توست فرنسي', 'Tost Fransî', 'تۆست فرەنسی', 'Fransız tostu', 'French toast', 'توست فرنسي', 'Tost fransî', 'تۆست فرەنسی', 26.00, 5, 0, true, false, false, true, 300, 'France', true),
('Granola Bowl', 'Granola Bowl', 'وعاء جرانولا', 'Bowl Granola', 'بۆڵ گرەنۆلا', 'Granola kasesi', 'Granola bowl', 'وعاء جرانولا', 'Bowl granola', 'بۆڵ گرەنۆلا', 22.00, 5, 0, true, true, true, false, 240, 'USA', true),
('Yogurt with Honey', 'Yogurt with Honey', 'زبادي مع عسل', 'Mast û Hingiv', 'مەست و ھەنگوین', 'Ballı yoğurt', 'Yogurt with honey', 'زبادي مع عسل', 'Mast û hingiv', 'مەست و ھەنگوین', 18.00, 5, 0, true, true, true, false, 180, 'Turkey', true); 