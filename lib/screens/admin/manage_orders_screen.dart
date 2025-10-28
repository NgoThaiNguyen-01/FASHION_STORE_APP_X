import 'package:flutter/material.dart';
import '../../database/db_helper.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);
    try {
      final list = await DBHelper.getAllOrders();
      setState(() => orders = list);
    } catch (e) {
      _showError('Lỗi tải danh sách đơn hàng: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      await DBHelper.updateOrderStatus(orderId, newStatus);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật trạng thái đơn hàng')),
        );
      }
    } catch (e) {
      _showError('Lỗi cập nhật trạng thái: $e');
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'shipped':
        return 'Đang giao';
      case 'delivered':
        return 'Hoàn thành';
      case 'cancelled':
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orders.isEmpty) {
      return const Center(child: Text('Chưa có đơn hàng nào'));
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
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
                Text('Tổng tiền: ${order['totalAmount']}₫'),
                Text('Ngày đặt: ${order['orderDate']}'),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cập nhật trạng thái:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Chờ xử lý'),
                          onPressed: () =>
                              _updateOrderStatus(order['id'], 'pending'),
                          backgroundColor: status == 'pending'
                              ? Colors.grey
                              : null,
                        ),
                        ActionChip(
                          label: const Text('Đang xử lý'),
                          onPressed: () =>
                              _updateOrderStatus(order['id'], 'processing'),
                          backgroundColor: status == 'processing'
                              ? Colors.blue
                              : null,
                        ),
                        ActionChip(
                          label: const Text('Đang giao'),
                          onPressed: () =>
                              _updateOrderStatus(order['id'], 'shipped'),
                          backgroundColor: status == 'shipped'
                              ? Colors.orange
                              : null,
                        ),
                        ActionChip(
                          label: const Text('Hoàn thành'),
                          onPressed: () =>
                              _updateOrderStatus(order['id'], 'delivered'),
                          backgroundColor: status == 'delivered'
                              ? Colors.green
                              : null,
                        ),
                        ActionChip(
                          label: const Text('Hủy đơn'),
                          onPressed: () =>
                              _updateOrderStatus(order['id'], 'cancelled'),
                          backgroundColor: status == 'cancelled'
                              ? Colors.red
                              : null,
                        ),
                      ],
                    ),
                    const Divider(),
                    const Text(
                      'Chi tiết đơn hàng:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // TODO: Hiển thị danh sách sản phẩm trong đơn hàng
                    Text('Địa chỉ: ${order['address']}'),
                    Text('Số điện thoại: ${order['phone']}'),
                    Text('Ghi chú: ${order['note'] ?? 'Không có'}'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
