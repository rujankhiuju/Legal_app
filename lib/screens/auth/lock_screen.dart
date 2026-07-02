import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/biometric_service.dart';
import '../../providers/auth_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  String? _error;
  bool _loading = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
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
        if (err != null) _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : const Color(0xFF0A192F);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkCard : Colors.white.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 36,
                    color: isDark ? AppColors.darkAccent : const Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'App Locked',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter your PIN to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkSubtitle : Colors.white60,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
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
                  child: ElevatedButton(
                    onPressed: _loading ? null : _unlock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: const Color(0xFF0A192F),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 4,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF0A192F),
                            ),
                          )
                        : const Text(
                            'Unlock',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                if (_biometricAvailable) ...[
                  const SizedBox(height: 16),
                  IconButton(
                    onPressed: _loading ? null : _tryBiometric,
                    icon: const Icon(Icons.fingerprint, size: 36),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkCard : Colors.white.withOpacity(0.1),
                      foregroundColor: isDark ? AppColors.darkAccent : const Color(0xFFD4AF37),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                    tooltip: 'Use Biometrics',
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
