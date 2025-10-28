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
    bool isAdmin = user['isAdmin'] == 1;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                enabled: false, // Không cho phép đổi email
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Quyền Admin'),
                value: isAdmin,
                onChanged: (value) => setState(() => isAdmin = value),
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
                  _showSuccess('Đã cập nhật thông tin người dùng');
                }
              } catch (e) {
                _showError('Lỗi cập nhật: $e');
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _addUser() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool isAdmin = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                decoration: const InputDecoration(labelText: 'Mật khẩu *'),
                obscureText: true,
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
                onChanged: (value) => setState(() => isAdmin = value),
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
              final email = emailCtrl.text.trim();
              final password = passwordCtrl.text;

              if (name.isEmpty || email.isEmpty || password.isEmpty) {
                _showError('Vui lòng điền đầy đủ thông tin bắt buộc');
                return;
              }

              try {
                await DBHelper.createUser(
                  name,
                  email,
                  password,
                  phoneCtrl.text.trim(),
                  isAdmin,
                );
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
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
                        if (user['isAdmin'] == 1)
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
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Xóa'),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _updateUser(user);
                            break;
                          case 'delete':
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
                            break;
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
