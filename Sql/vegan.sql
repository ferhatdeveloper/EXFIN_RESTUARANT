-- EXFIN REST - Vegan Kategorisi
-- Bu script vegan kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 19);
DELETE FROM products WHERE category_id = 19;

-- =====================================================
-- VEGAN KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(19, 'Vegan', 'Vegan', 'نباتي صرف', 'Vegan', 'ڤێگان', 'Vegan yemekler', 'Vegan dishes', 'أطباق نباتية صرفة', 'Xwarinên vegan', 'خواردنە ڤێگانییەکان', 'eco', '#8BC34A', 19, true)
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
-- VEGAN ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Vegan Buddha Bowl', 'Vegan Buddha Bowl', 'وعاء بوذا نباتي', 'Buddha Bowl Vegan', 'بودا بۆڵ ڤێگان', 'Vegan buddha kasesi', 'Vegan buddha bowl', 'وعاء بوذا نباتي', 'Buddha bowl vegan', 'بودا بۆڵ ڤێگان', 34.00, 19, 0, true, true, true, false, 280, 'Thailand', true),
('Tofu Stir Fry', 'Tofu Stir Fry', 'توفو مقلي', 'Tofu Sorkirî', 'تۆفو سۆرکر', 'Tofu sote', 'Tofu stir fry', 'توفو مقلي', 'Tofu sorkirî', 'تۆفو سۆرکر', 26.00, 19, 1, true, true, true, true, 220, 'China', true),
('Vegan Sushi', 'Vegan Sushi', 'سوشي نباتي', 'Sûşî Vegan', 'سۆشی ڤێگان', 'Vegan sushi', 'Vegan sushi', 'سوشي نباتي', 'Sûşî vegan', 'سۆشی ڤێگان', 32.00, 19, 0, true, true, true, false, 240, 'Japan', true),
('Lentil Curry', 'Lentil Curry', 'كاري عدس', 'Kerî Nîsk', 'کەری نیسک', 'Mercimek körisi', 'Lentil curry', 'كاري عدس', 'Kerî nîsk', 'کەری نیسک', 24.00, 19, 2, true, true, true, true, 260, 'India', true),
('Vegan Burger', 'Vegan Burger', 'برجر نباتي', 'Burger Vegan', 'بۆرگر ڤێگان', 'Vegan burger', 'Vegan burger', 'برجر نباتي', 'Burger vegan', 'بۆرگر ڤێگان', 28.00, 19, 1, true, true, false, true, 320, 'USA', true),
('Chickpea Salad', 'Chickpea Salad', 'سلطة حمص', 'Salataya Noxûd', 'سەلاتەی نەخود', 'Nohut salatası', 'Chickpea salad', 'سلطة حمص', 'Salataya noxûd', 'سەلاتەی نەخود', 20.00, 19, 0, true, true, true, false, 180, 'Lebanon', true),
('Vegan Pasta', 'Vegan Pasta', 'مكرونة نباتية', 'Makarna Vegan', 'ماکارۆنا ڤێگان', 'Vegan makarna', 'Vegan pasta', 'مكرونة نباتية', 'Makarna vegan', 'ماکارۆنای ڤێگان', 30.00, 19, 1, true, true, false, true, 380, 'Italy', true),
('Avocado Toast', 'Avocado Toast', 'توست أفوكادو', 'Tost Avokado', 'تۆست ئەڤۆکادۆ', 'Avokado tostu', 'Avocado toast', 'توست أفوكادو', 'Tost avokado', 'تۆست ئەڤۆکادۆ', 22.00, 19, 0, true, true, false, false, 200, 'Australia', true); 