import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../model/pdf_document.dart';
import '../providers/scanner_provider.dart';

class PdfLibraryScreen extends ConsumerWidget {
  const PdfLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.deepNavy : AppColors.lightBackground;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner, color: AppColors.gold),
            onPressed: () => context.pushNamed(RouteNames.scanner),
            tooltip: 'Scan new document',
          ),
        ],
      ),
      body: Container(
        color: bgColor,
        child: ref.watch(pdfListProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (pdfs) {
            if (pdfs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf, size: 72, color: AppColors.gold.withOpacity(0.4)),
                    const SizedBox(height: 16),
                    Text('No PDFs yet',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.white.withOpacity(0.7)
                            : AppColors.deepNavy.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => context.pushNamed(RouteNames.scanner),
                      icon: const Icon(Icons.document_scanner, color: AppColors.gold),
                      label: const Text('Scan a document', style: TextStyle(color: AppColors.gold)),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pdfs.length,
              itemBuilder: (context, index) => _PdfCard(
                doc: pdfs[index],
                isDark: isDark,
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
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month-1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark ? AppColors.white : AppColors.deepNavy;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.picture_as_pdf, color: AppColors.gold, size: 26),
        ),
        title: Text(
          doc.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        ),
        subtitle: Text(
          '${doc.pageCount} page${doc.pageCount > 1 ? 's' : ''} · ${_formatDate(doc.createdAt)}',
          style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: textColor.withOpacity(0.6)),
          onSelected: (action) => _handleAction(context, ref, action),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'view', child: ListTile(
              leading: Icon(Icons.visibility, color: AppColors.gold),
              title: Text('View'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
            const PopupMenuItem(value: 'share', child: ListTile(
              leading: Icon(Icons.share, color: AppColors.gold),
              title: Text('Share'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
            const PopupMenuItem(value: 'rename', child: ListTile(
              leading: Icon(Icons.edit, color: AppColors.gold),
              title: Text('Rename'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
            const PopupMenuItem(value: 'delete', child: ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text('Delete', style: TextStyle(color: Colors.redAccent)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
          ],
        ),
        onTap: () => context.pushNamed(RouteNames.pdfViewer, extra: doc),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, String action) async {
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
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
