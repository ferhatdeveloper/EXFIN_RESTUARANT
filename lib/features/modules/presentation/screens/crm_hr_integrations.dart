import 'package:flutter/material.dart';
import '../../../admin/presentation/widgets/backoffice_widgets.dart';

class CrmModule extends StatelessWidget {
  const CrmModule({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color(0xFFF8FAFC), body: Column(children: [
      const BackofficeHeader(title: 'CRM & Sadakat', icon: Icons.loyalty_outlined, gradientStart: Color(0xFFEC4899), gradientEnd: Color(0xFFDB2777)),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _section('Sadakat Programı', [
          _feature('Puan Sistemi', 'Her 1000 IQD = 1 puan', Icons.stars),
          _feature('Seviye Sistemi', 'Normal → VIP → Premium', Icons.trending_up),
          _feature('Ödüller', 'İndirim kuponu, ücretsiz ürün', Icons.card_giftcard),
        ]),
        _section('Hediye Kartı', [
          _feature('Fiziksel Kart', 'Barkodlu hediye kartı basımı', Icons.credit_card),
          _feature('Dijital Kart', 'SMS/WhatsApp ile gönderim', Icons.phone_android),
          _feature('Bakiye Takip', 'Yükleme, kullanım, geçmiş', Icons.account_balance_wallet),
        ]),
        _section('Müşteri Segmentasyonu', [
          _feature('RFM Analizi', 'Recency/Frequency/Monetary', Icons.analytics),
          _feature('Otomatik Segment', 'Kaybedilen, sadık, yeni', Icons.people_outline),
          _feature('Hedefli Kampanya', 'Segmente özel teklif', Icons.campaign),
        ]),
      ]))),
    ]));
  }

  Widget _section(String title, List<Widget> items) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(bottom: 10, top: 16), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
    ...items,
  ]);

  Widget _feature(String title, String desc, IconData icon) => Card(margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(leading: Icon(icon, color: const Color(0xFFEC4899)), title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))));
}

class HrModule extends StatelessWidget {
  const HrModule({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color(0xFFF8FAFC), body: Column(children: [
      const BackofficeHeader(title: 'İnsan Kaynakları', icon: Icons.badge_outlined, gradientStart: Color(0xFF0EA5E9), gradientEnd: Color(0xFF0284C7)),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _section('Personel Yönetimi', [
          _feature('Personel Kartı', 'Ad, iletişim, pozisyon, maaş', Icons.person),
          _feature('Departman', 'Mutfak, servis, kasa, yönetim', Icons.group_work),
          _feature('Özlük Dosyası', 'Belgeler, sertifikalar', Icons.folder_shared),
        ]),
        _section('Vardiya & Puantaj', [
          _feature('Vardiya Planı', 'Haftalık/aylık çizelge', Icons.calendar_today),
          _feature('Giriş/Çıkış', 'PIN ile mesai takibi', Icons.access_time),
          _feature('Fazla Mesai', 'Otomatik hesaplama', Icons.timer),
        ]),
        _section('Bordro', [
          _feature('Maaş Hesaplama', 'Brüt → net, SGK, vergi', Icons.calculate),
          _feature('İkramiye / Prim', 'Satış bazlı prim sistemi', Icons.emoji_events),
          _feature('Bordro Çıktısı', 'PDF bordro slip', Icons.print),
        ]),
      ]))),
    ]));
  }

  Widget _section(String title, List<Widget> items) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(bottom: 10, top: 16), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
    ...items,
  ]);

  Widget _feature(String title, String desc, IconData icon) => Card(margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(leading: Icon(icon, color: const Color(0xFF0EA5E9)), title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))));
}

class IntegrationsModule extends StatelessWidget {
  const IntegrationsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color(0xFFF8FAFC), body: Column(children: [
      const BackofficeHeader(title: 'Entegrasyonlar', icon: Icons.extension_outlined, gradientStart: Color(0xFF7C3AED), gradientEnd: Color(0xFF6D28D9)),
      Expanded(child: GridView.count(crossAxisCount: 3, padding: const EdgeInsets.all(16), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
        children: [
          _integrationCard('WhatsApp', 'Bildirim & kampanya', Icons.chat, const Color(0xFF25D366), true),
          _integrationCard('SMS', 'Toplu mesaj gönderimi', Icons.sms, const Color(0xFF3B82F6), true),
          _integrationCard('E-posta', 'Kampanya & fatura', Icons.email, const Color(0xFFEF4444), false),
          _integrationCard('E-Fatura', 'GİB UBL entegrasyonu', Icons.receipt_long, const Color(0xFF1E40AF), false),
          _integrationCard('Marketplace', 'Trendyol, Getir, Yemeksepeti', Icons.shopping_bag, const Color(0xFFF97316), false),
          _integrationCard('Ödeme', 'FIB, FastPay, ZainCash', Icons.payment, const Color(0xFF10B981), true),
          _integrationCard('Kargo', 'MNG, Yurtiçi, PTT', Icons.local_shipping, const Color(0xFF64748B), false),
          _integrationCard('Logo ERP', 'Tiger/Go entegrasyonu', Icons.sync, const Color(0xFF0891B2), false),
          _integrationCard('AI Asistan', 'Stok tahmini, rapor chat', Icons.psychology, const Color(0xFF8B5CF6), false),
        ],
      )),
    ]));
  }

  Widget _integrationCard(String name, String desc, IconData icon, Color color, bool active) {
    return Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: active ? const Color(0xFF10B981) : const Color(0xFFD1D5DB))),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          Text(desc, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ])),
    );
  }
}
