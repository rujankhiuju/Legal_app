import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/pill_button.dart';

class SetupAccountScreen extends ConsumerStatefulWidget {
  const SetupAccountScreen({super.key});

  @override
  ConsumerState<SetupAccountScreen> createState() => _SetupAccountScreenState();
}

class _SetupAccountScreenState extends ConsumerState<SetupAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _pinFocus = FocusNode();
  bool _loading = false;
  bool _pinStep = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _pinCtrl.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    final pin = _pinCtrl.text.trim();
    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PIN must be 4-6 digits'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    await ref.read(authProvider.notifier).setupAccount(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          pin: pin,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : const Color(0xFF0A192F);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
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
                      Icons.gavel_rounded,
                      size: 40,
                      color: isDark ? AppColors.darkAccent : const Color(0xFFD4AF37),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Setup Your Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _pinStep ? 'Set a 4-6 digit PIN for quick access' : 'Create your profile to get started',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.darkSubtitle : Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 32),
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
                    child: _pinStep
                        ? Column(
                            children: [
                              TextField(
                                controller: _pinCtrl,
                                focusNode: _pinFocus,
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
                                      color: isDark ? AppColors.darkDivider : Colors.white24,
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
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD4AF37),
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
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              TextFormField(
                                controller: _firstNameCtrl,
                                focusNode: _firstNameFocus,
                                decoration: InputDecoration(
                                  labelText: 'First Name',
                                  prefixIcon: Icon(Icons.person_outline,
                                      color: isDark ? AppColors.darkSubtitle : Colors.white54),
                                  labelStyle: TextStyle(
                                    color: isDark ? AppColors.darkSubtitle : Colors.white54,
                                  ),
                                  filled: true,
                                  fillColor: isDark ? AppColors.darkSurface : Colors.white.withOpacity(0.06),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                                  ),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => _lastNameFocus.requestFocus(),
                                style: TextStyle(
                                  color: isDark ? AppColors.darkText : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _lastNameCtrl,
                                focusNode: _lastNameFocus,
                                decoration: InputDecoration(
                                  labelText: 'Last Name',
                                  prefixIcon: Icon(Icons.person_outline,
                                      color: isDark ? AppColors.darkSubtitle : Colors.white54),
                                  labelStyle: TextStyle(
                                    color: isDark ? AppColors.darkSubtitle : Colors.white54,
                                  ),
                                  filled: true,
                                  fillColor: isDark ? AppColors.darkSurface : Colors.white.withOpacity(0.06),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                                  ),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() => _pinStep = true);
                                    _pinFocus.requestFocus();
                                  }
                                },
                                style: TextStyle(
                                  color: isDark ? AppColors.darkText : Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: PillButton(
                      label: _loading
                          ? 'Creating...'
                          : (_pinStep ? 'Create Account' : 'Continue'),
                      onTap: _loading ? null : (_pinStep ? _createAccount : () {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _pinStep = true);
                          _pinFocus.requestFocus();
                        }
                      }),
                      loading: _loading,
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: const Color(0xFF0A192F),
                    ),
                  ),
                  if (_pinStep)
                    TextButton(
                      onPressed: () => setState(() {
                        _pinStep = false;
                        _pinCtrl.clear();
                      }),
                      child: Text(
                        'Back',
                        style: TextStyle(
                          color: isDark ? AppColors.darkAccent : Colors.white54,
                        ),
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
}
