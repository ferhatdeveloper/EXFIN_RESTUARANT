-- EXFIN REST - Salatalar Kategorisi
-- Bu script salatalar kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 25);
DELETE FROM products WHERE category_id = 25;

-- =====================================================
-- SALATALAR KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(25, 'Salatalar', 'Salads', 'سلطات', 'Selata', 'سەلاتە', 'Salata çeşitleri', 'Salad varieties', 'سلطات', 'Selata', 'سەلاتە', 'eco', '#4CAF50', 25, true)
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
-- SALATALARI EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Caesar Salad', 'Caesar Salad', 'سلطة قيصر', 'Selataya Sezar', 'سەلاتەی سێزار', 'Marul, tavuk, peynir', 'Lettuce, chicken, cheese', 'سلطة قيصر', 'Selataya sezar', 'سەلاتەی سێزار', 26.00, 25, 0, false, false, true, false, 220, 'USA', true),
('Greek Salad', 'Greek Salad', 'سلطة يونانية', 'Selataya Yewnanî', 'سەلاتەی یۆنانی', 'Feta peynirli salata', 'Feta cheese salad', 'سلطة يونانية', 'Selataya yewnanî', 'سەلاتەی یۆنانی', 24.00, 25, 0, true, false, true, false, 200, 'Greece', true),
('Cobb Salad', 'Cobb Salad', 'سلطة كوب', 'Selataya Kob', 'سەلاتەی کۆب', 'Tavuk, yumurta, avokado', 'Chicken, egg, avocado', 'سلطة كوب', 'Selataya kob', 'سەلاتەی کۆب', 28.00, 25, 0, false, false, true, false, 280, 'USA', true),
('Nicoise Salad', 'Nicoise Salad', 'سلطة نيسواز', 'Selataya Nîswaz', 'سەلاتەی نیسواز', 'Ton balığı, yumurta, patates', 'Tuna, egg, potato', 'سلطة نيسواز', 'Selataya nîswaz', 'سەلاتەی نیسواز', 30.00, 25, 0, false, false, true, false, 320, 'France', true),
('Waldorf Salad', 'Waldorf Salad', 'سلطة والدورف', 'Selataya Waldorf', 'سەلاتەی ڤاڵدۆرف', 'Elma, ceviz, mayonez', 'Apple, walnut, mayonnaise', 'سلطة والدورف', 'Selataya waldorf', 'سەلاتەی ڤاڵدۆرف', 22.00, 25, 0, true, false, true, false, 240, 'USA', true),
('Caprese Salad', 'Caprese Salad', 'سلطة كابريزي', 'Selataya Kaprez', 'سەلاتەی کاپرەز', 'Mozzarella, domates, fesleğen', 'Mozzarella, tomato, basil', 'سلطة كابريزي', 'Selataya kaprez', 'سەلاتەی کاپرەز', 25.00, 25, 0, true, false, true, false, 180, 'Italy', true),
('Quinoa Salad', 'Quinoa Salad', 'سلطة كينوا', 'Selataya Qûnwa', 'سەلاتەی قوینوا', 'Kinoa salatası', 'Quinoa salad', 'سلطة كينوا', 'Selataya qûnwa', 'سەلاتەی قوینوا', 24.00, 25, 0, true, true, true, false, 180, 'Peru', true),
('Spinach Salad', 'Spinach Salad', 'سلطة سبانخ', 'Selataya Sipînax', 'سەلاتەی سپینەخ', 'Ispanak salatası', 'Spinach salad', 'سلطة سبانخ', 'Selataya sipînax', 'سەلاتەی سپینەخ', 20.00, 25, 0, true, true, true, false, 160, 'USA', true); 