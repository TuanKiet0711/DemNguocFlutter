// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final confirmC = TextEditingController();
  bool showPass = false;
  bool showConfirm = false;
  bool loading = false;

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
      if (context.mounted) {
        Navigator.pop(context); // quay lại trang đăng nhập
        _toast("Đăng ký thành công!");
      }
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? "Lỗi đăng ký tài khoản");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F7),
      appBar: AppBar(
        title: const Text("Đăng ký tài khoản"),
        backgroundColor: Colors.teal,
      ),
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
                      const Icon(Icons.person_add_alt_1,
                          size: 60, color: Colors.teal),
                      const SizedBox(height: 8),
                      Text(
                        "Tạo tài khoản mới",
                        style: theme.textTheme.titleLarge!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // Email
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
                          final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v);
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
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => showPass = !showPass),
                            icon: Icon(
                                showPass ? Icons.visibility_off : Icons.visibility),
                          ),
                        ),
                        validator: (v) =>
                            (v ?? '').length < 6 ? 'Tối thiểu 6 ký tự' : null,
                      ),
                      const SizedBox(height: 12),

                      // Xác nhận mật khẩu
                      TextFormField(
                        controller: confirmC,
                        obscureText: !showConfirm,
                        decoration: InputDecoration(
                          labelText: 'Nhập lại mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => showConfirm = !showConfirm),
                            icon: Icon(showConfirm
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                        validator: (v) {
                          if (v != passC.text) return 'Mật khẩu không khớp';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: loading ? null : _register,
                          child: loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Đăng ký",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Đã có tài khoản? Đăng nhập"),
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
