import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _pushNotify = true;
  bool _emailNotify = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _pushNotify = prefs.getBool('pushNotify') ?? true;
      _emailNotify = prefs.getBool('emailNotify') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _darkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = _darkMode ? Colors.white : Colors.black87;
    final subColor = _darkMode ? Colors.grey[400] : Colors.black54;
    final tileColor = _darkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: _darkMode ? const Color(0xFF000000) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: bgColor,
        title: Text(
          'Cài đặt',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: textColor),
        elevation: 0.3,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _sectionTitle('Giao diện', textColor),
          _switchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Chế độ tối',
            subtitle: 'Bật giao diện tối cho trang cài đặt',
            value: _darkMode,
            onChanged: (val) {
              setState(() => _darkMode = val);
              _saveSetting('darkMode', val);
            },
            tileColor: tileColor,
            textColor: textColor,
            subColor: subColor!,
          ),
          const SizedBox(height: 20),

          _sectionTitle('Thông báo', textColor),
          _switchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Thông báo đẩy',
            subtitle: 'Nhận thông báo về đơn hàng và khuyến mãi',
            value: _pushNotify,
            onChanged: (val) {
              setState(() => _pushNotify = val);
              _saveSetting('pushNotify', val);
            },
            tileColor: tileColor,
            textColor: textColor,
            subColor: subColor,
          ),
          _switchTile(
            icon: Icons.email_outlined,
            title: 'Thông báo qua email',
            subtitle: 'Nhận cập nhật đơn hàng qua email',
            value: _emailNotify,
            onChanged: (val) {
              setState(() => _emailNotify = val);
              _saveSetting('emailNotify', val);
            },
            tileColor: tileColor,
            textColor: textColor,
            subColor: subColor,
          ),
          const SizedBox(height: 20),

          _sectionTitle('Chính sách', textColor),
          _infoTile(
            icon: Icons.shield_outlined,
            title: 'Chính sách bảo mật',
            subtitle: 'Xem chi tiết chính sách bảo mật của cửa hàng',
            onTap: () => _showSnack('Mở trang Chính sách bảo mật', context),
            tileColor: tileColor,
            textColor: textColor,
            subColor: subColor,
          ),
          _infoTile(
            icon: Icons.description_outlined,
            title: 'Điều khoản sử dụng',
            subtitle: 'Xem các điều khoản và quy định sử dụng',
            onTap: () => _showSnack('Mở trang Điều khoản sử dụng', context),
            tileColor: tileColor,
            textColor: textColor,
            subColor: subColor,
          ),
          const SizedBox(height: 20),

          _sectionTitle('Thông tin ứng dụng', textColor),
          _infoTile(
            icon: Icons.info_outline,
            title: 'Phiên bản ứng dụng',
            subtitle: '1.0.0',
            onTap: () {},
            tileColor: tileColor,
            textColor: textColor,
            subColor: subColor,
          ),
        ],
      ),
    );
  }

  // ===== Tiện ích UI =====
  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color tileColor,
    required Color textColor,
    required Color subColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.orangeAccent),
        title: Text(title, style: TextStyle(color: textColor)),
        subtitle: Text(subtitle, style: TextStyle(color: subColor, fontSize: 13)),
        trailing: Switch(
          activeColor: Colors.orangeAccent,
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color tileColor,
    required Color textColor,
    required Color subColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.orangeAccent),
        title: Text(title, style: TextStyle(color: textColor)),
        subtitle: Text(subtitle, style: TextStyle(color: subColor, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showSnack(String msg, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }
}
