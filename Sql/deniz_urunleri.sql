-- EXFIN REST - Deniz Ürünleri Kategorisi
-- Bu script deniz ürünleri kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 17);
DELETE FROM products WHERE category_id = 17;

-- =====================================================
-- DENİZ ÜRÜNLERİ KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(17, 'Deniz Ürünleri', 'Seafood', 'مأكولات بحرية', 'Xwarinên Deryayî', 'خواردنە دەریایییەکان', 'Deniz ürünleri', 'Seafood dishes', 'مأكولات بحرية', 'Xwarinên deryayî', 'خواردنە دەریایییەکان', 'set_meal', '#2196F3', 17, true)
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
-- DENİZ ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Grilled Salmon', 'Grilled Salmon', 'سلمون مشوي', 'Somon Sorkirî', 'سەمۆن سۆرکر', 'Izgara somon', 'Grilled salmon', 'سلمون مشوي', 'Somon sorkirî', 'سەمۆن سۆرکر', 45.00, 17, 0, false, false, true, true, 280, 'Norway', true),
('Shrimp Scampi', 'Shrimp Scampi', 'جمبري سكامبي', 'Krevêt Skampî', 'کرەڤێت سکەمپی', 'Karides scampi', 'Shrimp scampi', 'جمبري سكامبي', 'Krevêt skampî', 'کرەڤێت سکەمپی', 38.00, 17, 1, false, false, true, true, 220, 'Italy', true),
('Lobster Thermidor', 'Lobster Thermidor', 'استاكوزا ثيرميدور', 'Lobster Termîdor', 'لۆبستەر تەرمیدۆر', 'Istavrit termidor', 'Lobster thermidor', 'استاكوزا ثيرميدور', 'Lobster termîdor', 'لۆبستەر تەرمیدۆر', 65.00, 17, 1, false, false, false, true, 350, 'France', true),
('Tuna Steak', 'Tuna Steak', 'ستيك تونة', 'Stekê Ton', 'ستەکێ تۆن', 'Ton balığı biftek', 'Tuna steak', 'ستيك تونة', 'Stekê ton', 'ستەکێ تۆن', 42.00, 17, 0, false, false, true, true, 250, 'Japan', true),
('Calamari', 'Calamari', 'كالاماري', 'Kalamarî', 'کەڵەمەری', 'Kızarmış kalamar', 'Fried calamari', 'كالاماري', 'Kalamarî sorkirî', 'کەڵەمەری سۆرکر', 32.00, 17, 1, false, false, false, true, 200, 'Greece', true),
('Fish & Chips', 'Fish & Chips', 'سمك و بطاطس', 'Masî û Kartol', 'ماسی و کەرتۆڵ', 'Balık ve patates', 'Fish and chips', 'سمك و بطاطس', 'Masî û kartol', 'ماسی و کەرتۆڵ', 28.00, 17, 0, false, false, false, true, 380, 'UK', true),
('Seafood Paella', 'Seafood Paella', 'باييا مأكولات بحرية', 'Paella Deryayî', 'پایەڵا دەریایی', 'Deniz ürünlü paella', 'Seafood paella', 'باييا مأكولات بحرية', 'Paella deryayî', 'پایەڵای دەریایی', 48.00, 17, 1, false, false, false, true, 420, 'Spain', true),
('Crab Cakes', 'Crab Cakes', 'كيك سلطعون', 'Kekê Keftar', 'کەکێ کەفتەر', 'Yengeç köftesi', 'Crab cakes', 'كيك سلطعون', 'Kekê keftar', 'کەکێ کەفتەر', 35.00, 17, 0, false, false, false, true, 280, 'USA', true); 