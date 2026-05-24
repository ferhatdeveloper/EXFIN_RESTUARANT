import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/base/base_viewmodel.dart';
import '../../../services/postgres_service.dart';
import '../../../services/signalr_service.dart';
import 'dart:developer' as developer;

class TablesViewModel extends ChangeNotifier {
  final PostgresService _postgresService = PostgresService();
  final SignalRService _signalRService = SignalRService();

  List<Map<String, dynamic>> _tables = [];
  List<Map<String, dynamic>> _regions = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get tables => _tables;
  List<Map<String, dynamic>> get regions => _regions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Masaları yükle
  Future<void> loadTables() async {
    try {
      setLoading(true);
      clearError();

      developer.log('🪑 Masalar yükleniyor...', name: 'TablesViewModel');
      
      await _postgresService.initialize();
      final tables = await _postgresService.getTables();
      
      _tables = tables;
      developer.log('✅ ${tables.length} masa yüklendi', name: 'TablesViewModel');
      
      notifyListeners();
    } catch (e) {
      developer.log('❌ Masalar yüklenirken hata: $e', name: 'TablesViewModel');
      setError('Masalar yüklenirken hata oluştu: $e');
    } finally {
      setLoading(false);
    }
  }

  /// Bölgeleri yükle
  Future<void> loadRegions() async {
    try {
      developer.log('🗺️ Bölgeler yükleniyor...', name: 'TablesViewModel');
      
      await _postgresService.initialize();
      final regions = await _postgresService.getRegions();
      
      _regions = regions;
      developer.log('✅ ${regions.length} bölge yüklendi', name: 'TablesViewModel');
      
      notifyListeners();
    } catch (e) {
      developer.log('❌ Bölgeler yüklenirken hata: $e', name: 'TablesViewModel');
      setError('Bölgeler yüklenirken hata oluştu: $e');
    }
  }

  /// Masa durumunu güncelle
  Future<bool> updateTableStatus(int tableId, String status) async {
    try {
      developer.log('🔄 Masa durumu güncelleniyor: Table $tableId -> $status', name: 'TablesViewModel');
      
      final success = await _postgresService.updateTableStatus(tableId, status);
      
      if (success) {
        // Masaları yeniden yükle
        await loadTables();
        developer.log('✅ Masa durumu güncellendi', name: 'TablesViewModel');
      } else {
        developer.log('❌ Masa durumu güncellenemedi', name: 'TablesViewModel');
      }
      
      return success;
    } catch (e) {
      developer.log('❌ Masa durumu güncellenirken hata: $e', name: 'TablesViewModel');
      setError('Masa durumu güncellenirken hata oluştu: $e');
      return false;
    }
  }

  /// Yeni masa ekle
  Future<bool> addTable(Map<String, dynamic> tableData) async {
    try {
      developer.log('➕ Yeni masa ekleniyor: ${tableData['name']}', name: 'TablesViewModel');
      
      final success = await _postgresService.addTable(tableData);
      
      if (success) {
        // Masaları yeniden yükle
        await loadTables();
        developer.log('✅ Yeni masa eklendi', name: 'TablesViewModel');
      } else {
        developer.log('❌ Yeni masa eklenemedi', name: 'TablesViewModel');
      }
      
      return success;
    } catch (e) {
      developer.log('❌ Yeni masa eklenirken hata: $e', name: 'TablesViewModel');
      setError('Yeni masa eklenirken hata oluştu: $e');
      return false;
    }
  }

  /// Masa güncelle
  Future<bool> updateTable(int tableId, Map<String, dynamic> tableData) async {
    try {
      developer.log('✏️ Masa güncelleniyor: Table $tableId', name: 'TablesViewModel');
      
      final success = await _postgresService.updateTable(tableId, tableData);
      
      if (success) {
        // Masaları yeniden yükle
        await loadTables();
        developer.log('✅ Masa güncellendi', name: 'TablesViewModel');
      } else {
        developer.log('❌ Masa güncellenemedi', name: 'TablesViewModel');
      }
      
      return success;
    } catch (e) {
      developer.log('❌ Masa güncellenirken hata: $e', name: 'TablesViewModel');
      setError('Masa güncellenirken hata oluştu: $e');
      return false;
    }
  }

  /// Masa sil
  Future<bool> deleteTable(int tableId) async {
    try {
      developer.log('🗑️ Masa siliniyor: Table $tableId', name: 'TablesViewModel');
      
      final success = await _postgresService.deleteTable(tableId);
      
      if (success) {
        // Masaları yeniden yükle
        await loadTables();
        developer.log('✅ Masa silindi', name: 'TablesViewModel');
      } else {
        developer.log('❌ Masa silinemedi', name: 'TablesViewModel');
      }
      
      return success;
    } catch (e) {
      developer.log('❌ Masa silinirken hata: $e', name: 'TablesViewModel');
      setError('Masa silinirken hata oluştu: $e');
      return false;
    }
  }

  /// Bölgeye göre masaları getir
  Future<List<Map<String, dynamic>>> getTablesByRegion(int regionId) async {
    try {
      developer.log('📍 Bölge masaları getiriliyor: Region $regionId', name: 'TablesViewModel');
      
      await _postgresService.initialize();
      final tables = await _postgresService.getTablesByRegion(regionId);
      
      developer.log('✅ ${tables.length} bölge masası getirildi', name: 'TablesViewModel');
      return tables;
    } catch (e) {
      developer.log('❌ Bölge masaları getirilirken hata: $e', name: 'TablesViewModel');
      setError('Bölge masaları getirilirken hata oluştu: $e');
      return [];
    }
  }

  /// İstatistikleri getir
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      developer.log('📊 İstatistikler getiriliyor...', name: 'TablesViewModel');
      
      await _postgresService.initialize();
      final stats = await _postgresService.getStatistics();
      
      developer.log('✅ İstatistikler getirildi: $stats', name: 'TablesViewModel');
      return stats;
    } catch (e) {
      developer.log('❌ İstatistikler getirilirken hata: $e', name: 'TablesViewModel');
      setError('İstatistikler getirilirken hata oluştu: $e');
      return {
        'totalTables': 0,
        'availableTables': 0,
        'occupiedTables': 0,
        'reservedTables': 0,
      };
    }
  }

  /// SignalR başlat
  Future<void> initializeSignalR() async {
    try {
      developer.log('🔌 SignalR başlatılıyor...', name: 'TablesViewModel');
      
      await _signalRService.initialize();
      await _signalRService.connect();
      
      // Callback'leri ayarla
      _signalRService.onTableStatusChanged((tableId, status) {
        developer.log('🔄 Masa durumu değişti: Table $tableId -> $status', name: 'TablesViewModel');
        loadTables(); // Masaları yeniden yükle
      });

      _signalRService.onTableUpdated((tableId, data) {
        developer.log('✏️ Masa güncellendi: Table $tableId', name: 'TablesViewModel');
        loadTables(); // Masaları yeniden yükle
      });

      _signalRService.onTableCreated((data) {
        developer.log('➕ Yeni masa oluşturuldu', name: 'TablesViewModel');
        loadTables(); // Masaları yeniden yükle
      });

      _signalRService.onTableDeleted((tableId) {
        developer.log('🗑️ Masa silindi: Table $tableId', name: 'TablesViewModel');
        loadTables(); // Masaları yeniden yükle
      });

      developer.log('✅ SignalR başlatıldı', name: 'TablesViewModel');
    } catch (e) {
      developer.log('❌ SignalR başlatılırken hata: $e', name: 'TablesViewModel');
      // SignalR hatası kritik değil, uygulama devam edebilir
    }
  }

  /// Masa durumu rengini al
  Color getTableStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'occupied':
        return Colors.red;
      case 'reserved':
        return Colors.orange;
      case 'alert':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  /// Masa durumu metnini al
  String getTableStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Müsait';
      case 'occupied':
        return 'Dolu';
      case 'reserved':
        return 'Rezerve';
      case 'alert':
        return 'Uyarı';
      default:
        return 'Bilinmiyor';
    }
  }

  /// Loading durumunu ayarla
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Hata mesajını ayarla
  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Hata mesajını temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _signalRService.disconnect();
    super.dispose();
  }
}

// Provider
final tablesProvider = ChangeNotifierProvider<TablesViewModel>((ref) {
  return TablesViewModel();
});
