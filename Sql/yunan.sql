-- EXFIN REST - Yunan Mutfağı Kategorisi
-- Bu script Yunan mutfağı kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 16);
DELETE FROM products WHERE category_id = 16;

-- =====================================================
-- YUNAN MUTFAĞI KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(16, 'Yunan Mutfağı', 'Greek Cuisine', 'المطبخ اليوناني', 'Pêjgeha Yewnanî', 'پێشگەی یۆنانی', 'Yunan yemekleri', 'Greek dishes', 'أطباق يونانية', 'Xwarinên Yewnanî', 'خواردنە یۆنانییەکان', 'restaurant', '#4CAF50', 16, true)
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
-- YUNAN MUTFAĞI ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Moussaka', 'Moussaka', 'موساكا', 'Musaka', 'موساکا', 'Patlıcan ve et yemeği', 'Eggplant and meat dish', 'موساكا', 'Musaka', 'موساکا', 38.00, 16, 1, false, false, false, true, 450, 'Greece', true),
('Souvlaki', 'Souvlaki', 'سوفلاكي', 'Sovlaki', 'سۆڤلاکی', 'Izgara et şiş', 'Grilled meat skewer', 'سوفلاكي', 'Sovlaki', 'سۆڤلاکی', 32.00, 16, 1, false, false, true, true, 380, 'Greece', true),
('Greek Salad', 'Greek Salad', 'سلطة يونانية', 'Salataya Yewnanî', 'سەلاتەی یۆنانی', 'Feta peynirli salata', 'Feta cheese salad', 'سلطة يونانية', 'Salataya yewnanî', 'سەلاتەی یۆنانی', 24.00, 16, 0, true, false, true, false, 200, 'Greece', true),
('Spanakopita', 'Spanakopita', 'سباناكوبيتا', 'Spanakopîta', 'سپەناکۆپیتا', 'Ispanaklı börek', 'Spinach pie', 'سباناكوبيتا', 'Spanakopîta', 'سپەناکۆپیتا', 26.00, 16, 0, true, false, false, false, 320, 'Greece', true),
('Dolmades', 'Dolmades', 'دولماديس', 'Dolmade', 'دۆڵمەدە', 'Asma yaprağı sarması', 'Grape leaf rolls', 'دولماديس', 'Dolmade', 'دۆڵمەدە', 22.00, 16, 0, true, true, true, false, 180, 'Greece', true),
('Tzatziki', 'Tzatziki', 'تزاتزيكي', 'Tzatzikî', 'تزەتزیکی', 'Yoğurt sosu', 'Yogurt sauce', 'تزاتزيكي', 'Tzatzikî', 'تزەتزیکی', 16.00, 16, 0, true, true, true, false, 120, 'Greece', true),
('Pastitsio', 'Pastitsio', 'باستيتسيو', 'Pastîtsio', 'پاستیتسیۆ', 'Makarna ve et yemeği', 'Pasta and meat dish', 'باستيتسيو', 'Pastîtsio', 'پاستیتسیۆ', 36.00, 16, 1, false, false, false, true, 480, 'Greece', true),
('Baklava', 'Baklava', 'بقلاوة', 'Baklava', 'بەکلاڤا', 'Fıstıklı tatlı', 'Pistachio dessert', 'بقلاوة', 'Baklava', 'بەکلاڤا', 28.00, 16, 0, true, false, false, false, 350, 'Greece', true); 