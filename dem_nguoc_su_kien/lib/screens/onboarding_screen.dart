import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../i18n/app_localizations.dart';
import '../services/user_meta_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pc = PageController();
  int _index = 0;

  late final AnimationController _bgAC;
  late final Animation<double> _bgShift;

  bool _notifGranted = false;
  bool _mediaGranted = false;

  @override
  void initState() {
    super.initState();
    _bgAC = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
    _bgShift = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.linear))
        .animate(_bgAC);

    _checkCurrentPerms();
  }

  @override
  void dispose() {
    _bgAC.dispose();
    _pc.dispose();
    super.dispose();
  }

  Future<void> _checkCurrentPerms() async {
    final notif = await Permission.notification.status;
    final camera = await Permission.camera.status;
    final photos = await Permission.photos.status;
    if (!mounted) return;
    setState(() {
      _notifGranted = notif.isGranted;
      _mediaGranted = camera.isGranted || photos.isGranted;
    });
  }

  Future<void> _askNotification(AppLoc loc) async {
    final result = await Permission.notification.request();
    if (!mounted) return;
    setState(() => _notifGranted = result.isGranted);
    _toast(result.isGranted ? loc.granted : loc.denied);
    HapticFeedback.selectionClick();
  }

  Future<void> _askMedia(AppLoc loc) async {
    final cam = await Permission.camera.request();
    // iOS 14+ dùng photos; Android sẽ bỏ qua
    final pho = await Permission.photos
        .request()
        .onError((_, __) => PermissionStatus.denied);

    if (!mounted) return;
    setState(() => _mediaGranted = cam.isGranted || pho.isGranted);
    _toast(_mediaGranted ? loc.granted : loc.denied);
    HapticFeedback.lightImpact();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _finish() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await UserMetaService().markOnboarded(uid);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLoc.of(context);

    return AnimatedBuilder(
      animation: _bgAC,
      builder: (_, __) {
        return Scaffold(
          backgroundColor: const Color(0xFFF2FAF8),
          body: Stack(
            children: [
              // Nền gradient động
              Positioned.fill(child: _AnimatedGradient(shift: _bgShift.value)),
              // Lớp hạt nổi
              const Positioned.fill(child: _FloatingDotsLayer()),
              // Nội dung
              SafeArea(
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          // Logo + brand
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(.22),
                                ),
                                child: const Icon(Icons.hourglass_top_rounded,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Đếm ngược sự kiện',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: .3,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _finish,
                            child: Text(
                              loc.skip,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Pages
                    Expanded(
                      child: PageView(
                        controller: _pc,
                        onPageChanged: (i) => setState(() => _index = i),
                        children: [
                          _FeaturePage(
                            // Parallax card 1
                            accent: Colors.teal,
                            icon: Icons.event,
                            title: loc.onbTitle1,
                            desc: loc.onbDesc1,
                            chips: const ['Sinh nhật', 'Kỷ niệm', 'Thi cử', 'Mục tiêu'],
                          ),
                          _PermissionPage(
                            accent: const Color(0xFF20B2AA),
                            icon: Icons.notifications_active_outlined,
                            title: loc.onbTitle2,
                            desc: loc.onbDesc2,
                            buttonText:
                                _notifGranted ? '✓ ${loc.granted}' : loc.enableNotifications,
                            onTap: _notifGranted ? null : () => _askNotification(loc),
                            granted: _notifGranted,
                          ),
                          _PermissionPage(
                            accent: const Color(0xFF26A69A),
                            icon: Icons.photo_camera_back_outlined,
                            title: loc.onbTitle3,
                            desc: loc.onbDesc3,
                            buttonText: _mediaGranted ? '✓ ${loc.granted}' : loc.enableMedia,
                            onTap: _mediaGranted ? null : () => _askMedia(loc),
                            granted: _mediaGranted,
                          ),
                        ],
                      ),
                    ),

                    // Footer: Dots + CTA
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                      child: Row(
                        children: [
                          _Dots(count: 3, index: _index),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: (_index + 1) / 3,
                                minHeight: 8,
                                color: Colors.white,
                                backgroundColor: Colors.white.withOpacity(.25),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF006E63),
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              if (_index < 2) {
                                HapticFeedback.selectionClick();
                                _pc.nextPage(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOut,
                                );
                              } else {
                                HapticFeedback.mediumImpact();
                                await _finish();
                              }
                            },
                            child: Row(
                              children: [
                                Text(
                                  _index < 2 ? loc.next : loc.getStarted,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(_index < 2
                                    ? Icons.arrow_forward_rounded
                                    : Icons.rocket_launch_rounded),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Animated gradient background with soft movement
class _AnimatedGradient extends StatelessWidget {
  const _AnimatedGradient({required this.shift});
  final double shift;

  @override
  Widget build(BuildContext context) {
    final c1 = Color.lerp(const Color(0xFF0FB9B1), const Color(0xFF20B2AA), shift)!;
    final c2 = Color.lerp(const Color(0xFF20B2AA), const Color(0xFF009688), shift)!;
    final c3 = Color.lerp(const Color(0xFF009688), const Color(0xFF26A69A), shift)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1 + shift, -1),
          end: Alignment(1 - shift, 1),
          stops: const [0.0, .5, 1.0],
          colors: [c1, c2, c3],
        ),
      ),
      child: Container(color: Colors.white.withOpacity(.06)),
    );
  }
}

/// Floating dots (soft ambient particles)
class _FloatingDotsLayer extends StatefulWidget {
  const _FloatingDotsLayer();

  @override
  State<_FloatingDotsLayer> createState() => _FloatingDotsLayerState();
}

class _FloatingDotsLayerState extends State<_FloatingDotsLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DotsPainter(progress: _ac));
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({required this.progress}) : super(repaint: progress);
  final Animation<double> progress;

  Offset _pos(Size s, int i, double t) {
    final baseX = (i * 97) % s.width;
    final speed = .08 + (i % 5) * .03;
    final y = s.height * (0.85 - (t * speed + i * .07) % 1.0);
    final x = baseX + sin(t * 2 * pi * (.3 + i * .02)) * 22;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 18; i++) {
      final p = _pos(size, i, t);
      final r = 5.0 + (i % 5) * 2.5;
      paint.color = Colors.white.withOpacity(.08 + (i % 4) * .05);
      canvas.drawCircle(p, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter oldDelegate) => true;
}

/// Pretty feature page with parallax card
class _FeaturePage extends StatelessWidget {
  const _FeaturePage({
    required this.accent,
    required this.icon,
    required this.title,
    required this.desc,
    this.chips = const [],
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String desc;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: -12, end: 0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (_, dy, child) {
                return Transform.translate(offset: Offset(0, dy), child: child);
              },
              child: _ParallaxCard(
                accent: accent,
                icon: icon,
                title: title,
                desc: desc,
                chips: chips,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _ParallaxCard extends StatelessWidget {
  const _ParallaxCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.desc,
    required this.chips,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String desc;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Glow shadow
        Positioned(
          top: -30,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(.25),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.92),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(.18),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: accent.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 54, color: accent),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: .2),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black.withOpacity(.65),
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),
              if (chips.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: chips
                      .map((t) => Chip(
                            label: Text(
                              t,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: accent.withOpacity(.08),
                            side: BorderSide(color: accent.withOpacity(.28)),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Permission page with big icon + action button (shows granted state)
class _PermissionPage extends StatelessWidget {
  const _PermissionPage({
    required this.accent,
    required this.icon,
    required this.title,
    required this.desc,
    required this.buttonText,
    required this.onTap,
    required this.granted,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String desc;
  final String buttonText;
  final VoidCallback? onTap;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Layered icon effect
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(.10),
                    ),
                  ),
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(.16),
                    ),
                  ),
                  Icon(icon, size: 62, color: Colors.white),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(.93),
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onTap,
                icon: Icon(granted ? Icons.check_circle : Icons.settings),
                label: Text(
                  buttonText,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF006E63),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              if (onTap != null)
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(
                    AppLoc.of(context).later,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: active
                ? Border.all(color: Colors.white, width: 0)
                : Border.all(color: Colors.white.withOpacity(.45), width: 1),
          ),
        );
      }),
    );
  }
}
