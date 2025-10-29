import 'package:flutter/material.dart';
import '../../database/db_helper.dart';

class ManageOrdersScreen extends StatefulWidget {
  final VoidCallback? onRefresh;
  const ManageOrdersScreen({super.key, this.onRefresh});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  List<Map<String, dynamic>> orders = [];
  Map<int, List<Map<String, dynamic>>> orderItems = {};
  bool isLoading = true;
  String? filterStatus;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);
    try {
      final list = filterStatus != null
          ? await DBHelper.getOrdersByStatus(filterStatus!)
          : await DBHelper.getAllOrders();
      setState(() {
        orders = list;
        orderItems.clear();
      });
    } catch (e) {
      _showError('Lỗi tải danh sách đơn hàng: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      await DBHelper.updateOrderStatus(orderId, newStatus);
      if (newStatus == 'delivered') await DBHelper.completeOrder(orderId);
      await _loadOrders();
      widget.onRefresh?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            newStatus == 'delivered'
                ? 'Đơn hàng đã hoàn tất và cập nhật kho'
                : 'Đã cập nhật trạng thái đơn hàng',
          ),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      _showError('Lỗi cập nhật trạng thái: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _getStatusText(String status) {
    final s = status.toLowerCase().trim();
    switch (s) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'shipped':
        return 'Đang giao';
      case 'delivered':
      case 'complete':
      case 'completed':
        return 'Hoàn tất';
      case 'cancelled':
      case 'canceled':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }


  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(filterStatus != null
            ? 'Đơn hàng ${_getStatusText(filterStatus!).toLowerCase()}'
            : 'Tất cả đơn hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(child: Text('Chưa có đơn hàng nào'))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, i) {
          final order = orders[i];
          final status = order['status'] as String;
          return Card(
            margin: const EdgeInsets.all(8),
            child: ExpansionTile(
              title: Row(
                children: [
                  Text('#${order['id']}'),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      _getStatusText(status),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: _getStatusColor(status),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Khách hàng: ${order['customerName']}'),
                  Text(
                      'Tổng tiền: ${(order['totalAmount'] as num).toStringAsFixed(0)}₫'),
                  Text(
                      'Ngày đặt: ${order['createdAt']?.toString().substring(0, 16) ?? 'N/A'}'),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Hoàn tất'),
                        onPressed: () => _updateOrderStatus(
                            order['id'], 'delivered'),
                        backgroundColor: status == 'delivered'
                            ? Colors.green
                            : null,
                      ),
                      ActionChip(
                        label: const Text('Hủy đơn'),
                        onPressed: () => _updateOrderStatus(
                            order['id'], 'cancelled'),
                        backgroundColor: status == 'cancelled'
                            ? Colors.red
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Tất cả đơn hàng'),
              onTap: () {
                this.setState(() => filterStatus = null);
                Navigator.pop(context);
                _loadOrders();
              },
            ),
            ...['pending', 'processing', 'shipped', 'delivered', 'cancelled']
                .map((s) => ListTile(
              title: Text(_getStatusText(s)),
              onTap: () {
                this.setState(() => filterStatus = s);
                Navigator.pop(context);
                _loadOrders();
              },
            )),
          ],
        ),
      ),
    );
  }
}
