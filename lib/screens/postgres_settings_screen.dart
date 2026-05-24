import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/postgres_service.dart';

class PostgresSettingsScreen extends StatefulWidget {
  const PostgresSettingsScreen({super.key});

  @override
  State<PostgresSettingsScreen> createState() => _PostgresSettingsScreenState();
}

class _PostgresSettingsScreenState extends State<PostgresSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _databaseController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isConnected = false;
  String _connectionMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _databaseController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final dbService = DatabaseService();
      final settings = await dbService.getPostgresSettings();

      if (settings != null) {
        setState(() {
          _hostController.text = settings['host'] ?? '';
          _portController.text = settings['port']?.toString() ?? '5432';
          _databaseController.text = settings['database'] ?? '';
          _usernameController.text = settings['username'] ?? '';
          _passwordController.text = settings['password'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Ayarlar yüklenirken hata: $e');
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final settings = {
        'host': _hostController.text.trim(),
        'port': int.tryParse(_portController.text.trim()) ?? 5432,
        'database': _databaseController.text.trim(),
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
      };

      final dbService = DatabaseService();
      await dbService.savePostgresSettings(
        host: settings['host'] as String,
        port: settings['port'] as int,
        database: settings['database'] as String,
        username: settings['username'] as String,
        password: settings['password'] as String,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PostgreSQL ayarları kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ayarlar kaydedilirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isLoading = true);

    try {
      final postgresService = PostgresService();
      final isConnected = await postgresService.testConnection();

      setState(() {
        _isConnected = isConnected;
        _connectionMessage = isConnected
            ? 'PostgreSQL bağlantısı başarılı!'
            : 'PostgreSQL bağlantısı başarısız!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_connectionMessage),
            backgroundColor: isConnected ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionMessage = 'Bağlantı hatası: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PostgreSQL Ayarları'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bağlantı Durumu Kartı
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      _isConnected ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isConnected ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.check_circle : Icons.error,
                      color: _isConnected ? Colors.green : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PostgreSQL Bağlantısı',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isConnected ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(
                            _connectionMessage.isEmpty
                                ? 'Bağlantı test edilmedi'
                                : _connectionMessage,
                            style: TextStyle(
                              fontSize: 12,
                              color: _isConnected
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Ayarlar Formu
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Host
                      TextFormField(
                        controller: _hostController,
                        decoration: const InputDecoration(
                          labelText: 'Host',
                          hintText: 'localhost',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Host gerekli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Port
                      TextFormField(
                        controller: _portController,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          hintText: '5432',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Port gerekli';
                          }
                          final port = int.tryParse(value.trim());
                          if (port == null || port <= 0 || port > 65535) {
                            return 'Geçerli bir port numarası girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Database
                      TextFormField(
                        controller: _databaseController,
                        decoration: const InputDecoration(
                          labelText: 'Veritabanı Adı',
                          hintText: 'exfin_rest',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veritabanı adı gerekli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Username
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Kullanıcı Adı',
                          hintText: 'postgres',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Kullanıcı adı gerekli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Şifre',
                          hintText: '********',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Şifre gerekli';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                          _isLoading ? 'Kaydediliyor...' : 'Ayarları Kaydet'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _testConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_isLoading
                          ? 'Test Ediliyor...'
                          : 'Bağlantıyı Test Et'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
