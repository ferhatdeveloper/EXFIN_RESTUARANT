-- EXFIN REST - Tatlılar Kategorisi
-- Bu script tatlılar kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 3);
DELETE FROM products WHERE category_id = 3;

-- =====================================================
-- TATLILAR KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(3, 'Tatlılar', 'Desserts', 'حلويات', 'Şîrînî', 'شیرینی', 'Tatlılar', 'Desserts', 'حلويات', 'Şîrînî', 'شیرینی', 'cake', '#E91E63', 3, true)
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
-- TATLILARI EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Tiramisu', 'Tiramisu', 'تيراميسو', 'Tîramîsû', 'تیڕامیسو', 'İtalyan tatlısı', 'Italian dessert', 'تيراميسو', 'Tîramîsû', 'تیڕامیسو', 32.00, 3, 0, true, false, false, false, 280, 'Italy', true),
('Cheesecake', 'Cheesecake', 'كيك جبن', 'Kekê Penîr', 'کەکێ پەنیر', 'Peynirli kek', 'Cheese cake', 'كيك جبن', 'Kekê penîr', 'کەکێ پەنیر', 28.00, 3, 0, true, false, false, false, 320, 'USA', true),
('Chocolate Cake', 'Chocolate Cake', 'كيك شوكولاتة', 'Kekê Çîkolata', 'کەکێ چیکۆلاتە', 'Çikolatalı kek', 'Chocolate cake', 'كيك شوكولاتة', 'Kekê çîkolata', 'کەکێ چیکۆلاتە', 26.00, 3, 0, true, false, false, false, 350, 'France', true),
('Apple Pie', 'Apple Pie', 'فطيرة تفاح', 'Kekê Sêv', 'کەکێ سێو', 'Elmalı turta', 'Apple pie', 'فطيرة تفاح', 'Kekê sêv', 'کەکێ سێو', 24.00, 3, 0, true, false, false, false, 300, 'USA', true),
('Crème Brûlée', 'Crème Brûlée', 'كريم برولي', 'Krêm Brûlée', 'کرێم برۆلێ', 'Fransız tatlısı', 'French dessert', 'كريم برولي', 'Krêm brûlée', 'کرێم برۆلێ', 30.00, 3, 0, true, false, false, false, 280, 'France', true),
('Baklava', 'Baklava', 'بقلاوة', 'Baklava', 'بەکلاڤا', 'Fıstıklı tatlı', 'Pistachio dessert', 'بقلاوة', 'Baklava', 'بەکلاڤا', 34.00, 3, 0, true, false, false, false, 380, 'Turkey', true),
('Panna Cotta', 'Panna Cotta', 'بانا كوتا', 'Panna Kotta', 'پەنە کۆتە', 'İtalyan muhallebisi', 'Italian pudding', 'بانا كوتا', 'Panna kotta', 'پەنە کۆتە', 26.00, 3, 0, true, false, false, false, 240, 'Italy', true),
('Red Velvet Cake', 'Red Velvet Cake', 'كيك مخمل أحمر', 'Kekê Velvet Sor', 'کەکێ ڤێڵڤێت سۆر', 'Kırmızı kadife kek', 'Red velvet cake', 'كيك مخمل أحمر', 'Kekê velvet sor', 'کەکێ ڤێڵڤێت سۆر', 32.00, 3, 0, true, false, false, false, 360, 'USA', true); 