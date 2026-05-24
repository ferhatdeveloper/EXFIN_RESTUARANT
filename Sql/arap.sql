-- EXFIN REST - Arap Mutfağı Kategorisi
-- Bu script Arap mutfağı kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 15);
DELETE FROM products WHERE category_id = 15;

-- =====================================================
-- ARAP MUTFAĞI KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(15, 'Arap Mutfağı', 'Arabic Cuisine', 'المطبخ العربي', 'Pêjgeha Erebî', 'پێشگەی عەرەبی', 'Arap yemekleri', 'Arabic dishes', 'أطباق عربية', 'Xwarinên Erebî', 'خواردنە عەرەبییەکان', 'restaurant', '#8D6E63', 15, true)
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
-- ARAP MUTFAĞI ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Hummus', 'Hummus', 'حمص', 'Humus', 'حومس', 'Nohut ezmesi', 'Chickpea dip', 'حمص', 'Humus', 'حومس', 18.00, 15, 0, true, true, true, false, 166, 'Lebanon', true),
('Falafel', 'Falafel', 'فلافل', 'Falafel', 'فەلافەل', 'Nohut köftesi', 'Chickpea fritters', 'فلافل', 'Falafel', 'فەلافەل', 22.00, 15, 1, true, true, false, true, 333, 'Egypt', true),
('Shawarma', 'Shawarma', 'شاورما', 'Şawerma', 'شاوەرما', 'Tavuk veya et döner', 'Chicken or meat wrap', 'شاورما', 'Şawerma', 'شاوەرما', 28.00, 15, 1, false, false, false, true, 350, 'Lebanon', true),
('Kebab', 'Kebab', 'كباب', 'Kebab', 'کەباب', 'Izgara et şiş', 'Grilled meat skewer', 'كباب', 'Kebab', 'کەباب', 35.00, 15, 1, false, false, true, true, 450, 'Turkey', true),
('Tabouleh', 'Tabouleh', 'تبولة', 'Tebûle', 'تەبۆلە', 'Bulgur salatası', 'Bulgur salad', 'تبولة', 'Tebûle', 'تەبۆلە', 16.00, 15, 0, true, true, true, false, 120, 'Lebanon', true),
('Baba Ganoush', 'Baba Ganoush', 'بابا غنوج', 'Baba Ganoj', 'بابا غەنۆج', 'Patlıcan ezmesi', 'Eggplant dip', 'بابا غنوج', 'Baba ganoj', 'بابا غەنۆج', 20.00, 15, 0, true, true, true, false, 150, 'Lebanon', true),
('Mansaf', 'Mansaf', 'منسف', 'Mensaf', 'مەنسەف', 'Pirinç ve et yemeği', 'Rice and meat dish', 'منسف', 'Mensaf', 'مەنسەف', 45.00, 15, 1, false, false, true, true, 600, 'Jordan', true),
('Knafeh', 'Knafeh', 'كنافة', 'Knafe', 'کنەفە', 'Tatlı peynir', 'Sweet cheese dessert', 'كنافة', 'Knafe', 'کنەفە', 25.00, 15, 0, true, false, false, false, 400, 'Palestine', true); 