-- EXFIN REST - Çocuk Menüsü Kategorisi
-- Bu script çocuk menüsü kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 24);
DELETE FROM products WHERE category_id = 24;

-- =====================================================
-- ÇOCUK MENÜSÜ KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(24, 'Çocuk Menüsü', 'Kids Menu', 'قائمة أطفال', 'Menûya Zarok', 'مێنووی زارۆک', 'Çocuk menüsü', 'Kids menu', 'قائمة أطفال', 'Menûya zarok', 'مێنووی زارۆک', 'child_care', '#FFC107', 24, true)
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
-- ÇOCUK MENÜSÜ ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Kids Burger', 'Kids Burger', 'برجر أطفال', 'Burger Zarok', 'بۆرگر زارۆک', 'Çocuk burger', 'Kids burger', 'برجر أطفال', 'Burger zarok', 'بۆرگر زارۆک', 22.00, 24, 0, false, false, false, true, 280, 'USA', true),
('Chicken Nuggets', 'Chicken Nuggets', 'قطع دجاج', 'Parçeyên Mirîşk', 'پەرچەکێ مریشک', 'Tavuk nugget', 'Chicken nuggets', 'قطع دجاج', 'Parçeyên mirîşk', 'پەرچەکێ مریشک', 18.00, 24, 0, false, false, false, true, 240, 'USA', true),
('Kids Pizza', 'Kids Pizza', 'بيتزا أطفال', 'Pîzza Zarok', 'پیتزای زارۆک', 'Çocuk pizza', 'Kids pizza', 'بيتزا أطفال', 'Pîzza zarok', 'پیتزای زارۆک', 20.00, 24, 0, true, false, false, true, 220, 'Italy', true),
('Fish Fingers', 'Fish Fingers', 'أصابع سمك', 'Tiliyên Masî', 'تیلێ ماسی', 'Balık parmak', 'Fish fingers', 'أصابع سمك', 'Tiliyên masî', 'تیلێ ماسی', 16.00, 24, 0, false, false, false, true, 200, 'UK', true),
('Mac & Cheese', 'Mac & Cheese', 'مكرونة وجبن', 'Makarna û Penîr', 'ماکارۆنا و پەنیر', 'Makarna peynir', 'Mac and cheese', 'مكرونة وجبن', 'Makarna û penîr', 'ماکارۆنا و پەنیر', 15.00, 24, 0, true, false, false, true, 260, 'USA', true),
('Kids Pasta', 'Kids Pasta', 'مكرونة أطفال', 'Makarna Zarok', 'ماکارۆنای زارۆک', 'Çocuk makarna', 'Kids pasta', 'مكرونة أطفال', 'Makarna zarok', 'ماکارۆنای زارۆک', 14.00, 24, 0, true, false, false, true, 180, 'Italy', true),
('Ice Cream Sundae', 'Ice Cream Sundae', 'آيس كريم سندي', 'Dondurma Sundae', 'دۆندوڕمای سەندای', 'Dondurma sundae', 'Ice cream sundae', 'آيس كريم سندي', 'Dondurma sundae', 'دۆندوڕمای سەندای', 12.00, 24, 0, true, false, true, false, 180, 'USA', true),
('Chocolate Milkshake', 'Chocolate Milkshake', 'شيكولاتة ميلك شيك', 'Mîlkşêk Çîkolata', 'میلکشێک چیکۆلاتە', 'Çikolatalı milkshake', 'Chocolate milkshake', 'شيكولاتة ميلك شيك', 'Mîlkşêk çîkolata', 'میلکشێک چیکۆلاتە', 10.00, 24, 0, true, false, true, false, 220, 'USA', true); 