import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/staggered_animation.dart';
import '../../shared/widgets/polished_card.dart';
import '../../providers/law_provider.dart';
import 'model/legal_document.dart';
import 'providers/rule_book_provider.dart';

class RuleBookPage extends ConsumerStatefulWidget {
  const RuleBookPage({super.key});

  @override
  ConsumerState<RuleBookPage> createState() => _RuleBookPageState();
}

class _RuleBookPageState extends ConsumerState<RuleBookPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _offlineSnackbarShown = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final lawState = ref.watch(lawStateProvider);

    if (!_offlineSnackbarShown &&
        lawState.error != null &&
        lawState.documents.isNotEmpty) {
      _offlineSnackbarShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Using offline library'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSecondary,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rule Book'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 3,
            child: AnimatedOpacity(
              opacity: lawState.isLoading ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                ),
              ),
            ),
          ),
          _SearchBar(
            controller: _searchController,
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                ref.read(lawStateProvider.notifier).setSearch(v);
              });
            },
            onClear: () {
              _debounce?.cancel();
              _searchController.clear();
              ref.read(lawStateProvider.notifier).setSearch('');
            },
            isDark: isDark,
          ),
          _CategoryChips(
            categories: lawState.categories,
            selected: lawState.selectedCategory,
            onSelected: (cat) {
              ref.read(lawStateProvider.notifier).setCategory(cat);
            },
            isDark: isDark,
          ),
          Expanded(
            child: Container(color: bgColor, child: _DocumentList(isDark: isDark)),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search documents...',
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

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final bool isDark;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 48,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final label = isAll ? 'All' : categories[index - 1];
          final isSelected = isAll ? selected == null : selected == label;
          return GestureDetector(
            onTap: () => onSelected(isAll ? null : label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0A192F)
                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFD4AF37)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? const Color(0xFFD4AF37)
                        : (isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DocumentList extends ConsumerWidget {
  final bool isDark;

  const _DocumentList({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawState = ref.watch(lawStateProvider);
    final query = lawState.searchQuery;
    final filtered = lawState.filteredDocuments;

    if (lawState.isLoading && lawState.documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading legal documents...',
              style: TextStyle(
                color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
              ),
            ),
          ],
        ),
      );
    }

    if (lawState.error != null && lawState.documents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load documents',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                lawState.error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => ref.read(lawStateProvider.notifier).refresh(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Map<String, List<LegalDocument>> grouped = {};
    for (final doc in filtered) {
      grouped.putIfAbsent(doc.category, () => []).add(doc);
    }

    if (grouped.isEmpty && query.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 72,
                color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
              ),
              const SizedBox(height: 16),
              Text(
                "No laws found for '$query'",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  ref.read(lawStateProvider.notifier).setSearch('');
                  context.findAncestorStateOfType<_RuleBookPageState>()
                      ?._searchController.clear();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Clear Search',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
            ),
            const SizedBox(height: 16),
            Text(
              'No documents available',
              style: TextStyle(
                color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(lawStateProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (query.isEmpty) _RecentSection(isDark: isDark),
          for (final entry in grouped.entries) ...[
            _CategoryHeader(
              category: entry.key,
              count: entry.value.length,
              isDark: isDark,
            ),
            for (final doc in entry.value)
              StaggeredFadeSlide(
                index: entry.value.indexOf(doc),
                child: _DocumentCard(doc: doc, isDark: isDark),
              ),
          ],
        ],
      ),
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
                  Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recently Viewed',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 110,
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
    return GestureDetector(
      onTap: () {
        ref.read(ruleBookActionsProvider).markAsViewed(doc);
        context.push('/rule-book/${doc.id}');
      },
      child: PolishedCard(
        padding: const EdgeInsets.all(14),
        margin: EdgeInsets.zero,
        borderRadius: 20,
        child: Container(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkAccent.withOpacity(0.12)
                      : AppColors.lightSecondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.book_rounded,
                  size: 24,
                  color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                doc.titleEn,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Text(
            category,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkAccent.withOpacity(0.15)
                  : AppColors.lightSecondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
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
    final lawState = ref.watch(lawStateProvider);
    final isBookmarked = lawState.bookmarkIds.contains(doc.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Hero(
        tag: 'doc_card_${doc.id}',
        child: PolishedCard(
          padding: const EdgeInsets.all(16),
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              ref.read(ruleBookActionsProvider).markAsViewed(doc);
              context.push('/rule-book/${doc.id}');
            },
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkAccent.withOpacity(0.12)
                        : AppColors.lightSecondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.gavel_rounded,
                    color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
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
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doc.titleNp,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isBookmarked)
                  Icon(
                    Icons.bookmark_rounded,
                    color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
