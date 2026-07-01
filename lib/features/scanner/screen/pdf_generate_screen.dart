import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/scanner_provider.dart';

class PdfGenerateScreen extends ConsumerStatefulWidget {
  const PdfGenerateScreen({super.key});

  @override
  ConsumerState<PdfGenerateScreen> createState() => _PdfGenerateScreenState();
}

class _PdfGenerateScreenState extends ConsumerState<PdfGenerateScreen> {
  final _titleController = TextEditingController(
    text: 'Scan ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}',
  );
  bool _generating = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _generatePdf() async {
    final imagePaths = ref.read(scannedImagePathsProvider);
    if (imagePaths.isEmpty) return;

    setState(() => _generating = true);

    try {
      final pdf = pw.Document();

      for (final path in imagePaths) {
        final file = File(path);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        final image = pw.MemoryImage(bytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            ),
          ),
        );
      }

      final bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          '${_titleController.text.trim()}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${dir.path}/$fileName';
      await File(filePath).writeAsBytes(bytes);

      await ref.read(pdfActionsProvider).savePdf(
            title: _titleController.text.trim(),
            filePath: filePath,
            pageCount: imagePaths.length,
          );

      ref.read(scannedImagePathsProvider.notifier).clear();
      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved: ${_titleController.text.trim()}'),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('PDF generation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate PDF'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePaths = ref.watch(scannedImagePathsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create PDF'),
        actions: [
          _generating
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.save_rounded, color: accentColor),
                  onPressed: _generatePdf,
                ),
        ],
      ),
      body: Container(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Document title',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(18),
                  prefixIcon: Icon(
                    Icons.description_rounded,
                    color: accentColor,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.image_rounded, size: 16, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    '${imagePaths.length} page${imagePaths.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(scannedImagePathsProvider.notifier).clear();
                      if (mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Clear all'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.7,
                ),
                itemCount: imagePaths.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(imagePaths[index]),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            ref.read(scannedImagePathsProvider.notifier).remove(index);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
