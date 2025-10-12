import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../main.dart';

class CountdownText extends StatefulWidget {
  final DateTime target;
  final TextStyle? style;
  final String doneText;
  final bool notifyWhenDone;

  const CountdownText({
    super.key,
    required this.target,
    this.style,
    this.doneText = '🎉 ĐÃ ĐẾN HẸN 🎉',
    this.notifyWhenDone = true,
  });

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _timer;
  Duration _diff = Duration.zero;
  bool _finished = false;

  late final ConfettiController _confetti;
  late final AnimationController _pulseAC;
  late final Animation<double> _pulse;
  late final AnimationController _shimmerAC;
  late final AnimationController _fadeOutAC;

  OverlayEntry? _confettiOverlay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _confetti = ConfettiController(duration: const Duration(seconds: 8));

    _pulseAC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.96, end: 1.09)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_pulseAC);

    _shimmerAC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _fadeOutAC = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // ❗ Trì hoãn đến sau frame đầu để Overlay sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recompute(force: true);
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _recompute());
  }

  // 👉 Bắt sự kiện khi app resume (mở lại từ nền)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Khi mở lại app, cập nhật lại thời gian chính xác
      _recompute(force: true);
    }
  }

  Future<void> _onFinish() async {
    if (_finished) return;
    _finished = true;

    // ❗ Chèn overlay + play confetti sau frame kế tiếp để chắc chắn có Overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGlobalConfetti();
      _confetti.play();
    });

    if (widget.notifyWhenDone) {
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
        widget.doneText,
        'Sự kiện của bạn đã đến!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            kEventChannel.id,
            kEventChannel.name,
            channelDescription: kEventChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('ding'),
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }

    // 6s sau thì fade-out confetti, 9s thì tháo overlay (dư 1s để chắc chắn)
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) _fadeOutAC.forward();
    });
    Future.delayed(const Duration(seconds: 9), _removeGlobalConfetti);
  }

  void _showGlobalConfetti() {
    _removeGlobalConfetti();

    // ❗ Phòng trường hợp Overlay.of(context) null
    final overlayState =
        Overlay.maybeOf(context, rootOverlay: true) ?? Navigator.of(context).overlay;
    if (overlayState == null) return; // Không có overlay => thoát an toàn

    _confettiOverlay = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: FadeTransition(
          opacity: ReverseAnimation(_fadeOutAC),
          child: IgnorePointer(
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.14,
              numberOfParticles: 30,
              gravity: 0.35,
              maxBlastForce: 18,
              minBlastForce: 6,
              colors: const [
                Colors.tealAccent,
                Colors.amber,
                Colors.pinkAccent,
                Colors.lightBlue,
                Colors.deepPurpleAccent,
                Colors.greenAccent,
              ],
            ),
          ),
        ),
      ),
    );
    overlayState.insert(_confettiOverlay!);
  }

  void _removeGlobalConfetti() {
    _confettiOverlay?.remove();
    _confettiOverlay = null;
  }

  void _recompute({bool force = false}) {
    final now = DateTime.now();
    final next = widget.target.difference(now);
    if (!mounted) return;

    // Nếu force = true (mở lại app), cho phép cập nhật và tái trigger hiệu ứng nếu cần
    if (force || next.inSeconds != _diff.inSeconds) {
      setState(() => _diff = next);
      if (next.inSeconds <= 0) {
        _onFinish();
      }
    }
  }

  @override
  void didUpdateWidget(covariant CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _finished = false;
      _fadeOutAC.reset(); // reset lại fade-out phòng khi đổi target sau khi bắn xong
      _recompute(force: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _confetti.dispose();
    _pulseAC.dispose();
    _shimmerAC.dispose();
    _fadeOutAC.dispose();
    _removeGlobalConfetti();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _diff.isNegative || _diff.inSeconds == 0;

    if (isDone) {
      return AnimatedBuilder(
        animation: Listenable.merge([_pulseAC, _shimmerAC]),
        builder: (_, __) {
          final gradient = LinearGradient(
            colors: const [
              Color(0xFF00BCD4),
              Color(0xFFB2FF59),
              Color(0xFFFFF59D),
              Color(0xFF00BCD4),
            ],
            stops: const [0.0, 0.35, 0.7, 1.0],
            transform: GradientRotation(_shimmerAC.value * 2 * pi),
          );

          return Transform.scale(
            scale: _pulse.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.35),
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
                        fontSize: 28,
                        letterSpacing: 1.3,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      );
    }

    // Đếm ngược
    final d = _diff.inDays;
    final h = _diff.inHours % 24;
    final m = _diff.inMinutes % 60;
    final s = _diff.inSeconds % 60;

    return Text(
      ' $d ngày $h giờ $m phút $s giây',
      style: widget.style ??
          const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.teal,
          ),
    );
  }
}
