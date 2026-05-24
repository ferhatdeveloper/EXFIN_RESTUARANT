-- EXFIN REST - Japon Mutfağı Kategorisi
-- Bu script Japon mutfağı kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 11);
DELETE FROM products WHERE category_id = 11;

-- =====================================================
-- JAPON MUTFAĞI KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(11, 'Japon Mutfağı', 'Japanese Cuisine', 'المطبخ الياباني', 'Pêjgeha Japonî', 'پێشگەی ژاپۆنی', 'Japon yemekleri', 'Japanese dishes', 'أطباق يابانية', 'Xwarinên Japonî', 'خواردنە ژاپۆنییەکان', 'sushi', '#3F51B5', 11, true)
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
-- JAPON MUTFAĞI ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Sushi Roll', 'Sushi Roll', 'سوشي رول', 'Sushi Roll', 'سۆشی ڕۆڵ', 'Çeşitli sushi roll', 'Various sushi roll', 'سوشي رول متنوع', 'Sushi roll cureyên cuda', 'سۆشی ڕۆڵ جۆرەکانی جیاواز', 35.00, 11, 0, false, false, true, false, 250, 'Japan', true),
('Nigiri Sushi', 'Nigiri Sushi', 'نيجيري سوشي', 'Nigiri Sushi', 'نیجیری سۆشی', 'Balık sushi', 'Fish sushi', 'سوشي سمك', 'Sushi masî', 'سۆشی ماسی', 28.00, 11, 0, false, false, true, false, 180, 'Japan', true),
('Maki Sushi', 'Maki Sushi', 'ماكي سوشي', 'Maki Sushi', 'ماکی سۆشی', 'Yuvarlak sushi', 'Round sushi', 'سوشي دائري', 'Sushi gogî', 'سۆشی گۆگ', 32.00, 11, 0, false, false, true, false, 220, 'Japan', true),
('Sashimi', 'Sashimi', 'ساشيمي', 'Sashimi', 'ساشیمی', 'Çiğ balık dilimleri', 'Raw fish slices', 'شرائح سمك نيء', 'Parçeyên masî xav', 'پارچەکانی ماسی خاو', 45.00, 11, 0, false, false, true, false, 150, 'Japan', true),
('Tempura', 'Tempura', 'تمبورا', 'Tempura', 'تەمپورا', 'Kızarmış sebze/deniz ürünü', 'Fried vegetables/seafood', 'خضار ومأكولات بحرية مقلي', 'Sebzeyên sorkirî/xwarinên deryayî', 'سەوزەوات/خواردنە دەریایییە سۆرکرەکان', 38.00, 11, 0, true, true, false, true, 300, 'Japan', true),
('Ramen', 'Ramen', 'رامن', 'Ramen', 'ڕامەن', 'Erişte çorbası', 'Noodle soup', 'حساء نودلز', 'Şorbaya noodle', 'شۆربای نۆدڵ', 42.00, 11, 1, false, false, false, true, 400, 'Japan', true),
('Udon', 'Udon', 'أودون', 'Udon', 'ئۆدۆن', 'Kalın erişte', 'Thick noodles', 'نودلز سميك', 'Noodle stûr', 'نۆدڵ ستوور', 36.00, 11, 0, false, false, false, true, 350, 'Japan', true),
('Soba', 'Soba', 'سوبا', 'Soba', 'سۆبا', 'Karabuğday eriştesi', 'Buckwheat noodles', 'نودلز حنطة سوداء', 'Noodle gêzika reş', 'نۆدڵ گێزکەی ڕەش', 34.00, 11, 0, true, true, false, true, 320, 'Japan', true),
('Teriyaki Tavuk', 'Teriyaki Chicken', 'دجاج تريياكي', 'Mirîşka Teriyaki', 'مریشکی تەرییاکی', 'Teriyaki soslu tavuk', 'Teriyaki sauce chicken', 'دجاج بصلصة تريياكي', 'Mirîşka bi sosa Teriyaki', 'مریشکی بە سۆسای تەرییاکی', 40.00, 11, 1, false, false, true, true, 380, 'Japan', true),
('Yakitori', 'Yakitori', 'ياكيتوري', 'Yakitori', 'یاکیتۆری', 'Izgara tavuk şiş', 'Grilled chicken skewers', 'سيخ دجاج مشوي', 'Mirîşka şîş ya biraştî', 'مریشکی شیشی براژت', 35.00, 11, 1, false, false, true, true, 320, 'Japan', true),
('Gyoza', 'Gyoza', 'غيوزا', 'Gyoza', 'گیۆزا', 'Japon mantısı', 'Japanese dumplings', 'زلابية يابانية', 'Mantîyên Japonî', 'مەنتییە ژاپۆنییەکان', 25.00, 11, 0, false, false, false, true, 200, 'Japan', true),
('Miso Çorbası', 'Miso Soup', 'حساء ميسو', 'Şorbaya Miso', 'شۆربای میسۆ', 'Miso çorbası', 'Miso soup', 'حساء ميسو', 'Şorbaya miso', 'شۆربای میسۆ', 18.00, 11, 0, true, true, true, true, 120, 'Japan', true),
('Onigiri', 'Onigiri', 'أونيجيري', 'Onigiri', 'ئۆنیجیری', 'Pirinç topu', 'Rice ball', 'كرة أرز', 'Gogê birincê', 'گۆگەی برنج', 15.00, 11, 0, true, true, true, false, 150, 'Japan', true),
('Takoyaki', 'Takoyaki', 'تاكوياكي', 'Takoyaki', 'تاکۆیاکی', 'Ahtapot topu', 'Octopus ball', 'كرة أخطبوط', 'Gogê heştpiyê', 'گۆگەی ھەشتپێ', 22.00, 11, 0, false, false, false, true, 180, 'Japan', true),
('Okonomiyaki', 'Okonomiyaki', 'أوكونومياكي', 'Okonomiyaki', 'ئۆکۆنۆمیاکی', 'Japon pizzası', 'Japanese pizza', 'بيتزا يابانية', 'Pîzzaya Japonî', 'پیتزای ژاپۆنی', 30.00, 11, 0, false, false, false, true, 350, 'Japan', true),
('Tonkatsu', 'Tonkatsu', 'تونكاتسو', 'Tonkatsu', 'تۆنکاتسو', 'Kızarmış domuz pirzola', 'Fried pork cutlet', 'قطع لحم خنزير مقلي', 'Pîrzolaya berazê sorkirî', 'پیرزۆلای بەرازی سۆرکر', 38.00, 11, 0, false, false, false, true, 420, 'Japan', true),
('Katsudon', 'Katsudon', 'كاتسودون', 'Katsudon', 'کاتسۆدۆن', 'Pirinç üzerine tonkatsu', 'Rice with tonkatsu', 'أرز مع تونكاتسو', 'Birinc bi Tonkatsu', 'برنج بە تۆنکاتسو', 36.00, 11, 0, false, false, false, true, 450, 'Japan', true),
('Oyakodon', 'Oyakodon', 'أويادون', 'Oyakodon', 'ئۆیاکۆدۆن', 'Tavuk ve yumurta', 'Chicken and egg', 'دجاج وبيض', 'Mirîşk û hêlke', 'مریشک و هێلکە', 32.00, 11, 0, false, false, true, true, 380, 'Japan', true),
('Karaage', 'Karaage', 'كاراجي', 'Karaage', 'کاراگە', 'Japon tavuk kızartması', 'Japanese fried chicken', 'دجاج مقلي ياباني', 'Mirîşka sorkirî ya Japonî', 'مریشکی سۆرکری ژاپۆنی', 28.00, 11, 0, false, false, false, true, 320, 'Japan', true),
('Agedashi Tofu', 'Agedashi Tofu', 'أغيداشي توفو', 'Agedashi Tofu', 'ئەگەداش تۆفو', 'Kızarmış tofu', 'Fried tofu', 'توفو مقلي', 'Tofu sorkirî', 'تۆفوی سۆرکر', 20.00, 11, 0, true, true, false, true, 150, 'Japan', true),
('Matcha Dondurma', 'Matcha Ice Cream', 'آيس كريم ماتشا', 'Dondurmayê Matcha', 'دۆندوورمای ماتچا', 'Matcha dondurması', 'Matcha ice cream', 'آيس كريم ماتشا', 'Dondurmayê matcha', 'دۆندوورمای ماتچا', 18.00, 11, 0, true, true, true, false, 180, 'Japan', true); 