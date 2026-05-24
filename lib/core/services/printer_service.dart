import 'dart:io';
import 'package:flutter/foundation.dart';
import '../app_config.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  Future<bool> printToCategory(String category, String content) async {
    try {
      // Kategori bazlı yazıcı IP'sini al
      String? printerIp = await _getPrinterIpForCategory(category);

      if (printerIp == null) {
        throw Exception('Kategori $category için yazıcı bulunamadı');
      }

      // Yazıcıya gönder
      return await _sendToPrinter(printerIp, content);
    } catch (e) {
      // TODO: Logger kullan
      debugPrint('Yazıcı hatası: $e');
      return false;
    }
  }

  Future<String?> _getPrinterIpForCategory(String category) async {
    // TODO: Veritabanından kategori-yazıcı eşleştirmesini al
    // Şimdilik mock data
    Map<String, String> categoryPrinters = {
      'Sıcak Yemek': '192.168.1.20',
      'İçecek': '192.168.1.21',
      'Tatlı': '192.168.1.22',
      'Salata': '192.168.1.23',
    };

    return categoryPrinters[category];
  }

  Future<bool> _sendToPrinter(String ip, String content) async {
    try {
      final socket = await Socket.connect(ip, 9100,
          timeout: const Duration(milliseconds: AppConfig.printerTimeout));

      socket.write(content);
      await socket.flush();
      socket.destroy();

      return true;
    } catch (e) {
      // TODO: Logger kullan
      debugPrint('Yazıcı bağlantı hatası: $e');
      return false;
    }
  }
}
