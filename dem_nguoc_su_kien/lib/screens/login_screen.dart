// lib/screens/login_screen.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool showPass = false;
  bool loading = false;

  late final AnimationController _ac;
  late final Animation<double> _hourglassBounce;
  late final Animation<double> _bgShift;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
    _hourglassBounce = Tween(begin: -4.0, end: 4.0)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_ac);
    _bgShift =
        Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.linear)).animate(_ac);
  }

  @override
  void dispose() {
    _ac.dispose();
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _signInEmail() async {
  if (!formKey.currentState!.validate()) return;
  setState(() => loading = true);
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailC.text.trim(),
      password: passC.text.trim(),
    );
} on FirebaseAuthException catch (e) {
  // In ra mã lỗi để kiểm tra nếu cần
  debugPrint('FirebaseAuth error: ${e.code}');

  final code = e.code.toLowerCase();
  String msg;

  if (code == 'user-not-found' ||
      code == 'wrong-password' ||
      code == 'invalid-credential' ||              // Firebase mới dùng mã này
      code == 'invalid-login-credentials') {       // đôi khi trả về mã này
    msg = 'Email hoặc mật khẩu không đúng';
  } else if (code == 'invalid-email') {
    msg = 'Email không hợp lệ';
  } else if (code == 'user-disabled') {
    msg = 'Tài khoản này đã bị vô hiệu hóa';
  } else if (code == 'too-many-requests') {
    msg = 'Bạn đã thử quá nhiều lần, vui lòng thử lại sau';
  } else if (code == 'network-request-failed') {
    msg = 'Không có kết nối mạng, vui lòng kiểm tra lại';
  } else {
    msg = 'Đăng nhập thất bại, vui lòng thử lại';
  }

  _toast(msg);
}
 finally {
    if (mounted) setState(() => loading = false);
  }
}

  Future<void> _signInGoogle() async {
    setState(() => loading = true);
    try {
      final g = GoogleSignIn();
      await g.signOut(); // luôn mở picker tài khoản
      final u = await g.signIn();
      if (u == null) {
        setState(() => loading = false);
        return;
      }
      final tok = await u.authentication;
      final cred = GoogleAuthProvider.credential(
        idToken: tok.idToken,
        accessToken: tok.accessToken,
      );
      await FirebaseAuth.instance.signInWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Không thể đăng nhập bằng Google');
    } catch (e) {
      _toast('Lỗi: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = emailC.text.trim();
    if (email.isEmpty) return _toast('Nhập email trước');
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _toast('Đã gửi email đặt lại mật khẩu');
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Không thể gửi email đặt lại mật khẩu');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = MediaQuery.of(context).size.height;
    final compact = h < 720; // màn nhỏ -> nén layout

    return AnimatedBuilder(
      animation: _ac,
      builder: (context, _) {
        return Scaffold(
          // Không scroll, không đẩy khi bật bàn phím
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // ===== BG gradient động + bubble =====
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, .5, 1.0],
                      colors: [
                        Color.lerp(const Color(0xFF0FB9B1), const Color(0xFF20B2AA), _bgShift.value)!,
                        Color.lerp(const Color(0xFF20B2AA), const Color(0xFF009688), _bgShift.value)!,
                        Color.lerp(const Color(0xFF009688), const Color(0xFF26A69A), _bgShift.value)!,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: Container(color: Colors.white.withOpacity(.12))),
              Positioned.fill(child: _Bubbles(ac: _ac)),

              // ===== Nội dung cố định =====
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: compact ? 8 : 20,
                    bottom: compact ? 8 : 16,
                  ),
                  child: Column(
                    children: [
                      _Header(ac: _hourglassBounce),
                      const SizedBox(height: 10),

                      // Card gói toàn bộ (có cả "Quên mật khẩu?")
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Card(
                            elevation: 12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                18, // padding nén hơn để tránh tràn
                                compact ? 16 : 22,
                                18,
                                compact ? 12 : 16,
                              ),
                              child: Form(
                                key: formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Đăng nhập để tiếp tục',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: compact ? 18 : 20,
                                      ),
                                    ),
                                    SizedBox(height: compact ? 12 : 16),

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
                                        final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v);
                                        if (!ok) return 'Email không hợp lệ';
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: compact ? 10 : 12),

                                    // Password
                                    TextFormField(
                                      controller: passC,
                                      obscureText: !showPass,
                                      decoration: InputDecoration(
                                        labelText: 'Mật khẩu',
                                        prefixIcon: const Icon(Icons.lock_outline),
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(() => showPass = !showPass),
                                          icon: Icon(showPass
                                              ? Icons.visibility_off
                                              : Icons.visibility),
                                        ),
                                      ),
                                      validator: (v) =>
                                          (v ?? '').length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                                    ),

                                    // Quên mật khẩu (nằm TRONG Card)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                        ),
                                        onPressed: loading ? null : _forgotPassword,
                                        child: const Text('Quên mật khẩu?'),
                                      ),
                                    ),

                                    // Nút Đăng nhập
                                    SizedBox(
                                      height: compact ? 46 : 50,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF009688),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        onPressed: loading ? null : _signInEmail,
                                        child: loading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Text(
                                                'Đăng nhập',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                      ),
                                    ),

                                    SizedBox(height: compact ? 8 : 10),

                                    // Tạo tài khoản
                                    SizedBox(
                                      height: compact ? 44 : 48,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        onPressed: loading
                                            ? null
                                            : () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => const RegisterScreen(),
                                                  ),
                                                ),
                                        child: const Text('Tạo tài khoản mới'),
                                      ),
                                    ),

                                    SizedBox(height: compact ? 10 : 12),

                                    // Divider
                                    Row(
                                      children: const [
                                        Expanded(child: Divider()),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text('hoặc'),
                                        ),
                                        Expanded(child: Divider()),
                                      ],
                                    ),

                                    SizedBox(height: compact ? 10 : 12),

                                    // Google
                                    SizedBox(
                                      height: compact ? 46 : 50,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        onPressed: loading ? null : _signInGoogle,
                                        icon: const Icon(Icons.g_mobiledata, size: 26),
                                        label: const Text(
                                          'Đăng nhập bằng Google',
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // chêm khoảng dưới một chút cho an toàn
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

class _Header extends StatelessWidget {
  const _Header({required this.ac});
  final Animation<double> ac;
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ac,
      builder: (_, __) {
        return Column(
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
              child: const Icon(Icons.hourglass_top_rounded, size: 44, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              'Đếm ngược sự kiện',
              style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: .3),
            ),
            const SizedBox(height: 4),
            Text(
              'Luôn đúng hẹn với mục tiêu của bạn',
              style: TextStyle(color: Colors.white.withOpacity(.9), fontSize: 13.5),
            ),
          ],
        );
      },
    );
  }
}

class _Bubbles extends StatelessWidget {
  const _Bubbles({required this.ac});
  final AnimationController ac;
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _BubblesPainter(progress: ac));
}

class _BubblesPainter extends CustomPainter {
  _BubblesPainter({required this.progress}) : super(repaint: progress);
  final Animation<double> progress;

  Offset _bubblePos(Size s, int i, double t) {
    final baseX = (i * 97) % s.width;
    final speed = .15 + (i % 5) * .05;
    final y = s.height * (0.75 - (t * speed + i * .07) % 1.0);
    final x = baseX + sin(t * 2 * pi * (.3 + i * .02)) * 20;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 16; i++) {
      final p = _bubblePos(size, i, t);
      final r = 6.0 + (i % 5) * 3.0;
      paint.color = Colors.white.withOpacity(.10 + (i % 4) * .05);
      canvas.drawCircle(p, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) => true;
}
