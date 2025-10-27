import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final emailCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool hideNewPass = true;
  bool hideConfirm = true;

  bool isVerified = false; // sau khi xác minh email
  String? message;
  bool isLoading = false;

  // 1️⃣ Xác minh email
  Future<void> _verifyEmail() async {
    final email = emailCtrl.text.trim();

    // Kiểm tra rỗng
    if (email.isEmpty) {
      setState(() => message = 'Vui lòng nhập email của bạn');
      return;
    }

    // Kiểm tra định dạng email
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => message = 'Email không hợp lệ (ví dụ: ten@gmail.com)');
      return;
    }

    setState(() => isLoading = true);

    try {
      // Kiểm tra tồn tại trong DB
      final exists = await DBHelper.checkEmailExists(email);

      setState(() {
        isLoading = false;
        if (exists) {
          isVerified = true;
          message = null;
        } else {
          message = 'Email không tồn tại trong hệ thống';
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        message = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      });
    }
  }

  // 2️⃣ Cập nhật mật khẩu mới
  Future<void> _updatePassword() async {
    final newPass = newPassCtrl.text;
    final confirm = confirmCtrl.text;

    // Kiểm tra rỗng
    if (newPass.isEmpty || confirm.isEmpty) {
      setState(() => message = 'Vui lòng nhập đầy đủ mật khẩu mới và xác nhận');
      return;
    }

    // Kiểm tra độ mạnh mật khẩu
    final passRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d!@#\$%^&*()_+=\-\[\]{}.,?]{8,}$');
    if (!passRegex.hasMatch(newPass)) {
      setState(() => message = 'Mật khẩu phải có ít nhất 8 ký tự và chứa cả chữ và số');
      return;
    }

    // Kiểm tra trùng khớp
    if (newPass != confirm) {
      setState(() => message = 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => isLoading = true);

    try {
      // Cập nhật DB
      final email = emailCtrl.text.trim();
      final ok = await DBHelper.updatePassword(email, newPass);

      setState(() {
        isLoading = false;
        if (ok) {
          message = '✅ Đổi mật khẩu thành công! Hãy đăng nhập lại.';
          // Tự động chuyển về màn hình login sau 2 giây
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacementNamed(context, '/login');
          });
        } else {
          message = 'Đã xảy ra lỗi, vui lòng thử lại.';
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        message = 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.';
      });
    }
  }

  // Quay lại màn hình xác minh email
  void _backToEmailVerification() {
    setState(() {
      isVerified = false;
      newPassCtrl.clear();
      confirmCtrl.clear();
      message = null;
    });
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    newPassCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (isVerified) {
              _backToEmailVerification();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Icon lớn
                Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: Colors.deepOrange.withOpacity(0.8),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Đặt lại mật khẩu',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  isVerified
                      ? 'Nhập mật khẩu mới cho tài khoản ${emailCtrl.text}'
                      : 'Nhập email để nhận liên kết đặt lại mật khẩu',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54
                  ),
                ),
                const SizedBox(height: 32),

                // Form xác minh email
                if (!isVerified) ...[
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email của bạn',
                      hintText: 'ví dụ: nguyenvana@gmail.com',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _verifyEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                        'Xác nhận email',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                  ),
                ],

                // Form đổi mật khẩu mới
                if (isVerified) ...[
                  TextField(
                    controller: newPassCtrl,
                    obscureText: hideNewPass,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      hintText: 'Ít nhất 8 ký tự, có cả chữ và số',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(hideNewPass ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => hideNewPass = !hideNewPass),
                      ),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: hideConfirm,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(hideConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => hideConfirm = !hideConfirm),
                      ),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _updatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                        'Cập nhật mật khẩu',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Thông báo lỗi / thành công
                if (message != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: message!.contains('✅')
                          ? Colors.green.withOpacity(0.1)
                          : Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: message!.contains('✅')
                            ? Colors.green
                            : Colors.redAccent,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: message!.contains('✅')
                            ? Colors.green
                            : Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Link quay lại đăng nhập
                if (!isVerified) ...[
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text(
                      'Quay lại đăng nhập',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}