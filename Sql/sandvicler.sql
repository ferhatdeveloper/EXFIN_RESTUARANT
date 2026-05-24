-- EXFIN REST - Sandviçler Kategorisi
-- Bu script sandviçler kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 22);
DELETE FROM products WHERE category_id = 22;

-- =====================================================
-- SANDVİÇLER KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(22, 'Sandviçler', 'Sandwiches', 'ساندويتش', 'Sandwîç', 'ساندویچ', 'Sandviç çeşitleri', 'Sandwich varieties', 'ساندويتش', 'Sandwîç', 'ساندویچ', 'lunch_dining', '#8BC34A', 22, true)
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
-- SANDVİÇLERİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Club Sandwich', 'Club Sandwich', 'ساندويتش نادي', 'Sandwîç Klûb', 'ساندویچ کڵووب', 'Kulüp sandviç', 'Club sandwich', 'ساندويتش نادي', 'Sandwîç klûb', 'ساندویچ کڵووب', 28.00, 22, 0, false, false, false, false, 420, 'USA', true),
('BLT Sandwich', 'BLT Sandwich', 'ساندويتش بي إل تي', 'Sandwîç BLT', 'ساندویچ بی ئێڵ تی', 'Pastırma, marul, domates', 'Bacon, lettuce, tomato', 'ساندويتش بي إل تي', 'Sandwîç BLT', 'ساندویچ بی ئێڵ تی', 26.00, 22, 0, false, false, false, false, 380, 'USA', true),
('Tuna Sandwich', 'Tuna Sandwich', 'ساندويتش تونة', 'Sandwîç Ton', 'ساندویچ تۆن', 'Ton balıklı sandviç', 'Tuna sandwich', 'ساندويتش تونة', 'Sandwîç ton', 'ساندویچ تۆن', 24.00, 22, 0, false, false, false, false, 320, 'USA', true),
('Chicken Sandwich', 'Chicken Sandwich', 'ساندويتش دجاج', 'Sandwîç Mirîşk', 'ساندویچ مریشک', 'Tavuklu sandviç', 'Chicken sandwich', 'ساندويتش دجاج', 'Sandwîç mirîşk', 'ساندویچ مریشک', 25.00, 22, 0, false, false, false, false, 350, 'USA', true),
('Veggie Sandwich', 'Veggie Sandwich', 'ساندويتش نباتي', 'Sandwîç Nebatî', 'ساندویچ نەباتی', 'Sebze sandviç', 'Veggie sandwich', 'ساندويتش نباتي', 'Sandwîç nebatî', 'ساندویچ نەباتی', 22.00, 22, 0, true, true, false, false, 280, 'USA', true),
('Turkey Sandwich', 'Turkey Sandwich', 'ساندويتش ديك رومي', 'Sandwîç Dîk Rûmî', 'ساندویچ دیک ڕوومی', 'Hindi sandviç', 'Turkey sandwich', 'ساندويتش ديك رومي', 'Sandwîç dîk rûmî', 'ساندویچ دیک ڕوومی', 27.00, 22, 0, false, false, false, false, 360, 'USA', true),
('Ham & Cheese', 'Ham & Cheese', 'ساندويتش لحم وجبن', 'Sandwîç Jambon û Penîr', 'ساندویچ جەمبۆن و پەنیر', 'Jambon peynirli sandviç', 'Ham and cheese sandwich', 'ساندويتش لحم وجبن', 'Sandwîç jambon û penîr', 'ساندویچ جەمبۆن و پەنیر', 26.00, 22, 0, false, false, false, false, 340, 'USA', true),
('Egg Salad Sandwich', 'Egg Salad Sandwich', 'ساندويتش سلطة بيض', 'Sandwîç Salataya Hêlka', 'ساندویچ سەلاتەی ھێلکە', 'Yumurta salatalı sandviç', 'Egg salad sandwich', 'ساندويتش سلطة بيض', 'Sandwîç salataya hêlka', 'ساندویچ سەلاتەی ھێلکە', 23.00, 22, 0, true, false, false, false, 300, 'USA', true); 