import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/route_names.dart';
import '../../shared/widgets/app_card.dart';
import '../../features/notes/model/case_note.dart';
import '../../features/notes/providers/notes_provider.dart';

const double _tabletBreakpoint = 600;

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditor(CaseNote? note) {
    context.pushNamed(RouteNames.notesEditor, extra: note);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > _tabletBreakpoint;
        final iconSize = isTablet ? 28.0 : 22.0;
        final titleSize = isTablet ? 22.0 : 18.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Case Notes'),
          ),
          body: Column(
            children: [
              _SearchBar(
                controller: _searchController,
                onChanged: (v) =>
                    ref.read(notesSearchQueryProvider.notifier).state = v,
                onClear: () {
                  _searchController.clear();
                  ref.read(notesSearchQueryProvider.notifier).state = '';
                },
              ),
              Expanded(
                child: _NotesList(
                  isTablet: isTablet,
                  iconSize: iconSize,
                  titleSize: titleSize,
                  onOpenEditor: _openEditor,
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openEditor(null),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search notes...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: onClear,
                )
              : null,
        ),
      ),
    );
  }
}

class _NotesList extends ConsumerWidget {
  final bool isTablet;
  final double iconSize;
  final double titleSize;
  final void Function(CaseNote?) onOpenEditor;

  const _NotesList({
    required this.isTablet,
    required this.iconSize,
    required this.titleSize,
    required this.onOpenEditor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(sortedNotesProvider);
    final query = ref.watch(notesSearchQueryProvider);

    if (notes.isEmpty) {
      return _EmptyState(
        query: query,
        onOpenEditor: onOpenEditor,
      );
    }

    final pinned = notes.where((n) => n.pinned).toList();
    final unpinned = notes.where((n) => !n.pinned).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pinned.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.push_pin_rounded, size: 16, color: AppColors.accentPrimary),
                  SizedBox(width: 6),
                  Text('Pinned', style: AppTextStyles.subtitle),
                ],
              ),
            ),
            if (isTablet)
              _MasonryNoteGrid(notes: pinned, onTap: onOpenEditor)
            else
              ...pinned.map((note) => _NoteCard(note: note, onTap: () => onOpenEditor(note))),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.history_rounded, size: 16, color: AppColors.accentPrimary),
                SizedBox(width: 6),
                Text('Recent Notes', style: AppTextStyles.subtitle),
              ],
            ),
          ),
          if (isTablet)
            _MasonryNoteGrid(notes: unpinned, onTap: onOpenEditor)
          else
            ...unpinned.map((note) => _NoteCard(note: note, onTap: () => onOpenEditor(note))),
        ],
      ),
    );
  }
}

class _MasonryNoteGrid extends StatelessWidget {
  final List<CaseNote> notes;
  final void Function(CaseNote?) onTap;

  const _MasonryNoteGrid({required this.notes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return _NoteCard(note: note, onTap: () => onTap(note));
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  final void Function(CaseNote?) onOpenEditor;

  const _EmptyState({required this.query, required this.onOpenEditor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            query.isEmpty ? Icons.note_add_outlined : Icons.search_off_rounded,
            size: 72,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? 'No notes yet' : 'No results for "$query"',
            style: AppTextStyles.body,
          ),
          if (query.isEmpty) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => onOpenEditor(null),
              icon: const Icon(Icons.add_rounded, color: AppColors.accentPrimary),
              label: const Text(
                'Create your first note',
                style: TextStyle(color: AppColors.accentPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final CaseNote note;
  final VoidCallback onTap;

  const _NoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Dismissible(
        key: ValueKey(note.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: AppColors.white, size: 28),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Note'),
              content: Text('Delete "${note.title}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) {
          ref.read(notesActionsProvider).deleteNote(note.id);
        },
        child: GestureDetector(
          onLongPress: () {
            HapticFeedback.mediumImpact();
            ref.read(notesActionsProvider).togglePin(note);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(note.pinned ? 'Unpinned' : 'Pinned'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: AppCard(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: note.pinned ? AppColors.accentPrimary : AppColors.accentPrimary.withOpacity(0.3),
                    width: 3,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (note.pinned) ...[
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.accentPrimary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.push_pin_rounded, size: 12, color: AppColors.accentPrimary),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? 'Untitled' : note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    if (note.content.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.4),
                      ),
                    ],
                    if (note.tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: note.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentPrimary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              tag,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.accentPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(note.updatedAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}';
  }
}
