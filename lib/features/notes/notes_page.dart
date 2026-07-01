import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/staggered_animation.dart';
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
    final bgColor = isDark ? AppColors.deepNavy : AppColors.lightBackground;

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
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.deepNavy,
        onPressed: () => _openEditor(null),
        child: const Icon(Icons.add),
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
      color: isDark ? AppColors.darkSurface : AppColors.white,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search notes...',
          prefixIcon: const Icon(Icons.search, color: AppColors.gold),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.gold),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: isDark
              ? AppColors.deepNavy.withOpacity(0.6)
              : AppColors.lightBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
              _SectionHeader(title: 'Pinned', isDark: isDark, icon: Icons.push_pin),
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
              icon: query.isEmpty ? Icons.history : Icons.search,
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
            query.isEmpty ? Icons.note_add_outlined : Icons.search_off,
            size: 72,
            color: AppColors.gold.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? 'No notes yet' : 'No results for "$query"',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? AppColors.white.withOpacity(0.7)
                      : AppColors.deepNavy.withOpacity(0.7),
                ),
          ),
          if (query.isEmpty) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => onOpenEditor(null),
              icon: const Icon(Icons.add, color: AppColors.gold),
              label: const Text(
                'Create your first note',
                style: TextStyle(color: AppColors.gold),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isDark
                  ? AppColors.white.withOpacity(0.7)
                  : AppColors.deepNavy.withOpacity(0.7),
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
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final textColor = isDark ? AppColors.white : AppColors.deepNavy;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Dismissible(
        key: ValueKey(note.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete_outline, color: AppColors.white, size: 28),
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
                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
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
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: note.pinned
                  ? BorderSide(color: AppColors.gold.withOpacity(0.4))
                  : BorderSide.none,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
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
                                const Icon(Icons.push_pin,
                                    size: 14, color: AppColors.gold),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  note.title.isEmpty ? 'Untitled' : note.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: textColor,
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
                                color: isDark
                                    ? AppColors.white.withOpacity(0.6)
                                    : AppColors.deepNavy.withOpacity(0.6),
                              ),
                            ),
                          ],
                          if (note.tags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: note.tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.gold,
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
                        fontSize: 11,
                        color: isDark
                            ? AppColors.white.withOpacity(0.4)
                            : AppColors.deepNavy.withOpacity(0.4),
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
