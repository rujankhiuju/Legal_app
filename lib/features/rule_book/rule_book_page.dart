import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/staggered_animation.dart';
import 'model/legal_document.dart';
import 'providers/rule_book_provider.dart';

class RuleBookPage extends ConsumerStatefulWidget {
  const RuleBookPage({super.key});

  @override
  ConsumerState<RuleBookPage> createState() => _RuleBookPageState();
}

class _RuleBookPageState extends ConsumerState<RuleBookPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.deepNavy : AppColors.lightBackground;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rule Book'),
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: (v) =>
                ref.read(searchQueryProvider.notifier).state = v,
            onClear: () {
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).state = '';
            },
            isDark: isDark,
          ),
          Expanded(
            child: Container(
              color: bgColor,
              child: _DocumentList(isDark: isDark),
            ),
          ),
        ],
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
          hintText: 'Search documents...',
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

class _DocumentList extends ConsumerWidget {
  final bool isDark;

  const _DocumentList({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(filteredDocsProvider);
    final query = ref.watch(searchQueryProvider);

    if (grouped.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 64, color: AppColors.gold.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  query.isEmpty ? 'No documents available' : 'No results for "$query"',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark ? AppColors.white.withOpacity(0.7) : AppColors.deepNavy.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (query.isEmpty) _RecentSection(isDark: isDark),
            for (final entry in grouped.entries) ...[
              _CategoryHeader(category: entry.key, count: entry.value.length, isDark: isDark),
              for (final doc in entry.value)
                StaggeredFadeSlide(
                  index: entry.value.indexOf(doc),
                  child: _DocumentCard(doc: doc, isDark: isDark),
                ),
            ],
          ],
        );
  }
}

class _RecentSection extends ConsumerWidget {
  final bool isDark;

  const _RecentSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentDocsProvider);

    return recentAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (recent) {
        if (recent.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.history, size: 18, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Text(
                    'Recently Viewed',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? AppColors.white.withOpacity(0.8) : AppColors.deepNavy,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final doc = recent[index];
                  return _RecentCard(doc: doc, isDark: isDark);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _RecentCard extends ConsumerWidget {
  final LegalDocument doc;
  final bool isDark;

  const _RecentCard({required this.doc, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    return GestureDetector(
      onTap: () {
        ref.read(ruleBookActionsProvider).markAsViewed(doc);
        context.push('/rule-book/${doc.id}');
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.book, size: 24, color: AppColors.gold),
            const SizedBox(height: 8),
            Text(
              doc.titleEn,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.white : AppColors.deepNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String category;
  final int count;
  final bool isDark;

  const _CategoryHeader({
    required this.category,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            category,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.gold : AppColors.darkBlue,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends ConsumerWidget {
  final LegalDocument doc;
  final bool isDark;

  const _DocumentCard({required this.doc, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final textColor = isDark ? AppColors.white : AppColors.deepNavy;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Hero(
        tag: 'doc_card_${doc.id}',
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              ref.read(ruleBookActionsProvider).markAsViewed(doc);
              context.push('/rule-book/${doc.id}');
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.gavel, color: AppColors.gold, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.titleEn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          doc.titleNp,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.white.withOpacity(0.6)
                                : AppColors.deepNavy.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (doc.isBookmarked)
                    const Icon(Icons.bookmark, color: AppColors.gold, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
