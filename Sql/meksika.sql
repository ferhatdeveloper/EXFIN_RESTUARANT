-- EXFIN REST - Meksika Mutfağı Kategorisi
-- Bu script Meksika mutfağı kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 12);
DELETE FROM products WHERE category_id = 12;

-- =====================================================
-- MEKSİKA MUTFAĞI KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(12, 'Meksika Mutfağı', 'Mexican Cuisine', 'المطبخ المكسيكي', 'Pêjgeha Meksîkî', 'پێشگەی مەکسیکی', 'Meksika yemekleri', 'Mexican dishes', 'أطباق مكسيكية', 'Xwarinên Meksîkî', 'خواردنە مەکسیکییەکان', 'taco', '#4CAF50', 12, true)
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
-- MEKSİKA MUTFAĞI ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Taco', 'Taco', 'تاكو', 'Taco', 'تاکۆ', 'Meksika taco', 'Mexican taco', 'تاكو مكسيكي', 'Taco Meksîkî', 'تاکۆی مەکسیکی', 25.00, 12, 1, false, false, false, true, 280, 'Mexico', true),
('Burrito', 'Burrito', 'بوريتو', 'Burrito', 'بۆریتۆ', 'Meksika burrito', 'Mexican burrito', 'بوريتو مكسيكي', 'Burrito Meksîkî', 'بۆریتۆی مەکسیکی', 32.00, 12, 1, false, false, false, true, 350, 'Mexico', true),
('Quesadilla', 'Quesadilla', 'كيساديا', 'Quesadilla', 'کێسادیا', 'Peynirli tortilla', 'Cheese tortilla', 'تورتييا جبن', 'Tortilla penîr', 'تۆرتییای پەنیر', 28.00, 12, 0, true, false, false, true, 300, 'Mexico', true),
('Enchilada', 'Enchilada', 'إنتشيلادا', 'Enchilada', 'ئەنچیڵادا', 'Soslu tortilla', 'Sauced tortilla', 'تورتييا بصلصة', 'Tortilla bi sosa', 'تۆرتییا بە سۆسا', 30.00, 12, 2, false, false, false, true, 320, 'Mexico', true),
('Fajita', 'Fajita', 'فاخيتا', 'Fajita', 'فاخیتا', 'Izgara et fajita', 'Grilled meat fajita', 'فاخيتا لحم مشوي', 'Fajita goştê biraştî', 'فاخیتای گۆشتی براژت', 35.00, 12, 1, false, false, false, true, 380, 'Mexico', true),
('Chimichanga', 'Chimichanga', 'تشيميشانغا', 'Chimichanga', 'چیمیچانگا', 'Kızarmış burrito', 'Fried burrito', 'بوريتو مقلي', 'Burrito sorkirî', 'بۆریتۆی سۆرکر', 38.00, 12, 1, false, false, false, true, 420, 'Mexico', true),
('Tamale', 'Tamale', 'تامالي', 'Tamale', 'تاماڵە', 'Mısır hamuru', 'Corn dough', 'عجين ذرة', 'Hevîrê garisê', 'هەویری گەنمی', 22.00, 12, 0, false, false, false, true, 250, 'Mexico', true),
('Pozole', 'Pozole', 'بوزولي', 'Pozole', 'پۆزۆڵە', 'Meksika çorbası', 'Mexican soup', 'حساء مكسيكي', 'Şorbaya Meksîkî', 'شۆربای مەکسیکی', 26.00, 12, 1, false, false, true, true, 280, 'Mexico', true),
('Chile Relleno', 'Chile Relleno', 'تشيلي ريلينو', 'Chile Relleno', 'چیڵی ڕێڵینۆ', 'Dolgulu biber', 'Stuffed pepper', 'فلفل محشي', 'Bîberê dagirtî', 'بیبەری دەگرت', 24.00, 12, 1, true, false, false, true, 220, 'Mexico', true),
('Guacamole', 'Guacamole', 'غواكامولي', 'Guacamole', 'گواکامۆڵە', 'Avokado sosu', 'Avocado sauce', 'صلصة أفوكادو', 'Sosa avokado', 'سۆسای ئەڤۆکادۆ', 18.00, 12, 0, true, true, true, false, 150, 'Mexico', true),
('Salsa', 'Salsa', 'سالسا', 'Salsa', 'ساڵسا', 'Domates sosu', 'Tomato sauce', 'صلصة طماطم', 'Sosa bacanaş', 'سۆسای باژەنگ', 12.00, 12, 1, true, true, true, false, 80, 'Mexico', true),
('Nachos', 'Nachos', 'ناتشوس', 'Nachos', 'ناچۆس', 'Mısır cipsi', 'Corn chips', 'رقائق ذرة', 'Çîpên garisê', 'چیپەکانی گەنم', 20.00, 12, 0, true, true, false, false, 200, 'Mexico', true),
('Churro', 'Churro', 'تشورو', 'Churro', 'چوڕۆ', 'Meksika tatlısı', 'Mexican dessert', 'حلويات مكسيكية', 'Şîrînîya Meksîkî', 'شیرینی مەکسیکی', 16.00, 12, 0, true, true, false, false, 180, 'Mexico', true),
('Flan', 'Flan', 'فلان', 'Flan', 'فڵان', 'Kremalı tatlı', 'Creamy dessert', 'حلويات كريمية', 'Şîrînîya kremî', 'شیرینی کڕێمی', 18.00, 12, 0, true, false, false, false, 200, 'Mexico', true),
('Tres Leches', 'Tres Leches', 'تريس ليتشيس', 'Tres Leches', 'ترێس لێچێس', 'Üç sütlü kek', 'Three milk cake', 'كيكة ثلاث حليب', 'Kekê sê şîr', 'کەکێ سێ شیر', 22.00, 12, 0, true, false, false, false, 250, 'Mexico', true),
('Horchata', 'Horchata', 'هورتشاتا', 'Horchata', 'ھۆرچاتا', 'Pirinç içeceği', 'Rice drink', 'مشروب أرز', 'Şerabê birincê', 'شەرابی برنج', 15.00, 12, 0, true, true, true, false, 120, 'Mexico', true),
('Jamaica', 'Jamaica', 'جامايكا', 'Jamaica', 'جامایکا', 'Hibiskus çayı', 'Hibiscus tea', 'شاي كركديه', 'Çaya hibiskus', 'چای ھیبسکەس', 12.00, 12, 0, true, true, true, false, 80, 'Mexico', true),
('Tequila', 'Tequila', 'تيكيلا', 'Tequila', 'تێکیلا', 'Meksika içkisi', 'Mexican spirit', 'مشروب مكسيكي', 'Şerabê Meksîkî', 'شەرابی مەکسیکی', 45.00, 12, 0, true, true, true, false, 100, 'Mexico', true),
('Margarita', 'Margarita', 'مارغريتا', 'Margarita', 'ماڕگەریتا', 'Tequila kokteyli', 'Tequila cocktail', 'كوكتيل تيكيلا', 'Kokteyla tequila', 'کۆکتەیل تێکیلا', 35.00, 12, 0, true, true, true, false, 180, 'Mexico', true); 