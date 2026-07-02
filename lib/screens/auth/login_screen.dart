import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/biometric_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/pin_input_field.dart';
import '../../shared/widgets/pill_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  String? _error;
  bool _loading = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final service = BiometricService();
    final available = await service.isAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  Future<void> _unlock() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'Enter at least 4 digits');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    final err = await ref.read(authProvider.notifier).loginWithPin(pin);
    if (mounted) {
      setState(() {
        _loading = false;
        if (err != null) {
          _error = err;
        }
      });
    }
  }

  Future<void> _biometricLogin() async {
    setState(() => _loading = true);
    final err = await ref.read(authProvider.notifier).loginWithBiometrics();
    if (mounted) {
      setState(() {
        _loading = false;
        if (err != null) _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : const Color(0xFF0A192F);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkCard : Colors.white.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: isDark ? AppColors.darkAccent : const Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : Colors.white,
                  ),
                ),
                if (user != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    user.fullName,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppColors.darkSubtitle : Colors.white70,
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard.withOpacity(0.5) : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkDivider.withOpacity(0.3)
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Enter PIN',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkSubtitle : Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pinController,
                        focusNode: _pinFocusNode,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 12,
                          color: isDark ? AppColors.darkText : Colors.white,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurface : Colors.white.withOpacity(0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: _error != null
                                  ? AppColors.error
                                  : (isDark ? AppColors.darkDivider : Colors.white24),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.darkDivider : Colors.white24,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: const Color(0xFFD4AF37),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          hintText: '• • • •',
                          hintStyle: TextStyle(
                            fontSize: 32,
                            letterSpacing: 12,
                            color: isDark ? AppColors.darkSubtitle : Colors.white30,
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        onSubmitted: (_) => _unlock(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                              const SizedBox(width: 6),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: PillButton(
                    label: _loading ? 'Unlocking...' : 'Unlock',
                    onTap: _loading ? null : _unlock,
                    loading: _loading,
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF0A192F),
                  ),
                ),
                if (_biometricAvailable) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _biometricLogin,
                      icon: Icon(
                        Icons.fingerprint,
                        color: isDark ? AppColors.darkAccent : const Color(0xFFD4AF37),
                      ),
                      label: Text(
                        'Unlock with Biometrics',
                        style: TextStyle(
                          color: isDark ? AppColors.darkAccent : const Color(0xFFD4AF37),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkDivider
                              : Colors.white24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => ref.read(authProvider.notifier).continueAsGuest(),
                  child: Text(
                    'Continue as Guest',
                    style: TextStyle(
                      color: isDark ? AppColors.darkSubtitle : Colors.white54,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
