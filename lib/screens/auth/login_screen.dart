import 'package:flutter/material.dart';
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
  String? _error;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final service = BiometricService();
    final available = await service.isAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  Future<void> _loginWithPin(String pin) async {
    final err = await ref.read(authProvider.notifier).loginWithPin(pin);
    if (err != null && mounted) {
      setState(() => _error = err);
    }
  }

  Future<void> _loginWithBio() async {
    final err = await ref.read(authProvider.notifier).loginWithBiometrics();
    if (err != null && mounted) {
      setState(() => _error = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                if (user != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.fullName,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                PinInputField(
                  length: 4,
                  errorText: _error,
                  onCompleted: _loginWithPin,
                ),
                const SizedBox(height: 24),
                PillButton(
                  label: 'Unlock',
                  onTap: () {},
                ),
                if (_biometricAvailable) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _loginWithBio,
                    icon: Icon(
                      Icons.fingerprint,
                      color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                    ),
                    label: Text(
                      'Unlock with Biometrics',
                      style: TextStyle(
                        color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => ref.read(authProvider.notifier).continueAsGuest(),
                  child: Text(
                    'Continue as Guest',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkSubtitle
                          : AppColors.lightSubtitle,
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
