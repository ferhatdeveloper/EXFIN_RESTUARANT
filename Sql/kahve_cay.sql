-- EXFIN REST - Kahve ve Çay Kategorisi
-- Bu script kahve ve çay kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 2);
DELETE FROM products WHERE category_id = 2;

-- =====================================================
-- KAHVE VE ÇAY KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(2, 'Kahve & Çay', 'Coffee & Tea', 'قهوة وشاي', 'Qehwe û Çay', 'قەهوە و چای', 'Sıcak içecekler', 'Hot beverages', 'مشروبات ساخنة', 'Şerabên germ', 'شەرابە گەرمەکان', 'coffee', '#795548', 2, true)
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
-- KAHVE VE ÇAY ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Türk Kahvesi', 'Turkish Coffee', 'قهوة تركية', 'Qehweya Tirkî', 'قەهوەی تورکی', 'Geleneksel Türk Kahvesi', 'Traditional Turkish Coffee', 'قهوة تركية تقليدية', 'Qehweya kevneşopî ya Tirkî', 'قەهوەی کۆنەپارێزی تورکی', 12.00, 2, 0, true, true, true, true, 5, 'Turkey', true),
('Espresso', 'Espresso', 'اسبريسو', 'Espresso', 'ئێسپرێسۆ', 'Tek Shot Espresso', 'Single Shot Espresso', 'اسبريسو شوت واحد', 'Espresso tek shot', 'ئێسپرێسۆی تەک شۆت', 15.00, 2, 0, true, true, true, true, 5, 'Italy', true),
('Cappuccino', 'Cappuccino', 'كابتشينو', 'Cappuccino', 'کاپۆچینۆ', 'Espresso, Süt, Süt Köpüğü', 'Espresso, Milk, Milk Foam', 'اسبريسو وحليب ورغوة الحليب', 'Espresso, şîr, kefşîr', 'ئێسپرێسۆ، شیر، کەفشیر', 18.00, 2, 0, true, true, true, true, 80, 'Italy', true),
('Latte', 'Latte', 'لاتيه', 'Latte', 'لاتە', 'Espresso ve Buharlanmış Süt', 'Espresso and Steamed Milk', 'اسبريسو وحليب مبخر', 'Espresso û şîrê biharî', 'ئێسپرێسۆ و شیری بەهار', 20.00, 2, 0, true, true, true, true, 120, 'Italy', true),
('Çay', 'Tea', 'شاي', 'Çay', 'چای', 'Sıcak Çay', 'Hot Tea', 'شاي ساخن', 'Çay germ', 'چای گەرم', 8.00, 2, 0, true, true, true, true, 2, 'Turkey', true),
('Yeşil Çay', 'Green Tea', 'شاي اخضر', 'Çaya Kesk', 'چای سەوز', 'Sıcak Yeşil Çay', 'Hot Green Tea', 'شاي اخضر ساخن', 'Çaya kesk germ', 'چای سەوزی گەرم', 10.00, 2, 0, true, true, true, true, 2, 'China', true),
('Nane Çayı', 'Mint Tea', 'شاي نعناع', 'Çaya Pûng', 'چای پوونگ', 'Sıcak Nane Çayı', 'Hot Mint Tea', 'شاي نعناع ساخن', 'Çaya pûng germ', 'چای پوونگی گەرم', 12.00, 2, 0, true, true, true, true, 3, 'Morocco', true),
('Ihlamur Çayı', 'Linden Tea', 'شاي زيزفون', 'Çaya Gulî', 'چای گوڵی', 'Sıcak Ihlamur Çayı', 'Hot Linden Tea', 'شاي زيزفون ساخن', 'Çaya gulî germ', 'چای گوڵی گەرم', 10.00, 2, 0, true, true, true, true, 2, 'Turkey', true),
('Americano', 'Americano', 'أمريكانو', 'Amerîkano', 'ئەمەریکانۆ', 'Espresso ve Sıcak Su', 'Espresso and Hot Water', 'اسبريسو وماء ساخن', 'Espresso û av germ', 'ئێسپرێسۆ و ئاوی گەرم', 14.00, 2, 0, true, true, true, true, 5, 'USA', true),
('Mocha', 'Mocha', 'موكا', 'Moka', 'مۆکا', 'Espresso, Çikolata, Süt', 'Espresso, Chocolate, Milk', 'اسبريسو وشوكولاتة وحليب', 'Espresso, çîkolata, şîr', 'ئێسپرێسۆ، چیکۆلاتا، شیر', 22.00, 2, 0, true, false, true, true, 150, 'Italy', true),
('Macchiato', 'Macchiato', 'ماكياتو', 'Makîato', 'ماکیاتۆ', 'Espresso ve Az Süt', 'Espresso and Little Milk', 'اسبريسو وقليل من الحليب', 'Espresso û şîrê kêm', 'ئێسپرێسۆ و شیری کەم', 16.00, 2, 0, true, true, true, true, 40, 'Italy', true),
('Flat White', 'Flat White', 'فلات وايت', 'Flat White', 'فلەت وایت', 'Espresso ve Buharlanmış Süt', 'Espresso and Steamed Milk', 'اسبريسو وحليب مبخر', 'Espresso û şîrê biharî', 'ئێسپرێسۆ و شیری بەهار', 19.00, 2, 0, true, true, true, true, 100, 'Australia', true),
('Earl Grey', 'Earl Grey', 'إيرل غراي', 'Earl Grey', 'ئێرڵ گڕەی', 'Bergamot Aromalı Çay', 'Bergamot Flavored Tea', 'شاي بنكهول', 'Çaya bergamot', 'چای بەرگەمۆت', 12.00, 2, 0, true, true, true, true, 2, 'England', true),
('Chai Latte', 'Chai Latte', 'تشاي لاتيه', 'Çay Latte', 'چای لاتە', 'Hint Baharatlı Çay', 'Indian Spiced Tea', 'شاي هندي بالبهارات', 'Çaya Hindî bi baharat', 'چای هیندی بە بەهارات', 18.00, 2, 1, true, true, true, true, 120, 'India', true); 