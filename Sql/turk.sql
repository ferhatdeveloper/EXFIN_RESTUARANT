-- EXFIN REST - Türk Mutfağı Kategorisi
-- Bu script Türk mutfağı kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 7);
DELETE FROM products WHERE category_id = 7;

-- =====================================================
-- TÜRK MUTFAĞI KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(7, 'Türk Mutfağı', 'Turkish Cuisine', 'المطبخ التركي', 'Pêjgeha Tirkî', 'پێشگەی تورکی', 'Geleneksel Türk yemekleri', 'Traditional Turkish dishes', 'أطباق تركية تقليدية', 'Xwarinên kevneşopî yên Tirkî', 'خواردنە کۆنەپارێزە تورکییەکان', 'restaurant', '#E91E63', 7, true)
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
-- TÜRK MUTFAĞI ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('İskender Kebap', 'Iskender Kebab', 'إسكندر كباب', 'Îskender Kebab', 'ئیسکەندەر کەباب', 'Döner et, yoğurt, domates sosu', 'Doner meat, yogurt, tomato sauce', 'لحم دوينر وزبادي وصلصة طماطم', 'Goştê doner, mast, sosa bacanaş', 'گۆشتی دۆنەر، مەست، سۆسای باژەنگ', 45.00, 7, 1, false, false, true, true, 350, 'Turkey', true),
('Adana Kebap', 'Adana Kebab', 'أضنة كباب', 'Adana Kebab', 'ئەدانە کەباب', 'Acılı kıyma kebap', 'Spicy minced meat kebab', 'كباب لحم مفروم حار', 'Kebabê goştê hûrkirî ya tûj', 'کەبابی گۆشتی هەڵکوتراوەی تۆژ', 42.00, 7, 3, false, false, true, true, 380, 'Turkey', true),
('Urfa Kebap', 'Urfa Kebab', 'أورفا كباب', 'Riha Kebab', 'ئورفە کەباب', 'Az acılı kıyma kebap', 'Mild minced meat kebab', 'كباب لحم مفروم معتدل', 'Kebabê goştê hûrkirî ya nerm', 'کەبابی گۆشتی هەڵکوتراوەی نەرم', 40.00, 7, 1, false, false, true, true, 360, 'Turkey', true),
('Pide', 'Pide', 'بيضة', 'Pîde', 'پیدە', 'Türk pizzası', 'Turkish pizza', 'بيتزا تركية', 'Pîzzaya Tirkî', 'پیتزای تورکی', 35.00, 7, 0, false, false, false, true, 280, 'Turkey', true),
('Lahmacun', 'Lahmacun', 'لحم بعجين', 'Lahmacûn', 'لەحمەجون', 'İnce hamur üzerine kıyma', 'Minced meat on thin dough', 'لحم مفروم على عجين رقيق', 'Goştê hûrkirî li ser hevîrê tenik', 'گۆشتی هەڵکوتراوە لەسەر هەویری تەنک', 25.00, 7, 1, false, false, false, true, 220, 'Turkey', true),
('Mantı', 'Manti', 'منتو', 'Mantî', 'مەنتی', 'Küçük hamur parçaları', 'Small dough pieces', 'قطع عجين صغيرة', 'Parçeyên hevîrê biçûk', 'پارچەکانی هەویری بچووک', 30.00, 7, 0, false, false, false, true, 250, 'Turkey', true),
('Karnıyarık', 'Karniyarik', 'كرني يرك', 'Karnîyarik', 'کەرنی یەریک', 'Patlıcan dolması', 'Stuffed eggplant', 'باذنجان محشي', 'Bacanaşê dagirtî', 'باژەنگی دەگرت', 28.00, 7, 1, true, false, true, true, 200, 'Turkey', true),
('İmambayıldı', 'Imam Bayildi', 'إمام بايلدي', 'Îmam Bayildî', 'ئیمام بەیڵدی', 'Patlıcan yemeği', 'Eggplant dish', 'طبق باذنجان', 'Xwarina bacanaş', 'خواردنی باژەنگ', 26.00, 7, 0, true, true, true, true, 180, 'Turkey', true),
('Döner', 'Doner', 'دونر', 'Doner', 'دۆنەر', 'Döner et', 'Doner meat', 'لحم دوينر', 'Goştê doner', 'گۆشتی دۆنەر', 35.00, 7, 0, false, false, true, true, 300, 'Turkey', true),
('Kuzu Pirzola', 'Lamb Chops', 'قطع لحم خروف', 'Kuzu Pîrzola', 'کوزو پیرزۆلا', 'Kuzu pirzola', 'Lamb chops', 'قطع لحم خروف', 'Kuzu pîrzola', 'کوزو پیرزۆلا', 55.00, 7, 0, false, false, true, true, 450, 'Turkey', true),
('Tavuk Şiş', 'Chicken Shish', 'سيخ دجاج', 'Mirîşka Şîş', 'مریشکی شیش', 'Tavuk şiş', 'Chicken shish', 'سيخ دجاج', 'Mirîşka şîş', 'مریشکی شیش', 38.00, 7, 1, false, false, true, true, 320, 'Turkey', true),
('Kuzu Şiş', 'Lamb Shish', 'سيخ خروف', 'Kuzu Şîş', 'کوزو شیش', 'Kuzu şiş', 'Lamb shish', 'سيخ خروف', 'Kuzu şîş', 'کوزو شیش', 45.00, 7, 1, false, false, true, true, 380, 'Turkey', true),
('Köfte', 'Meatballs', 'كفتة', 'Kifte', 'کفتە', 'Kıyma köfte', 'Minced meat meatballs', 'كفتة لحم مفروم', 'Kifte goştê hûrkirî', 'کفتەی گۆشتی هەڵکوتراوە', 32.00, 7, 1, false, false, true, true, 280, 'Turkey', true),
('Hünkar Beğendi', 'Hunkar Begendi', 'هونكار بغندي', 'Hunkar Begendî', 'ھونکار بەگەندی', 'Patlıcan püresi', 'Eggplant puree', 'هريس باذنجان', 'Pûrê bacanaş', 'پووری باژەنگ', 30.00, 7, 0, true, false, true, true, 220, 'Turkey', true),
('Dolma', 'Stuffed Vegetables', 'محشي', 'Dolma', 'دۆڵما', 'Sebze dolması', 'Stuffed vegetables', 'خضار محشي', 'Sebzeyên dagirtî', 'سەوزەواتی دەگرت', 28.00, 7, 0, true, true, true, true, 200, 'Turkey', true),
('Sarma', 'Stuffed Grape Leaves', 'ورق عنب محشي', 'Sarma', 'سەرما', 'Asma yaprağı sarması', 'Stuffed grape leaves', 'ورق عنب محشي', 'Pelên tîrê dagirtî', 'پەڵی تیری دەگرت', 25.00, 7, 0, true, true, true, true, 180, 'Turkey', true),
('Börek', 'Borek', 'بوريك', 'Borek', 'بۆرەک', 'Hamur işi', 'Pastry', 'معجنات', 'Xwarina hevîrê', 'خواردنی هەویر', 20.00, 7, 0, false, false, false, true, 250, 'Turkey', true),
('Gözleme', 'Gozleme', 'غوزلامة', 'Gözleme', 'گۆزلەمە', 'El açması hamur', 'Hand-rolled dough', 'عجين مفتول يدويا', 'Hevîrê destan', 'هەویری دەست', 18.00, 7, 0, false, false, false, true, 200, 'Turkey', true),
('Menemen', 'Menemen', 'منمن', 'Menemen', 'مەنەمەن', 'Domates, yumurta, biber', 'Tomato, egg, pepper', 'طماطم وبيض وفلفل', 'Bacanaş, hêlke, bîber', 'باژەنگ، هێلکە، بیبەر', 22.00, 7, 1, false, false, true, true, 180, 'Turkey', true),
('Kısır', 'Kisir', 'كسير', 'Kîsîr', 'کیسیر', 'Bulgur salatası', 'Bulgur salad', 'سلطة برغل', 'Salataya bulgur', 'سەلاتەی بۆڵگور', 20.00, 7, 1, true, true, true, false, 150, 'Turkey', true),
('Mercimek Köftesi', 'Lentil Balls', 'كفتة عدس', 'Kifteya Nîsk', 'کفتەی نیسک', 'Mercimek köftesi', 'Lentil balls', 'كفتة عدس', 'Kifteya nîsk', 'کفتەی نیسک', 18.00, 7, 1, true, true, true, false, 160, 'Turkey', true); 