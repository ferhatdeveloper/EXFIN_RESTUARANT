// Dosya Adı: postgres_settings_screen.dart
// Açıklama: RetailEX tarzı Veritabanı Bağlantısı ayar ekranı
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-12-02

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import '../services/postgres_service.dart';

enum ConnectionMode { online, hybrid, offline }

enum ConnectionProvider { postgresql, restApi }

class PostgresSettingsScreen extends StatefulWidget {
  const PostgresSettingsScreen({super.key});

  @override
  State<PostgresSettingsScreen> createState() => _PostgresSettingsScreenState();
}

class _PostgresSettingsScreenState extends State<PostgresSettingsScreen> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _databaseController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _restUrlController = TextEditingController();
  final _tenantController = TextEditingController();

  ConnectionMode _mode = ConnectionMode.offline;
  ConnectionProvider _provider = ConnectionProvider.postgresql;
  bool _isTesting = false;
  bool _testSuccess = false;
  String? _testMessage;

  @override
  void initState() {
    super.initState();
    _hostController.text = dotenv.env['PG_HOST'] ?? 'localhost';
    _portController.text = dotenv.env['PG_PORT'] ?? '5432';
    _databaseController.text = dotenv.env['PG_DATABASE'] ?? 'exfin_db';
    _usernameController.text = dotenv.env['PG_USERNAME'] ?? 'postgres';
    _passwordController.text = dotenv.env['PG_PASSWORD'] ?? '';
    _restUrlController.text = 'https://api.retailex.app/';
    _tenantController.text = '';
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _databaseController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _restUrlController.dispose();
    _tenantController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testMessage = null;
    });

    try {
      final service = PostgresService();
      final connected = await service.testConnection();
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = connected;
          _testMessage =
              connected ? 'Bağlantı başarılı!' : 'Bağlantı başarısız.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testMessage = 'Hata: $e';
        });
      }
    }
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Ayarlar kaydedildi'),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
    _closeScreen();
  }

  void _closeScreen() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2D),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModeDropdown(),
                        const SizedBox(height: 8),
                        _buildModeDescription(),
                        const SizedBox(height: 20),
                        if (_mode == ConnectionMode.online)
                          _buildOnlineFields()
                        else
                          _buildOfflineFields(),
                        const SizedBox(height: 16),
                        _buildInfoText(),
                        const SizedBox(height: 20),
                        _buildTestButton(),
                        if (_testMessage != null) ...[
                          const SizedBox(height: 12),
                          _buildTestResult(),
                        ],
                        const SizedBox(height: 12),
                        _buildSaveButton(),
                        const SizedBox(height: 12),
                        _buildFooterText(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A5F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.storage_outlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'VERİTABANI BAĞLANTISI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          TextButton(
            onPressed: _testConnection,
            child: Text(
              'TEST',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: _closeScreen,
            tooltip: 'Kapat',
            iconSize: 24,
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

  Widget _buildModeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BAĞLANTI MODU',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<ConnectionMode>(
            value: _mode,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(
                value: ConnectionMode.online,
                child: Text('Online — merkezi (uzak) sunucu'),
              ),
              DropdownMenuItem(
                value: ConnectionMode.hybrid,
                child: Text('Hybrid — yerel/LAN host + senkron'),
              ),
              DropdownMenuItem(
                value: ConnectionMode.offline,
                child: Text('Offline — yalnızca bu ekrandaki host'),
              ),
            ],
            onChanged: (v) => setState(() => _mode = v!),
          ),
        ),
      ],
    );
  }

  Widget _buildModeDescription() {
    final String text;
    if (_mode == ConnectionMode.online) {
      text =
          'Online seçiliyken SQL, Yönetim → Veritabanı\'ndaki uzak sunucu bilgisine gider. Uzak şube için genelde Hybrid veya Offline + aşağıdaki host.';
    } else if (_mode == ConnectionMode.hybrid) {
      text =
          'Hybrid modda lokal PostgreSQL + uzak sunucu birlikte çalışır. Bağlantı kesilince lokal devam eder.';
    } else {
      text =
          'Online seçiliyken SQL, Yönetim → Veritabanı\'ndaki uzak sunucu bilgisine gider. Uzak şube için genelde Hybrid veya Offline + aşağıdaki host.';
    }
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
    );
  }

  Widget _buildOnlineFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('BAĞLANTI SAĞLAYICI'),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<ConnectionProvider>(
            value: _provider,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(
                value: ConnectionProvider.postgresql,
                child: Text('PostgreSQL (doğrudan)'),
              ),
              DropdownMenuItem(
                value: ConnectionProvider.restApi,
                child: Text('Rest API (PostgREST)'),
              ),
            ],
            onChanged: (v) => setState(() => _provider = v!),
          ),
        ),
        const SizedBox(height: 16),
        if (_provider == ConnectionProvider.restApi) ...[
          _buildLabel('POSTGREST API URL'),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'RETAİLEX BULUTU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ÖZEL TAM URL',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildTextField(
                  _restUrlController,
                  'https://api.retailex.app/',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildTextField(_tenantController, 'kiracı_adı'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'RetailEX bulutu: yalnızca kiracı yolunu yazın (kayıtta https://api.retailex.app/kiracı birleştirilir). LAN veya başka domain için «Özel tam URL».',
            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ] else
          _buildPgFields(),
      ],
    );
  }

  Widget _buildOfflineFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('BAĞLANTI SAĞLAYICI'),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'PostgreSQL (doğrudan)',
            style: TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        _buildPgFields(),
      ],
    );
  }

  Widget _buildPgFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('HOST (SUNUCU IP / HOSTNAME)'),
                  const SizedBox(height: 6),
                  _buildTextField(_hostController, 'localhost'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('PORT'),
                  const SizedBox(height: 6),
                  _buildTextField(_portController, '5432'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildLabel('VERİTABANI'),
        const SizedBox(height: 6),
        _buildTextField(_databaseController, 'retailex_local'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('KULLANICI'),
                  const SizedBox(height: 6),
                  _buildTextField(_usernameController, 'postgres'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('ŞİFRE'),
                  const SizedBox(height: 6),
                  _buildTextField(_passwordController, '••••••••',
                      obscure: true),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoText() {
    return Text(
      'Uzak sunucu: PostgreSQL\'in kurulu olduğu makinenin adresini girin. PG bu bilgisayardaysa 127.0.0.1 kullanın.',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildTestButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isTesting ? null : _testConnection,
        icon: _isTesting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.cable_outlined, size: 18),
        label: Text(
          _isTesting ? 'Test ediliyor...' : 'BAĞLANTIYI TEST ET',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildTestResult() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _testSuccess
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _testSuccess
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _testSuccess ? Icons.check_circle : Icons.error_outline,
            color: _testSuccess ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _testMessage!,
              style: TextStyle(
                fontSize: 13,
                color: _testSuccess ? Colors.green[800] : Colors.red[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: const Text(
          'AYARLARI KAYDET',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterText() {
    return const Text(
      'TEST DAİMA BU FORMDAKİ PG BİLGİSİNİ DENER. ONLİNE MODDA ÇALIŞMA ZAMANI UZAK KAYDI KULLANIR — AYNI ADRESİ KAYDET VEYA YÖNETİM\'DEN EŞİTLEYİN.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 10,
        color: Color(0xFF9CA3AF),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
