import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart' hide PdfDocument;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/pill_button.dart';
import '../../providers/pdf_provider.dart';
import '../scanner/model/pdf_document.dart';

class PdfCombinerScreen extends ConsumerStatefulWidget {
  const PdfCombinerScreen({super.key});

  @override
  ConsumerState<PdfCombinerScreen> createState() => _PdfCombinerScreenState();
}

class _PdfCombinerScreenState extends ConsumerState<PdfCombinerScreen> {
  List<String> _selectedFiles = [];
  List<String> _fileNames = [];
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
            if (file.path != null && !_selectedFiles.contains(file.path)) {
              _selectedFiles.add(file.path!);
              _fileNames.add(file.name);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e')),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      _fileNames.removeAt(index);
    });
  }

  void _moveUp(int index) {
    if (index == 0) return;
    setState(() {
      final tempFile = _selectedFiles.removeAt(index);
      final tempName = _fileNames.removeAt(index);
      _selectedFiles.insert(index - 1, tempFile);
      _fileNames.insert(index - 1, tempName);
    });
  }

  void _moveDown(int index) {
    if (index >= _selectedFiles.length - 1) return;
    setState(() {
      final tempFile = _selectedFiles.removeAt(index);
      final tempName = _fileNames.removeAt(index);
      _selectedFiles.insert(index + 1, tempFile);
      _fileNames.insert(index + 1, tempName);
    });
  }

  Future<void> _merge() async {
    if (_selectedFiles.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 2 PDFs to merge')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final pdf = pw.Document();
      int totalPages = 0;
      for (final filePath in _selectedFiles) {
        final file = File(filePath);
        final bytes = await file.readAsBytes();

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
      final outputPath = '${dir.path}/combined_$timestamp.pdf';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(await pdf.save());

      final pdfDoc = PdfDocument(
        id: timestamp.toString(),
        title: 'Combined PDF',
        filePath: outputPath,
        pageCount: totalPages,
        createdAt: DateTime.now(),
      );
      await ref.read(pdfActionsProvider).savePdf(pdfDoc);

      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Merged ${_selectedFiles.length} PDFs ($totalPages pages)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _selectedFiles.clear();
          _fileNames.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Merge error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtitleColor = isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('PDF Combiner'),
      ),
      body: Container(
        color: bgColor,
        child: Column(
          children: [
            if (_selectedFiles.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.merge_type_rounded,
                        size: 80,
                        color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No PDFs selected',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select PDF files to combine them into one',
                        style: TextStyle(color: subtitleColor),
                      ),
                      const SizedBox(height: 32),
                      PillButton(
                        label: 'Pick PDF Files',
                        onTap: _pickFiles,
                        icon: Icons.add_rounded,
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
                            color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedFiles.length} file(s) selected',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _pickFiles,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkAccent.withOpacity(0.15)
                                    : AppColors.lightSecondary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, size: 14, color: isDark ? AppColors.darkAccent : AppColors.lightSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Add More',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
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
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _selectedFiles.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  _fileNames[index],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (index > 0)
                                      _IconBtn(
                                        icon: Icons.keyboard_arrow_up_rounded,
                                        onTap: () => _moveUp(index),
                                        isDark: isDark,
                                      ),
                                    if (index < _selectedFiles.length - 1)
                                      _IconBtn(
                                        icon: Icons.keyboard_arrow_down_rounded,
                                        onTap: () => _moveDown(index),
                                        isDark: isDark,
                                      ),
                                    _IconBtn(
                                      icon: Icons.close_rounded,
                                      onTap: () => _removeFile(index),
                                      color: AppColors.error,
                                      isDark: isDark,
                                    ),
                                  ],
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
            if (_selectedFiles.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: PillButton(
                    label: _loading ? 'Merging...' : 'Merge PDFs',
                    onTap: _loading ? null : _merge,
                    loading: _loading,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final Color? color;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? (isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: color ?? (isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle),
        ),
      ),
    );
  }
}
