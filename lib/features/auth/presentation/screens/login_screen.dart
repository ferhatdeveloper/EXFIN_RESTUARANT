// Dosya Adı: login_screen.dart
// Açıklama: Eski tasarıma uygun login ekranı - sadece hızlı giriş butonları
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/postgres_service.dart';
import '../../../../screens/postgres_settings_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isDbConnected = false;
  bool _isCheckingConnection = true;
  bool _showNumericKeyboard = false;
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _checkDatabaseConnection();
  }

  Future<void> _checkDatabaseConnection() async {
    setState(() => _isCheckingConnection = true);

    try {
      final postgresService = PostgresService();
      final isConnected = await postgresService.testConnection();

      if (mounted) {
        setState(() {
          _isDbConnected = isConnected;
          _isCheckingConnection = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDbConnected = false;
          _isCheckingConnection = false;
        });
      }
    }
  }

  void _openDatabaseSettings() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const PostgresSettingsScreen(),
      ),
    )
        .then((_) {
      // Ayarlar ekranından döndükten sonra bağlantıyı tekrar kontrol et
      _checkDatabaseConnection();
    });
  }

  void _quickLogin(String username, String password) async {
    try {
      final postgresService = PostgresService();
      await postgresService.initialize();

      final authenticatedUser =
          await postgresService.authenticateUser(username, password);

      if (authenticatedUser != null && mounted) {
        context.go('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hızlı giriş başarısız'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hızlı giriş hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openKeyboard() {
    // Numerik klavye açma işlevi
    setState(() {
      _showNumericKeyboard = true;
    });

    // Kısa bir gecikme sonrası focus'u ayarla
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _passwordFocusNode.requestFocus();
      }
    });
  }

  void _closeKeyboard() {
    setState(() {
      _showNumericKeyboard = false;
    });
    _passwordFocusNode.unfocus();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      body: Stack(
        children: [
          // Sağ üstte DB Bağlantısı durumu ve ikonlar
          Positioned(
            top: 24,
            right: 24,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isCheckingConnection
                        ? Colors.orange[400]
                        : _isDbConnected
                            ? Colors.green[400]
                            : Colors.red[400],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isCheckingConnection
                            ? Icons.hourglass_empty
                            : _isDbConnected
                                ? Icons.wifi
                                : Icons.wifi_off,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isCheckingConnection
                            ? 'Bağlantı Kontrol Ediliyor...'
                            : _isDbConnected
                                ? 'DB Bağlantısı Var'
                                : 'DB Bağlantısı Kapalı',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.grey),
                  onPressed: _openDatabaseSettings,
                  tooltip: 'Veritabanı Ayarları',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    // Uygulamayı kapat
                    Navigator.of(context).pop();
                  },
                  tooltip: 'Kapat',
                ),
              ],
            ),
          ),
          // Ortadaki kart
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: 380,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green[400],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 6),
                      ),
                      child: const Center(
                        child: Text(
                          'EXFIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Başlık
                    const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'EX',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1389FD),
                              fontSize: 28,
                            ),
                          ),
                          TextSpan(
                            text: 'FIN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB0A9B7),
                              fontSize: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'CAFE REST',
                      style: TextStyle(
                        color: Color(0xFFB0A9B7),
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Şifreli giriş alanı
                    if (_showNumericKeyboard) ...[
                      // Numerik klavye açıkken TextField göster
                      Container(
                        width: 200,
                        child: TextField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'Şifre girin',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _quickLogin('admin', value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _closeKeyboard,
                            child: const Text('Klavyeyi Kapat'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_passwordController.text.isNotEmpty) {
                                _quickLogin('admin', _passwordController.text);
                              }
                            },
                            child: const Text('Giriş Yap'),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Numerik klavye kapalıyken yıldızlı göster
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          8,
                          (i) => const Icon(
                            Icons.star,
                            size: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Hızlı Giriş (Geçici)',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Hızlı giriş butonları
                    Column(
                      children: [
                        _roleButton(
                          context,
                          'Admin',
                          Icons.admin_panel_settings,
                          Colors.red,
                          () => _quickLogin('admin', 'admin123'),
                        ),
                        const SizedBox(height: 10),
                        _roleButton(
                          context,
                          'Manager',
                          Icons.person,
                          Colors.blue,
                          () => _quickLogin('manager', 'password'),
                        ),
                        const SizedBox(height: 10),
                        _roleButton(
                          context,
                          'Cashier',
                          Icons.credit_card,
                          Colors.teal,
                          () => _quickLogin('cashier', 'password'),
                        ),
                        const SizedBox(height: 10),
                        _roleButton(
                          context,
                          'Garson',
                          Icons.person_outline,
                          Colors.orange,
                          () => _quickLogin('waiter', 'password'),
                        ),
                        const SizedBox(height: 10),
                        _roleButton(
                          context,
                          'Kitchen',
                          Icons.kitchen,
                          Colors.purple,
                          () => _quickLogin('kitchen', 'password'),
                        ),
                        const SizedBox(height: 10),
                        _roleButton(
                          context,
                          'Guest',
                          Icons.remove_red_eye,
                          Colors.teal,
                          () => _quickLogin('guest', 'password'),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _showNumericKeyboard
                              ? _closeKeyboard
                              : _openKeyboard,
                          icon: Icon(_showNumericKeyboard
                              ? Icons.keyboard_hide
                              : Icons.keyboard),
                          label: Text(_showNumericKeyboard
                              ? 'Klavyeyi Kapat'
                              : 'Klavye Aç'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(color: Colors.blueGrey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Eski login ekranı için özel buton
  static Widget _roleButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}
