import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  String _vnd(num v) =>
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
          .format(v);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await DBHelper.getOrderDetail(widget.orderId);
    if (!mounted) return;
    setState(() {
      _order = data?['order'];
      _items = (data?['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _loading = false;
    });
  }

  Widget _image(String? jsonImages, {double w = 60, double h = 60}) {
    try {
      final imgs = jsonDecode(jsonImages ?? '[]') as List;
      if (imgs.isNotEmpty) {
        final path = imgs.first.toString();
        if (path.startsWith('/')) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(path), width: w, height: h, fit: BoxFit.cover),
          );
        } else {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(path, width: w, height: h, fit: BoxFit.cover),
          );
        }
      }
    } catch (_) {}
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  Future<void> _cancel() async {
    await DBHelper.cancelOrder(widget.orderId);
    if (!mounted) return;
    _snack('Đã hủy đơn hàng');
    await _load();
  }

  Future<void> _delete() async {
    await DBHelper.deleteOrder(widget.orderId);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _snack(String msg, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? Colors.green : Colors.redAccent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy đơn hàng')),
      );
    }

    final o = _order!;
    final status = o['status'] ?? 'pending';
    final createdAt = o['createdAt'] ?? '';
    final total = (o['totalAmount'] as num?)?.toDouble() ?? 0;
    final discount = (o['discountAmount'] as num?)?.toDouble() ?? 0;
    final finalAmount = (o['finalAmount'] as num?)?.toDouble() ?? 0;
    final pay = o['paymentMethod'] ?? '';
    final note = o['note'] ?? '';
    final name = o['customerName'] ?? '';
    final addr = o['shippingAddress'] ?? '';
    final phone = o['customerPhone'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Thông tin đơn hàng
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Đơn ${o['orderCode'] ?? ''}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      _statusChip(status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Ngày tạo: $createdAt',
                      style: const TextStyle(color: Colors.grey)),
                  Text('Thanh toán: ${pay.toUpperCase()}',
                      style: const TextStyle(color: Colors.grey)),
                  const Divider(height: 14, thickness: 1),
                  Text('Tạm tính: ${_vnd(total)}'),
                  if (discount > 0)
                    Text('Giảm giá: -${_vnd(discount)}',
                        style: const TextStyle(color: Colors.red)),
                  Text('Thành tiền: ${_vnd(finalAmount)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red)),
                  if (note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Ghi chú: $note',
                          style: const TextStyle(color: Colors.black87)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Sản phẩm
            const Text('Sản phẩm trong đơn',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ..._items.map((it) {
              final price = (it['productPrice'] as num?)?.toDouble() ?? 0;
              final qty = (it['quantity'] as num?)?.toInt() ?? 1;
              final totalPrice = price * qty;
              final size = it['size'] ?? '';
              final color = it['color'] ?? '';
              final imgs = it['productImages'] as String?;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _image(imgs),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it['productName'] ?? '',
                              style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('SL: $qty | Size: $size | Màu: $color',
                              style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(_vnd(totalPrice),
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 16),

            // --- Địa chỉ giao hàng
            const Text('Địa chỉ giao hàng',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$name\n$addr\nSDT: $phone',
                  style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 20),

            // --- Nút hành động
            if (status == 'pending' || status == 'processing') ...[
              _button('Hủy đơn hàng', Colors.red, _cancel),
              const SizedBox(height: 10),
            ],
            _button('Xóa đơn hàng', Colors.grey, _delete),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case 'completed':
        color = Colors.green;
        text = 'Hoàn tất';
        break;
      case 'cancelled':
        color = Colors.grey;
        text = 'Đã hủy';
        break;
      case 'processing':
      case 'pending':
      default:
        color = Colors.orange;
        text = 'Đang xử lý';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
      BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _button(String text, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(
          text.contains('Xóa') ? Icons.delete_outline : Icons.cancel,
          color: Colors.white,
        ),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onTap,
      ),
    );
  }
}
