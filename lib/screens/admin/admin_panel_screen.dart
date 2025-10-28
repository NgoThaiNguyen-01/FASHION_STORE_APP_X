import 'package:flutter/material.dart';
import 'manage_orders_screen.dart';
import 'manage_users_screen.dart';
import 'admin_statistics_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ManageUsersScreen(),
    ManageOrdersScreen(),
    AdminStatisticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_currentIndex) {
          0 => 'Quản lý người dùng',
          1 => 'Quản lý đơn hàng',
          2 => 'Thống kê',
          _ => 'Quản trị',
        }),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people), label: 'Người dùng'),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Đơn hàng',
          ),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Thống kê'),
        ],
      ),
    );
  }
}
