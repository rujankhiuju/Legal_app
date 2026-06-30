import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'model/court_event.dart';
import 'providers/calendar_provider.dart';

class AddHearingPage extends ConsumerStatefulWidget {
  const AddHearingPage({super.key});

  @override
  ConsumerState<AddHearingPage> createState() => _AddHearingPageState();
}

class _AddHearingPageState extends ConsumerState<AddHearingPage> {
  final _titleController = TextEditingController();
  final _caseNameController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _selectedColor = '1E3A8A';
  bool _isHearing = true;

  static const _colorOptions = [
    ('1E3A8A', 'Blue'),
    ('E53E3E', 'Red'),
    ('38A169', 'Green'),
    ('DD6B20', 'Orange'),
    ('805AD5', 'Purple'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _caseNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.gold,
                  onPrimary: AppColors.deepNavy,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.gold,
                  onPrimary: AppColors.deepNavy,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty || _caseNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and Case Name are required')),
      );
      return;
    }

    final now = DateTime.now();
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final event = CourtEvent(
      id: now.millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      caseName: _caseNameController.text.trim(),
      dateTime: dateTime,
      notes: _notesController.text.trim(),
      colorHex: _selectedColor,
      isHearing: _isHearing,
    );

    HapticFeedback.mediumImpact();
    await ref.read(calendarActionsProvider).addEvent(event);
    if (mounted) Navigator.of(context).pop();
  }

  Color _parseColor(String hex) {
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.deepNavy;
    final inputBg = isDark ? AppColors.darkSurface : AppColors.white;
    final hintColor = textColor.withValues(alpha: 0.35);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Hearing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.gold),
            onPressed: _save,
          ),
        ],
      ),
      body: Container(
        color: isDark ? AppColors.deepNavy : AppColors.lightBackground,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _titleController,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
              decoration: InputDecoration(
                hintText: 'Hearing Title',
                hintStyle: TextStyle(color: hintColor),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _caseNameController,
              style: TextStyle(fontSize: 16, color: textColor),
              decoration: InputDecoration(
                hintText: 'Case Name',
                hintStyle: TextStyle(color: hintColor),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.gold, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: TextStyle(fontSize: 12, color: hintColor),
                        ),
                        Text(
                          '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                          style: TextStyle(fontSize: 16, color: textColor),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_calendar, color: AppColors.gold, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: AppColors.gold, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time',
                          style: TextStyle(fontSize: 12, color: hintColor),
                        ),
                        Text(
                          _selectedTime.format(context),
                          style: TextStyle(fontSize: 16, color: textColor),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.edit, color: AppColors.gold, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.palette, color: AppColors.gold, size: 20),
                      const SizedBox(width: 12),
                      Text('Color', style: TextStyle(fontSize: 12, color: hintColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: _colorOptions.map((opt) {
                      final isSelected = _selectedColor == opt.$1;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = opt.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _parseColor(opt.$1),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: AppColors.gold, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 8)]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: AppColors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              style: TextStyle(fontSize: 15, height: 1.5, color: textColor),
              decoration: InputDecoration(
                hintText: 'Notes (optional)',
                hintStyle: TextStyle(color: hintColor),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              title: Text('Is Hearing', style: TextStyle(color: textColor)),
              value: _isHearing,
              onChanged: (v) => setState(() => _isHearing = v),
              activeColor: AppColors.gold,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ],
        ),
      ),
    );
  }
}
