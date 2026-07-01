import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../model/pdf_document.dart';
import '../providers/scanner_provider.dart';

class PdfViewerScreen extends ConsumerWidget {
  final PdfDocument doc;

  const PdfViewerScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.gold),
            onPressed: () async {
              HapticFeedback.lightImpact();
              try {
                await Share.shareXFiles([XFile(doc.filePath)], text: doc.title);
              } catch (e) {
                debugPrint('Share error: $e');
              }
            },
            tooltip: 'Share',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: isDark ? AppColors.white : AppColors.deepNavy),
            onSelected: (action) async {
              final actions = ref.read(pdfActionsProvider);
              switch (action) {
                case 'rename':
                  final ctrl = TextEditingController(text: doc.title);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Rename'),
                      content: TextField(controller: ctrl, autofocus: true),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () {
                            if (ctrl.text.trim().isNotEmpty) {
                              actions.rename(doc, ctrl.text.trim());
                              Navigator.pop(ctx);
                            }
                          },
                          child: const Text('Rename'),
                        ),
                      ],
                    ),
                  );
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
                    await actions.delete(doc);
                    if (context.mounted) Navigator.of(context).pop();
                  }
              }
            },
            itemBuilder: (_) => [
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
        ],
      ),
      body: PdfPreview(
        build: (format) async => File(doc.filePath).readAsBytes(),
        canChangeOrientation: false,
        maxPageWidth: 400,
        scrollViewDecoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A192F) : const Color(0xFFF8F9FC),
        ),
        loadingWidget: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      ),
    );
  }
}
