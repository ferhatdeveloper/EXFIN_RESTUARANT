-- EXFIN REST - Burgerler Kategorisi
-- Bu script burgerler kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 21);
DELETE FROM products WHERE category_id = 21;

-- =====================================================
-- BURGERLER KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(21, 'Burgerler', 'Burgers', 'برجر', 'Burger', 'بۆرگر', 'Burger çeşitleri', 'Burger varieties', 'برجر', 'Burger', 'بۆرگر', 'fastfood', '#795548', 21, true)
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
-- BURGERLERİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Classic Burger', 'Classic Burger', 'برجر كلاسيك', 'Burger Klasîk', 'بۆرگر کڵاسیک', 'Klasik burger', 'Classic burger', 'برجر كلاسيك', 'Burger klasîk', 'بۆرگر کڵاسیک', 32.00, 21, 0, false, false, false, true, 450, 'USA', true),
('Cheeseburger', 'Cheeseburger', 'برجر جبن', 'Burger Penîr', 'بۆرگر پەنیر', 'Peynirli burger', 'Cheeseburger', 'برجر جبن', 'Burger penîr', 'بۆرگر پەنیر', 35.00, 21, 0, false, false, false, true, 480, 'USA', true),
('Bacon Burger', 'Bacon Burger', 'برجر لحم خنزير', 'Burger Bacon', 'بۆرگر بەیکۆن', 'Pastırmalı burger', 'Bacon burger', 'برجر لحم خنزير', 'Burger bacon', 'بۆرگر بەیکۆن', 38.00, 21, 0, false, false, false, true, 520, 'USA', true),
('Veggie Burger', 'Veggie Burger', 'برجر نباتي', 'Burger Nebatî', 'بۆرگر نەباتی', 'Sebze burger', 'Veggie burger', 'برجر نباتي', 'Burger nebatî', 'بۆرگر نەباتی', 28.00, 21, 0, true, true, false, true, 320, 'USA', true),
('Chicken Burger', 'Chicken Burger', 'برجر دجاج', 'Burger Mirîşk', 'بۆرگر مریشک', 'Tavuk burger', 'Chicken burger', 'برجر دجاج', 'Burger mirîşk', 'بۆرگر مریشک', 30.00, 21, 0, false, false, false, true, 380, 'USA', true),
('Mushroom Burger', 'Mushroom Burger', 'برجر فطر', 'Burger Kûvark', 'بۆرگر کوڤەرک', 'Mantarlı burger', 'Mushroom burger', 'برجر فطر', 'Burger kûvark', 'بۆرگر کوڤەرک', 34.00, 21, 0, true, false, false, true, 420, 'USA', true),
('Double Burger', 'Double Burger', 'برجر مزدوج', 'Burger Du', 'بۆرگر دوو', 'Çift katlı burger', 'Double burger', 'برجر مزدوج', 'Burger du', 'بۆرگر دوو', 42.00, 21, 0, false, false, false, true, 650, 'USA', true),
('Fish Burger', 'Fish Burger', 'برجر سمك', 'Burger Masî', 'بۆرگر ماسی', 'Balık burger', 'Fish burger', 'برجر سمك', 'Burger masî', 'بۆرگر ماسی', 36.00, 21, 0, false, false, false, true, 400, 'USA', true); 