import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/pin_input_field.dart';
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
  String _pin = '';
  int _step = 0;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pin.length < 4) {
      setState(() => _error = 'PIN must be 4-6 digits');
      return;
    }
    setState(() => _loading = true);
    await ref.read(authProvider.notifier).setupAccount(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          pin: _pin,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    ),
                    child: Icon(
                      Icons.gavel_rounded,
                      size: 40,
                      color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Setup Your Account',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your profile to get started',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_step == 0) ...[
                    TextFormField(
                      controller: _firstNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        labelStyle: TextStyle(
                          color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        labelStyle: TextStyle(
                          color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PillButton(
                      label: 'Continue',
                      onTap: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _step = 1);
                        }
                      },
                    ),
                  ] else ...[
                    Text(
                      'Set Your PIN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter a 4-6 digit PIN for quick access',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PinInputField(
                      length: 4,
                      errorText: _error,
                      onCompleted: (pin) {
                        setState(() {
                          _pin = pin;
                          _error = null;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    PillButton(
                      label: _loading ? 'Creating...' : 'Create Account',
                      onTap: _createAccount,
                    ),
                    if (_step > 0)
                      TextButton(
                        onPressed: () => setState(() {
                          _step = 0;
                          _error = null;
                          _pin = '';
                        }),
                        child: Text(
                          'Back',
                          style: TextStyle(
                            color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
