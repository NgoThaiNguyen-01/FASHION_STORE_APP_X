import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final fullNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool hidePassword = true;
  bool hideConfirm = true;
  bool isLoading = false;

  String? generalMessage; // thông báo tổng (lỗi từ DB hoặc thành công)

  // ===== Validators =====
  String? _validateFullName(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Vui lòng nhập họ và tên';
    if (value.length < 2) return 'Họ và tên phải có ít nhất 2 ký tự';
    if (value.length > 50) return 'Họ và tên tối đa 50 ký tự';
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ỹ\s'\-\.]+$");
    if (!nameRegex.hasMatch(value)) {
      return 'Họ và tên chỉ gồm chữ, khoảng trắng và dấu hợp lệ';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Vui lòng nhập email';
    // Email chuẩn thông dụng
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ (ví dụ: ten@gmail.com)';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    final value = (v ?? '');
    if (value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (value.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
    // Có chữ và số, cho phép một số ký tự đặc biệt phổ biến
    final passRegex =
    RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d!@#\$%^&*()_+=\-\[\]{}.,?]{8,}$');
    if (!passRegex.hasMatch(value)) {
      return 'Mật khẩu phải chứa cả chữ và số';
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    final value = (v ?? '');
    if (value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
    if (value != passwordCtrl.text) return 'Mật khẩu xác nhận không khớp';
    return null;
  }

  Future<void> _signUp() async {
    setState(() {
      generalMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final fullName = fullNameCtrl.text.trim();
    final email = emailCtrl.text.trim().toLowerCase();
    final password = passwordCtrl.text;

    // Giả định: DBHelper.registerUser trả về String? (null = OK, lỗi = message)
    final err = await DBHelper.registerUser(
      fullName: fullName,
      email: email,
      password: password, // hashing nên làm ở DBHelper
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (err == null) {
      // Thành công
      setState(() => generalMessage = null);
      // Chuyển thẳng vào Home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Lỗi (ví dụ: email đã tồn tại)
      setState(() => generalMessage = err);
    }
  }

  @override
  void dispose() {
    fullNameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tạo tài khoản',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Nhập thông tin bên dưới để đăng ký'),
                    const SizedBox(height: 28),

                    // Họ và tên
                    TextFormField(
                      controller: fullNameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateFullName,
                    ),
                    const SizedBox(height: 14),

                    // Email
                    TextFormField(
                      controller: emailCtrl,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 14),

                    // Mật khẩu
                    TextFormField(
                      controller: passwordCtrl,
                      textInputAction: TextInputAction.next,
                      obscureText: hidePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            hidePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => hidePassword = !hidePassword),
                        ),
                        border: const OutlineInputBorder(),
                        helperText: 'Tối thiểu 8 ký tự, gồm chữ và số',
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 14),

                    // Xác nhận mật khẩu
                    TextFormField(
                      controller: confirmCtrl,
                      textInputAction: TextInputAction.done,
                      obscureText: hideConfirm,
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            hideConfirm ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => hideConfirm = !hideConfirm),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: _validateConfirm,
                    ),

                    // Thông báo tổng
                    if (generalMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        generalMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],

                    const SizedBox(height: 22),

                    // Nút đăng ký
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text(
                          'Đăng ký',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đã có tài khoản? Đăng nhập'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
