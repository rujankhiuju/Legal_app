import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class PinInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final String? errorText;
  final bool obscure;

  const PinInputField({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.errorText,
    this.obscure = true,
  });

  @override
  State<PinInputField> createState() => _PinInputFieldState();
}

class _PinInputFieldState extends State<PinInputField> {
  final _controllers = <TextEditingController>[];
  final _focusNodes = <FocusNode>[];
  final _values = <String>[];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.length; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
      _values.add('');
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      for (int i = 0; i < value.length && i + index < widget.length; i++) {
        _values[i + index] = value[i];
        _controllers[i + index].text = value[i];
      }
      if (index + value.length >= widget.length) {
        _focusNodes.last.unfocus();
        _submit();
        return;
      }
      _focusNodes[index + value.length].requestFocus();
      return;
    }
    _values[index] = value;
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (index == widget.length - 1 && value.isNotEmpty) {
      _focusNodes[index].unfocus();
      _submit();
    }
  }

  void _submit() {
    final pin = _values.join();
    if (pin.length == widget.length) {
      widget.onCompleted(pin);
    }
  }

  void clear() {
    for (int i = 0; i < widget.length; i++) {
      _values[i] = '';
      _controllers[i].clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            return Container(
              width: 52,
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard.withOpacity(0.6)
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _values[index].isNotEmpty
                      ? (isDark ? AppColors.darkAccent : AppColors.lightSecondary)
                      : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  obscureText: widget.obscure,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) => _onChanged(index, v),
                  enableSuggestions: false,
                  autocorrect: false,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
