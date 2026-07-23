// Dosya Adı: login_screen.dart
// Açıklama: Şık marka odaklı login ekranı ve hızlı rol girişi
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-23

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../screens/postgres_settings_screen.dart';
import '../../../../services/postgres_service.dart';

/// {@template login_screen}
/// EXFIN Restaurant giriş ekranı.
///
/// Marka odaklı atmosfer, PIN girişi ve hızlı rol seçimi sunar.
///
/// Kullanım örneği:
/// ```dart
/// const LoginScreen();
/// ```
/// {@endtemplate}
class LoginScreen extends ConsumerStatefulWidget {
  /// {@macro login_screen}
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  /// [_isDbConnected]: Veritabanı bağlantısı açık mı
  bool _isDbConnected = false;

  /// [_isCheckingConnection]: Bağlantı kontrolü sürüyor mu
  bool _isCheckingConnection = true;

  /// [_showNumericKeyboard]: Numerik klavye görünür mü
  bool _showNumericKeyboard = false;

  /// [_isLoggingIn]: Giriş işlemi devam ediyor mu
  bool _isLoggingIn = false;

  /// [_passwordController]: PIN / şifre alanı denetleyicisi
  final TextEditingController _passwordController = TextEditingController();

  /// [_passwordFocusNode]: PIN alanı odak düğümü
  final FocusNode _passwordFocusNode = FocusNode();

  /// [_entryController]: Açılış animasyonu denetleyicisi
  late final AnimationController _entryController;

  /// [_breathController]: Arka plan nefes animasyonu
  late final AnimationController _breathController;

  /// [_fadeIn]: İçerik fade animasyonu
  late final Animation<double> _fadeIn;

  /// [_slideUp]: İçerik yukarı kayma animasyonu
  late final Animation<Offset> _slideUp;

  static const Color _accent = Color(0xFFFF6B35);
  static const Color _ink = Color(0xFF1C1917);
  static const Color _muted = Color(0xFF78716C);
  static const Color _panel = Color(0xFFFBF8F5);
  static const Color _stone = Color(0xFFE7E2DC);

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entryController.forward();
    _checkDatabaseConnection();
  }

  /// {@template _checkDatabaseConnection}
  /// PostgreSQL bağlantısını test eder ve durum rozetini günceller.
  ///
  /// Dönüş değeri:
  /// - [Future<void>]: Kontrol tamamlandığında tamamlanır
  /// {@endtemplate}
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _isDbConnected = false;
          _isCheckingConnection = false;
        });
      }
    }
  }

  /// {@template _openDatabaseSettings}
  /// Veritabanı ayarları ekranını açar; dönüşte bağlantıyı yeniden kontrol eder.
  /// {@endtemplate}
  void _openDatabaseSettings() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const PostgresSettingsScreen(),
      ),
    )
        .then((_) {
      _checkDatabaseConnection();
    });
  }

  /// {@template _quickLogin}
  /// Verilen kullanıcı adı ve şifre ile hızlı giriş dener.
  ///
  /// Parametreler:
  /// - [username]: Kullanıcı adı
  /// - [password]: Şifre
  /// {@endtemplate}
  Future<void> _quickLogin(String username, String password) async {
    if (_isLoggingIn) return;

    setState(() => _isLoggingIn = true);
    try {
      final postgresService = PostgresService();
      await postgresService.initialize();

      final authenticatedUser =
          await postgresService.authenticateUser(username, password);

      if (authenticatedUser != null && mounted) {
        context.go('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Giriş başarısız'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giriş hatası: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  /// {@template _openKeyboard}
  /// Numerik PIN klavyesini açar ve odaklar.
  /// {@endtemplate}
  void _openKeyboard() {
    setState(() => _showNumericKeyboard = true);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _passwordFocusNode.requestFocus();
      }
    });
  }

  /// {@template _closeKeyboard}
  /// Numerik PIN klavyesini kapatır.
  /// {@endtemplate}
  void _closeKeyboard() {
    setState(() => _showNumericKeyboard = false);
    _passwordFocusNode.unfocus();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _breathController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 900;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _breathController,
            builder: (context, child) {
              return CustomPaint(
                painter: _LoginAtmospherePainter(
                  progress: _breathController.value,
                ),
                size: Size.infinite,
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _TopBar(
                    isChecking: _isCheckingConnection,
                    isConnected: _isDbConnected,
                    onSettings: _openDatabaseSettings,
                    onClose: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1080),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 40 : 20,
                              vertical: 24,
                            ),
                            child: isWide
                                ? Row(
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: _BrandHero(accent: _accent),
                                      ),
                                      const SizedBox(width: 40),
                                      Expanded(
                                        flex: 4,
                                        child: _LoginPanel(
                                          showKeyboard: _showNumericKeyboard,
                                          isLoggingIn: _isLoggingIn,
                                          passwordController:
                                              _passwordController,
                                          passwordFocusNode:
                                              _passwordFocusNode,
                                          onOpenKeyboard: _openKeyboard,
                                          onCloseKeyboard: _closeKeyboard,
                                          onSubmitPin: (value) {
                                            if (value.isNotEmpty) {
                                              _quickLogin('admin', value);
                                            }
                                          },
                                          onRoleTap: _quickLogin,
                                        ),
                                      ),
                                    ],
                                  )
                                : SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        const _BrandHero(accent: _accent),
                                        const SizedBox(height: 28),
                                        _LoginPanel(
                                          showKeyboard: _showNumericKeyboard,
                                          isLoggingIn: _isLoggingIn,
                                          passwordController:
                                              _passwordController,
                                          passwordFocusNode:
                                              _passwordFocusNode,
                                          onOpenKeyboard: _openKeyboard,
                                          onCloseKeyboard: _closeKeyboard,
                                          onSubmitPin: (value) {
                                            if (value.isNotEmpty) {
                                              _quickLogin('admin', value);
                                            }
                                          },
                                          onRoleTap: _quickLogin,
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoggingIn)
            ColoredBox(
              color: _ink.withValues(alpha: 0.18),
              child: const Center(
                child: CircularProgressIndicator(color: _accent),
              ),
            ),
        ],
      ),
    );
  }
}

/// {@template _top_bar}
/// Üst durum çubuğu: bağlantı durumu, ayarlar ve kapat.
/// {@endtemplate}
class _TopBar extends StatelessWidget {
  /// {@macro _top_bar}
  const _TopBar({
    required this.isChecking,
    required this.isConnected,
    required this.onSettings,
    required this.onClose,
  });

  /// [isChecking]: Bağlantı kontrol ediliyor mu
  final bool isChecking;

  /// [isConnected]: Bağlantı var mı
  final bool isConnected;

  /// [onSettings]: Ayarlar geri çağrısı
  final VoidCallback onSettings;

  /// [onClose]: Kapat geri çağrısı
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    if (isChecking) {
      statusColor = const Color(0xFFD97706);
      statusLabel = 'Kontrol ediliyor';
      statusIcon = Icons.hourglass_top_rounded;
    } else if (isConnected) {
      statusColor = const Color(0xFF15803D);
      statusLabel = 'Veritabanı bağlı';
      statusIcon = Icons.wifi_rounded;
    } else {
      statusColor = const Color(0xFFB91C1C);
      statusLabel = 'Veritabanı kapalı';
      statusIcon = Icons.wifi_off_rounded;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7E2DC)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _IconAction(
          icon: Icons.tune_rounded,
          tooltip: 'Veritabanı Ayarları',
          onTap: onSettings,
        ),
        const SizedBox(width: 8),
        _IconAction(
          icon: Icons.close_rounded,
          tooltip: 'Kapat',
          onTap: onClose,
        ),
      ],
    );
  }
}

/// {@template _icon_action}
/// Üst bardaki yuvarlatılmış ikon düğmesi.
/// {@endtemplate}
class _IconAction extends StatelessWidget {
  /// {@macro _icon_action}
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  /// [icon]: Gösterilecek ikon
  final IconData icon;

  /// [tooltip]: Erişilebilirlik ipucu
  final String tooltip;

  /// [onTap]: Dokunma geri çağrısı
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE7E2DC)),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF44403C)),
          ),
        ),
      ),
    );
  }
}

/// {@template _brand_hero}
/// Marka hero alanı: EXFIN kelime işareti ve kısa tanıtım.
/// {@endtemplate}
class _BrandHero extends StatelessWidget {
  /// {@macro _brand_hero}
  const _BrandHero({required this.accent});

  /// [accent]: Vurgu rengi
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Center(
            child: Text(
              'EX',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'EX',
                style: TextStyle(
                  fontSize: 64,
                  height: 0.95,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: -1.5,
                ),
              ),
              const TextSpan(
                text: 'FIN',
                style: TextStyle(
                  fontSize: 64,
                  height: 0.95,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF1C1917),
                  letterSpacing: -1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'RESTAURANT',
          style: TextStyle(
            color: Color(0xFF78716C),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: const Text(
            'Masalar, siparişler ve mutfak — tek ekrandan yönetin.',
            style: TextStyle(
              color: Color(0xFF57534E),
              fontSize: 17,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

/// {@template _login_panel}
/// Giriş etkileşim paneli: PIN ve rol seçimi.
/// {@endtemplate}
class _LoginPanel extends StatelessWidget {
  /// {@macro _login_panel}
  const _LoginPanel({
    required this.showKeyboard,
    required this.isLoggingIn,
    required this.passwordController,
    required this.passwordFocusNode,
    required this.onOpenKeyboard,
    required this.onCloseKeyboard,
    required this.onSubmitPin,
    required this.onRoleTap,
  });

  /// [showKeyboard]: PIN alanı açık mı
  final bool showKeyboard;

  /// [isLoggingIn]: Giriş yükleniyor mu
  final bool isLoggingIn;

  /// [passwordController]: PIN denetleyicisi
  final TextEditingController passwordController;

  /// [passwordFocusNode]: PIN odak düğümü
  final FocusNode passwordFocusNode;

  /// [onOpenKeyboard]: Klavye aç
  final VoidCallback onOpenKeyboard;

  /// [onCloseKeyboard]: Klavye kapat
  final VoidCallback onCloseKeyboard;

  /// [onSubmitPin]: PIN gönder
  final ValueChanged<String> onSubmitPin;

  /// [onRoleTap]: Rol ile giriş
  final Future<void> Function(String username, String password) onRoleTap;

  static const List<_RoleOption> _roles = [
    _RoleOption('Admin', 'admin', 'admin123', Icons.shield_outlined,
        Color(0xFFDC2626)),
    _RoleOption('Manager', 'manager', 'password', Icons.badge_outlined,
        Color(0xFF2563EB)),
    _RoleOption('Cashier', 'cashier', 'password', Icons.payments_outlined,
        Color(0xFF0F766E)),
    _RoleOption('Garson', 'waiter', 'password', Icons.room_service_outlined,
        Color(0xFFEA580C)),
    _RoleOption('Kitchen', 'kitchen', 'password', Icons.soup_kitchen_outlined,
        Color(0xFF7C3AED)),
    _RoleOption('Guest', 'guest', 'password', Icons.visibility_outlined,
        Color(0xFF475569)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      decoration: BoxDecoration(
        color: _LoginScreenState._panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C1917).withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Giriş',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _LoginScreenState._ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Rol seçin veya PIN ile devam edin',
            style: TextStyle(
              fontSize: 14,
              color: _LoginScreenState._muted,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: showKeyboard
                ? _PinEntry(
                    key: const ValueKey('pin-open'),
                    controller: passwordController,
                    focusNode: passwordFocusNode,
                    onClose: onCloseKeyboard,
                    onSubmit: onSubmitPin,
                  )
                : _PinPreview(
                    key: const ValueKey('pin-closed'),
                    onOpen: onOpenKeyboard,
                  ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Hızlı giriş',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _LoginScreenState._muted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoCol = constraints.maxWidth >= 320;
              if (!twoCol) {
                return Column(
                  children: [
                    for (var i = 0; i < _roles.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _RoleTile(
                        role: _roles[i],
                        enabled: !isLoggingIn,
                        onTap: () => onRoleTap(
                          _roles[i].username,
                          _roles[i].password,
                        ),
                      ),
                    ],
                  ],
                );
              }

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final role in _roles)
                    SizedBox(
                      width: (constraints.maxWidth - 10) / 2,
                      child: _RoleTile(
                        role: role,
                        enabled: !isLoggingIn,
                        onTap: () => onRoleTap(role.username, role.password),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// {@template _pin_preview}
/// Kapalı PIN önizlemesi ve klavye aç düğmesi.
/// {@endtemplate}
class _PinPreview extends StatelessWidget {
  /// {@macro _pin_preview}
  const _PinPreview({
    super.key,
    required this.onOpen,
  });

  /// [onOpen]: Klavye açma geri çağrısı
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < 4
                    ? _LoginScreenState._ink.withValues(alpha: 0.85)
                    : _LoginScreenState._stone,
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.dialpad_rounded, size: 20),
            label: const Text(
              'PIN ile giriş',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _LoginScreenState._ink,
              side: const BorderSide(color: Color(0xFFD6D3D1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// {@template _pin_entry}
/// Açık PIN giriş alanı.
/// {@endtemplate}
class _PinEntry extends StatelessWidget {
  /// {@macro _pin_entry}
  const _PinEntry({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onClose,
    required this.onSubmit,
  });

  /// [controller]: Metin denetleyicisi
  final TextEditingController controller;

  /// [focusNode]: Odak düğümü
  final FocusNode focusNode;

  /// [onClose]: Kapat geri çağrısı
  final VoidCallback onClose;

  /// [onSubmit]: Gönder geri çağrısı
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          obscureText: true,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            letterSpacing: 8,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'PIN',
            hintStyle: TextStyle(
              color: _LoginScreenState._muted.withValues(alpha: 0.7),
              letterSpacing: 4,
              fontSize: 18,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE7E2DC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE7E2DC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: _LoginScreenState._accent,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onSubmitted: onSubmit,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: onClose,
                child: const Text('Vazgeç'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      onSubmit(controller.text);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _LoginScreenState._accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Giriş Yap',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// {@template _role_option}
/// Hızlı giriş rol tanımı.
/// {@endtemplate}
class _RoleOption {
  /// {@macro _role_option}
  const _RoleOption(
    this.label,
    this.username,
    this.password,
    this.icon,
    this.color,
  );

  /// [label]: Görünen rol adı
  final String label;

  /// [username]: Giriş kullanıcı adı
  final String username;

  /// [password]: Giriş şifresi
  final String password;

  /// [icon]: Rol ikonu
  final IconData icon;

  /// [color]: Vurgu rengi
  final Color color;
}

/// {@template _role_tile}
/// Rol seçim kutusu.
/// {@endtemplate}
class _RoleTile extends StatefulWidget {
  /// {@macro _role_tile}
  const _RoleTile({
    required this.role,
    required this.enabled,
    required this.onTap,
  });

  /// [role]: Rol bilgisi
  final _RoleOption role;

  /// [enabled]: Tıklanabilir mi
  final bool enabled;

  /// [onTap]: Seçim geri çağrısı
  final VoidCallback onTap;

  @override
  State<_RoleTile> createState() => _RoleTileState();
}

class _RoleTileState extends State<_RoleTile> {
  /// [_hovered]: Fare üzerinde mi
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final role = widget.role;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _hovered ? Colors.white : const Color(0xFFFFFCF9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? role.color.withValues(alpha: 0.45)
                : const Color(0xFFE7E2DC),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: role.color.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? widget.onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: role.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(role.icon, size: 18, color: role.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      role.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _LoginScreenState._ink,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: _LoginScreenState._muted.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// {@template _login_atmosphere_painter}
/// Login arka planı için yumuşak gradient ve ışık lekeleri.
/// {@endtemplate}
class _LoginAtmospherePainter extends CustomPainter {
  /// {@macro _login_atmosphere_painter}
  _LoginAtmospherePainter({required this.progress});

  /// [progress]: 0–1 arası animasyon ilerlemesi
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shift = math.sin(progress * math.pi) * 0.08;

    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-0.8 + shift, -1),
        end: Alignment(1, 1.1 - shift),
        colors: const [
          Color(0xFFF3EEE8),
          Color(0xFFE8E0D6),
          Color(0xFFF7F2EC),
          Color(0xFFEDE6DE),
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final blobPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    blobPaint.color = const Color(0xFFFF6B35).withValues(alpha: 0.14 + shift * 0.05);
    canvas.drawCircle(
      Offset(size.width * (0.18 + shift * 0.04), size.height * 0.22),
      size.shortestSide * 0.42,
      blobPaint,
    );

    blobPaint.color = const Color(0xFF78716C).withValues(alpha: 0.08);
    canvas.drawCircle(
      Offset(size.width * (0.86 - shift * 0.03), size.height * 0.78),
      size.shortestSide * 0.48,
      blobPaint,
    );

    blobPaint.color = const Color(0xFFFFB088).withValues(alpha: 0.12);
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * (0.18 + shift * 0.05)),
      size.shortestSide * 0.28,
      blobPaint,
    );

    final linePaint = Paint()
      ..color = const Color(0xFF1C1917).withValues(alpha: 0.035)
      ..strokeWidth = 1;

    for (var i = 0; i < 8; i++) {
      final y = size.height * (0.12 + i * 0.11);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoginAtmospherePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
