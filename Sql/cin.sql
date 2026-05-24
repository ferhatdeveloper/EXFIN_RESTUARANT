-- EXFIN REST - Çin Mutfağı Kategorisi
-- Bu script Çin mutfağı kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 9);
DELETE FROM products WHERE category_id = 9;

-- =====================================================
-- ÇİN MUTFAĞI KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(9, 'Çin Mutfağı', 'Chinese Cuisine', 'المطبخ الصيني', 'Pêjgeha Çînî', 'پێشگەی چینی', 'Çin yemekleri', 'Chinese dishes', 'أطباق صينية', 'Xwarinên Çînî', 'خواردنە چینییەکان', 'ramen_dining', '#FF5722', 9, true)
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
-- ÇİN MUTFAĞI ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Kung Pao Tavuk', 'Kung Pao Chicken', 'دجاج كونغ باو', 'Mirîşka Kung Pao', 'مریشکی کۆنگ پاو', 'Acılı tavuk yemeği', 'Spicy chicken dish', 'طبق دجاج حار', 'Xwarina mirîşk ya tûj', 'خواردنی مریشک تۆژ', 42.00, 9, 3, false, false, true, true, 380, 'China', true),
('Tavuklu Noodle', 'Chicken Noodles', 'نودلز دجاج', 'Noodle bi Mirîşk', 'نۆدڵ بە مریشک', 'Tavuklu erişte', 'Chicken noodles', 'نودلز دجاج', 'Noodle bi mirîşk', 'نۆدڵ بە مریشک', 35.00, 9, 1, false, false, false, true, 320, 'China', true),
('Sebzeli Noodle', 'Vegetable Noodles', 'نودلز خضار', 'Noodle bi Sebzeyan', 'نۆدڵ بە سەوزەوات', 'Sebzeli erişte', 'Vegetable noodles', 'نودلز خضار', 'Noodle bi sebzeyan', 'نۆدڵ بە سەوزەوات', 28.00, 9, 0, true, true, false, true, 280, 'China', true),
('Peking Ördeği', 'Peking Duck', 'بطة بكين', 'Mîra Pekîng', 'میرای پەکینگ', 'Pekin ördeği', 'Peking duck', 'بطة بكين', 'Mîra Pekîng', 'میرای پەکینگ', 65.00, 9, 0, false, false, true, true, 450, 'China', true),
('Dim Sum', 'Dim Sum', 'ديم سوم', 'Dim Sum', 'دیم سۆم', 'Buharda pişmiş hamur işi', 'Steamed dumplings', 'زلابية مطبوخة بالبخار', 'Xwarina hevîrê biharî', 'خواردنی هەویری بەهار', 25.00, 9, 0, false, false, false, true, 200, 'China', true),
('Wonton Çorbası', 'Wonton Soup', 'حساء وونتون', 'Şorbaya Wonton', 'شۆربای ۆنتۆن', 'Wonton çorbası', 'Wonton soup', 'حساء وونتون', 'Şorbaya wonton', 'شۆربای ۆنتۆن', 30.00, 9, 0, false, false, false, true, 180, 'China', true),
('Kızarmış Pirinç', 'Fried Rice', 'أرز مقلي', 'Birincê Sorkirî', 'برنجی سۆرکر', 'Kızarmış pirinç', 'Fried rice', 'أرز مقلي', 'Birincê sorkirî', 'برنجی سۆرکر', 22.00, 9, 0, true, true, true, true, 250, 'China', true),
('Mapo Tofu', 'Mapo Tofu', 'ماپو توفو', 'Mapo Tofu', 'ماپۆ تۆفو', 'Acılı tofu yemeği', 'Spicy tofu dish', 'طبق توفو حار', 'Xwarina tofu ya tûj', 'خواردنی تۆفو تۆژ', 32.00, 9, 3, true, true, true, true, 220, 'China', true),
('Sweet and Sour Tavuk', 'Sweet and Sour Chicken', 'دجاج حلو وحامض', 'Mirîşka Şîrîn û Tirş', 'مریشکی شیرین و تڕش', 'Tatlı ekşi tavuk', 'Sweet and sour chicken', 'دجاج حلو وحامض', 'Mirîşka şîrîn û tirş', 'مریشکی شیرین و تڕش', 38.00, 9, 1, false, false, true, true, 350, 'China', true),
('Beef and Broccoli', 'Beef and Broccoli', 'لحم بقري وبروكلي', 'Goştê Çêl û Brokolî', 'گۆشتی چێل و برۆکۆلی', 'Dana eti ve brokoli', 'Beef and broccoli', 'لحم بقري وبروكلي', 'Goştê çêl û brokolî', 'گۆشتی چێل و برۆکۆلی', 45.00, 9, 1, false, false, true, true, 320, 'China', true),
('General Tso Tavuk', 'General Tso Chicken', 'دجاج جنرال تسو', 'Mirîşka General Tso', 'مریشکی جەنەراڵ تسۆ', 'General Tso tavuk', 'General Tso chicken', 'دجاج جنرال تسو', 'Mirîşka General Tso', 'مریشکی جەنەراڵ تسۆ', 40.00, 9, 2, false, false, true, true, 380, 'China', true),
('Orange Tavuk', 'Orange Chicken', 'دجاج برتقال', 'Mirîşka Porteqal', 'مریشکی پرتەقاڵ', 'Portakallı tavuk', 'Orange chicken', 'دجاج برتقال', 'Mirîşka porteqal', 'مریشکی پرتەقاڵ', 36.00, 9, 1, false, false, true, true, 340, 'China', true),
('Szechuan Tavuk', 'Szechuan Chicken', 'دجاج سيشوان', 'Mirîşka Szechuan', 'مریشکی سێچوان', 'Szechuan tavuk', 'Szechuan chicken', 'دجاج سيشوان', 'Mirîşka Szechuan', 'مریشکی سێچوان', 42.00, 9, 3, false, false, true, true, 360, 'China', true),
('Honey Tavuk', 'Honey Chicken', 'دجاج عسل', 'Mirîşka Hingiv', 'مریشکی ھەنگوین', 'Ballı tavuk', 'Honey chicken', 'دجاج عسل', 'Mirîşka hingiv', 'مریشکی ھەنگوین', 38.00, 9, 0, false, false, true, true, 330, 'China', true),
('Lemon Tavuk', 'Lemon Chicken', 'دجاج ليمون', 'Mirîşka Lîmon', 'مریشکی لیۆن', 'Limonlu tavuk', 'Lemon chicken', 'دجاج ليمون', 'Mirîşka lîmon', 'مریشکی لیۆن', 35.00, 9, 0, false, false, true, true, 310, 'China', true),
('Garlic Tavuk', 'Garlic Chicken', 'دجاج ثوم', 'Mirîşka Sîr', 'مریشکی سیر', 'Sarımsaklı tavuk', 'Garlic chicken', 'دجاج ثوم', 'Mirîşka sîr', 'مریشکی سیر', 34.00, 9, 1, false, false, true, true, 300, 'China', true),
('Cashew Tavuk', 'Cashew Chicken', 'دجاج كاجو', 'Mirîşka Kajû', 'مریشکی کەجو', 'Kaju fıstıklı tavuk', 'Cashew chicken', 'دجاج كاجو', 'Mirîşka kajû', 'مریشکی کەجو', 40.00, 9, 1, false, false, true, true, 350, 'China', true),
('Almond Tavuk', 'Almond Chicken', 'دجاج لوز', 'Mirîşka Badam', 'مریشکی بادەم', 'Bademli tavuk', 'Almond chicken', 'دجاج لوز', 'Mirîşka badam', 'مریشکی بادەم', 42.00, 9, 0, false, false, true, true, 370, 'China', true),
('Walnut Tavuk', 'Walnut Chicken', 'دجاج جوز', 'Mirîşka Gûz', 'مریشکی گووز', 'Cevizli tavuk', 'Walnut chicken', 'دجاج جوز', 'Mirîşka gûz', 'مریشکی گووز', 44.00, 9, 1, false, false, true, true, 380, 'China', true),
('Sesame Tavuk', 'Sesame Chicken', 'دجاج سمسم', 'Mirîşka Kuncît', 'مریشکی کونجیت', 'Susamlı tavuk', 'Sesame chicken', 'دجاج سمسم', 'Mirîşka kuncît', 'مریشکی کونجیت', 36.00, 9, 0, false, false, true, true, 320, 'China', true); 