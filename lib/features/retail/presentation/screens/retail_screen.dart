// Dosya Adı: retail_screen.dart
// Açıklama: Perakende satış ekranı - Tüm masaları listeler
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-12-02

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/postgres_service.dart';
import 'dart:developer' as developer;

/// {@template RetailScreen}
/// Perakende satış ekranı - Tüm masaları listeler
///
/// Kullanım örneği:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => const RetailScreen()),
/// );
/// ```
/// {@endtemplate}
class RetailScreen extends ConsumerStatefulWidget {
  const RetailScreen({super.key});

  @override
  ConsumerState<RetailScreen> createState() => _RetailScreenState();
}

class _RetailScreenState extends ConsumerState<RetailScreen> {
  List<Map<String, dynamic>> _tables = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      developer.log('📊 Masalar yükleniyor...', name: 'RetailScreen');

      // PostgreSQL'den masaları çek
      final postgresService = PostgresService();
      await postgresService.initialize();

      // PostgreSQL'den veri çek
      try {
        developer.log('🔍 PostgreSQL\'den veri çekiliyor...',
            name: 'RetailScreen');
        final tables = await postgresService.getTables();
        developer.log('📊 PostgreSQL Response: ${tables.length} masa', name: 'RetailScreen');

        if (tables.isNotEmpty) {
          setState(() {
            _tables = tables;
            _isLoading = false;
          });
          developer.log('✅ ${tables.length} masa yüklendi',
              name: 'RetailScreen');
        } else {
          // PostgreSQL'den veri alınamazsa varsayılan masalar
          setState(() {
            _tables = _getDefaultTables();
            _isLoading = false;
          });
          developer.log(
              '⚠️ PostgreSQL\'den veri alınamadı, varsayılan masalar kullanılıyor',
              name: 'RetailScreen');
        }
      } catch (e) {
        developer.log('❌ PostgreSQL hatası: $e', name: 'RetailScreen');
        setState(() {
          _tables = _getDefaultTables();
          _isLoading = false;
        });
        developer.log('⚠️ PostgreSQL hatası nedeniyle varsayılan masalar kullanılıyor',
            name: 'RetailScreen');
      }
    } catch (e) {
      developer.log('❌ Masa yükleme hatası: $e', name: 'RetailScreen');
      setState(() {
        _error = 'Masalar yüklenirken hata oluştu: $e';
        _tables = _getDefaultTables();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getDefaultTables() {
    return [
      {
        'id': 1,
        'name': 'Masa 1',
        'capacity': 4,
        'status': 'Available',
        'location': 'Bahçe',
        'isActive': true,
        'createdAt': '2025-08-01T23:08:21.097382+03',
        'updatedAt': null,
      },
      {
        'id': 2,
        'name': 'Masa 2',
        'capacity': 4,
        'status': 'Available',
        'location': 'Bahçe',
        'isActive': true,
        'createdAt': '2025-08-01T23:08:21.097383+03',
        'updatedAt': null,
      },
      {
        'id': 3,
        'name': 'Masa 3',
        'capacity': 6,
        'status': 'Available',
        'location': 'İç Mekan',
        'isActive': true,
        'createdAt': '2025-08-01T23:08:21.097384+03',
        'updatedAt': null,
      },
      {
        'id': 4,
        'name': 'Masa 4',
        'capacity': 6,
        'status': 'Available',
        'location': 'İç Mekan',
        'isActive': true,
        'createdAt': '2025-08-01T23:08:21.097386+03',
        'updatedAt': null,
      },
      {
        'id': 5,
        'name': 'Masa 5',
        'capacity': 8,
        'status': 'Available',
        'location': 'Teras',
        'isActive': true,
        'createdAt': '2025-08-01T23:08:21.097387+03',
        'updatedAt': null,
      },
      {
        'id': 6,
        'name': 'Masa 6',
        'capacity': 2,
        'status': 'Available',
        'location': 'Bar',
        'isActive': true,
        'createdAt': '2025-08-01T23:08:21.097388+03',
        'updatedAt': null,
      },
      {
        'id': 7,
        'name': 'Masa 7',
        'capacity': 4,
        'status': 'Available',
        'location': 'İç Mekan',
        'isActive': true,
        'createdAt': '2025-08-01T23:08:21.097389+03',
        'updatedAt': null,
      },
      {
        'id': 8,
        'name': 'Masa 8',
        'capacity': 6,
        'status': 'Available',
        'location': 'Bahçe',
        'isActive': true,
        'createdAt': '2025-08-01T23:08:21.097390+03',
        'updatedAt': null,
      },
      {
        'id': 9,
        'name': 'VIP Masa 1',
        'capacity': 10,
        'status': 'Available',
        'location': 'Özel Bölüm',
        'isActive': true,
        'createdAt': '2025-08-01T23:08:21.097391+03',
        'updatedAt': null,
      },
      {
        'id': 10,
        'name': 'VIP Masa 2',
        'capacity': 12,
        'status': 'Available',
        'location': 'Özel Bölüm',
        'isActive': true,
        'createdAt': '2025-08-01T23:08:21.097392+03',
        'updatedAt': null,
      },
    ];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
      case 'boş':
      case 'empty':
        return Colors.green;
      case 'occupied':
      case 'dolu':
        return Colors.red;
      case 'reserved':
      case 'rezerve':
        return Colors.orange;
      case 'alert':
      case 'uyarı':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available':
      case 'boş':
      case 'empty':
        return Icons.event_seat;
      case 'occupied':
      case 'dolu':
        return Icons.people;
      case 'reserved':
      case 'rezerve':
        return Icons.schedule;
      case 'alert':
      case 'uyarı':
        return Icons.cleaning_services;
      default:
        return Icons.all_inclusive;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'MÜSAİT';
      case 'occupied':
      case 'dolu':
        return 'DOLU';
      case 'reserved':
      case 'rezerve':
        return 'REZERVE';
      case 'alert':
      case 'uyarı':
        return 'UYARI';
      default:
        return 'BİLİNMİYOR';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppConstants.exfinRed,
        foregroundColor: Colors.white,
        title: const Text('Servis - Tüm Masalar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddTableDialog,
            tooltip: 'Masa Ekle',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTables,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Masalar yükleniyor...'),
                ],
              ),
            )
          : _error != null
              ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                        Icons.error,
              size: 64,
                        color: Colors.red,
            ),
                      const SizedBox(height: 16),
            Text(
                        'Hata',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTables,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Başlık ve istatistikler
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Toplam Masa: ${_tables.length}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Boş: ${_tables.where((t) => t['status'] == 'Available').length} | '
                                  'Dolu: ${_tables.where((t) => t['status'] == 'occupied').length} | '
                                  'Rezerve: ${_tables.where((t) => t['status'] == 'reserved').length} | '
                                  'Uyarı: ${_tables.where((t) => t['status'] == 'alert').length}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.table_restaurant,
                            size: 32,
                            color: AppConstants.exfinRed,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Masalar listesi
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _tables.length,
                        itemBuilder: (context, index) {
                          final table = _tables[index];
                          final status =
                              table['status']?.toString() ?? 'bilinmiyor';
                          final name = table['name']?.toString() ??
                              'Masa ${table['id']}';
                          final capacity = table['capacity']?.toString() ?? '?';
                          final location = table['location']?.toString() ?? '';

                          return Card(
                            elevation: 4,
                            child: InkWell(
                              onTap: () {
                                // Masa detayına git
                                _showTableDetails(table);
                              },
                              onLongPress: () {
                                // Masa düzenleme menüsü
                                _showTableOptions(table);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _getStatusIcon(status),
                                      size: 32,
                                      color: _getStatusColor(status),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getStatusLabel(status),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(status),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$capacity Kişilik',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (location.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        location,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showTableDetails(Map<String, dynamic> table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${table['name']} Detayları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Durum: ${table['status']}'),
            Text('Kapasite: ${table['capacity']} kişi'),
            if (table['id'] != null) Text('ID: ${table['id']}'),
            if (table['location'] != null) Text('Konum: ${table['location']}'),
            if (table['notes'] != null) Text('Notlar: ${table['notes']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showAddTableDialog() {
    final nameController = TextEditingController();
    final capacityController = TextEditingController();
    String selectedStatus = 'Available';
    String selectedLocation = 'Bahçe';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Masa Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Masa Adı',
                hintText: 'Örn: Masa 9',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: capacityController,
              decoration: const InputDecoration(
                labelText: 'Kapasite',
                hintText: 'Örn: 4',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Durum',
              ),
              items: [
                DropdownMenuItem(value: 'Available', child: Text('Müsait')),
                DropdownMenuItem(value: 'occupied', child: Text('Dolu')),
                DropdownMenuItem(value: 'reserved', child: Text('Rezerve')),
                DropdownMenuItem(value: 'alert', child: Text('Uyarı')),
              ],
              onChanged: (value) {
                selectedStatus = value!;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedLocation,
              decoration: const InputDecoration(
                labelText: 'Konum',
              ),
              items: [
                DropdownMenuItem(value: 'Bahçe', child: Text('Bahçe')),
                DropdownMenuItem(value: 'İç Mekan', child: Text('İç Mekan')),
                DropdownMenuItem(value: 'Teras', child: Text('Teras')),
                DropdownMenuItem(value: 'Bar', child: Text('Bar')),
                DropdownMenuItem(
                    value: 'Özel Bölüm', child: Text('Özel Bölüm')),
              ],
              onChanged: (value) {
                selectedLocation = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  capacityController.text.isNotEmpty) {
                final newTable = {
                  'name': nameController.text,
                  'capacity': int.tryParse(capacityController.text) ?? 4,
                  'status': selectedStatus,
                  'location': selectedLocation,
                  'isActive': true,
                  'id': _tables.length + 1,
                };

                setState(() {
                  _tables.add(newTable);
                });

                Navigator.of(context).pop();

                // Başarı mesajı göster
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${nameController.text} başarıyla eklendi'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen tüm alanları doldurun'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showTableOptions(Map<String, dynamic> table) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text('${table['name']} Düzenle'),
            onTap: () {
              Navigator.of(context).pop();
              _showEditTableDialog(table);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text('${table['name']} Sil'),
            onTap: () {
              Navigator.of(context).pop();
              _showDeleteTableDialog(table);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text('${table['name']} Detayları'),
            onTap: () {
              Navigator.of(context).pop();
              _showTableDetails(table);
            },
          ),
        ],
      ),
    );
  }

  void _showEditTableDialog(Map<String, dynamic> table) {
    final nameController =
        TextEditingController(text: table['name']?.toString() ?? '');
    final capacityController =
        TextEditingController(text: table['capacity']?.toString() ?? '');
    String selectedStatus = table['status']?.toString() ?? 'Available';
    String selectedLocation = table['location']?.toString() ?? 'Bahçe';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${table['name']} Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Masa Adı',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: capacityController,
              decoration: const InputDecoration(
                labelText: 'Kapasite',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Durum',
              ),
              items: [
                DropdownMenuItem(value: 'Available', child: Text('Müsait')),
                DropdownMenuItem(value: 'occupied', child: Text('Dolu')),
                DropdownMenuItem(value: 'reserved', child: Text('Rezerve')),
                DropdownMenuItem(value: 'alert', child: Text('Uyarı')),
              ],
              onChanged: (value) {
                selectedStatus = value!;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedLocation,
              decoration: const InputDecoration(
                labelText: 'Konum',
              ),
              items: [
                DropdownMenuItem(value: 'Bahçe', child: Text('Bahçe')),
                DropdownMenuItem(value: 'İç Mekan', child: Text('İç Mekan')),
                DropdownMenuItem(value: 'Teras', child: Text('Teras')),
                DropdownMenuItem(value: 'Bar', child: Text('Bar')),
                DropdownMenuItem(
                    value: 'Özel Bölüm', child: Text('Özel Bölüm')),
              ],
              onChanged: (value) {
                selectedLocation = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  capacityController.text.isNotEmpty) {
                final index = _tables.indexWhere((t) => t['id'] == table['id']);
                if (index != -1) {
                  setState(() {
                    _tables[index] = {
                      ...table,
                      'name': nameController.text,
                      'capacity': int.tryParse(capacityController.text) ?? 4,
                      'status': selectedStatus,
                      'location': selectedLocation,
                    };
                  });

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('${nameController.text} başarıyla güncellendi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen tüm alanları doldurun'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTableDialog(Map<String, dynamic> table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Masa Sil'),
        content: Text(
            '${table['name']} masasını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _tables.removeWhere((t) => t['id'] == table['id']);
              });

              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${table['name']} başarıyla silindi'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
