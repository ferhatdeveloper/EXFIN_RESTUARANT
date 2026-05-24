// Dosya Adı: login_screen.dart
// Açıklama: Modern POS/Retail tarzı login ekranı - Dark/Light tema, PIN pad ve personel seçimi
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-12-02

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/postgres_service.dart';
import '../../../../screens/postgres_settings_screen.dart';
import '../../../../shared/providers/theme_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isDbConnected = false;
  bool _isCheckingConnection = true;
  bool _isLoggingIn = false;
  String _enteredPin = '';
  int? _selectedStaffIndex;
  late AnimationController _shakeController;

  static const int _pinLength = 6;

  final List<_StaffMember> _staffMembers = [
    _StaffMember(
      username: 'admin',
      password: 'admin123',
      role: 'admin',
      displayName: 'Admin',
      icon: Icons.shield_outlined,
      color: Color(0xFFE53935),
    ),
    _StaffMember(
      username: 'manager',
      password: 'password',
      role: 'manager',
      displayName: 'Müdür',
      icon: Icons.manage_accounts_outlined,
      color: Color(0xFF1E88E5),
    ),
    _StaffMember(
      username: 'cashier',
      password: 'password',
      role: 'cashier',
      displayName: 'Kasiyer',
      icon: Icons.point_of_sale_outlined,
      color: Color(0xFF00897B),
    ),
    _StaffMember(
      username: 'waiter',
      password: 'password',
      role: 'waiter',
      displayName: 'Garson',
      icon: Icons.room_service_outlined,
      color: Color(0xFFF4511E),
    ),
    _StaffMember(
      username: 'kitchen',
      password: 'password',
      role: 'kitchen',
      displayName: 'Mutfak',
      icon: Icons.soup_kitchen_outlined,
      color: Color(0xFF8E24AA),
    ),
    _StaffMember(
      username: 'guest',
      password: 'password',
      role: 'guest',
      displayName: 'Misafir',
      icon: Icons.person_outline,
      color: Color(0xFF546E7A),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkDatabaseConnection();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
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
        .push(MaterialPageRoute(
          builder: (context) => const PostgresSettingsScreen(),
        ))
        .then((_) => _checkDatabaseConnection());
  }

  void _onNumberPressed(String number) {
    if (_enteredPin.length < _pinLength) {
      setState(() => _enteredPin += number);
      if (_enteredPin.length == _pinLength) {
        _attemptLogin();
      }
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _onClearPressed() {
    setState(() => _enteredPin = '');
  }

  void _selectStaff(int index) {
    setState(() {
      _selectedStaffIndex = index;
      _enteredPin = '';
    });
  }

  void _attemptLogin() {
    if (_selectedStaffIndex == null) {
      _quickLogin('admin', _enteredPin);
    } else {
      final staff = _staffMembers[_selectedStaffIndex!];
      _quickLogin(staff.username, staff.password);
    }
  }

  void _quickLogin(String username, String password) async {
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
        _onLoginFailed('Giriş başarısız. Lütfen tekrar deneyin.');
      }
    } catch (e) {
      if (mounted) {
        _onLoginFailed('Bağlantı hatası oluştu.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
          _enteredPin = '';
        });
      }
    }
  }

  void _onLoginFailed(String message) {
    _shakeController.forward(from: 0);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleTheme() {
    final currentMode = ref.read(themeProvider);
    final ThemeMode nextMode;
    if (currentMode == ThemeMode.dark) {
      nextMode = ThemeMode.light;
    } else {
      nextMode = ThemeMode.dark;
    }
    ref.read(themeProvider.notifier).setTheme(nextMode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = _LoginColors.fromBrightness(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackground(colors),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return _buildWideLayout(colors);
                }
                return _buildNarrowLayout(colors);
              },
            ),
            _buildTopBar(colors, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(_LoginColors colors) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.backgroundGradient,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(_LoginColors colors, bool isDark) {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Row(
        children: [
          _buildConnectionBadge(colors),
          const Spacer(),
          _buildThemeToggle(colors, isDark),
          const SizedBox(width: 8),
          _buildSmallIconButton(
            Icons.settings_outlined,
            _openDatabaseSettings,
            colors,
          ),
          const SizedBox(width: 4),
          _buildSmallIconButton(
            Icons.refresh_outlined,
            _checkDatabaseConnection,
            colors,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBadge(_LoginColors colors) {
    final Color badgeColor = _isCheckingConnection
        ? Colors.orange
        : _isDbConnected
            ? Colors.green
            : Colors.redAccent;

    final IconData badgeIcon = _isCheckingConnection
        ? Icons.sync
        : _isDbConnected
            ? Icons.cloud_done_outlined
            : Icons.cloud_off_outlined;

    final String badgeText = _isCheckingConnection
        ? 'Kontrol...'
        : _isDbConnected
            ? 'Bağlı'
            : 'Bağlantı Yok';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: badgeColor, size: 14),
          const SizedBox(width: 5),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(_LoginColors colors, bool isDark) {
    return GestureDetector(
      onTap: _toggleTheme,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Icon(
          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          color: colors.textSecondary,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildSmallIconButton(
    IconData icon,
    VoidCallback onTap,
    _LoginColors colors,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Icon(icon, color: colors.textSecondary, size: 18),
      ),
    );
  }

  Widget _buildWideLayout(_LoginColors colors) {
    return Row(
      children: [
        Expanded(flex: 4, child: _buildBrandingPanel(colors)),
        Expanded(flex: 6, child: _buildLoginPanel(colors)),
      ],
    );
  }

  Widget _buildNarrowLayout(_LoginColors colors) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              _buildCompactBranding(colors),
              const SizedBox(height: 28),
              _buildStaffGrid(colors),
              const SizedBox(height: 20),
              _buildPinDots(colors),
              const SizedBox(height: 20),
              _buildNumpad(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingPanel(_LoginColors colors) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1389FD), Color(0xFF0D47A1)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1389FD).withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'EX',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'EX',
                  style: TextStyle(
                    color: Color(0xFF1389FD),
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                TextSpan(
                  text: 'FIN',
                  style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.6),
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'RESTAURANT POS',
            style: TextStyle(
              color: colors.textSecondary.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 5,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  color: colors.textSecondary.withValues(alpha: 0.4),
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'Personel girişi için\nkullanıcı seçin ve PIN girin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBranding(_LoginColors colors) {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'EX',
                style: TextStyle(
                  color: Color(0xFF1389FD),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              TextSpan(
                text: 'FIN',
                style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.6),
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'RESTAURANT POS',
          style: TextStyle(
            color: colors.textSecondary.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPanel(_LoginColors colors) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.border),
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
              _buildStaffGrid(colors),
              const SizedBox(height: 24),
              _buildPinDots(colors),
              const SizedBox(height: 20),
              _buildNumpad(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffGrid(_LoginColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'Personel Seçin',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_staffMembers.length, (index) {
            final staff = _staffMembers[index];
            final isSelected = _selectedStaffIndex == index;

            return GestureDetector(
              onTap: () => _selectStaff(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: 84,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? staff.color.withValues(alpha: 0.12)
                      : colors.numpadKeyBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? staff.color.withValues(alpha: 0.5)
                        : colors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? staff.color.withValues(alpha: 0.2)
                            : colors.avatarBackground,
                      ),
                      child: Icon(
                        staff.icon,
                        color: isSelected
                            ? staff.color
                            : colors.textSecondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      staff.displayName,
                      style: TextStyle(
                        color: isSelected
                            ? staff.color
                            : colors.textSecondary,
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPinDots(_LoginColors colors) {
    return Column(
      children: [
        if (_selectedStaffIndex != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${_staffMembers[_selectedStaffIndex!].displayName} olarak giriş',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final progress = _shakeController.value;
            final offset = progress < 1.0
                ? 12.0 *
                    (1.0 - progress) *
                    _shakeOffset(progress * 4 * 3.14159)
                : 0.0;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pinLength, (index) {
              final isFilled = index < _enteredPin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 7),
                width: isFilled ? 14 : 12,
                height: isFilled ? 14 : 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled
                      ? const Color(0xFF1389FD)
                      : Colors.transparent,
                  border: Border.all(
                    color: isFilled
                        ? const Color(0xFF1389FD)
                        : colors.pinBorder,
                    width: 2,
                  ),
                  boxShadow: isFilled
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1389FD)
                                .withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
        ),
        if (_isLoggingIn) ...[
          const SizedBox(height: 14),
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1389FD)),
            ),
          ),
        ],
      ],
    );
  }

  double _shakeOffset(double x) {
    return (x - x.floorToDouble()) < 0.5 ? 1.0 : -1.0;
  }

  Widget _buildNumpad(_LoginColors colors) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: [
          _buildNumpadRow(['1', '2', '3'], colors),
          const SizedBox(height: 8),
          _buildNumpadRow(['4', '5', '6'], colors),
          const SizedBox(height: 8),
          _buildNumpadRow(['7', '8', '9'], colors),
          const SizedBox(height: 8),
          _buildNumpadRow(['C', '0', '⌫'], colors),
          const SizedBox(height: 14),
          _buildLoginButton(colors),
        ],
      ),
    );
  }

  Widget _buildNumpadRow(List<String> keys, _LoginColors colors) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildNumpadKey(key, colors),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumpadKey(String key, _LoginColors colors) {
    final bool isSpecial = key == 'C' || key == '⌫';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoggingIn
            ? null
            : () {
                if (key == 'C') {
                  _onClearPressed();
                } else if (key == '⌫') {
                  _onBackspacePressed();
                } else {
                  _onNumberPressed(key);
                }
              },
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF1389FD).withValues(alpha: 0.15),
        highlightColor: const Color(0xFF1389FD).withValues(alpha: 0.05),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: isSpecial
                ? colors.numpadSpecialBackground
                : colors.numpadKeyBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Center(
            child: key == '⌫'
                ? Icon(
                    Icons.backspace_outlined,
                    color: colors.textSecondary,
                    size: 19,
                  )
                : Text(
                    key,
                    style: TextStyle(
                      color: isSpecial
                          ? colors.textSecondary
                          : colors.textPrimary,
                      fontSize: isSpecial ? 13 : 20,
                      fontWeight:
                          isSpecial ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(_LoginColors colors) {
    final hasSelection = _selectedStaffIndex != null;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: (_isLoggingIn || !hasSelection)
            ? null
            : _attemptLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1389FD),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFF1389FD).withValues(alpha: 0.25),
          disabledForegroundColor: Colors.white54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoggingIn
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                hasSelection ? 'Giriş Yap' : 'Personel Seçin',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

class _StaffMember {
  final String username;
  final String password;
  final String role;
  final String displayName;
  final IconData icon;
  final Color color;

  const _StaffMember({
    required this.username,
    required this.password,
    required this.role,
    required this.displayName,
    required this.icon,
    required this.color,
  });
}

class _LoginColors {
  final Color background;
  final List<Color> backgroundGradient;
  final Color cardBackground;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color numpadKeyBackground;
  final Color numpadSpecialBackground;
  final Color avatarBackground;
  final Color pinBorder;

  const _LoginColors({
    required this.background,
    required this.backgroundGradient,
    required this.cardBackground,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.numpadKeyBackground,
    required this.numpadSpecialBackground,
    required this.avatarBackground,
    required this.pinBorder,
  });

  factory _LoginColors.fromBrightness(bool isDark) {
    if (isDark) {
      return const _LoginColors(
        background: Color(0xFF0F1117),
        backgroundGradient: [
          Color(0xFF0F1117),
          Color(0xFF131620),
          Color(0xFF161B26),
        ],
        cardBackground: Color(0xFF1A1F2E),
        border: Color(0xFF2A2F3E),
        textPrimary: Color(0xFFE8ECF4),
        textSecondary: Color(0xFF8B92A5),
        numpadKeyBackground: Color(0xFF1E2433),
        numpadSpecialBackground: Color(0xFF161B26),
        avatarBackground: Color(0xFF232838),
        pinBorder: Color(0xFF3A4055),
      );
    } else {
      return const _LoginColors(
        background: Color(0xFFF5F7FA),
        backgroundGradient: [
          Color(0xFFF5F7FA),
          Color(0xFFEEF1F6),
          Color(0xFFE8ECF2),
        ],
        cardBackground: Color(0xFFFFFFFF),
        border: Color(0xFFE2E6ED),
        textPrimary: Color(0xFF1A1F36),
        textSecondary: Color(0xFF6B7280),
        numpadKeyBackground: Color(0xFFF8F9FB),
        numpadSpecialBackground: Color(0xFFF0F2F5),
        avatarBackground: Color(0xFFF3F4F6),
        pinBorder: Color(0xFFCDD3DE),
      );
    }
  }
}
