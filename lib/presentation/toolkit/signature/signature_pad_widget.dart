import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SignaturePadWidget extends StatefulWidget {
  final ValueChanged<List<List<Offset>>>? onStrokeChanged;

  const SignaturePadWidget({
    super.key,
    this.onStrokeChanged,
  });

  @override
  State<SignaturePadWidget> createState() => SignaturePadWidgetState();
}

class SignaturePadWidgetState extends State<SignaturePadWidget> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  Color _strokeColor = Colors.black;
  double _strokeWidth = 3.0;

  bool get isEmpty => _strokes.isEmpty && _currentStroke.isEmpty;

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
    widget.onStrokeChanged?.call(_strokes);
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
      widget.onStrokeChanged?.call(_strokes);
    }
  }

  void setStrokeColor(Color color) {
    setState(() => _strokeColor = color);
  }

  void setStrokeWidth(double width) {
    setState(() => _strokeWidth = width);
  }

  Future<Uint8List?> exportPngBytes({double scale = 2.0}) async {
    if (isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(400, 200);

    // Transparent background
    final painter = _SignaturePainter(
      strokes: _strokes,
      currentStroke: _currentStroke,
      color: _strokeColor,
      strokeWidth: _strokeWidth,
    );

    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage((size.width * scale).toInt(), (size.height * scale).toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Controls: Colors & Pen Width
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _ColorDot(
                  color: Colors.black,
                  isSelected: _strokeColor == Colors.black,
                  onTap: () => setStrokeColor(Colors.black),
                ),
                const SizedBox(width: 8),
                _ColorDot(
                  color: const Color(0xFF1E3A8A), // Classic Navy
                  isSelected: _strokeColor == const Color(0xFF1E3A8A),
                  onTap: () => setStrokeColor(const Color(0xFF1E3A8A)),
                ),
                const SizedBox(width: 8),
                _ColorDot(
                  color: const Color(0xFFDC2626), // Red
                  isSelected: _strokeColor == const Color(0xFFDC2626),
                  onTap: () => setStrokeColor(const Color(0xFFDC2626)),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.undo, size: 20),
                  tooltip: 'Undo stroke',
                  onPressed: _strokes.isNotEmpty ? undo : null,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Clear canvas',
                  onPressed: !isEmpty ? clear : null,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Drawing Canvas
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Baseline indicator
              Positioned(
                bottom: 40,
                left: 24,
                right: 24,
                child: Container(
                  height: 1,
                  color: (isDark ? Colors.white : Colors.black).withAlpha(35),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 24,
                child: Text(
                  'Sign on the line above',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),

              // Interactive gesture area
              GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _currentStroke = [details.localPosition];
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _currentStroke.add(details.localPosition);
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    if (_currentStroke.isNotEmpty) {
                      _strokes.add(List.from(_currentStroke));
                      _currentStroke.clear();
                    }
                  });
                  widget.onStrokeChanged?.call(_strokes);
                },
                child: CustomPaint(
                  painter: _SignaturePainter(
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                    color: _strokeColor,
                    strokeWidth: _strokeWidth,
                  ),
                  size: Size.infinite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
            width: 2.5,
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color color;
  final double strokeWidth;

  _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }
    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke, paint);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      canvas.drawCircle(points.first, strokeWidth / 2, paint);
      return;
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
