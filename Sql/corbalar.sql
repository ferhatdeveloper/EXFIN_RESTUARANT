-- EXFIN REST - Çorbalar Kategorisi
-- Bu script çorbalar kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 26);
DELETE FROM products WHERE category_id = 26;

-- =====================================================
-- ÇORBALAR KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(26, 'Çorbalar', 'Soups', 'شوربات', 'Şorba', 'شۆربە', 'Çorba çeşitleri', 'Soup varieties', 'شوربات', 'Şorba', 'شۆربە', 'soup_kitchen', '#FF9800', 26, true)
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
-- ÇORBALARI EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Tomato Soup', 'Tomato Soup', 'شوربة طماطم', 'Şorba Tûm', 'شۆربەی تۆم', 'Domates çorbası', 'Tomato soup', 'شوربة طماطم', 'Şorba tûm', 'شۆربەی تۆم', 18.00, 26, 0, true, true, true, true, 120, 'Italy', true),
('Chicken Noodle Soup', 'Chicken Noodle Soup', 'شوربة دجاج ونودلز', 'Şorba Mirîşk û Nûdel', 'شۆربەی مریشک و نۆدەڵ', 'Tavuk şehriye çorbası', 'Chicken noodle soup', 'شوربة دجاج ونودلز', 'Şorba mirîşk û nûdel', 'شۆربەی مریشک و نۆدەڵ', 22.00, 26, 0, false, false, false, true, 180, 'China', true),
('Mushroom Soup', 'Mushroom Soup', 'شوربة فطر', 'Şorba Kûvark', 'شۆربەی کوڤەرک', 'Mantar çorbası', 'Mushroom soup', 'شوربة فطر', 'Şorba kûvark', 'شۆربەی کوڤەرک', 20.00, 26, 0, true, true, true, true, 140, 'France', true),
('Lentil Soup', 'Lentil Soup', 'شوربة عدس', 'Şorba Nîsk', 'شۆربەی نیسک', 'Mercimek çorbası', 'Lentil soup', 'شوربة عدس', 'Şorba nîsk', 'شۆربەی نیسک', 16.00, 26, 0, true, true, true, true, 160, 'Turkey', true),
('French Onion Soup', 'French Onion Soup', 'شوربة بصل فرنسية', 'Şorba Pîvaz Fransî', 'شۆربەی پیواز فرەنسی', 'Fransız soğan çorbası', 'French onion soup', 'شوربة بصل فرنسية', 'Şorba pîvaz fransî', 'شۆربەی پیواز فرەنسی', 24.00, 26, 0, true, false, false, true, 200, 'France', true),
('Minestrone Soup', 'Minestrone Soup', 'شوربة مينسترون', 'Şorba Mînîstron', 'شۆربەی مینسترۆن', 'İtalyan sebze çorbası', 'Minestrone soup', 'شوربة مينسترون', 'Şorba mînîstron', 'شۆربەی مینسترۆن', 20.00, 26, 0, true, true, true, true, 180, 'Italy', true),
('Clam Chowder', 'Clam Chowder', 'شوربة محار', 'Şorba Midye', 'شۆربەی میدیە', 'Midye çorbası', 'Clam chowder', 'شوربة محار', 'Şorba midye', 'شۆربەی میدیە', 26.00, 26, 0, false, false, false, true, 220, 'USA', true),
('Gazpacho', 'Gazpacho', 'غزباتشو', 'Gazpaço', 'گەزپەچۆ', 'Soğuk domates çorbası', 'Cold tomato soup', 'غزباتشو', 'Gazpaço', 'گەزپەچۆ', 18.00, 26, 0, true, true, true, false, 100, 'Spain', true); 