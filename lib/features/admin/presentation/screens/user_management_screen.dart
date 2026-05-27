import 'package:flutter/material.dart';
import '../widgets/backoffice_widgets.dart';
import '../../../../services/postgres_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
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
        "SELECT u.id, u.username, u.full_name, u.email, u.phone, u.role, u.is_active, u.last_login_at, u.created_at, r.name as role_name, r.color as role_color FROM public.users u LEFT JOIN public.roles r ON r.id = u.role_id ORDER BY u.username",
      );
      if (mounted) setState(() { _users = results; _filtered = results; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = _users.where((u) {
        final s = q.toLowerCase();
        return (u['username'] ?? '').toString().toLowerCase().contains(s) ||
            (u['full_name'] ?? '').toString().toLowerCase().contains(s) ||
            (u['email'] ?? '').toString().toLowerCase().contains(s);
      }).toList();
    });
  }

  Color _getRoleColor(String? roleName) {
    switch (roleName?.toLowerCase()) {
      case 'admin': return const Color(0xFF7C3AED);
      case 'manager': return const Color(0xFF2563EB);
      case 'cashier': return const Color(0xFF10B981);
      case 'stock': return const Color(0xFFF59E0B);
      case 'garson': return const Color(0xFFF97316);
      default: return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _users.where((u) => u['is_active'] == true).length;

    return Column(
      children: [
        BackofficeHeader(
          title: 'Kullanıcı Yönetimi',
          icon: Icons.manage_accounts_outlined,
          gradientStart: const Color(0xFF2563EB),
          gradientEnd: const Color(0xFF7C3AED),
          count: _users.length,
          actions: [
            HeaderIconButton(icon: Icons.refresh, onTap: _load),
            const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.person_add, label: 'Yeni Kullanıcı', onTap: () {}),
          ],
        ),
        _buildStatCards(activeCount),
        BackofficeSearchBar(hint: 'Kullanıcı adı, ad soyad veya e-posta ara...', onChanged: _onSearch),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(child: Text('Kullanıcı bulunamadı'))
                  : _buildTable(),
        ),
      ],
    );
  }

  Widget _buildStatCards(int activeCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _statMini('Toplam', '${_users.length}', const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          _statMini('Aktif', '$activeCount', const Color(0xFF10B981)),
          const SizedBox(width: 10),
          _statMini('Pasif', '${_users.length - activeCount}', const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _statMini(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowMinHeight: 44,
          dataRowMaxHeight: 52,
          columnSpacing: 24,
          horizontalMargin: 16,
          headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          columns: const [
            DataColumn(label: Text('KULLANICI')),
            DataColumn(label: Text('AD SOYAD')),
            DataColumn(label: Text('E-POSTA')),
            DataColumn(label: Text('ROL')),
            DataColumn(label: Text('DURUM')),
            DataColumn(label: Text('SON GİRİŞ')),
          ],
          rows: _filtered.map((u) {
            final roleName = u['role_name']?.toString() ?? u['role']?.toString() ?? '-';
            final roleColor = _getRoleColor(roleName);
            final isActive = u['is_active'] == true;

            return DataRow(cells: [
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: roleColor.withValues(alpha: 0.15),
                    child: Text(
                      (u['username']?.toString() ?? '?')[0].toUpperCase(),
                      style: TextStyle(color: roleColor, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(u['username']?.toString() ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              )),
              DataCell(Text(u['full_name']?.toString() ?? '-', style: const TextStyle(fontSize: 12))),
              DataCell(Text(u['email']?.toString() ?? '-', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
              DataCell(StatusBadge(label: roleName, color: roleColor)),
              DataCell(StatusBadge(
                label: isActive ? 'Aktif' : 'Pasif',
                color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              )),
              DataCell(Text(u['last_login_at']?.toString() ?? '-', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
