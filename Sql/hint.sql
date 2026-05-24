-- EXFIN REST - Hint Mutfağı Kategorisi
-- Bu script Hint mutfağı kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 10);
DELETE FROM products WHERE category_id = 10;

-- =====================================================
-- HİNT MUTFAĞI KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(10, 'Hint Mutfağı', 'Indian Cuisine', 'المطبخ الهندي', 'Pêjgeha Hindî', 'پێشگەی هیندی', 'Hint yemekleri', 'Indian dishes', 'أطباق هندية', 'Xwarinên Hindî', 'خواردنە هیندییەکان', 'curry', '#FF9800', 10, true)
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
-- HİNT MUTFAĞI ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Butter Chicken', 'Butter Chicken', 'دجاج بالزبدة', 'Mirîşka Rûnê', 'مریشکی ڕوون', 'Tereyağlı tavuk', 'Butter chicken', 'دجاج بالزبدة', 'Mirîşka rûnê', 'مریشکی ڕوون', 45.00, 10, 2, false, false, true, true, 420, 'India', true),
('Tandoori Tavuk', 'Tandoori Chicken', 'دجاج تندوري', 'Mirîşka Tandoorî', 'مریشکی تەندۆری', 'Tandoor fırınında tavuk', 'Tandoor oven chicken', 'دجاج تندوري', 'Mirîşka firûnê tandoor', 'مریشکی فیرۆنی تەندۆر', 48.00, 10, 2, false, false, true, true, 380, 'India', true),
('Biryani', 'Biryani', 'برياني', 'Biryani', 'بیرانی', 'Baharatlı pirinç yemeği', 'Spiced rice dish', 'أرز بالبهارات', 'Xwarina birincê biharat', 'خواردنی برنج بەهارات', 38.00, 10, 2, false, false, true, true, 450, 'India', true),
('Palak Paneer', 'Palak Paneer', 'بالاك بانير', 'Palak Paneer', 'پاڵاک پانێر', 'Ispanaklı peynir', 'Spinach with cheese', 'سبانخ بالجبن', 'Sipînaş bi penîr', 'سپیناش بە پەنیر', 32.00, 10, 1, true, false, true, true, 280, 'India', true),
('Dal Makhani', 'Dal Makhani', 'دال مخاني', 'Dal Makhani', 'داڵ مەخانی', 'Mercimek yemeği', 'Lentil dish', 'طبق عدس', 'Xwarina nîsk', 'خواردنی نیسک', 28.00, 10, 1, true, true, true, true, 250, 'India', true),
('Naan', 'Naan', 'نان', 'Naan', 'نان', 'Hint ekmeği', 'Indian bread', 'خبز هندي', 'Nana Hindî', 'نانی هیندی', 8.00, 10, 0, true, true, false, true, 120, 'India', true),
('Raita', 'Raita', 'رايتا', 'Raita', 'ڕایەتا', 'Yoğurtlu sos', 'Yogurt sauce', 'صلصة زبادي', 'Sosa mast', 'سۆسای مەست', 12.00, 10, 0, true, true, true, false, 80, 'India', true),
('Gulab Jamun', 'Gulab Jamun', 'غولاب جامون', 'Gulab Jamun', 'گوڵاب جامون', 'Hint tatlısı', 'Indian dessert', 'حلويات هندية', 'Şîrînîya Hindî', 'شیرینی هیندی', 18.00, 10, 0, true, true, false, false, 200, 'India', true),
('Chicken Tikka Masala', 'Chicken Tikka Masala', 'دجاج تيكا ماسالا', 'Mirîşka Tikka Masala', 'مریشکی تیکا مەساڵا', 'Tikka masala tavuk', 'Chicken tikka masala', 'دجاج تيكا ماسالا', 'Mirîşka Tikka Masala', 'مریشکی تیکا مەساڵا', 42.00, 10, 2, false, false, true, true, 400, 'India', true),
('Lamb Curry', 'Lamb Curry', 'كاري لحم خروف', 'Kariya Goştê Mî', 'کەرییە گۆشتی می', 'Kuzu kari', 'Lamb curry', 'كاري لحم خروف', 'Kariya goştê mî', 'کەرییە گۆشتی می', 46.00, 10, 2, false, false, true, true, 420, 'India', true),
('Vegetable Curry', 'Vegetable Curry', 'كاري خضار', 'Kariya Sebzeyan', 'کەرییە سەوزەوات', 'Sebze kari', 'Vegetable curry', 'كاري خضار', 'Kariya sebzeyan', 'کەرییە سەوزەوات', 30.00, 10, 1, true, true, true, true, 280, 'India', true),
('Chicken Vindaloo', 'Chicken Vindaloo', 'دجاج فيندالو', 'Mirîşka Vindaloo', 'مریشکی ڤینداڵۆ', 'Acılı tavuk vindaloo', 'Spicy chicken vindaloo', 'دجاج فيندالو', 'Mirîşka Vindaloo ya tûj', 'مریشکی ڤینداڵۆ تۆژ', 44.00, 10, 3, false, false, true, true, 380, 'India', true),
('Rogan Josh', 'Rogan Josh', 'روغن جوش', 'Rogan Josh', 'ڕۆگان جۆش', 'Kuzu eti yemeği', 'Lamb dish', 'طبق لحم خروف', 'Xwarina goştê mî', 'خواردنی گۆشتی می', 48.00, 10, 2, false, false, true, true, 450, 'India', true),
('Chicken Korma', 'Chicken Korma', 'دجاج كورما', 'Mirîşka Korma', 'مریشکی کۆرما', 'Kremalı tavuk korma', 'Creamy chicken korma', 'دجاج كورما', 'Mirîşka Korma bi krem', 'مریشکی کۆرما بە کڕێم', 40.00, 10, 1, false, false, true, true, 360, 'India', true),
('Aloo Gobi', 'Aloo Gobi', 'آلو غوبي', 'Aloo Gobi', 'ئاڵۆ غۆبی', 'Patates ve karnabahar', 'Potato and cauliflower', 'بطاطس وقرنبيط', 'Kartol û gulkelem', 'کەرتۆڵ و گوڵکەڵەم', 26.00, 10, 1, true, true, true, true, 220, 'India', true),
('Chana Masala', 'Chana Masala', 'تشانا ماسالا', 'Chana Masala', 'چەنا مەساڵا', 'Nohut yemeği', 'Chickpea dish', 'طبق حمص', 'Xwarina nîsk', 'خواردنی نیسک', 24.00, 10, 1, true, true, true, true, 200, 'India', true),
('Samosa', 'Samosa', 'ساموسا', 'Samosa', 'سامۆسا', 'Kızarmış hamur işi', 'Fried pastry', 'معجنات مقلي', 'Xwarina hevîrê sorkirî', 'خواردنی هەویری سۆرکر', 16.00, 10, 1, true, true, false, true, 180, 'India', true),
('Pakora', 'Pakora', 'باكورا', 'Pakora', 'پاکۆرا', 'Sebze kızartması', 'Vegetable fritters', 'خضار مقلي', 'Sebzeyên sorkirî', 'سەوزەواتی سۆرکر', 18.00, 10, 1, true, true, false, true, 200, 'India', true),
('Kheer', 'Kheer', 'خير', 'Kheer', 'خێر', 'Sütlü tatlı', 'Milk dessert', 'حلويات حليب', 'Şîrînîya şîr', 'شیرینی شیر', 20.00, 10, 0, true, true, true, false, 250, 'India', true),
('Jalebi', 'Jalebi', 'جاليبي', 'Jalebi', 'جاڵەبی', 'Şerbetli tatlı', 'Syrup dessert', 'حلويات شراب', 'Şîrînîya şerbet', 'شیرینی شەربەت', 22.00, 10, 0, true, true, false, false, 280, 'India', true); 