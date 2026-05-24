-- EXFIN REST - İtalyan Mutfağı Kategorisi
-- Bu script İtalyan mutfağı kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 8);
DELETE FROM products WHERE category_id = 8;

-- =====================================================
-- İTALYAN MUTFAĞI KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(8, 'İtalyan Mutfağı', 'Italian Cuisine', 'المطبخ الإيطالي', 'Pêjgeha Îtalî', 'پێشگەی ئیتاڵی', 'İtalyan yemekleri', 'Italian dishes', 'أطباق إيطالية', 'Xwarinên Îtalî', 'خواردنە ئیتاڵییەکان', 'pizza', '#F44336', 8, true)
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
-- İTALYAN MUTFAĞI ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Spaghetti Carbonara', 'Spaghetti Carbonara', 'سباغيتي كاربونارا', 'Spaghetti Carbonara', 'سپاگەتی کاربۆنارا', 'Yumurta, peynir, pastırma', 'Egg, cheese, bacon', 'بيض وجبن وبيكون', 'Hêlke, penîr, pastirma', 'هێلکە، پەنیر، پاسترما', 38.00, 8, 0, false, false, false, true, 420, 'Italy', true),
('Penne Arrabbiata', 'Penne Arrabbiata', 'بيني أرابياتا', 'Penne Arrabbiata', 'پێنەی ئەرەبیاتا', 'Acılı domates sosu', 'Spicy tomato sauce', 'صلصة طماطم حارة', 'Sosa bacanaş ya tûj', 'سۆسای باژەنگ تۆژ', 32.00, 8, 2, true, true, false, true, 350, 'Italy', true),
('Risotto ai Funghi', 'Mushroom Risotto', 'ريسوتو بالفطر', 'Risotto bi Kûvark', 'ریسۆتۆ بە کەوەرک', 'Mantar risottosu', 'Mushroom risotto', 'ريسوتو بالفطر', 'Risotto bi kûvark', 'ریسۆتۆ بە کەوەرک', 36.00, 8, 0, true, false, false, true, 380, 'Italy', true),
('Lasagna', 'Lasagna', 'لازانيا', 'Lasagna', 'لازانیا', 'Katmanlı makarna', 'Layered pasta', 'معكرونة مطبقة', 'Makarnaya tewşî', 'ماکارۆنی تەوشی', 42.00, 8, 0, false, false, false, true, 450, 'Italy', true),
('Osso Buco', 'Osso Buco', 'أوسو بوكو', 'Osso Buco', 'ئۆسۆ بۆکۆ', 'Dana incik yemeği', 'Veal shank dish', 'طبق عجل', 'Xwarina goştê golikê', 'خواردنی گۆشتی گۆلک', 48.00, 8, 1, false, false, true, true, 520, 'Italy', true),
('Tiramisu', 'Tiramisu', 'تيراميسو', 'Tiramisu', 'تیڕامیسو', 'İtalyan tatlısı', 'Italian dessert', 'حلويات إيطالية', 'Şîrînîya Îtalî', 'شیرینی ئیتاڵی', 25.00, 8, 0, true, false, false, false, 280, 'Italy', true),
('Bruschetta', 'Bruschetta', 'بروشيتا', 'Bruschetta', 'بڕۆشێتا', 'Tost ekmek üzerine domates', 'Tomato on toasted bread', 'طماطم على خبز محمص', 'Bacanaş li ser nanê biraştî', 'باژەنگ لەسەر نانی براژت', 18.00, 8, 0, true, true, false, false, 120, 'Italy', true),
('Minestrone', 'Minestrone', 'مينسترون', 'Minestrone', 'مینەسترۆنە', 'Sebze çorbası', 'Vegetable soup', 'حساء خضار', 'Şorbaya sebzeyan', 'شۆربای سەوزەوات', 28.00, 8, 0, true, true, true, true, 200, 'Italy', true),
('Pizza Margherita', 'Pizza Margherita', 'بيتزا مارجريتا', 'Pîzza Margherita', 'پیتزا ماڕگەریتا', 'Domates, mozzarella, fesleğen', 'Tomato, mozzarella, basil', 'طماطم وموزاريلا وريحان', 'Bacanaş, mozzarella, reyhan', 'باژەنگ، مۆزەرێلا، ڕەیحان', 35.00, 8, 0, true, false, false, true, 300, 'Italy', true),
('Pizza Quattro Stagioni', 'Pizza Quattro Stagioni', 'بيتزا كواترو ستاجيوني', 'Pîzza Quattro Stagioni', 'پیتزا کواترۆ ستاگیۆنی', 'Dört mevsim pizza', 'Four seasons pizza', 'بيتزا أربع فصول', 'Pîzza çar demsal', 'پیتزای چوار دەمساڵ', 40.00, 8, 0, false, false, false, true, 350, 'Italy', true),
('Pizza Diavola', 'Pizza Diavola', 'بيتزا ديافولا', 'Pîzza Diavola', 'پیتزا دیاڤۆلا', 'Acılı salam pizza', 'Spicy salami pizza', 'بيتزا سلامي حار', 'Pîzza salam ya tûj', 'پیتزای سەلام تۆژ', 38.00, 8, 2, false, false, false, true, 380, 'Italy', true),
('Fettuccine Alfredo', 'Fettuccine Alfredo', 'فتوتشيني ألفريدو', 'Fettuccine Alfredo', 'فەتۆچینە ئەلفرێدۆ', 'Kremalı makarna', 'Creamy pasta', 'معكرونة بالكريمة', 'Makarnaya kremî', 'ماکارۆنی کڕێمی', 36.00, 8, 0, true, false, false, true, 400, 'Italy', true),
('Gnocchi', 'Gnocchi', 'نيوكي', 'Gnocchi', 'نیۆکی', 'Patates hamuru', 'Potato dumplings', 'زلابية بطاطس', 'Xwarina kartolê', 'خواردنی کەرتۆڵ', 32.00, 8, 0, true, true, false, true, 280, 'Italy', true),
('Panna Cotta', 'Panna Cotta', 'بانا كوتا', 'Panna Cotta', 'پانە کۆتا', 'İtalyan tatlısı', 'Italian dessert', 'حلويات إيطالية', 'Şîrînîya Îtalî', 'شیرینی ئیتاڵی', 22.00, 8, 0, true, false, false, false, 200, 'Italy', true),
('Gelato', 'Gelato', 'جيلاتو', 'Gelato', 'گێلاتۆ', 'İtalyan dondurması', 'Italian ice cream', 'آيس كريم إيطالي', 'Dondurmayê Îtalî', 'دۆندوورمای ئیتاڵی', 18.00, 8, 0, true, true, true, false, 150, 'Italy', true),
('Cannoli', 'Cannoli', 'كانولي', 'Cannoli', 'کانۆلی', 'Krema dolgulu hamur', 'Cream-filled pastry', 'معجنات محشوة بالكريمة', 'Xwarina hevîrê dagirtî bi krem', 'خواردنی هەویری دەگرت بە کڕێم', 20.00, 8, 0, true, false, false, false, 220, 'Italy', true),
('Arancini', 'Arancini', 'أرانشيني', 'Arancini', 'ئەرانچینی', 'Kızarmış pirinç topları', 'Fried rice balls', 'كرات ب أرز مقلي', 'Gogên birincê sorkirî', 'گۆگەنی برنجی سۆرکر', 25.00, 8, 0, false, false, false, true, 300, 'Italy', true),
('Caprese Salad', 'Caprese Salad', 'سلطة كابريزي', 'Salataya Caprese', 'سەلاتەی کاپرێزە', 'Mozzarella, domates, fesleğen', 'Mozzarella, tomato, basil', 'موزاريلا وطماطم وريحان', 'Mozzarella, bacanaş, reyhan', 'مۆزەرێلا، باژەنگ، ڕەیحان', 30.00, 8, 0, true, false, true, false, 180, 'Italy', true),
('Truffle Pasta', 'Truffle Pasta', 'معكرونة ترفل', 'Makarnaya Trûfel', 'ماکارۆنی تڕوفەڵ', 'Trüf mantarlı makarna', 'Truffle pasta', 'معكرونة بالفطر الأسود', 'Makarnaya bi kûvarkê reş', 'ماکارۆنی بە کەوەرکی ڕەش', 45.00, 8, 0, true, false, false, true, 350, 'Italy', true); 