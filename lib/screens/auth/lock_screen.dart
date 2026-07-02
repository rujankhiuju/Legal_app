import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/biometric_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/pin_input_field.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String? _error;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    final service = BiometricService();
    final available = await service.isAvailable();
    if (!mounted) return;
    setState(() => _biometricAvailable = available);
    if (available) {
      final ok = await service.authenticate(reason: 'Auto-lock is active');
      if (ok && mounted) {
        ref.read(authProvider.notifier).updateActivity();
      }
    }
  }

  Future<void> _unlockWithPin(String pin) async {
    final err = await ref.read(authProvider.notifier).loginWithPin(pin);
    if (err != null && mounted) setState(() => _error = err);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 36,
                    color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'App Locked',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter your PIN to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                  ),
                ),
                const SizedBox(height: 28),
                PinInputField(
                  length: 4,
                  errorText: _error,
                  onCompleted: _unlockWithPin,
                ),
                if (_biometricAvailable) ...[
                  const SizedBox(height: 20),
                  IconButton.filled(
                    onPressed: _tryBiometric,
                    icon: const Icon(Icons.fingerprint),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                      foregroundColor: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
