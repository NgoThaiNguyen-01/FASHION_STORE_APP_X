import 'package:flutter/material.dart';
import '../../database/db_helper.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      final list = await DBHelper.getAllUsers();
      setState(() => users = list);
      print('✅ Loaded ${list.length} users');
    } catch (e) {
      _showError('Lỗi tải danh sách người dùng: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _deleteUser(int userId) async {
    try {
      await DBHelper.deleteUser(userId);
      await _loadUsers();
      _showSuccess('Đã xóa người dùng');
    } catch (e) {
      _showError('Lỗi xóa người dùng: $e');
    }
  }

  Future<void> _updateUser(Map<String, dynamic> user) async {
    final nameCtrl = TextEditingController(text: user['fullName']);
    final emailCtrl = TextEditingController(text: user['email']);
    final phoneCtrl = TextEditingController(text: user['phone']);
    final passwordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    bool isAdmin = (user['role'] == 'admin');
    bool showPasswordFields = false;
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cập nhật người dùng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ tên'),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  enabled: false,
                ),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Đổi mật khẩu'),
                  value: showPasswordFields,
                  onChanged: (v) => setState(() => showPasswordFields = v),
                ),
                if (showPasswordFields) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordCtrl,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                    obscureText: obscurePassword,
                  ),
                  TextField(
                    controller: confirmPasswordCtrl,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(() =>
                        obscureConfirmPassword = !obscureConfirmPassword),
                      ),
                    ),
                    obscureText: obscureConfirmPassword,
                  ),
                ],
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Quyền Admin'),
                  value: isAdmin,
                  onChanged: (v) => setState(() => isAdmin = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (showPasswordFields) {
                    final newPass = passwordCtrl.text.trim();
                    final confirm = confirmPasswordCtrl.text.trim();
                    if (newPass.isEmpty || confirm.isEmpty) {
                      _showError('Vui lòng nhập đầy đủ mật khẩu mới');
                      return;
                    }
                    if (newPass != confirm) {
                      _showError('Mật khẩu xác nhận không khớp');
                      return;
                    }
                    if (newPass.length < 8) {
                      _showError('Mật khẩu phải có ít nhất 8 ký tự');
                      return;
                    }
                    await DBHelper.updatePassword(
                        emailCtrl.text.trim(), newPass);
                  }

                  await DBHelper.updateUser(
                    user['id'],
                    nameCtrl.text.trim(),
                    emailCtrl.text.trim(),
                    phoneCtrl.text.trim(),
                    isAdmin,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    await _loadUsers();
                    _showSuccess('Đã cập nhật người dùng');
                  }
                } catch (e) {
                  _showError('Lỗi cập nhật: $e');
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addUser() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool isAdmin = false;
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm người dùng mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ tên *'),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: passwordCtrl,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu *',
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                  obscureText: obscurePassword,
                ),
                TextField(
                  controller: confirmPasswordCtrl,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu *',
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(() =>
                      obscureConfirmPassword = !obscureConfirmPassword),
                    ),
                  ),
                  obscureText: obscureConfirmPassword,
                ),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Quyền Admin'),
                  value: isAdmin,
                  onChanged: (v) => setState(() => isAdmin = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final email = emailCtrl.text.trim().toLowerCase();
                final password = passwordCtrl.text;
                final confirm = confirmPasswordCtrl.text;

                if (name.isEmpty ||
                    email.isEmpty ||
                    password.isEmpty ||
                    confirm.isEmpty) {
                  _showError('Vui lòng điền đầy đủ thông tin bắt buộc');
                  return;
                }

                if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email)) {
                  _showError('Email không hợp lệ');
                  return;
                }

                if (password.length < 6) {
                  _showError('Mật khẩu phải có ít nhất 6 ký tự');
                  return;
                }

                if (password != confirm) {
                  _showError('Mật khẩu xác nhận không khớp');
                  return;
                }

                try {
                  final err = await DBHelper.createUser(
                    name,
                    email,
                    password,
                    phoneCtrl.text.trim(),
                    isAdmin,
                  );
                  if (err != null) {
                    _showError(err);
                    return;
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    await _loadUsers();
                    _showSuccess('Đã thêm người dùng mới');
                  }
                } catch (e) {
                  _showError('Lỗi tạo người dùng: $e');
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
      ),
      body: users.isEmpty
          ? const Center(child: Text('Chưa có người dùng nào'))
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.person),
              ),
              title: Text(user['fullName'] ?? 'Chưa có tên'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['email'] ?? ''),
                  Text(user['phone'] ?? 'Chưa có SĐT'),
                  if (user['role'] == 'admin')
                    const Chip(
                      label: Text(
                        'Admin',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                ],
              ),
              trailing: PopupMenuButton(
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Sửa')),
                  PopupMenuItem(value: 'delete', child: Text('Xóa')),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _updateUser(user);
                  } else if (value == 'delete') {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Xác nhận xóa'),
                        content: const Text(
                          'Bạn có chắc muốn xóa người dùng này?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteUser(user['id']);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUser,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
