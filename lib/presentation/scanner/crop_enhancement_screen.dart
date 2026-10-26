import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/storage/file_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/enhancement_preset.dart';
import '../../domain/models/scanned_page.dart';
import '../../services/image_pipeline_service.dart';
import 'widgets/quad_crop_painter.dart';

class CropEnhancementScreen extends StatefulWidget {
  final ScannedPage page;
  final FileStorageService fileStorageService;

  const CropEnhancementScreen({
    super.key,
    required this.page,
    required this.fileStorageService,
  });

  @override
  State<CropEnhancementScreen> createState() => _CropEnhancementScreenState();
}

class _CropEnhancementScreenState extends State<CropEnhancementScreen> {
  late EnhancementPreset _selectedPreset;
  late int _rotation;
  late List<PointCoord> _corners;
  int? _activeCornerIndex;
  bool _isSaving = false;

  Uint8List? _sourceBytes;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.page.preset;
    _rotation = widget.page.rotation;
    _corners = widget.page.cropCorners != null
        ? List.from(widget.page.cropCorners!)
        : [
            const PointCoord(0.05, 0.05), // TL
            const PointCoord(0.95, 0.05), // TR
            const PointCoord(0.95, 0.95), // BR
            const PointCoord(0.05, 0.95), // BL
          ];
    _loadSourceImage();
  }

  Future<void> _loadSourceImage() async {
    final file = File(widget.page.originalPath);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      setState(() {
        _sourceBytes = bytes;
      });
    }
  }

  void _rotateClockwise() {
    setState(() {
      _rotation = (_rotation + 90) % 360;
    });
  }

  Future<void> _applyAndSave() async {
    if (_sourceBytes == null) return;
    setState(() => _isSaving = true);

    try {
      Uint8List processed = _sourceBytes!;

      // 1. Perspective Crop if corners modified
      final isFullQuad = _corners[0].x <= 0.02 &&
          _corners[0].y <= 0.02 &&
          _corners[1].x >= 0.98 &&
          _corners[1].y <= 0.02 &&
          _corners[2].x >= 0.98 &&
          _corners[2].y >= 0.98 &&
          _corners[3].x <= 0.02 &&
          _corners[3].y >= 0.98;

      if (!isFullQuad) {
        // Map normalized coordinates to source image resolution
        final decoded = await File(widget.page.originalPath).readAsBytes();
        final imgObj = ImagePipelineService.applyPreset(decoded, EnhancementPreset.original);
        // Crop using perspective transform
        processed = ImagePipelineService.perspectiveCrop(
          imgObj,
          topLeft: PointCoord(_corners[0].x * 1000, _corners[0].y * 1000),
          topRight: PointCoord(_corners[1].x * 1000, _corners[1].y * 1000),
          bottomRight: PointCoord(_corners[2].x * 1000, _corners[2].y * 1000),
          bottomLeft: PointCoord(_corners[3].x * 1000, _corners[3].y * 1000),
        );
      }

      // 2. Rotation
      if (_rotation > 0) {
        processed = ImagePipelineService.rotate(processed, _rotation);
      }

      // 3. Preset Filter
      processed = ImagePipelineService.applyPreset(processed, _selectedPreset);

      // Save processed derivative into temporary managed storage
      final outPath = widget.fileStorageService.createTempFilePath(extension: 'jpg');
      await File(outPath).writeAsBytes(processed, flush: true);

      final updatedPage = widget.page.copyWith(
        currentPath: outPath,
        rotation: _rotation,
        preset: _selectedPreset,
        cropCorners: _corners,
      );

      if (mounted) {
        Navigator.of(context).pop(updatedPage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size canvasSize) {
    if (_activeCornerIndex == null) return;

    final newX = (details.localPosition.dx / canvasSize.width).clamp(0.0, 1.0);
    final newY = (details.localPosition.dy / canvasSize.height).clamp(0.0, 1.0);

    setState(() {
      _corners[_activeCornerIndex!] = PointCoord(newX, newY);
    });
  }

  int? _findNearestCorner(Offset localPos, Size canvasSize) {
    const touchRadius = 40.0;
    for (int i = 0; i < 4; i++) {
      final cornerOffset = Offset(_corners[i].x * canvasSize.width, _corners[i].y * canvasSize.height);
      if ((localPos - cornerOffset).distance <= touchRadius) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Adjust Crop & Filter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_right),
            tooltip: 'Rotate 90°',
            onPressed: _rotateClockwise,
          ),
          TextButton(
            onPressed: _isSaving ? null : _applyAndSave,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Done',
                    style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Interactive Canvas
          Expanded(
            child: _sourceBytes == null
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        onPanDown: (details) {
                          _activeCornerIndex = _findNearestCorner(details.localPosition, canvasSize);
                        },
                        onPanUpdate: (details) {
                          _onPanUpdate(details, canvasSize);
                        },
                        onPanEnd: (_) {
                          _activeCornerIndex = null;
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Base Image Display
                            Center(
                              child: RotatedBox(
                                quarterTurns: _rotation ~/ 90,
                                child: Image.memory(
                                  _sourceBytes!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            // Quad Crop Painter Overlay
                            CustomPaint(
                              size: canvasSize,
                              painter: QuadCropPainter(
                                corners: _corners,
                                imageDisplaySize: canvasSize,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Filter & Presets Carousel
          Container(
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enhancement Filter',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: EnhancementPreset.values.map((preset) {
                      final isSelected = _selectedPreset == preset;
                      return ChoiceChip(
                        label: Text(preset.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedPreset = preset);
                          }
                        },
                        selectedColor: AppColors.primaryLight,
                        backgroundColor: const Color(0xFF334155),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
