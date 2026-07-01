import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/widgets/staggered_animation.dart';
import '../../../shared/widgets/polished_card.dart';
import '../model/pdf_document.dart';
import '../providers/scanner_provider.dart';

class PdfLibraryScreen extends ConsumerWidget {
  const PdfLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Library'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.document_scanner_rounded,
              color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
            ),
            onPressed: () => context.pushNamed(RouteNames.scanner),
            tooltip: 'Scan new document',
          ),
        ],
      ),
      body: Container(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        child: ref.watch(pdfListProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (pdfs) {
            if (pdfs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 72,
                      color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No PDFs yet',
                      style: TextStyle(
                        color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => context.pushNamed(RouteNames.scanner),
                      icon: Icon(
                        Icons.document_scanner_rounded,
                        color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                      ),
                      label: Text(
                        'Scan a document',
                        style: TextStyle(
                          color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pdfs.length,
              itemBuilder: (context, index) => StaggeredFadeSlide(
                index: index,
                child: _PdfCard(doc: pdfs[index], isDark: isDark),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PdfCard extends ConsumerWidget {
  final PdfDocument doc;
  final bool isDark;

  const _PdfCard({required this.doc, required this.isDark});

  String _formatDate(DateTime dt) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PolishedCard(
        padding: const EdgeInsets.all(0),
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 56,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              color: accentColor,
              size: 26,
            ),
          ),
          title: Text(
            doc.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          subtitle: Text(
            '${doc.pageCount} page${doc.pageCount > 1 ? 's' : ''} · ${_formatDate(doc.createdAt)}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
            ),
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz_rounded,
              color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
            ),
            onSelected: (action) => _handleAction(context, ref, action),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'view',
                child: ListTile(
                  leading: Icon(Icons.visibility_rounded),
                  title: Text('View'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share_rounded),
                  title: Text('Share'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'rename',
                child: ListTile(
                  leading: Icon(Icons.edit_rounded),
                  title: Text('Rename'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  title: Text('Delete', style: TextStyle(color: AppColors.error)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          onTap: () => context.pushNamed(RouteNames.pdfViewer, extra: doc),
        ),
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String action) async {
    final actions = ref.read(pdfActionsProvider);

    switch (action) {
      case 'view':
        context.pushNamed(RouteNames.pdfViewer, extra: doc);
      case 'share':
        try {
          final file = XFile(doc.filePath);
          await Share.shareXFiles([file], text: doc.title);
        } catch (e) {
          debugPrint('Share error: $e');
        }
      case 'rename':
        _showRenameDialog(context, ref, doc);
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete PDF'),
            content: Text('Delete "${doc.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          HapticFeedback.mediumImpact();
          final file = File(doc.filePath);
          if (await file.exists()) await file.delete();
          await actions.delete(doc);
        }
    }
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, PdfDocument doc) {
    final controller = TextEditingController(text: doc.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename PDF'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'New name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(pdfActionsProvider).rename(doc, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}
