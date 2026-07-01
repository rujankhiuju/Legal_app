import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'model/legal_document.dart';
import 'providers/rule_book_provider.dart';

class RuleBookDetailPage extends ConsumerWidget {
  final String docId;

  const RuleBookDetailPage({super.key, required this.docId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docAsync = ref.watch(legalDocByIdProvider(docId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return docAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Could not load document: $e')),
      ),
      data: (doc) {
        if (doc == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('Document not found')),
          );
        }
        return _DetailContent(doc: doc, isDark: isDark);
      },
    );
  }
}

class _DetailContent extends ConsumerWidget {
  final LegalDocument doc;
  final bool isDark;

  const _DetailContent({
    required this.doc,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtitleColor = isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightSecondary;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [AppColors.darkCard, AppColors.darkBackground]
                        : [AppColors.lightSecondary, AppColors.lightSecondary.withOpacity(0.8)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            doc.category,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          doc.titleEn,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doc.titleNp,
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.85),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              Consumer(
                builder: (context, ref, _) {
                  return IconButton(
                    icon: Icon(
                      doc.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: accentColor,
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ref.read(ruleBookActionsProvider).toggleBookmark(doc);
                    },
                    tooltip: doc.isBookmarked
                        ? 'Remove Bookmark'
                        : 'Add Bookmark',
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ContentSection(
                      title: 'English',
                      content: doc.contentEn,
                      textColor: textColor,
                      accentColor: accentColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ContentSection(
                      title: 'नेपाली',
                      content: doc.contentNp,
                      textColor: textColor,
                      accentColor: accentColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Keywords',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: doc.keywords.map((keyword) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            keyword,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (doc.lastViewed != null) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(Icons.history_rounded, size: 16, color: subtitleColor),
                          const SizedBox(width: 6),
                          Text(
                            'Last viewed: ${_formatDate(doc.lastViewed!)}',
                            style: TextStyle(fontSize: 12, color: subtitleColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _ContentSection extends StatelessWidget {
  final String title;
  final String content;
  final Color textColor;
  final Color accentColor;
  final bool isDark;

  const _ContentSection({
    required this.title,
    required this.content,
    required this.textColor,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
