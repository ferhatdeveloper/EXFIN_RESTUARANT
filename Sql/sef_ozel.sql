-- EXFIN REST - Şef Özel Kategorisi
-- Bu script şef özel kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 23);
DELETE FROM products WHERE category_id = 23;

-- =====================================================
-- ŞEF ÖZEL KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(23, 'Şef Özel', 'Chef Special', 'طبق الشيف', 'Xwarina Şef', 'خواردنی شێف', 'Şef özel yemekleri', 'Chef special dishes', 'أطباق الشيف', 'Xwarinên şef', 'خواردنە شێفییەکان', 'restaurant_menu', '#FF5722', 23, true)
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
-- ŞEF ÖZEL ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Chef Special Steak', 'Chef Special Steak', 'ستيك الشيف', 'Stekê Şef', 'ستەکێ شێف', 'Şef özel biftek', 'Chef special steak', 'ستيك الشيف', 'Stekê şef', 'ستەکێ شێف', 65.00, 23, 1, false, false, true, true, 480, 'France', true),
('Truffle Pasta', 'Truffle Pasta', 'مكرونة كمأة', 'Makarna Trûfel', 'ماکارۆنای تڕوفێڵ', 'Trüf mantarlı makarna', 'Truffle pasta', 'مكرونة كمأة', 'Makarna trûfel', 'ماکارۆنای تڕوفێڵ', 52.00, 23, 0, true, false, false, true, 420, 'Italy', true),
('Lobster Thermidor', 'Lobster Thermidor', 'استاكوزا ثيرميدور', 'Lobster Termîdor', 'لۆبستەر تەرمیدۆر', 'Istavrit termidor', 'Lobster thermidor', 'استاكوزا ثيرميدور', 'Lobster termîdor', 'لۆبستەر تەرمیدۆر', 75.00, 23, 1, false, false, false, true, 550, 'France', true),
('Wagyu Beef', 'Wagyu Beef', 'لحم واغيو', 'Goshtê Wagyu', 'گۆشتێ واگیو', 'Wagyu eti', 'Wagyu beef', 'لحم واغيو', 'Goshtê wagyu', 'گۆشتێ واگیو', 85.00, 23, 0, false, false, true, true, 520, 'Japan', true),
('Foie Gras', 'Foie Gras', 'كبد أوز', 'Kûrê Qaz', 'کوڕێ قاز', 'Kaz ciğeri', 'Foie gras', 'كبد أوز', 'Kûrê qaz', 'کوڕێ قاز', 68.00, 23, 0, false, false, true, false, 450, 'France', true),
('Caviar Service', 'Caviar Service', 'خدمة كافيار', 'Xizmeta Kavyar', 'خزمەتە کاڤیار', 'Havyar servisi', 'Caviar service', 'خدمة كافيار', 'Xizmeta kavyar', 'خزمەتە کاڤیار', 120.00, 23, 0, false, false, true, false, 280, 'Russia', true),
('Truffle Risotto', 'Truffle Risotto', 'ريسوتو كمأة', 'Rîsotto Trûfel', 'ریسۆتۆ تڕوفێڵ', 'Trüf mantarlı risotto', 'Truffle risotto', 'ريسوتو كمأة', 'Rîsotto trûfel', 'ریسۆتۆ تڕوفێڵ', 58.00, 23, 0, true, false, false, true, 480, 'Italy', true),
('Chef Signature Dessert', 'Chef Signature Dessert', 'حلويات توقيع الشيف', 'Şîrînîya Îmzaya Şef', 'شیرینیی ئیمزای شێف', 'Şef imzalı tatlı', 'Chef signature dessert', 'حلويات توقيع الشيف', 'Şîrînîya îmzaya şef', 'شیرینیی ئیمزای شێف', 42.00, 23, 0, true, false, false, false, 380, 'France', true); 