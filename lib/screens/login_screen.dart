import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool hidePassword = true;
  bool isLoading = false;
  String? thongBao;

  Future<void> _dangNhap() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // 1️⃣ Kiểm tra rỗng
    if (email.isEmpty || password.isEmpty) {
      setState(() => thongBao = 'Vui lòng nhập đầy đủ email và mật khẩu');
      return;
    }

    // 2️⃣ Kiểm tra định dạng email
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => thongBao = 'Email không hợp lệ (ví dụ: ten@gmail.com)');
      return;
    }

    // 3️⃣ Kiểm tra độ dài mật khẩu
    if (password.length < 8) {
      setState(() => thongBao = 'Mật khẩu phải có ít nhất 8 ký tự');
      return;
    }

    // 4️⃣ Kiểm tra mật khẩu có chữ hoa, chữ thường và số
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)');
    if (!passwordRegex.hasMatch(password)) {
      setState(() => thongBao = 'Mật khẩu phải chứa ít nhất 1 chữ hoa, 1 chữ thường và 1 số');
      return;
    }

    setState(() {
      thongBao = null;
      isLoading = true;
    });

    try {
      // 5️⃣ Gọi hàm login từ DBHelper
      final result = await DBHelper.login(email, password);

      setState(() => isLoading = false);

      if (result != null && result.containsKey('error')) {
        // Có lỗi từ server
        setState(() => thongBao = result['error'] as String);
      } else if (result != null) {
        // Đăng nhập thành công -> chuyển sang HomeScreen (KHÔNG hiển thị SnackBar)
        final fullName = result['fullName'] as String? ?? '';
        final role = result['role'] as String? ?? 'khach_hang';

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              fullName: fullName,
              isAdmin: role == 'admin',
              userId: (result['id'] as int?) ?? 0,   // <- THÊM DÒNG NÀY
            ),
          ),
        );
      } else {
        setState(() => thongBao = 'Đã xảy ra lỗi không xác định');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        thongBao = 'Lỗi kết nối: $e';
      });
      debugPrint('Lỗi đăng nhập: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Logo
                Image.asset(
                  'assets/images/anh_logo_cty.png',
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.shopping_bag, size: 60, color: Colors.deepOrange);
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  'Chào Mừng Trở Lại!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đăng nhập để tiếp tục mua sắm',
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Email
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Nhập email của bạn',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                  onChanged: (_) => setState(() => thongBao = null),
                ),
                const SizedBox(height: 16),

                // Mật khẩu
                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    hintText: 'Nhập mật khẩu của bạn',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(hidePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => hidePassword = !hidePassword),
                    ),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                  onChanged: (_) => setState(() => thongBao = null),
                ),

                // Quên mật khẩu
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/reset'),
                    child: const Text('Quên mật khẩu?', style: TextStyle(color: Colors.deepOrange)),
                  ),
                ),

                const SizedBox(height: 16),

                // Thông báo lỗi
                if (thongBao != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      thongBao!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 20),

                // Nút đăng nhập
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _dangNhap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'Đăng Nhập',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Đăng ký tài khoản
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Chưa có tài khoản?"),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      child: const Text(
                        'Đăng ký',
                        style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
