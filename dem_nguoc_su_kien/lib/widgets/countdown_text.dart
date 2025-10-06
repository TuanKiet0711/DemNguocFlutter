import 'dart:async';
import 'package:flutter/material.dart';

class CountdownText extends StatefulWidget {
  final DateTime target;           // mốc đếm đến (đã xử lý lặp nếu cần)
  final TextStyle? style;          // style tuỳ chọn
  final String doneText;           // text khi đã đến

  const CountdownText({
    super.key,
    required this.target,
    this.style,
    this.doneText = 'ĐÃ ĐẾN!',
  });

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  late Timer _timer;
  late Duration _diff;

  @override
  void initState() {
    super.initState();
    _tick();                                   // tính lần đầu
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    setState(() => _diff = widget.target.difference(now));
  }

  @override
  void didUpdateWidget(covariant CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) _tick(); // đổi target thì cập nhật ngay
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_diff.isNegative) {
      return Text(widget.doneText,
          style: (widget.style ?? const TextStyle(fontWeight: FontWeight.bold)));
    }
    final d = _diff.inDays;
    final h = _diff.inHours % 24;
    final m = _diff.inMinutes % 60;
    final s = _diff.inSeconds % 60;

    return Text(
      '${d}d ${h}h ${m}m ${s}s',
      style: widget.style ??
          const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'),
    );
  }
}
