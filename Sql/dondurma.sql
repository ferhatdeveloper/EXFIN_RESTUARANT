-- EXFIN REST - Dondurma Kategorisi
-- Bu script dondurma kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 4);
DELETE FROM products WHERE category_id = 4;

-- =====================================================
-- DONDURMA KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(4, 'Dondurma', 'Ice Cream', 'آيس كريم', 'Dondurma', 'دۆندوڕما', 'Dondurma çeşitleri', 'Ice cream varieties', 'آيس كريم', 'Dondurma', 'دۆندوڕما', 'icecream', '#00BCD4', 4, true)
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
-- DONDURMA ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Vanilla Ice Cream', 'Vanilla Ice Cream', 'آيس كريم فانيليا', 'Dondurma Vanîlya', 'دۆندوڕمای ڤەنیلیا', 'Vanilyalı dondurma', 'Vanilla ice cream', 'آيس كريم فانيليا', 'Dondurma vanîlya', 'دۆندوڕمای ڤەنیلیا', 18.00, 4, 0, true, false, true, false, 200, 'USA', true),
('Chocolate Ice Cream', 'Chocolate Ice Cream', 'آيس كريم شوكولاتة', 'Dondurma Çîkolata', 'دۆندوڕمای چیکۆلاتە', 'Çikolatalı dondurma', 'Chocolate ice cream', 'آيس كريم شوكولاتة', 'Dondurma çîkolata', 'دۆندوڕمای چیکۆلاتە', 20.00, 4, 0, true, false, true, false, 220, 'USA', true),
('Strawberry Ice Cream', 'Strawberry Ice Cream', 'آيس كريم فراولة', 'Dondurma Tûtî', 'دۆندوڕمای توتی', 'Çilekli dondurma', 'Strawberry ice cream', 'آيس كريم فراولة', 'Dondurma tûtî', 'دۆندوڕمای توتی', 22.00, 4, 0, true, false, true, false, 210, 'USA', true),
('Mint Chocolate Chip', 'Mint Chocolate Chip', 'آيس كريم نعناع', 'Dondurma Pûng û Çîkolata', 'دۆندوڕمای پوونگ و چیکۆلاتە', 'Nane çikolatalı dondurma', 'Mint chocolate chip', 'آيس كريم نعناع', 'Dondurma pûng û çîkolata', 'دۆندوڕمای پوونگ و چیکۆلاتە', 24.00, 4, 0, true, false, true, false, 240, 'USA', true),
('Cookie Dough Ice Cream', 'Cookie Dough Ice Cream', 'آيس كريم عجينة بسكويت', 'Dondurma Hevîrê Biskût', 'دۆندوڕمای هەڤیرێ بەسکویت', 'Kurabiye hamurlu dondurma', 'Cookie dough ice cream', 'آيس كريم عجينة بسكويت', 'Dondurma hevîrê biskût', 'دۆندوڕمای هەڤیرێ بەسکویت', 26.00, 4, 0, true, false, false, false, 280, 'USA', true),
('Rocky Road', 'Rocky Road', 'آيس كريم روكي رود', 'Dondurma Rocky Road', 'دۆندوڕمای ڕۆکی ڕۆد', 'Fındık çikolatalı dondurma', 'Rocky road ice cream', 'آيس كريم روكي رود', 'Dondurma rocky road', 'دۆندوڕمای ڕۆکی ڕۆد', 28.00, 4, 0, true, false, false, false, 300, 'USA', true),
('Coffee Ice Cream', 'Coffee Ice Cream', 'آيس كريم قهوة', 'Dondurma Qehwe', 'دۆندوڕمای قەهوە', 'Kahveli dondurma', 'Coffee ice cream', 'آيس كريم قهوة', 'Dondurma qehwe', 'دۆندوڕمای قەهوە', 22.00, 4, 0, true, false, true, false, 230, 'Italy', true),
('Butter Pecan', 'Butter Pecan', 'آيس كريم جوز هندي', 'Dondurma Pêkan', 'دۆندوڕمای پێکان', 'Cevizli dondurma', 'Butter pecan ice cream', 'آيس كريم جوز هندي', 'Dondurma pêkan', 'دۆندوڕمای پێکان', 26.00, 4, 0, true, false, true, false, 260, 'USA', true); 