-- EXFIN REST - Pizzalar Kategorisi
-- Bu script pizzalar kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 6);
DELETE FROM products WHERE category_id = 6;

-- =====================================================
-- PİZZALAR KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(6, 'Pizzalar', 'Pizzas', 'بيتزا', 'Pîzza', 'پیتزا', 'Pizza çeşitleri', 'Pizza varieties', 'بيتزا', 'Pîzza', 'پیتزا', 'local_pizza', '#F44336', 6, true)
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
-- PİZZALARI EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Margherita Pizza', 'Margherita Pizza', 'بيتزا مارجريتا', 'Pîzza Margherîta', 'پیتزای مارگەریتا', 'Domates, mozzarella, fesleğen', 'Tomato, mozzarella, basil', 'بيتزا مارجريتا', 'Pîzza margherîta', 'پیتزای مارگەریتا', 35.00, 6, 0, true, false, false, true, 280, 'Italy', true),
('Pepperoni Pizza', 'Pepperoni Pizza', 'بيتزا بيبروني', 'Pîzza Pepperonî', 'پیتزای پێپەرۆنی', 'Sucuk, mozzarella', 'Pepperoni, mozzarella', 'بيتزا بيبروني', 'Pîzza pepperonî', 'پیتزای پێپەرۆنی', 42.00, 6, 1, false, false, false, true, 320, 'USA', true),
('Quattro Formaggi', 'Quattro Formaggi', 'بيتزا أربعة أجبان', 'Pîzza Çar Penîr', 'پیتزای چار پەنیر', 'Dört peynirli pizza', 'Four cheese pizza', 'بيتزا أربعة أجبان', 'Pîzza çar penîr', 'پیتزای چار پەنیر', 45.00, 6, 0, true, false, false, true, 350, 'Italy', true),
('Hawaiian Pizza', 'Hawaiian Pizza', 'بيتزا هاواي', 'Pîzza Hawai', 'پیتزای ھاوای', 'Ananas, jambon, mozzarella', 'Pineapple, ham, mozzarella', 'بيتزا هاواي', 'Pîzza hawai', 'پیتزای ھاوای', 38.00, 6, 0, false, false, false, true, 300, 'Canada', true),
('BBQ Chicken Pizza', 'BBQ Chicken Pizza', 'بيتزا دجاج باربكيو', 'Pîzza Mirîşka BBQ', 'پیتزای مریشک باربیکیو', 'Barbekü soslu tavuk', 'BBQ chicken pizza', 'بيتزا دجاج باربكيو', 'Pîzza mirîşka BBQ', 'پیتزای مریشک باربیکیو', 40.00, 6, 1, false, false, false, true, 340, 'USA', true),
('Vegetarian Pizza', 'Vegetarian Pizza', 'بيتزا نباتية', 'Pîzza Nebatî', 'پیتزای نەباتی', 'Sebze pizza', 'Vegetarian pizza', 'بيتزا نباتية', 'Pîzza nebatî', 'پیتزای نەباتی', 36.00, 6, 0, true, false, false, true, 260, 'Italy', true),
('Supreme Pizza', 'Supreme Pizza', 'بيتزا سوبريم', 'Pîzza Supreme', 'پیتزای سۆپریم', 'Karışık malzemeli pizza', 'Supreme pizza', 'بيتزا سوبريم', 'Pîzza supreme', 'پیتزای سۆپریم', 48.00, 6, 1, false, false, false, true, 380, 'USA', true),
('Seafood Pizza', 'Seafood Pizza', 'بيتزا مأكولات بحرية', 'Pîzza Deryayî', 'پیتزای دەریایی', 'Deniz ürünlü pizza', 'Seafood pizza', 'بيتزا مأكولات بحرية', 'Pîzza deryayî', 'پیتزای دەریایی', 46.00, 6, 1, false, false, false, true, 360, 'Italy', true); 