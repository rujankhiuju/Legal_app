import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../providers/scanner_provider.dart';
import 'dart:io';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      _controller?.resumePreview();
    } else if (state == AppLifecycleState.inactive) {
      _controller?.pausePreview();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      final controller = CameraController(_cameras[0], ResolutionPreset.veryHigh);
      _controller = controller;
      await controller.initialize();
      if (mounted) setState(() => _isReady = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      HapticFeedback.mediumImpact();
      final XFile photo = await _controller!.takePicture();
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = '${dir.path}/scan_$timestamp.jpg';
      await File(photo.path).copy(savedPath);

      if (mounted) {
        ref.read(scannedImagePathsProvider.notifier).add(savedPath);
        context.pushNamed(RouteNames.editScan, extra: savedPath);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = '${dir.path}/scan_$timestamp.jpg';
      await File(image.path).copy(savedPath);

      if (mounted) {
        ref.read(scannedImagePathsProvider.notifier).add(savedPath);
        context.pushNamed(RouteNames.editScan, extra: savedPath);
      }
    } catch (e) {
      debugPrint('Gallery pick error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scanCount = ref.watch(scannedImagePathsProvider).length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
        title: const Text('Document Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickFromGallery,
            tooltip: 'Pick from gallery',
          ),
          if (scanCount > 0)
            IconButton(
              icon: const Icon(Icons.check, color: AppColors.gold),
              onPressed: () {
                context.pushNamed(RouteNames.pdfGenerate);
              },
              tooltip: 'Create PDF ($scanCount)',
            ),
        ],
      ),
      body: _isReady && _controller != null
          ? Stack(
              children: [
                CameraPreview(_controller!),
                SafeArea(
                  child: Column(
                    children: [
                      const Spacer(),
                      _CaptureControls(
                        scanCount: scanCount,
                        onCapture: _capture,
                        onGeneratePdf: () =>
                            context.pushNamed(RouteNames.pdfGenerate),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                if (scanCount > 0)
                  Positioned(
                    top: 8,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$scanCount scan${scanCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: AppColors.deepNavy,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.gold),
                  SizedBox(height: 16),
                  Text('Initializing camera...', style: TextStyle(color: AppColors.white)),
                ],
              ),
            ),
    );
  }
}

class _CaptureControls extends StatelessWidget {
  final int scanCount;
  final VoidCallback onCapture;
  final VoidCallback onGeneratePdf;

  const _CaptureControls({
    required this.scanCount,
    required this.onCapture,
    required this.onGeneratePdf,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onCapture,
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white,
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.black, width: 3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (scanCount > 0)
          ElevatedButton.icon(
            onPressed: onGeneratePdf,
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: Text('Create PDF ($scanCount)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.deepNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }
}
