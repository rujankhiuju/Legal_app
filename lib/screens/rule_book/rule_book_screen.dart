import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/staggered_animation.dart';
import '../../features/rule_book/model/legal_document.dart';
import '../../features/rule_book/providers/rule_book_provider.dart';
import '../../providers/law_provider.dart';

const double _tabletBreakpoint = 600;

class RuleBookScreen extends ConsumerStatefulWidget {
  const RuleBookScreen({super.key});

  @override
  ConsumerState<RuleBookScreen> createState() => _RuleBookScreenState();
}

class _RuleBookScreenState extends ConsumerState<RuleBookScreen> {
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
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > _tabletBreakpoint;
        final iconSize = isTablet ? 28.0 : 22.0;
        final titleSize = isTablet ? 22.0 : 18.0;

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
                  child: const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPrimary),
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
              ),
              _CategoryChips(
                categories: lawState.categories,
                selected: lawState.selectedCategory,
                onSelected: (cat) {
                  ref.read(lawStateProvider.notifier).setCategory(cat);
                },
              ),
              Expanded(
                child: _DocumentList(isTablet: isTablet, iconSize: iconSize, titleSize: titleSize),
              ),
            ],
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Focus(
        onFocusChange: (focused) {},
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search documents...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: onClear,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 48,
      color: AppColors.primaryBg,
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
                color: isSelected ? AppColors.accentPrimary.withOpacity(0.15) : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.accentPrimary : AppColors.divider,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.accentPrimary : AppColors.textSecondary,
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
  final bool isTablet;
  final double iconSize;
  final double titleSize;

  const _DocumentList({
    required this.isTablet,
    required this.iconSize,
    required this.titleSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawState = ref.watch(lawStateProvider);
    final query = lawState.searchQuery;
    final filtered = lawState.filteredDocuments;

    if (lawState.isLoading && lawState.documents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.accentPrimary),
            SizedBox(height: 16),
            Text('Loading legal documents...', style: AppTextStyles.body),
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
              const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              const Text('Failed to load documents', style: AppTextStyles.subtitle),
              const SizedBox(height: 8),
              Text(
                lawState.error.toString(),
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(lawStateProvider.notifier).refresh(),
                child: const Text('Retry'),
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
              const Icon(Icons.search_off_rounded, size: 72, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                "No laws found for '$query'",
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(lawStateProvider.notifier).setSearch('');
                },
                child: const Text('Clear Search'),
              ),
            ],
          ),
        ),
      );
    }

    if (grouped.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('No documents available', style: AppTextStyles.body),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(lawStateProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (query.isEmpty)
            SliverToBoxAdapter(
              child: _RecentSection(isTablet: isTablet),
            ),
          for (final entry in grouped.entries) ...[
            SliverToBoxAdapter(
              child: _CategoryHeader(
                category: entry.key,
                count: entry.value.length,
              ),
            ),
            if (isTablet)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = entry.value[index];
                      return _DocumentCard(doc: doc);
                    },
                    childCount: entry.value.length,
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final doc = entry.value[index];
                    return StaggeredFadeSlide(
                      index: index,
                      child: _DocumentCard(doc: doc),
                    );
                  },
                  childCount: entry.value.length,
                ),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _RecentSection extends ConsumerWidget {
  final bool isTablet;

  const _RecentSection({required this.isTablet});

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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 18, color: AppColors.accentPrimary),
                  SizedBox(width: 8),
                  Text('Recently Viewed', style: AppTextStyles.subtitle),
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
                  return _RecentCard(doc: doc);
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

  const _RecentCard({required this.doc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(ruleBookActionsProvider).markAsViewed(doc);
        context.push('/rule-book/${doc.id}');
      },
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.book_rounded, size: 24, color: AppColors.accentPrimary),
              ),
              const SizedBox(height: 10),
              Text(
                doc.titleEn,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subtitle.copyWith(fontSize: 13),
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

  const _CategoryHeader({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Text(
            category,
            style: AppTextStyles.subtitle.copyWith(fontSize: 15, letterSpacing: 0.3),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.accentPrimary,
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

  const _DocumentCard({required this.doc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawState = ref.watch(lawStateProvider);
    final isBookmarked = lawState.bookmarkIds.contains(doc.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Hero(
        tag: 'doc_card_${doc.id}',
        child: AppCard(
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
                  color: AppColors.accentPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.gavel_rounded, color: AppColors.accentPrimary, size: 22),
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
                      style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doc.titleNp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            doc.category,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            doc.contentEn.replaceAll(RegExp(r'<[^>]*>'), ''),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isBookmarked)
                const Icon(Icons.bookmark_rounded, color: AppColors.accentPrimary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
