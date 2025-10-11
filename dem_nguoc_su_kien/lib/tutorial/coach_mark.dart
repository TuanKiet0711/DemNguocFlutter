import 'dart:ui';
import 'package:flutter/material.dart';

class CoachStep {
  CoachStep({
    required this.key,
    required this.title,
    required this.body,
    this.align = Alignment.bottomCenter, // mặc định tooltip nằm dưới target
    this.padding = const EdgeInsets.all(12),
    this.radius = 12,
  });

  final GlobalKey key;
  final String title;
  final String body;
  final Alignment align;
  final EdgeInsets padding;
  final double radius;
}

class CoachMark {
  CoachMark(this.context, this.steps);

  final BuildContext context;
  final List<CoachStep> steps;

  OverlayEntry? _overlay;
  int _index = 0;

  Future<void> start() async {
    if (steps.isEmpty) return;
    _index = 0;
    _show();
  }

  void _show() {
    _remove();
    final step = steps[_index];
    final renderBox = step.key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _show());
      return;
    }

    final targetOffset = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;
    final mq = MediaQuery.of(context);
    final screen = mq.size;

    _overlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // lớp nền tối
          Positioned.fill(
            child: GestureDetector(
              onTap: next,
              child: CustomPaint(
                painter: _HolePainter(
                  holeRect: RRect.fromRectAndRadius(
                    Rect.fromLTWH(
                      targetOffset.dx - 8,
                      targetOffset.dy - 8,
                      targetSize.width + 16,
                      targetSize.height + 16,
                    ),
                    Radius.circular(step.radius),
                  ),
                ),
              ),
            ),
          ),

          // tooltip card
          Positioned(
            left: 16,
            right: 16,
            top: _computeTooltipTop(
              align: step.align,
              target: targetOffset,
              targetSize: targetSize,
              screen: screen,
              safeTop: mq.padding.top,
              safeBottom: mq.padding.bottom,
            ),
            child: _TipCard(
              title: step.title,
              body: step.body,
              index: _index,
              total: steps.length,
              onNext: next,
              onSkip: end,
            ),
          ),

          // viền sáng quanh vùng highlight
          Positioned(
            left: targetOffset.dx - 4,
            top: targetOffset.dy - 4,
            child: IgnorePointer(
              child: Container(
                width: targetSize.width + 8,
                height: targetSize.height + 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(step.radius),
                  border:
                      Border.all(color: Colors.white.withOpacity(.9), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.25),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_overlay!);
  }

  // ====== TÍNH VỊ TRÍ TOOLTIP (tránh che nút, FAB) ======
  static const double _kTipHeight = 180;
  static const double _kGap = 16;
  static const double _kFabReserve = 92;

  double _computeTooltipTop({
    required Alignment align,
    required Offset target,
    required Size targetSize,
    required Size screen,
    required double safeTop,
    required double safeBottom,
  }) {
    final double wantBelow = target.dy + targetSize.height + _kGap;
    final double wantAbove = target.dy - _kTipHeight - _kGap;
    final double bottomLimit =
        screen.height - (_kFabReserve + safeBottom + _kGap);

    // luôn ưu tiên tooltip ở DƯỚI target (chỉ xuống)
    double top = wantBelow;
    if (top + _kTipHeight > bottomLimit) {
      top = wantAbove;
      if (top < safeTop + _kGap) top = safeTop + _kGap;
    }
    return top;
  }

  void next() {
    if (_index < steps.length - 1) {
      _index++;
      _show();
    } else {
      end();
    }
  }

  void end() => _remove();

  void _remove() {
    _overlay?.remove();
    _overlay = null;
  }
}

// lớp nền + lỗ
class _HolePainter extends CustomPainter {
  _HolePainter({required this.holeRect});
  final RRect holeRect;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.black.withOpacity(.6);
    canvas.drawRect(Offset.zero & size, bg);

    final clear = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRRect(holeRect, clear);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HolePainter oldDelegate) =>
      oldDelegate.holeRect != holeRect;
}

// card hướng dẫn
class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.title,
    required this.body,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  final String title;
  final String body;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Card(
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black.withOpacity(.8)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // dot chỉ số
                  Row(
                    children: List.generate(
                      total,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i <= index
                              ? const Color(0xFF009688)
                              : Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: onSkip, child: const Text('Bỏ qua')),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009688),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(index == total - 1 ? 'Xong' : 'Tiếp'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
