import 'package:flutter/material.dart';
import '../../../../services/postgres_service.dart';
import '../../../admin/presentation/widgets/backoffice_widgets.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<Map<String, dynamic>> _categories = [];
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
        "SELECT id, code, name, description, is_restaurant, is_active FROM rex_001_categories ORDER BY name",
      );
      if (mounted) setState(() { _categories = results; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(
          title: 'Kategoriler',
          icon: Icons.category_outlined,
          gradientStart: const Color(0xFF8B5CF6),
          gradientEnd: const Color(0xFF7C3AED),
          count: _categories.length,
          actions: [
            HeaderIconButton(icon: Icons.refresh, onTap: _load),
            const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.add, label: 'Yeni Kategori', onTap: () => _showForm(null)),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _categories.isEmpty
                  ? const Center(child: Text('Kategori bulunamadı'))
                  : _buildGrid(),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, i) {
        final c = _categories[i];
        final isRest = c['is_restaurant'] == true;
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            onTap: () => _showForm(c),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: (isRest ? const Color(0xFFEF4444) : const Color(0xFF8B5CF6)).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isRest ? Icons.restaurant : Icons.category,
                      color: isRest ? const Color(0xFFEF4444) : const Color(0xFF8B5CF6),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(c['name']?.toString() ?? '-',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                        Text(c['code']?.toString() ?? '',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  if (isRest)
                    const StatusBadge(label: 'Rest', color: Color(0xFFEF4444)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showForm(Map<String, dynamic>? existing) {
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final codeCtrl = TextEditingController(text: existing?['code']?.toString() ?? '');
    bool isRest = existing?['is_restaurant'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing != null ? 'Kategori Düzenle' : 'Yeni Kategori',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Kategori Adı',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                decoration: InputDecoration(
                  labelText: 'Kod',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Restoran Kategorisi', style: TextStyle(fontSize: 13)),
                value: isRest,
                onChanged: (v) => setDState(() => isRest = v),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                final pg = PostgresService();
                if (!pg.isConnected) await pg.initialize();
                if (existing != null) {
                  await pg.query(
                    "UPDATE rex_001_categories SET name = @name, code = @code, is_restaurant = @isRest WHERE id = @id::uuid",
                    params: {'id': existing['id']?.toString(), 'name': nameCtrl.text, 'code': codeCtrl.text, 'isRest': isRest},
                  );
                } else {
                  await pg.query(
                    "INSERT INTO rex_001_categories (code, name, is_restaurant, is_active, created_at) VALUES (@code, @name, @isRest, true, NOW())",
                    params: {'name': nameCtrl.text, 'code': codeCtrl.text, 'isRest': isRest},
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

class BrandManagementScreen extends StatefulWidget {
  const BrandManagementScreen({super.key});

  @override
  State<BrandManagementScreen> createState() => _BrandManagementScreenState();
}

class _BrandManagementScreenState extends State<BrandManagementScreen> {
  List<Map<String, dynamic>> _brands = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      final results = await pg.query("SELECT id, code, name, description, is_active FROM rex_001_brands ORDER BY name");
      if (mounted) setState(() { _brands = results; _isLoading = false; });
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(title: 'Markalar', icon: Icons.loyalty_outlined,
          gradientStart: const Color(0xFFF59E0B), gradientEnd: const Color(0xFFD97706), count: _brands.length,
          actions: [HeaderIconButton(icon: Icons.refresh, onTap: _load), const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.add, label: 'Yeni Marka', onTap: () => _showForm(null))]),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator())
              : _brands.isEmpty ? const Center(child: Text('Marka bulunamadı'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12), itemCount: _brands.length,
                  itemBuilder: (context, i) {
                    final b = _brands[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(radius: 16, backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          child: Text((b['name']?.toString() ?? '?')[0], style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w700, fontSize: 12))),
                        title: Text(b['name']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(b['code']?.toString() ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        trailing: IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: () => _showForm(b)),
                        onTap: () => _showForm(b),
                      ),
                    );
                  }),
        ),
      ],
    );
  }

  void _showForm(Map<String, dynamic>? existing) {
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final codeCtrl = TextEditingController(text: existing?['code']?.toString() ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(existing != null ? 'Marka Düzenle' : 'Yeni Marka', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Marka Adı', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: codeCtrl, decoration: InputDecoration(labelText: 'Kod', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
        ElevatedButton(onPressed: () async {
          final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
          if (existing != null) { await pg.query("UPDATE rex_001_brands SET name = @name, code = @code WHERE id = @id::uuid", params: {'id': existing['id']?.toString(), 'name': nameCtrl.text, 'code': codeCtrl.text}); }
          else { await pg.query("INSERT INTO rex_001_brands (code, name, is_active, created_at) VALUES (@code, @name, true, NOW())", params: {'name': nameCtrl.text, 'code': codeCtrl.text}); }
          if (ctx.mounted) Navigator.pop(ctx); _load();
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white), child: const Text('Kaydet')),
      ],
    ));
  }
}

class UnitManagementScreen extends StatefulWidget {
  const UnitManagementScreen({super.key});

  @override
  State<UnitManagementScreen> createState() => _UnitManagementScreenState();
}

class _UnitManagementScreenState extends State<UnitManagementScreen> {
  List<Map<String, dynamic>> _units = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final pg = PostgresService();
      if (!pg.isConnected) await pg.initialize();
      final results = await pg.query("SELECT id, code, name, description, is_active FROM rex_001_units ORDER BY name");
      if (mounted) setState(() { _units = results; _isLoading = false; });
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackofficeHeader(title: 'Birimler', icon: Icons.straighten_outlined,
          gradientStart: const Color(0xFF06B6D4), gradientEnd: const Color(0xFF0891B2), count: _units.length,
          actions: [HeaderIconButton(icon: Icons.refresh, onTap: _load), const SizedBox(width: 6),
            HeaderIconButton(icon: Icons.add, label: 'Yeni Birim', onTap: () => _showForm(null))]),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator())
              : _units.isEmpty ? const Center(child: Text('Birim bulunamadı'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12), itemCount: _units.length,
                  itemBuilder: (context, i) {
                    final u = _units[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        dense: true,
                        leading: Container(width: 32, height: 32,
                          decoration: BoxDecoration(color: const Color(0xFF06B6D4).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Center(child: Text(u['code']?.toString() ?? '?', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF06B6D4))))),
                        title: Text(u['name']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(u['code']?.toString() ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        trailing: IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: () => _showForm(u)),
                      ),
                    );
                  }),
        ),
      ],
    );
  }

  void _showForm(Map<String, dynamic>? existing) {
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final codeCtrl = TextEditingController(text: existing?['code']?.toString() ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(existing != null ? 'Birim Düzenle' : 'Yeni Birim', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Birim Adı', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: codeCtrl, decoration: InputDecoration(labelText: 'Kod (ör: KG, ADET)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
        ElevatedButton(onPressed: () async {
          final pg = PostgresService(); if (!pg.isConnected) await pg.initialize();
          if (existing != null) { await pg.query("UPDATE rex_001_units SET name = @name, code = @code WHERE id = @id::uuid", params: {'id': existing['id']?.toString(), 'name': nameCtrl.text, 'code': codeCtrl.text}); }
          else { await pg.query("INSERT INTO rex_001_units (code, name, is_active, created_at) VALUES (@code, @name, true, NOW())", params: {'name': nameCtrl.text, 'code': codeCtrl.text}); }
          if (ctx.mounted) Navigator.pop(ctx); _load();
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white), child: const Text('Kaydet')),
      ],
    ));
  }
}
