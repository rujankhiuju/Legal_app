import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart' hide PdfDocument;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/pill_button.dart' hide AnimatedBuilder;

class PdfCombinerScreen extends ConsumerStatefulWidget {
  const PdfCombinerScreen({super.key});

  @override
  ConsumerState<PdfCombinerScreen> createState() => _PdfCombinerScreenState();
}

class _PdfCombinerScreenState extends ConsumerState<PdfCombinerScreen> {
  List<PlatformFile> _files = [];
  bool _loading = false;

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            final exists = _files.any((f) => f.path == file.path);
            if (!exists) {
              _files.add(file);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() => _files.removeAt(index));
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _files.removeAt(oldIndex);
      _files.insert(newIndex, item);
    });
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _combine() async {
    setState(() => _loading = true);
    try {
      final pdf = pw.Document();
      int totalPages = 0;

      for (final platformFile in _files) {
        final bytes = await File(platformFile.path!).readAsBytes();

        await for (final raster in Printing.raster(bytes)) {
          final pngBytes = await raster.toPng();
          final pageFormat = PdfPageFormat(
            raster.width * 72.0 / 150.0,
            raster.height * 72.0 / 150.0,
          );
          pdf.addPage(
            pw.Page(
              pageFormat: pageFormat,
              margin: const pw.EdgeInsets.all(0),
              build: (_) => pw.Image(pw.MemoryImage(pngBytes)),
            ),
          );
          totalPages++;
        }
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${dir.path}/Combined_$timestamp.pdf';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(outputPath)],
        text: 'Combined PDF',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDFs combined successfully! ($totalPages pages)')),
        );
        setState(() => _files.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error combining PDFs: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtitleColor = isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle;
    final bgColor = const Color(0xFF0A192F);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'PDF Combiner',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: bgColor,
        child: Column(
          children: [
            if (_files.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.merge_type_rounded,
                          size: 50,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'PDF Combiner',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select PDF files to combine them into one document',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 32),
                      PillButton(
                        label: 'Pick PDFs',
                        onTap: _pickFiles,
                        icon: Icons.add_rounded,
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF0A192F),
                      ),
                    ],
                  ),
                ),
              )
              else
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.description_rounded,
                              size: 18,
                              color: const Color(0xFFD4AF37),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_files.length} file(s) selected',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _pickFiles,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded, size: 14, color: Color(0xFFD4AF37)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Add More',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFD4AF37),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _files.length,
                          onReorder: _onReorder,
                          proxyDecorator: (child, index, animation) {
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) {
                                final scale = 1.0 + 0.02 * animation.value;
                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFD4AF37).withOpacity(0.2 * animation.value),
                                          blurRadius: 12 * animation.value,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: child,
                                  ),
                                );
                              },
                              child: child,
                            );
                          },
                          itemBuilder: (context, index) {
                            final file = _files[index];
                            final fileSize = File(file.path!).lengthSync();
                            return Dismissible(
                              key: ValueKey(file.path),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                              ),
                              onDismissed: (_) => _removeFile(index),
                              child: Container(
                                key: ValueKey(file.path),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4AF37).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFD4AF37),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    file.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  subtitle: Text(
                                    _formatSize(fileSize),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                  trailing: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _removeFile(index);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            if (_files.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.06)),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: PillButton(
                    label: _loading ? 'Combining...' : 'Combine PDFs',
                    onTap: _loading ? null : _combine,
                    loading: _loading,
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF0A192F),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
