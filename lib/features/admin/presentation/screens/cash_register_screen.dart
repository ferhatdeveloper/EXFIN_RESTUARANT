import 'package:flutter/material.dart';
import '../widgets/backoffice_widgets.dart';
import '../../../../services/postgres_service.dart';

class CashRegisterScreen extends StatefulWidget {
  const CashRegisterScreen({super.key});

  @override
  State<CashRegisterScreen> createState() => _CashRegisterScreenState();
}

class _CashRegisterScreenState extends State<CashRegisterScreen> {
  List<Map<String, dynamic>> _registers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      final results = await pg.query(
        "SELECT id, code, name, currency_code, balance, is_active FROM rex_001_cash_registers ORDER BY code",
      );
      if (mounted) setState(() { _registers = results; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(
          title: 'Kasalar',
          icon: Icons.point_of_sale_outlined,
          gradientStart: const Color(0xFF7C3AED),
          gradientEnd: const Color(0xFF6D28D9),
          count: _registers.length,
          actions: [
            HeaderIconButton(icon: Icons.refresh, onTap: _load),
            const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.add, label: 'Yeni Kasa', onTap: () {}),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _registers.isEmpty
                  ? const Center(child: Text('Kasa bulunamadı'))
                  : _buildGrid(),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        itemCount: _registers.length,
        itemBuilder: (context, i) {
          final r = _registers[i];
          final balRaw = r['balance'];
          final balance = balRaw is num ? balRaw.toDouble() : double.tryParse(balRaw?.toString() ?? '0') ?? 0;
          final isActive = r['is_active'] == true;

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.point_of_sale,
                              color: Color(0xFF7C3AED), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['name']?.toString() ?? '-',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              Text(r['code']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: isActive ? 'Aktif' : 'Pasif',
                          color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '${balance.toStringAsFixed(0)} ${r['currency_code'] ?? 'IQD'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
