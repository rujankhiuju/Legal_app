import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/scanner_provider.dart';

class EditScanScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const EditScanScreen({super.key, required this.imagePath});

  @override
  ConsumerState<EditScanScreen> createState() => _EditScanScreenState();
}

class _EditScanScreenState extends ConsumerState<EditScanScreen> {
  img.Image? _originalImage;
  img.Image? _workingImage;
  Uint8List? _displayBytes;
  final TransformationController _transformController = TransformationController();
  bool _isGrayscale = false;
  int _rotation = 0;
  bool _cropMode = false;
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image != null) {
      setState(() {
        _originalImage = image;
        _workingImage = img.Image.from(image);
        _displayBytes = Uint8List.fromList(img.encodeJpg(_workingImage!));
      });
    }
  }

  void _applyFilter() {
    if (_originalImage == null) return;
    var image = img.Image.from(_originalImage!);
    for (int i = 0; i < _rotation % 4; i++) {
      image = img.copyRotate(image, 90);
    }
    if (_isGrayscale) {
      image = img.grayscale(image);
    }
    _workingImage = image;
    _displayBytes = Uint8List.fromList(img.encodeJpg(image));
    setState(() {});
  }

  void _toggleGrayscale() {
    setState(() => _isGrayscale = !_isGrayscale);
    _applyFilter();
  }

  void _rotate(int degrees) {
    setState(() {
      _rotation = (_rotation + degrees ~/ 90) % 4;
    });
    _applyFilter();
  }

  Future<void> _cropToVisible() async {
    if (_workingImage == null) return;
    try {
      final RenderBox? box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final viewportSize = box.size;
      final matrix = _transformController.value;
      final inverse = Matrix4.tryInvert(matrix);
      if (inverse == null) return;

      final topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
      final bottomRight = MatrixUtils.transformPoint(
        inverse,
        Offset(viewportSize.width, viewportSize.height),
      );

      final scaleX = _workingImage!.width / viewportSize.width;
      final scaleY = _workingImage!.height / viewportSize.height;
      final scale = (matrix.getMaxScaleOnAxis());
      final cropX = (-topLeft.dx * scale).clamp(0, _workingImage!.width - 1).toInt();
      final cropY = (-topLeft.dy * scale).clamp(0, _workingImage!.height - 1).toInt();
      final cropW = (viewportSize.width / scale).clamp(1, _workingImage!.width - cropX).toInt();
      final cropH = (viewportSize.height / scale).clamp(1, _workingImage!.height - cropY).toInt();

      final cropped = img.copyCrop(_workingImage!, x: cropX, y: cropY, width: cropW, height: cropH);
      _workingImage = cropped;
      _displayBytes = Uint8List.fromList(img.encodeJpg(cropped));
      _transformController.value = Matrix4.identity();
      setState(() => _cropMode = false);
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Crop error: $e');
    }
  }

  Future<void> _save() async {
    if (_workingImage == null) return;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(path).writeAsBytes(img.encodeJpg(_workingImage!));

    final paths = ref.read(scannedImagePathsProvider);
    final idx = paths.indexOf(widget.imagePath);
    if (idx >= 0) {
      ref.read(scannedImagePathsProvider.notifier).replace(idx, path);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
        title: const Text('Edit Scan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.gold),
            onPressed: _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: _displayBytes == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : Column(
              children: [
                Expanded(
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.5,
                    maxScale: 4,
                    child: KeyedSubtree(
                      key: _imageKey,
                      child: Image.memory(_displayBytes!, fit: BoxFit.contain),
                    ),
                  ),
                ),
                Container(
                  color: Colors.grey[900],
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ToolButton(
                        icon: Icons.rotate_left,
                        label: 'Rotate',
                        onTap: () => _rotate(-90),
                      ),
                      _ToolButton(
                        icon: _isGrayscale ? Icons.color_lens : Icons.filter_b_and_w,
                        label: _isGrayscale ? 'Color' : 'Grayscale',
                        onTap: _toggleGrayscale,
                        active: _isGrayscale,
                      ),
                      _ToolButton(
                        icon: Icons.crop,
                        label: _cropMode ? 'Apply Crop' : 'Crop',
                        onTap: () {
                          if (_cropMode) {
                            _cropToVisible();
                          } else {
                            setState(() => _cropMode = true);
                          }
                        },
                        active: _cropMode,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active ? AppColors.gold : AppColors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: active ? AppColors.deepNavy : AppColors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: active ? AppColors.gold : AppColors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
