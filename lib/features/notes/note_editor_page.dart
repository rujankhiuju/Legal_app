import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'model/case_note.dart';
import 'providers/notes_provider.dart';

class NoteEditorPage extends ConsumerStatefulWidget {
  final CaseNote? existingNote;

  const NoteEditorPage({super.key, this.existingNote});

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _tagController;
  late final FocusNode _tagFocusNode;
  late List<String> _tags;
  final _formKey = GlobalKey<FormState>();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _bodyController = TextEditingController(text: widget.existingNote?.content ?? '');
    _tagController = TextEditingController();
    _tagFocusNode = FocusNode();
    _tags = List<String>.from(widget.existingNote?.tags ?? []);

    _titleController.addListener(_markChanged);
    _bodyController.addListener(_markChanged);
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() {
      _tags.add(tag);
      _tagController.clear();
      _hasChanges = true;
    });
    _tagFocusNode.requestFocus();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _hasChanges = true;
    });
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    final now = DateTime.now();
    final note = CaseNote(
      id: widget.existingNote?.id ?? now.millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      content: _bodyController.text.trim(),
      tags: List<String>.from(_tags),
      pinned: widget.existingNote?.pinned ?? false,
      createdAt: widget.existingNote?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.existingNote != null) {
      await ref.read(notesActionsProvider).updateNote(note);
    } else {
      await ref.read(notesActionsProvider).addNote(note);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightSecondary;
    final hintColor = isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingNote != null ? 'Edit Note' : 'New Note'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.check_rounded,
              color: accentColor,
            ),
            onPressed: _save,
          ),
        ],
      ),
      body: Container(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(color: hintColor.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _bodyController,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Start typing your notes...',
                  hintStyle: TextStyle(color: hintColor.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._tags.map((tag) => Chip(
                        label: Text(
                          tag,
                          style: const TextStyle(fontSize: 13, color: AppColors.white),
                        ),
                        backgroundColor: accentColor.withOpacity(0.7),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16, color: AppColors.white),
                        onDeleted: () => _removeTag(tag),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )),
                  SizedBox(
                    height: 32,
                    child: TextField(
                      controller: _tagController,
                      focusNode: _tagFocusNode,
                      style: TextStyle(fontSize: 13, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Add tag...',
                        hintStyle: TextStyle(
                          color: hintColor.withOpacity(0.5),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addTag(),
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
