import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/staggered_animation.dart';
import '../../shared/widgets/polished_card.dart';
import 'model/case_note.dart';
import 'providers/notes_provider.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;

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
            isDark: isDark,
          ),
          Expanded(
            child: Container(color: bgColor, child: _NotesList(isDark: isDark, onOpenEditor: _openEditor)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(null),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isDark;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search notes...',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                  ),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: isDark
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        ),
      ),
    );
  }
}

class _NotesList extends ConsumerWidget {
  final bool isDark;
  final void Function(CaseNote?) onOpenEditor;

  const _NotesList({required this.isDark, required this.onOpenEditor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(sortedNotesProvider);
    final query = ref.watch(notesSearchQueryProvider);

    if (notes.isEmpty) {
      return _EmptyState(
        query: query,
        isDark: isDark,
        onOpenEditor: onOpenEditor,
      );
    }

    final pinned = notes.where((n) => n.pinned).toList();
    final unpinned = notes.where((n) => !n.pinned).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        if (pinned.isNotEmpty) ...[
          _SectionHeader(
            title: 'Pinned',
            isDark: isDark,
            icon: Icons.push_pin_rounded,
          ),
          for (final note in pinned)
            StaggeredFadeSlide(
              index: pinned.indexOf(note),
              child: _NoteCard(
                note: note,
                isDark: isDark,
                onTap: () => onOpenEditor(note),
              ),
            ),
        ],
        _SectionHeader(
          title: query.isEmpty ? 'Recent Notes' : 'Results',
          isDark: isDark,
          icon: query.isEmpty ? Icons.history_rounded : Icons.search_rounded,
        ),
        for (final note in unpinned)
          StaggeredFadeSlide(
            index: unpinned.indexOf(note),
            child: _NoteCard(
              note: note,
              isDark: isDark,
              onTap: () => onOpenEditor(note),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  final bool isDark;
  final void Function(CaseNote?) onOpenEditor;

  const _EmptyState({
    required this.query,
    required this.isDark,
    required this.onOpenEditor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            query.isEmpty ? Icons.note_add_outlined : Icons.search_off_rounded,
            size: 72,
            color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
          ),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? 'No notes yet' : 'No results for "$query"',
            style: TextStyle(
              color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
            ),
          ),
          if (query.isEmpty) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => onOpenEditor(null),
              icon: Icon(
                Icons.add_rounded,
                color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
              ),
              label: Text(
                'Create your first note',
                style: TextStyle(
                  color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.isDark,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final CaseNote note;
  final bool isDark;
  final VoidCallback onTap;

  const _NoteCard({
    required this.note,
    required this.isDark,
    required this.onTap,
  });

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
            borderRadius: BorderRadius.circular(24),
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
          child: PolishedCard(
            padding: const EdgeInsets.all(16),
            margin: EdgeInsets.zero,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: note.pinned
                    ? Border.all(
                        color: isDark
                            ? AppColors.darkAccent.withOpacity(0.4)
                            : AppColors.lightSecondary.withOpacity(0.4),
                      )
                    : null,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onTap,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (note.pinned) ...[
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkAccent.withOpacity(0.12)
                                        : AppColors.lightSecondary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.push_pin_rounded,
                                    size: 12,
                                    color: isDark
                                        ? AppColors.darkAccent
                                        : AppColors.lightSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  note.title.isEmpty ? 'Untitled' : note.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: isDark ? AppColors.darkText : AppColors.lightText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (note.content.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              note.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                              ),
                            ),
                          ],
                          if (note.tags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: note.tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkAccent.withOpacity(0.12)
                                        : AppColors.lightSecondary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.darkAccent
                                          : AppColors.lightSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(note.updatedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                      ),
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
