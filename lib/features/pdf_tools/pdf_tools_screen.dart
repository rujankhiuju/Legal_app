import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/route_names.dart';
import '../../shared/widgets/staggered_animation.dart';
import '../../shared/widgets/polished_card.dart';
import '../../providers/pdf_provider.dart';

class PdfToolsScreen extends ConsumerWidget {
  const PdfToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtitleColor = isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Tools'),
      ),
      body: Container(
        color: bgColor,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 22,
                    color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Document Tools',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ToolCard(
                      icon: Icons.document_scanner_rounded,
                      title: 'Scanner',
                      subtitle: 'Scan documents with camera',
                      isDark: isDark,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      onTap: () => context.pushNamed(RouteNames.scanner),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ToolCard(
                      icon: Icons.merge_rounded,
                      title: 'PDF Combiner',
                      subtitle: 'Merge multiple PDFs',
                      isDark: isDark,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      onTap: () => context.pushNamed(RouteNames.pdfCombiner),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ToolCard(
                      icon: Icons.folder_rounded,
                      title: 'PDF Library',
                      subtitle: 'View saved PDFs',
                      isDark: isDark,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.pushNamed(RouteNames.pdfLibrary);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recent PDFs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _RecentPdfSection(
                isDark: isDark,
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color textColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.textColor,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: PolishedCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                icon,
                size: 24,
                color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: subtitleColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentPdfSection extends ConsumerWidget {
  final bool isDark;
  final Color textColor;
  final Color subtitleColor;

  const _RecentPdfSection({
    required this.isDark,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfsAsync = ref.watch(pdfListProvider);

    return pdfsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (pdfs) {
        if (pdfs.isEmpty) {
          return PolishedCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 48,
                  color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                ),
                const SizedBox(height: 12),
                Text(
                  'No PDFs yet',
                  style: TextStyle(color: subtitleColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scan or create PDFs to see them here',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final recent = pdfs.take(3).toList();
        return Column(
          children: recent.map((pdf) {
            return StaggeredFadeSlide(
              index: recent.indexOf(pdf),
              child: _PdfMiniTile(
                pdf: pdf,
                isDark: isDark,
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PdfMiniTile extends StatelessWidget {
  final dynamic pdf;
  final bool isDark;
  final Color textColor;
  final Color subtitleColor;

  const _PdfMiniTile({
    required this.pdf,
    required this.isDark,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PolishedCard(
        padding: const EdgeInsets.all(14),
        margin: EdgeInsets.zero,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                size: 22,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pdf.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pdf.pageCount} pages',
                    style: TextStyle(fontSize: 12, color: subtitleColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
