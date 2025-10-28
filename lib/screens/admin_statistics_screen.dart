import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  bool isLoading = true;
  String? _error;
  Map<String, dynamic> stats = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() {
        isLoading = true;
        _error = null;
      });

      final loadedStats = await DBHelper.getStatistics();
      setState(() {
        stats = loadedStats;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải thống kê: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê'), centerTitle: true),
      body: RefreshIndicator(onRefresh: _loadStatistics, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loadStatistics,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummarySection(),
          const SizedBox(height: 24),
          _buildOrdersSection(),
          const SizedBox(height: 24),
          _buildSalesSection(),
          const SizedBox(height: 24),
          _buildProductsSection(),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tổng quan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Tổng doanh thu',
              '${stats['totalRevenue'] ?? 0} ₫',
              Colors.green,
              Icons.attach_money,
            ),
            _buildStatCard(
              'Tổng đơn hàng',
              '${stats['totalOrders'] ?? 0}',
              Colors.blue,
              Icons.shopping_cart,
            ),
            _buildStatCard(
              'Số khách hàng',
              '${stats['totalCustomers'] ?? 0}',
              Colors.orange,
              Icons.people,
            ),
            _buildStatCard(
              'Số sản phẩm',
              '${stats['totalProducts'] ?? 0}',
              Colors.purple,
              Icons.inventory,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đơn hàng',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildOrderStatusItem(
                  'Chờ xác nhận',
                  stats['pendingOrders'] ?? 0,
                  Colors.orange,
                ),
                const Divider(),
                _buildOrderStatusItem(
                  'Đang xử lý',
                  stats['processingOrders'] ?? 0,
                  Colors.blue,
                ),
                const Divider(),
                _buildOrderStatusItem(
                  'Đang giao hàng',
                  stats['shippedOrders'] ?? 0,
                  Colors.amber,
                ),
                const Divider(),
                _buildOrderStatusItem(
                  'Đã giao hàng',
                  stats['deliveredOrders'] ?? 0,
                  Colors.green,
                ),
                const Divider(),
                _buildOrderStatusItem(
                  'Đã hủy',
                  stats['cancelledOrders'] ?? 0,
                  Colors.red,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Doanh số',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSalesItem(
                  'Hôm nay',
                  stats['todayRevenue'] ?? 0,
                  stats['todayOrders'] ?? 0,
                ),
                const Divider(),
                _buildSalesItem(
                  'Tuần này',
                  stats['weekRevenue'] ?? 0,
                  stats['weekOrders'] ?? 0,
                ),
                const Divider(),
                _buildSalesItem(
                  'Tháng này',
                  stats['monthRevenue'] ?? 0,
                  stats['monthOrders'] ?? 0,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sản phẩm',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProductStatusItem(
                  'Còn hàng',
                  stats['inStockProducts'] ?? 0,
                  Colors.green,
                ),
                const Divider(),
                _buildProductStatusItem(
                  'Sắp hết hàng',
                  stats['lowStockProducts'] ?? 0,
                  Colors.orange,
                ),
                const Divider(),
                _buildProductStatusItem(
                  'Hết hàng',
                  stats['outOfStockProducts'] ?? 0,
                  Colors.red,
                ),
                const Divider(),
                _buildProductStatusItem(
                  'Đang giảm giá',
                  stats['onSaleProducts'] ?? 0,
                  Colors.blue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusItem(String status, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(status),
            ],
          ),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesItem(String period, double revenue, int orders) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(period)),
          Expanded(
            flex: 3,
            child: Text(
              '$revenue ₫',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$orders đơn',
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductStatusItem(String status, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(status),
            ],
          ),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
