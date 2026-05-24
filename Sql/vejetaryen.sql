-- EXFIN REST - Vejetaryen Kategorisi
-- Bu script vejetaryen kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 18);
DELETE FROM products WHERE category_id = 18;

-- =====================================================
-- VEJETARYEN KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(18, 'Vejetaryen', 'Vegetarian', 'نباتي', 'Nebatî', 'نەباتی', 'Vejetaryen yemekler', 'Vegetarian dishes', 'أطباق نباتية', 'Xwarinên nebatî', 'خواردنە نەباتییەکان', 'eco', '#4CAF50', 18, true)
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
-- VEJETARYEN ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Vegetable Curry', 'Vegetable Curry', 'كاري خضار', 'Kerî Sebze', 'کەری سەوزە', 'Sebze körisi', 'Vegetable curry', 'كاري خضار', 'Kerî sebze', 'کەری سەوزە', 26.00, 18, 2, true, true, true, true, 280, 'India', true),
('Quinoa Bowl', 'Quinoa Bowl', 'وعاء كينوا', 'Qûnwa Bowl', 'قوینوا بۆڵ', 'Kinoa kasesi', 'Quinoa bowl', 'وعاء كينوا', 'Qûnwa bowl', 'قوینوا بۆڵ', 32.00, 18, 0, true, true, true, false, 320, 'Peru', true),
('Mushroom Risotto', 'Mushroom Risotto', 'ريسوتو فطر', 'Rîsotto Kûvark', 'ریسۆتۆ کوڤەرک', 'Mantarlı risotto', 'Mushroom risotto', 'ريسوتو فطر', 'Rîsotto kûvark', 'ریسۆتۆ کوڤەرک', 34.00, 18, 1, true, false, false, true, 380, 'Italy', true),
('Vegetable Stir Fry', 'Vegetable Stir Fry', 'خضار مقلي', 'Sebze Sorkirî', 'سەوزە سۆرکر', 'Sebze sote', 'Vegetable stir fry', 'خضار مقلي', 'Sebze sorkirî', 'سەوزە سۆرکر', 24.00, 18, 1, true, true, true, true, 220, 'China', true),
('Falafel Wrap', 'Falafel Wrap', 'لفافة فلافل', 'Falafel Wrap', 'فەلافەل ڕەپ', 'Falafel dürüm', 'Falafel wrap', 'لفافة فلافل', 'Falafel wrap', 'فەلافەل ڕەپ', 20.00, 18, 1, true, true, false, true, 280, 'Lebanon', true),
('Vegetable Lasagna', 'Vegetable Lasagna', 'لازانيا خضار', 'Lazanya Sebze', 'لەزەنیا سەوزە', 'Sebze lazanyası', 'Vegetable lasagna', 'لازانيا خضار', 'Lazanya sebze', 'لەزەنیا سەوزە', 30.00, 18, 0, true, false, false, true, 420, 'Italy', true),
('Chickpea Stew', 'Chickpea Stew', 'يخنة حمص', 'Noxûd Stew', 'نەخود ستێو', 'Nohut yahni', 'Chickpea stew', 'يخنة حمص', 'Noxûd stew', 'نەخود ستێو', 22.00, 18, 1, true, true, true, true, 260, 'Morocco', true),
('Vegetable Paella', 'Vegetable Paella', 'باييا خضار', 'Paella Sebze', 'پایەڵا سەوزە', 'Sebze paellası', 'Vegetable paella', 'باييا خضار', 'Paella sebze', 'پایەڵای سەوزە', 28.00, 18, 1, true, true, false, true, 340, 'Spain', true); 