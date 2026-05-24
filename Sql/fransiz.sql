-- EXFIN REST - Fransız Mutfağı Kategorisi
-- Bu script Fransız mutfağı kategorisindeki ürünleri ekler

-- =====================================================
-- MEVCUT VERİLERİ TEMİZLE
-- =====================================================

DELETE FROM order_items WHERE product_id IN (SELECT id FROM products WHERE category_id = 13);
DELETE FROM products WHERE category_id = 13;

-- =====================================================
-- FRANSIZ MUTFAĞI KATEGORİSİNİ EKLE
-- =====================================================

INSERT INTO categories (id, name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, icon, color, sort_order, is_featured) VALUES
(13, 'Fransız Mutfağı', 'French Cuisine', 'المطبخ الفرنسي', 'Pêjgeha Fransî', 'پێشگەی فەرەنسی', 'Fransız yemekleri', 'French dishes', 'أطباق فرنسية', 'Xwarinên Fransî', 'خواردنە فەرەنسییەکان', 'bakery_dining', '#9C27B0', 13, true)
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
-- FRANSIZ MUTFAĞI ÜRÜNLERİNİ EKLE
-- =====================================================

INSERT INTO products (name, name_en, name_ar, name_ku, name_sr, description, description_en, description_ar, description_ku, description_sr, price, category_id, spice_level, is_vegetarian, is_vegan, is_gluten_free, is_hot, calories, origin_country, popular) VALUES
('Coq au Vin', 'Coq au Vin', 'كوك أو فين', 'Coq au Vin', 'کۆک ئۆ ڤین', 'Şarap soslu tavuk', 'Chicken in wine sauce', 'دجاج بصلصة نبيذ', 'Mirîşka bi sosa mey', 'مریشکی بە سۆسای مەی', 48.00, 13, 0, false, false, true, true, 450, 'France', true),
('Beef Bourguignon', 'Beef Bourguignon', 'لحم بقري بورغينيون', 'Goştê Çêl Bourguignon', 'گۆشتی چێل بۆرگینیۆن', 'Şarap soslu dana eti', 'Beef in wine sauce', 'لحم بقري بصلصة نبيذ', 'Goştê çêl bi sosa mey', 'گۆشتی چێل بە سۆسای مەی', 55.00, 13, 0, false, false, true, true, 520, 'France', true),
('Ratatouille', 'Ratatouille', 'راتاتوي', 'Ratatouille', 'راتاتۆی', 'Sebze yemeği', 'Vegetable dish', 'طبق خضار', 'Xwarina sebzeyan', 'خواردنی سەوزەوات', 32.00, 13, 0, true, true, true, true, 280, 'France', true),
('Quiche Lorraine', 'Quiche Lorraine', 'كيش لورين', 'Quiche Lorraine', 'کیچ لۆرێن', 'Pastırmalı börek', 'Bacon pie', 'فطيرة بيكون', 'Pîzzaya pastirma', 'پیتزای پاسترما', 28.00, 13, 0, false, false, false, true, 350, 'France', true),
('Croissant', 'Croissant', 'كرواسون', 'Croissant', 'کڕۆسان', 'Fransız kruvasan', 'French croissant', 'كرواسون فرنسي', 'Kruvasana Fransî', 'کڕۆسانای فەرەنسی', 12.00, 13, 0, true, false, false, false, 200, 'France', true),
('Baguette', 'Baguette', 'باجيت', 'Baguette', 'باگێت', 'Fransız ekmeği', 'French bread', 'خبز فرنسي', 'Nana Fransî', 'نانی فەرەنسی', 8.00, 13, 0, true, true, false, false, 150, 'France', true),
('Escargot', 'Escargot', 'إسكارغو', 'Escargot', 'ئێسکارگۆ', 'Salyangoz', 'Snail', 'حلزون', 'Xûlî', 'خوڵی', 35.00, 13, 0, false, false, true, true, 180, 'France', true),
('Soupe à l''Oignon', 'Onion Soup', 'حساء بصل', 'Şorbaya Pîvaz', 'شۆربای پیاز', 'Soğan çorbası', 'Onion soup', 'حساء بصل', 'Şorbaya pîvaz', 'شۆربای پیاز', 24.00, 13, 0, true, false, true, true, 200, 'France', true),
('Cassoulet', 'Cassoulet', 'كاسوليه', 'Cassoulet', 'کاسۆلێ', 'Fasulye yemeği', 'Bean dish', 'طبق فاصوليا', 'Xwarina fasûlye', 'خواردنی فاسۆلیە', 42.00, 13, 0, false, false, true, true, 480, 'France', true),
('Duck Confit', 'Duck Confit', 'بطة كونفيت', 'Mîra Confit', 'میرای کۆنفیت', 'Konserve ördek', 'Preserved duck', 'بطة محفوظة', 'Mîra parastî', 'میرای پاراست', 58.00, 13, 0, false, false, true, true, 550, 'France', true),
('Steak Frites', 'Steak Frites', 'ستيك فريتس', 'Steak Frites', 'ستێک فریتس', 'Biftek ve patates', 'Steak and fries', 'ستيك وبطاطس', 'Steak û kartol', 'ستێک و کەرتۆڵ', 45.00, 13, 0, false, false, true, true, 520, 'France', true),
('Moules Marinières', 'Mussels Marinière', 'محار مارينير', 'Moules Marinières', 'مۆڵێس ماڕینیێر', 'Midye yemeği', 'Mussel dish', 'طبق محار', 'Xwarina midye', 'خواردنی میدیە', 38.00, 13, 0, false, false, true, true, 320, 'France', true),
('Tarte Tatin', 'Tarte Tatin', 'تارت تاتين', 'Tarte Tatin', 'تاڕت تاتین', 'Elmalı tart', 'Apple tart', 'تارت تفاح', 'Tartê sêv', 'تاڕتێ سێو', 22.00, 13, 0, true, false, false, false, 280, 'France', true),
('Crème Brûlée', 'Crème Brûlée', 'كريم برولي', 'Crème Brûlée', 'کڕێم بڕوڵێ', 'Karamelli krema', 'Caramelized cream', 'كريمة كراميل', 'Kremê karamel', 'کڕێمێ کەرەمەڵ', 20.00, 13, 0, true, false, false, false, 250, 'France', true),
('Macaron', 'Macaron', 'ماكارون', 'Macaron', 'ماکارۆن', 'Fransız kurabiyesi', 'French cookie', 'كوكيز فرنسي', 'Kurabiyeya Fransî', 'کورەبیەی فەرەنسی', 18.00, 13, 0, true, true, false, false, 180, 'France', true),
('Éclair', 'Éclair', 'إكلير', 'Éclair', 'ئێکڵێر', 'Kremalı hamur işi', 'Cream-filled pastry', 'معجنات محشوة بالكريمة', 'Xwarina hevîrê dagirtî bi krem', 'خواردنی هەویری دەگرت بە کڕێم', 16.00, 13, 0, true, false, false, false, 220, 'France', true),
('Profiterole', 'Profiterole', 'بروفيتيرول', 'Profiterole', 'پڕۆفیتەڕۆڵ', 'Kremalı top', 'Cream puff', 'فطيرة كريمية', 'Gogê kremî', 'گۆگێ کڕێمی', 14.00, 13, 0, true, false, false, false, 200, 'France', true),
('Madeleine', 'Madeleine', 'مادلين', 'Madeleine', 'مادەلین', 'Fransız keki', 'French cake', 'كيك فرنسي', 'Kekê Fransî', 'کەکێ فەرەنسی', 12.00, 13, 0, true, false, false, false, 160, 'France', true),
('Pain au Chocolat', 'Pain au Chocolat', 'بان أو شوكولات', 'Pain au Chocolat', 'پان ئۆ چیکۆلاتا', 'Çikolatalı ekmek', 'Chocolate bread', 'خبز شوكولاتة', 'Nana çîkolata', 'نانی چیکۆلاتا', 10.00, 13, 0, true, false, false, false, 180, 'France', true),
('Champagne', 'Champagne', 'شمبانيا', 'Champagne', 'شامپەین', 'Fransız şampanyası', 'French champagne', 'شمبانيا فرنسية', 'Şampanyaya Fransî', 'شامپەینای فەرەنسی', 120.00, 13, 0, true, true, true, false, 85, 'France', true); 