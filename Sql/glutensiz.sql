-- EXFIN REST - Glutensiz Kategorisi
-- Bu script glutensiz kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 20);
DELETE FROM products WHERE category_id = 20;

-- =====================================================
-- GLUTENSİZ KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(20, 'Glutensiz', 'Gluten Free', 'خالي من الغلوتين', 'Gluten Free', 'گڵوتن فری', 'Glutensiz yemekler', 'Gluten free dishes', 'أطباق خالية من الغلوتين', 'Xwarinên gluten free', 'خواردنە گڵوتن فرییەکان', 'allergies', '#FF9800', 20, true)
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
-- GLUTENSİZ ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Quinoa Salad', 'Quinoa Salad', 'سلطة كينوا', 'Salataya Qûnwa', 'سەلاتەی قوینوا', 'Kinoa salatası', 'Quinoa salad', 'سلطة كينوا', 'Salataya qûnwa', 'سەلاتەی قوینوا', 24.00, 20, 0, true, true, true, false, 180, 'Peru', true),
('Grilled Chicken', 'Grilled Chicken', 'دجاج مشوي', 'Mirîşka Sorkirî', 'مریشکی سۆرکر', 'Izgara tavuk', 'Grilled chicken', 'دجاج مشوي', 'Mirîşka sorkirî', 'مریشکی سۆرکر', 32.00, 20, 1, false, false, true, true, 280, 'Turkey', true),
('Rice Noodles', 'Rice Noodles', 'نودلز أرز', 'Nûdel Riz', 'نۆدەڵ ڕز', 'Pirinç eriştesi', 'Rice noodles', 'نودلز أرز', 'Nûdel riz', 'نۆدەڵ ڕز', 26.00, 20, 1, true, true, true, true, 220, 'Thailand', true),
('Baked Salmon', 'Baked Salmon', 'سلمون مخبوز', 'Somon Pexirî', 'سەمۆن پەخری', 'Fırında somon', 'Baked salmon', 'سلمون مخبوز', 'Somon pexirî', 'سەمۆن پەخری', 42.00, 20, 0, false, false, true, true, 320, 'Norway', true),
('Vegetable Soup', 'Vegetable Soup', 'شوربة خضار', 'Şorba Sebze', 'شۆربە سەوزە', 'Sebze çorbası', 'Vegetable soup', 'شوربة خضار', 'Şorba sebze', 'شۆربەی سەوزە', 18.00, 20, 0, true, true, true, true, 120, 'Turkey', true),
('Buckwheat Pancakes', 'Buckwheat Pancakes', 'فطائر حنطة سوداء', 'Pankek Greçka', 'پەنکەک گریچکا', 'Karabuğday krepleri', 'Buckwheat pancakes', 'فطائر حنطة سوداء', 'Pankek greçka', 'پەنکەک گریچکا', 22.00, 20, 0, true, false, true, false, 280, 'Russia', true),
('Gluten Free Pizza', 'Gluten Free Pizza', 'بيتزا خالية من الغلوتين', 'Pîzza Gluten Free', 'پیتزا گڵوتن فری', 'Glutensiz pizza', 'Gluten free pizza', 'بيتزا خالية من الغلوتين', 'Pîzza gluten free', 'پیتزای گڵوتن فری', 36.00, 20, 1, false, false, true, true, 380, 'Italy', true),
('Almond Flour Cake', 'Almond Flour Cake', 'كيك طحين لوز', 'Kekê Ardiya Badam', 'کەکێ ئەردیای بادەم', 'Badem unlu kek', 'Almond flour cake', 'كيك طحين لوز', 'Kekê ardiya badam', 'کەکێ ئەردیای بادەم', 28.00, 20, 0, true, false, true, false, 320, 'France', true); 