import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import 'edit_profile_screen.dart';
import 'orders_screen.dart';
import 'shipping_address_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'support_screen.dart';

class AccountScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const AccountScreen({super.key, required this.user});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late Map<String, dynamic> user;

  @override
  void initState() {
    super.initState();
    user = Map<String, dynamic>.from(widget.user);
  }

  Future<void> _dangXuat(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Đã đăng xuất thành công!'),
      backgroundColor: Colors.green,
    ));

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String fullName = user['fullName'] ?? 'Người dùng';
    final String email = user['email'] ?? 'Chưa cập nhật';
    final String? avatarPath = user['avatar'];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Tài khoản của tôi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ===== Thông tin người dùng =====
          Column(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundImage: (avatarPath != null && avatarPath.isNotEmpty)
                    ? FileImage(File(avatarPath))
                    : const AssetImage('assets/images/anh_avata_macdinh.png')
                as ImageProvider,
              ),
              const SizedBox(height: 12),
              Text(
                fullName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 160,
                height: 38,
                child: ElevatedButton(
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(user: user),
                      ),
                    );

                    if (updated == true) {
                      final fresh = await DBHelper.getUserById(user['id']);
                      if (fresh != null) {
                        setState(() => user = fresh);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cập nhật hồ sơ thành công!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Chỉnh sửa hồ sơ'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // ===== Danh sách chức năng =====
          _buildMenuItem(
            context,
            icon: Icons.shopping_bag_outlined,
            title: 'Đơn hàng của tôi',
            page: OrdersScreen(userId: user['id'] as int),
          ),
          _buildMenuItem(
            context,
            icon: Icons.location_on_outlined,
            title: 'Địa chỉ giao hàng',
            page: ShippingAddressScreen(
              userId: (user['id'] as num).toInt(),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.support_agent,
            title: 'Liên hệ hỗ trợ',
            page: const SupportScreen(), // ✅ không cần truyền userId
          ),
          _buildMenuItem(
            context,
            icon: Icons.settings_outlined,
            title: 'Cài đặt',
            page: const SettingsScreen(),
          ),

          const SizedBox(height: 10),
          const Divider(thickness: 0.5),

          // ===== Đăng xuất =====
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () => _dangXuat(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Widget page,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.orangeAccent, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
      ),
    );
  }
}
