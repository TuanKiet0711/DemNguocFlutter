// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_screen.dart'; // <-- import trang đăng ký

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool showPass = false;
  bool loading = false;

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ---------- Đăng nhập Email ----------
  Future<void> _signInEmail() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailC.text.trim(),
        password: passC.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Đăng nhập thất bại');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ---------- Đăng nhập Google (luôn hiển thị chọn tài khoản) ----------
  Future<void> _signInGoogle() async {
    setState(() => loading = true);
    try {
      final googleSignIn = GoogleSignIn();
      // 🔹 Đăng xuất trước để luôn hiển thị danh sách tài khoản Google
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => loading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final cur = FirebaseAuth.instance.currentUser;
      if (cur != null && cur.isAnonymous) {
        await cur.linkWithCredential(cred);
      } else {
        await FirebaseAuth.instance.signInWithCredential(cred);
      }
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Không thể đăng nhập bằng Google');
    } catch (e) {
      _toast('Lỗi: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ---------- Gửi email reset mật khẩu ----------
  Future<void> _forgotPassword() async {
    final email = emailC.text.trim();
    if (email.isEmpty) {
      _toast('Nhập email trước');
      return;
    }
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

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F7),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ===== Header Logo =====
                      CircleAvatar(
                        radius: 34,
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(.12),
                        child: Icon(Icons.hourglass_bottom,
                            size: 36, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Đăng nhập để tiếp tục',
                        style: theme.textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ===== Email =====
                      TextFormField(
                        controller: emailC,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          v = (v ?? '').trim();
                          if (v.isEmpty) return 'Nhập email';
                          final ok =
                              RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v);
                          if (!ok) return 'Email không hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // ===== Password =====
                      TextFormField(
                        controller: passC,
                        obscureText: !showPass,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu (≥ 6 ký tự)',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => showPass = !showPass),
                            icon: Icon(showPass
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                        validator: (v) => (v ?? '').length < 6
                            ? 'Mật khẩu tối thiểu 6 ký tự'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // ===== Buttons =====
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal),
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ===== Chuyển sang Đăng ký =====
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton(
                          onPressed: loading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const RegisterScreen()),
                                  );
                                },
                          child: const Text('Tạo tài khoản mới'),
                        ),
                      ),

                      // ===== Divider =====
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('hoặc'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                      ),

                      // ===== Google Sign-in =====
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: loading ? null : _signInGoogle,
                          icon: Image.asset(
                            'assets/google.png',
                            width: 20,
                            height: 20,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.g_mobiledata),
                          ),
                          label: const Text('Đăng nhập bằng Google'),
                        ),
                      ),

                      // ===== Forgot password =====
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
