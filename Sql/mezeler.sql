-- EXFIN REST - Mezeler Kategorisi
-- Bu script mezeler kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 27);
DELETE FROM products WHERE category_id = 27;

-- =====================================================
-- MEZELER KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(27, 'Mezeler', 'Appetizers', 'مقبلات', 'Meze', 'مەزە', 'Meze çeşitleri', 'Appetizer varieties', 'مقبلات', 'Meze', 'مەزە', 'tapas', '#9C27B0', 27, true)
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
-- MEZELERİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Hummus', 'Hummus', 'حمص', 'Humus', 'حومس', 'Nohut ezmesi', 'Chickpea dip', 'حمص', 'Humus', 'حومس', 16.00, 27, 0, true, true, true, false, 166, 'Lebanon', true),
('Baba Ganoush', 'Baba Ganoush', 'بابا غنوج', 'Baba Ganoj', 'بابا غەنۆج', 'Patlıcan ezmesi', 'Eggplant dip', 'بابا غنوج', 'Baba ganoj', 'بابا غەنۆج', 18.00, 27, 0, true, true, true, false, 150, 'Lebanon', true),
('Falafel', 'Falafel', 'فلافل', 'Falafel', 'فەلافەل', 'Nohut köftesi', 'Chickpea fritters', 'فلافل', 'Falafel', 'فەلافەل', 20.00, 27, 1, true, true, false, true, 333, 'Egypt', true),
('Tzatziki', 'Tzatziki', 'تزاتزيكي', 'Tzatzikî', 'تزەتزیکی', 'Yoğurt sosu', 'Yogurt sauce', 'تزاتزيكي', 'Tzatzikî', 'تزەتزیکی', 14.00, 27, 0, true, true, true, false, 120, 'Greece', true),
('Dolmades', 'Dolmades', 'دولماديس', 'Dolmade', 'دۆڵمەدە', 'Asma yaprağı sarması', 'Grape leaf rolls', 'دولماديس', 'Dolmade', 'دۆڵمەدە', 22.00, 27, 0, true, true, true, false, 180, 'Greece', true),
('Spanakopita', 'Spanakopita', 'سباناكوبيتا', 'Spanakopîta', 'سپەناکۆپیتا', 'Ispanaklı börek', 'Spinach pie', 'سباناكوبيتا', 'Spanakopîta', 'سپەناکۆپیتا', 24.00, 27, 0, true, false, false, false, 320, 'Greece', true),
('Calamari', 'Calamari', 'كالاماري', 'Kalamarî', 'کەڵەمەری', 'Kızarmış kalamar', 'Fried calamari', 'كالاماري', 'Kalamarî sorkirî', 'کەڵەمەری سۆرکر', 28.00, 27, 1, false, false, false, true, 200, 'Greece', true),
('Bruschetta', 'Bruschetta', 'بروشيتا', 'Bruşetta', 'بروشەتە', 'Domatesli tost', 'Tomato bruschetta', 'بروشيتا', 'Bruşetta', 'بروشەتە', 16.00, 27, 0, true, true, false, false, 140, 'Italy', true); 