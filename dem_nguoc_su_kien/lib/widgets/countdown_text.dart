import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../main.dart';

class CountdownText extends StatefulWidget {
  final DateTime target;            // mốc đếm đến
  final TextStyle? style;
  final String doneText;            // text khi kết thúc
  final bool notifyWhenDone;        // có bắn noti khi về 0 không

  const CountdownText({
    super.key,
    required this.target,
    this.style,
    this.doneText = 'ĐÃ ĐẾN HẸN',
    this.notifyWhenDone = true,
  });

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText>
    with TickerProviderStateMixin {
  Timer? _timer;
  Duration _diff = Duration.zero;
  bool _finished = false;

  // Confetti (pháo giấy)
  late final ConfettiController _confetti;

  // Pulse + glow cho text DONE
  late final AnimationController _pulseAC;
  late final Animation<double> _pulse;

  // Shimmer (ánh sáng chạy qua chữ)
  late final AnimationController _shimmerAC;

  @override
  void initState() {
    super.initState();

    _confetti = ConfettiController(duration: const Duration(seconds: 2));

    _pulseAC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.18).chain(CurveTween(curve: Curves.easeOutBack)), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 45),
    ]).animate(_pulseAC);

    _shimmerAC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _recompute();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _recompute());
  }

  Future<void> _onFinish() async {
    if (_finished) return;
    _finished = true;

    // 1) Nổ confetti + pulse chữ
    _confetti.play();
    _pulseAC.forward(from: 0);

    // 2) Bắn local notification (kèm âm thanh)
    if (widget.notifyWhenDone) {
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
        widget.doneText,
        null,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'su_kien',           // giữ nguyên channel đã dùng trong app
            'Sự kiện',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('ding'), // <== dùng ding.mp3
          ),
        ),
      );
    }
  }

  void _recompute() {
    final now = DateTime.now();
    final next = widget.target.difference(now);

    if (!mounted) return;
    setState(() => _diff = next);

    if (next.inSeconds <= 0) {
      _onFinish();
    }
  }

  @override
  void didUpdateWidget(covariant CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _finished = false;
      _pulseAC.reset();
      _recompute();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confetti.dispose();
    _pulseAC.dispose();
    _shimmerAC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _diff.isNegative || _diff.inSeconds == 0;

    if (isDone) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Confetti layer
          Positioned.fill(
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.12,
                numberOfParticles: 16,
                gravity: 0.6,
                maxBlastForce: 12,
                minBlastForce: 5,
              ),
            ),
          ),

          // Shimmer + pulse text
          AnimatedBuilder(
            animation: Listenable.merge([_pulseAC, _shimmerAC]),
            builder: (_, __) {
              final gradient = LinearGradient(
                begin: Alignment(-1 + 2 * _shimmerAC.value, 0),
                end: Alignment(1 + 2 * _shimmerAC.value, 0),
                colors: const [
                  Color(0xFF00695C),
                  Color(0xFF26A69A),
                  Color(0xFF00695C),
                ],
                stops: const [0.25, 0.5, 0.75],
              );

              return Transform.scale(
                scale: _pulse.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.25),
                        blurRadius: 14,
                        spreadRadius: 1.5,
                      ),
                    ],
                  ),
                  child: ShaderMask(
                    shaderCallback: (rect) => gradient.createShader(rect),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      widget.doneText,
                      style: widget.style ??
                          const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.3,
                          ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    // Chưa hết giờ -> hiển thị thời gian còn lại
    final d = _diff.inDays;
    final h = _diff.inHours % 24;
    final m = _diff.inMinutes % 60;
    final s = _diff.inSeconds % 60;

    return Text(
      'Còn lại $d ngày $h giờ $m phút $s giây',
      style: widget.style ??
          const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.teal,
          ),
    );
  }
}
