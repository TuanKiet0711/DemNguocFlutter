// lib/screens/register_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final confirmC = TextEditingController();
  bool showPass = false;
  bool showConfirm = false;
  bool loading = false;

  late final AnimationController _ac;
  late final Animation<double> _bgShift;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _bgShift = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.linear))
        .animate(_ac);
    _bounce = Tween(begin: -4.0, end: 4.0)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_ac);
  }

  @override
  void dispose() {
    _ac.dispose();
    emailC.dispose();
    passC.dispose();
    confirmC.dispose();
    super.dispose();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _register() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailC.text.trim(),
        password: passC.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      _toast('Đăng ký thành công!');
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Lỗi đăng ký tài khoản');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final compact = h < 740; // tăng “compact mode” cho máy thấp

    return AnimatedBuilder(
      animation: _ac,
      builder: (_, __) {
        return Scaffold(
          resizeToAvoidBottomInset: false, // KHÔNG scroll
          body: Stack(
            children: [
              // ===== BG gradient động =====
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(const Color(0xFF20B2AA),
                                const Color(0xFF009688), _bgShift.value)!
                            .withOpacity(.98),
                        Color.lerp(const Color(0xFF009688),
                            const Color(0xFF26A69A), _bgShift.value)!,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                  child: Container(color: Colors.white.withOpacity(.12))),
              Positioned.fill(child: const _BubblesLayer()),

              // ===== Nội dung =====
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, compact ? 8 : 14, 16, 10),
                  child: Column(
                    children: [
                      // hàng trên: back + để trống cân đối
                      Row(
                        children: [
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(.25),
                            ),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // ===== Header đồng hồ cát =====
                      _HeaderRegister(bounce: _bounce),

                      const SizedBox(height: 10),

                      // ===== Card đăng ký (không tràn, tự compact) =====
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Card(
                            elevation: 12,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22)),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                  18, compact ? 16 : 22, 18, compact ? 16 : 20),
                              child: Form(
                                key: formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // tiêu đề card
                                    const Text(
                                      'Tạo tài khoản',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Điền thông tin để bắt đầu đếm ngược!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.black.withOpacity(.65),
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 16),

                                    // Email
                                    TextFormField(
                                      controller: emailC,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: Icon(Icons.email_outlined),
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      validator: (v) {
                                        v = (v ?? '').trim();
                                        if (v.isEmpty) return 'Nhập email';
                                        final ok = RegExp(
                                                r'^[^@]+@[^@]+\.[^@]+$')
                                            .hasMatch(v);
                                        if (!ok) return 'Email không hợp lệ';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // Mật khẩu
                                    TextFormField(
                                      controller: passC,
                                      obscureText: !showPass,
                                      decoration: InputDecoration(
                                        labelText: 'Mật khẩu (≥ 6 ký tự)',
                                        prefixIcon:
                                            const Icon(Icons.lock_outline),
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(
                                              () => showPass = !showPass),
                                          icon: Icon(showPass
                                              ? Icons.visibility_off
                                              : Icons.visibility),
                                        ),
                                      ),
                                      validator: (v) => (v ?? '').length < 6
                                          ? 'Tối thiểu 6 ký tự'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),

                                    // Nhập lại
                                    TextFormField(
                                      controller: confirmC,
                                      obscureText: !showConfirm,
                                      decoration: InputDecoration(
                                        labelText: 'Nhập lại mật khẩu',
                                        prefixIcon:
                                            const Icon(Icons.lock_outline),
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(
                                              () => showConfirm = !showConfirm),
                                          icon: Icon(showConfirm
                                              ? Icons.visibility_off
                                              : Icons.visibility),
                                        ),
                                      ),
                                      validator: (v) => v != passC.text
                                          ? 'Mật khẩu không khớp'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),

                                    // Đăng ký
                                    SizedBox(
                                      height: compact ? 46 : 50,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF009688),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        onPressed: loading ? null : _register,
                                        child: loading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                'Đăng ký',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Đã có tài khoản?
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                          'Đã có tài khoản? Đăng nhập'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: compact ? 8 : 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ===== Header đồng hồ cát + 2 dòng chữ =====
class _HeaderRegister extends StatelessWidget {
  final Animation<double> bounce;
  const _HeaderRegister({required this.bounce});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bounce,
      builder: (_, __) {
        return Padding(
          padding: EdgeInsets.only(top: 6 + bounce.value),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.22),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.hourglass_top_rounded,
                    size: 44, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                'Đếm ngược sự kiện',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Luôn đúng hẹn với mục tiêu của bạn',
                style: TextStyle(
                  color: Colors.white.withOpacity(.9),
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ===== Bubble layer dùng chung =====
class _BubblesLayer extends StatelessWidget {
  const _BubblesLayer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BubblesPainter());
  }
}

class _BubblesPainter extends CustomPainter {
  final _t = ValueNotifier(DateTime.now());
  _BubblesPainter() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }
  void _tick() {
    _t.value = DateTime.now();
    Future.delayed(const Duration(milliseconds: 16), () {
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.detached) {
        _tick();
      }
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 14; i++) {
      final baseX = (i * 97) % size.width;
      final speed = .15 + (i % 5) * .05;
      final y = size.height * (0.8 - (time * speed + i * .07) % 1.0);
      final x = baseX + sin(time * 2 * pi * (.3 + i * .02)) * 20;
      final r = 6.0 + (i % 5) * 3.0;
      paint.color = Colors.white.withOpacity(.10 + (i % 4) * .05);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
