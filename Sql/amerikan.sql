-- EXFIN REST - Amerikan Mutfağı Kategorisi
-- Bu script Amerikan mutfağı kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 14);
DELETE FROM products WHERE category_id = 14;

-- =====================================================
-- AMERİKAN MUTFAĞI KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(14, 'Amerikan Mutfağı', 'American Cuisine', 'المطبخ الأمريكي', 'Pêjgeha Amerîkî', 'پێشگەی ئەمریکی', 'Amerikan yemekleri', 'American dishes', 'أطباق أمريكية', 'Xwarinên Amerîkî', 'خواردنە ئەمریکییەکان', 'fastfood', '#607D8B', 14, true)
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
-- AMERİKAN MUTFAĞI ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Cheeseburger', 'Cheeseburger', 'تشيز برجر', 'Cheeseburger', 'چیزبۆرگر', 'Peynirli hamburger', 'Cheese hamburger', 'برجر بالجبن', 'Burger penîr', 'بۆرگر پەنیر', 32.00, 14, 0, false, false, false, true, 450, 'USA', true),
('Hot Dog', 'Hot Dog', 'هوت دوغ', 'Hot Dog', 'هۆت دوگ', 'Sosisli sandviç', 'Sausage sandwich', 'ساندويتش سجق', 'Sandwîç sosis', 'ساندویچ سۆسج', 28.00, 14, 0, false, false, false, true, 380, 'USA', true),
('Fried Chicken', 'Fried Chicken', 'دجاج مقلي', 'Mirîşka Sorkirî', 'مریشکی سۆرکر', 'Kızarmış tavuk', 'Fried chicken', 'دجاج مقلي', 'Mirîşka sorkirî', 'مریشکی سۆرکر', 35.00, 14, 1, false, false, true, true, 420, 'USA', true),
('BBQ Ribs', 'BBQ Ribs', 'ضلوع مشوية', 'BBQ Ribs', 'ریبس باربیکیو', 'Barbekü kaburga', 'Barbecue ribs', 'ضلوع مشوية', 'Kaburga barbekû', 'کابورگای باربیکیو', 48.00, 14, 1, false, false, true, true, 550, 'USA', true),
('Mac and Cheese', 'Mac and Cheese', 'مكرونة بالجبن', 'Mac û Penîr', 'ماک و پەنیر', 'Peynirli makarna', 'Macaroni and cheese', 'مكرونة بالجبن', 'Makarnaya penîr', 'ماکارۆنی پەنیر', 22.00, 14, 0, true, false, false, true, 350, 'USA', true),
('Buffalo Wings', 'Buffalo Wings', 'أجنحة بافالو', 'Buffalo Wings', 'بافالو وینگز', 'Acılı tavuk kanadı', 'Spicy chicken wings', 'أجنحة دجاج حارة', 'Qanadê mirîşk ya tûj', 'قەنادی مریشک تۆژ', 30.00, 14, 2, false, false, true, true, 400, 'USA', true),
('Caesar Salad', 'Caesar Salad', 'سلطة قيصر', 'Salataya Sezar', 'سەلاتەی سێزار', 'Marul, tavuk, peynir', 'Lettuce, chicken, cheese', 'خس ودجاج وجبن', 'Selata, mirîşk, penîr', 'سەلاتە، مریشک، پەنیر', 26.00, 14, 0, false, false, true, true, 220, 'USA', true),
('Apple Pie', 'Apple Pie', 'فطيرة تفاح', 'Kekê Sêv', 'کەکێ سێو', 'Elmalı turta', 'Apple pie', 'فطيرة تفاح', 'Kekê sêv', 'کەکێ سێو', 18.00, 14, 0, true, false, false, false, 300, 'USA', true);