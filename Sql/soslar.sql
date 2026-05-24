-- EXFIN REST - Soslar Kategorisi
-- Bu script soslar kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 28);
DELETE FROM products WHERE category_id = 28;

-- =====================================================
-- SOSLAR KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(28, 'Soslar', 'Sauces', 'صلصات', 'Sos', 'سۆس', 'Sos çeşitleri', 'Sauce varieties', 'صلصات', 'Sos', 'سۆس', 'sauce', '#795548', 28, true)
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
-- SOSLARI EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Garlic Sauce', 'Garlic Sauce', 'صلصة ثوم', 'Sosê Sîr', 'سۆسێ سیر', 'Sarımsak sosu', 'Garlic sauce', 'صلصة ثوم', 'Sosê sîr', 'سۆسێ سیر', 8.00, 28, 0, true, true, true, false, 80, 'Turkey', true),
('Tzatziki Sauce', 'Tzatziki Sauce', 'صلصة تزاتزيكي', 'Sosê Tzatzikî', 'سۆسێ تزەتزیکی', 'Yoğurt sosu', 'Tzatziki sauce', 'صلصة تزاتزيكي', 'Sosê tzatzikî', 'سۆسێ تزەتزیکی', 10.00, 28, 0, true, true, true, false, 120, 'Greece', true),
('BBQ Sauce', 'BBQ Sauce', 'صلصة باربكيو', 'Sosê BBQ', 'سۆسێ باربیکیو', 'Barbekü sosu', 'BBQ sauce', 'صلصة باربكيو', 'Sosê BBQ', 'سۆسێ باربیکیو', 12.00, 28, 1, true, true, true, true, 100, 'USA', true),
('Hot Sauce', 'Hot Sauce', 'صلصة حارة', 'Sosê Tûj', 'سۆسێ تۆژ', 'Acı sos', 'Hot sauce', 'صلصة حارة', 'Sosê tûj', 'سۆسێ تۆژ', 8.00, 28, 3, true, true, true, true, 60, 'Mexico', true),
('Ranch Sauce', 'Ranch Sauce', 'صلصة رانش', 'Sosê Ranch', 'سۆسێ ڕەنچ', 'Ranch sosu', 'Ranch sauce', 'صلصة رانش', 'Sosê ranch', 'سۆسێ ڕەنچ', 10.00, 28, 0, true, false, true, false, 140, 'USA', true),
('Honey Mustard', 'Honey Mustard', 'خردل عسل', 'Xardel Hingiv', 'خەردەڵ ھەنگوین', 'Ballı hardal', 'Honey mustard', 'خردل عسل', 'Xardel hingiv', 'خەردەڵ ھەنگوین', 8.00, 28, 0, true, true, true, false, 100, 'USA', true),
('Tartar Sauce', 'Tartar Sauce', 'صلصة طرطور', 'Sosê Tartar', 'سۆسێ تەرتەر', 'Tartar sosu', 'Tartar sauce', 'صلصة طرطور', 'Sosê tartar', 'سۆسێ تەرتەر', 10.00, 28, 0, true, false, true, false, 120, 'France', true),
('Sweet Chili Sauce', 'Sweet Chili Sauce', 'صلصة فلفل حلو', 'Sosê Bîber Şîrîn', 'سۆسێ بیبەر شیرین', 'Tatlı acı sos', 'Sweet chili sauce', 'صلصة فلفل حلو', 'Sosê bîber şîrîn', 'سۆسێ بیبەر شیرین', 8.00, 28, 1, true, true, true, true, 80, 'Thailand', true); 