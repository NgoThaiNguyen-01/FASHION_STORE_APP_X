import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_screen.dart';
import './manage_orders_screen.dart';
import './manage_users_screen.dart';
import './manage_products_screen.dart';
import '../../database/db_helper.dart';

class AdminHomeScreen extends StatefulWidget {
  final String fullName;
  final int userId;

  const AdminHomeScreen({
    super.key,
    required this.fullName,
    required this.userId,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic> stats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => isLoading = true);
    try {
      final data = await DBHelper.getStatistics();
      setState(() => stats = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thống kê: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đăng xuất thành công'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // đợi 0.6s cho snackbar hiển thị
      await Future.delayed(const Duration(milliseconds: 600));

      // 🔁 Quay về màn hình login_screen.dart
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản trị viên'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: _buildCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_currentIndex == index && index == 0) {
            _loadStatistics(); // reload thống kê khi chọn lại tab đầu
          }
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Sản phẩm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Khách hàng',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildStatisticsScreen();
      case 1:
        return const ManageProductsScreen();
      case 2:
        return ManageOrdersScreen(onRefresh: _loadStatistics);
      case 3:
        return const ManageUsersScreen();
      default:
        return _buildStatisticsScreen();
    }
  }

  Widget _buildStatisticsScreen() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatisticsCard('Doanh thu', [
            _buildStatItem('Hôm nay', stats['todayRevenue'] ?? 0, true),
            _buildStatItem('Tuần này', stats['weekRevenue'] ?? 0, true),
            _buildStatItem('Tháng này', stats['monthRevenue'] ?? 0, true),
            _buildStatItem('Tổng cộng', stats['totalRevenue'] ?? 0, true),
          ]),
          const SizedBox(height: 16),
          _buildStatisticsCard('Đơn hàng', [
            _buildStatItem('Hôm nay', stats['todayOrders'] ?? 0),
            _buildStatItem('Tuần này', stats['weekOrders'] ?? 0),
            _buildStatItem('Tháng này', stats['monthOrders'] ?? 0),
            _buildStatItem('Tổng cộng', stats['totalOrders'] ?? 0),
          ]),
          const SizedBox(height: 16),
          _buildStatisticsCard('Trạng thái đơn hàng', [
            _buildStatItem('Chờ xử lý', stats['pendingOrders'] ?? 0),
            _buildStatItem('Đang xử lý', stats['processingOrders'] ?? 0),
            _buildStatItem('Đang giao', stats['shippedOrders'] ?? 0),
            _buildStatItem('Đã giao', stats['deliveredOrders'] ?? 0),
            _buildStatItem('Đã hủy', stats['cancelledOrders'] ?? 0),
          ]),
          const SizedBox(height: 16),
          _buildStatisticsCard('Sản phẩm', [
            _buildStatItem('Tổng số', stats['totalProducts'] ?? 0),
            _buildStatItem('Còn hàng', stats['inStockProducts'] ?? 0),
            _buildStatItem('Sắp hết', stats['lowStockProducts'] ?? 0),
            _buildStatItem('Hết hàng', stats['outOfStockProducts'] ?? 0),
            _buildStatItem('Đang giảm giá', stats['onSaleProducts'] ?? 0),
          ]),
          const SizedBox(height: 16),
          _buildStatisticsCard('Khách hàng', [
            _buildStatItem('Tổng số', stats['totalCustomers'] ?? 0),
          ]),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(String title, List<Widget> items) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, num value, [bool isCurrency = false]) {
    final displayValue = isCurrency
        ? '${value.toStringAsFixed(0)}₫'
        : value.toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            displayValue,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
