import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  final int userId;
  const OrdersScreen({super.key, required this.userId});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;

  Map<String, List<Map<String, dynamic>>> orders = {
    'pending': [],
    'completed': [],
    'cancelled': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final res = await DBHelper.getOrdersByUserSummary(widget.userId);

    orders = {
      'pending': res
          .where((e) => e['status'] == 'pending' || e['status'] == 'processing')
          .toList(),
      'completed': res
          .where((e) => e['status'] == 'completed' || e['status'] == 'delivered')
          .toList(),
      'cancelled': res.where((e) => e['status'] == 'cancelled').toList(),
    };
    setState(() => _loading = false);
  }

  String _vnd(num v) =>
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
          .format(v);

  Color _statusColor(String s) {
    if (s == 'completed' || s == 'delivered') return Colors.green;
    if (s == 'cancelled') return Colors.red;
    return Colors.orange;
  }

  String _statusText(String s) {
    switch (s) {
      case 'completed':
      case 'delivered':
        return 'Hoàn tất';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Đang xử lý';
    }
  }

  List<String> _parseImageList(dynamic raw) {
    try {
      if (raw == null) return [];
      final decoded = raw is String ? jsonDecode(raw) : raw;
      return List<String>.from(decoded.map((e) => e.toString()));
    } catch (_) {
      return [];
    }
  }

  Widget _imageOf(String? imageJson, {double w = 55, double h = 55}) {
    if (imageJson == null || imageJson.isEmpty) {
      return Image.asset('assets/images/anh_macdinh_sanpham_chuachonanh.png',
          width: w, height: h, fit: BoxFit.cover);
    }
    final imgs = _parseImageList(imageJson);
    final path = imgs.isNotEmpty
        ? imgs.first
        : 'assets/images/anh_macdinh_sanpham_chuachonanh.png';

    if (path.startsWith('assets/')) {
      return Image.asset(path, width: w, height: h, fit: BoxFit.cover);
    } else if (path.startsWith('http')) {
      return Image.network(path, width: w, height: h, fit: BoxFit.cover);
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, width: w, height: h, fit: BoxFit.cover);
      } else {
        return Image.asset('assets/images/anh_macdinh_sanpham_chuachonanh.png',
            width: w, height: h, fit: BoxFit.cover);
      }
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> o) {
    final finalAmount = (o['finalAmount'] as num?)?.toDouble() ?? 0;
    final itemsCount = (o['itemsCount'] as num?)?.toInt() ?? 0;
    final pay = (o['paymentMethod'] ?? 'Chưa rõ').toString();
    final status = (o['status'] ?? 'pending').toString();
    final firstImage = o['firstImage']?.toString() ?? '';

    return Card(
      color: Colors.pink.shade50,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _imageOf(firstImage, w: 55, h: 55),
        ),
        title: Text(
          'Đơn ${o['orderCode'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$itemsCount sản phẩm • ${_vnd(finalAmount)}',
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('Thanh toán: ${pay.toUpperCase()}',
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(
                      orderId: o['id'],      // ✅ orderId
                      userId: widget.userId, // ✅ userId truyền đúng
                    ),
                  ),
                );
                _loadOrders(); // refresh sau khi trở lại
              },
              child: const Text(
                'Xem chi tiết',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: _statusColor(status),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _statusText(status),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String key) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.pink));
    }
    final list = orders[key]!;
    if (list.isEmpty) {
      return const Center(child: Text('Chưa có đơn hàng'));
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        itemCount: list.length,
        itemBuilder: (_, i) => _buildOrderCard(list[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đơn hàng của tôi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(text: 'Đang xử lý'),
            Tab(text: 'Hoàn tất'),
            Tab(text: 'Đã hủy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab('pending'),
          _buildTab('completed'),
          _buildTab('cancelled'),
        ],
      ),
    );
  }
}
