-- EXFIN REST - İçecekler Kategorisi
-- Bu script içecekler kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 1);
DELETE FROM products WHERE category_id = 1;

-- =====================================================
-- İÇECEKLER KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(1, 'İçecekler', 'Beverages', 'مشروبات', 'Şerab', 'شەراب', 'Soğuk ve sıcak içecekler', 'Cold and hot beverages', 'مشروبات باردة وساخنة', 'Şerabên sar û germ', 'شەرابە سارد و گەرمەکان', 'local_drink', '#2196F3', 1, true)
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
-- İÇECEKLER ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_cold, calories, origin_country, popular) VALUES
('Coca Cola', 'Coca Cola', 'كوكا كولا', 'Coca Cola', 'کۆکا کۆلا', '330ml Coca Cola', '330ml Coca Cola', 'كوكا كولا 330 مل', 'Coca Cola 330ml', 'کۆکا کۆلای 330 مل', 15.00, 1, 0, true, true, true, true, 140, 'USA', true),
('Pepsi', 'Pepsi', 'بيبسي', 'Pepsi', 'پێپسی', '330ml Pepsi', '330ml Pepsi', 'بيبسي 330 مل', 'Pepsi 330ml', 'پێپسی 330 مل', 15.00, 1, 0, true, true, true, true, 150, 'USA', true),
('Fanta', 'Fanta', 'فانتا', 'Fanta', 'فانتا', '330ml Fanta Portakal', '330ml Fanta Orange', 'فانتا برتقال 330 مل', 'Fanta Porteqal 330ml', 'فانتای پرتەقاڵی 330 مل', 15.00, 1, 0, true, true, true, true, 160, 'Germany', true),
('Sprite', 'Sprite', 'سبرايت', 'Sprite', 'سپرایت', '330ml Sprite', '330ml Sprite', 'سبرايت 330 مل', 'Sprite 330ml', 'سپرایتی 330 مل', 15.00, 1, 0, true, true, true, true, 140, 'USA', true),
('Ayran', 'Ayran', 'عيران', 'Ayrûn', 'ئەیران', '500ml Taze Ayran', '500ml Fresh Ayran', 'عيران طازج 500 مل', 'Ayrûn taze 500ml', 'ئەیرانی تازەی 500 مل', 12.00, 1, 0, true, true, true, true, 60, 'Turkey', true),
('Su', 'Water', 'ماء', 'Av', 'ئاو', '500ml Doğal Su', '500ml Natural Water', 'ماء طبيعي 500 مل', 'Av xwezayî 500ml', 'ئاوی سروشتی 500 مل', 5.00, 1, 0, true, true, true, true, 0, 'Turkey', true),
('Meyve Suyu', 'Fruit Juice', 'عصير فواكه', 'Şîrê Mêweyan', 'شیری میوەکان', '250ml Karışık Meyve Suyu', '250ml Mixed Fruit Juice', 'عصير فواكه مختلط 250 مل', 'Şîrê mêweyan tevlihev 250ml', 'شیری میوە تێکەڵەکان 250 مل', 18.00, 1, 0, true, true, true, true, 120, 'Turkey', true),
('Limonata', 'Lemonade', 'ليموناضة', 'Lîmonata', 'لیمۆناتە', '300ml Taze Limonata', '300ml Fresh Lemonade', 'ليموناضة طازجة 300 مل', 'Lîmonata taze 300ml', 'لیمۆناتەی تازەی 300 مل', 20.00, 1, 0, true, true, true, true, 90, 'Turkey', true),
('Portakal Suyu', 'Orange Juice', 'عصير برتقال', 'Şîrê Porteqal', 'شیری پرتەقاڵ', '250ml Taze Portakal Suyu', '250ml Fresh Orange Juice', 'عصير برتقال طازج 250 مل', 'Şîrê porteqal taze 250ml', 'شیری پرتەقاڵی تازەی 250 مل', 22.00, 1, 0, true, true, true, true, 110, 'Turkey', true),
('Elma Suyu', 'Apple Juice', 'عصير تفاح', 'Şîrê Sêv', 'شیری سێو', '250ml Taze Elma Suyu', '250ml Fresh Apple Juice', 'عصير تفاح طازج 250 مل', 'Şîrê sêv taze 250ml', 'شیری سێوی تازەی 250 مل', 20.00, 1, 0, true, true, true, true, 100, 'Turkey', true),
('Üzüm Suyu', 'Grape Juice', 'عصير عنب', 'Şîrê Tîr', 'شیری تیر', '250ml Taze Üzüm Suyu', '250ml Fresh Grape Juice', 'عصير عنب طازج 250 مل', 'Şîrê tîr taze 250ml', 'شیری تیری تازەی 250 مل', 24.00, 1, 0, true, true, true, true, 130, 'Turkey', true),
('Ananas Suyu', 'Pineapple Juice', 'عصير أناناس', 'Şîrê Ananas', 'شیری ئەناناس', '250ml Taze Ananas Suyu', '250ml Fresh Pineapple Juice', 'عصير أناناس طازج 250 مل', 'Şîrê ananas taze 250ml', 'شیری ئەناناسی تازەی 250 مل', 26.00, 1, 0, true, true, true, true, 140, 'Thailand', true); 