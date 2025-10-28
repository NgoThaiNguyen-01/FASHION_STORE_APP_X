import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';

class CheckoutScreen extends StatefulWidget {
  final int userId;
  final List<Map<String, dynamic>> selectedItems;
  const CheckoutScreen({super.key, required this.userId, required this.selectedItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addrCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  String payment = 'cod'; // 'cod' | 'bank'

  String money(num v) => NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(v);
  double get total => widget.selectedItems.fold(0, (s, it) => s + (it['price'] as double) * (it['quantity'] as int));

  Future<void> _placeOrder() async {
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final addr = addrCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || addr.isEmpty) {
      _toast('Vui lòng nhập đầy đủ Họ tên, SĐT và Địa chỉ'); return;
    }

    final res = await DBHelper.createOrder(
      userId: widget.userId,
      customerName: name,
      customerPhone: phone,
      shippingAddress: addr,
      paymentMethod: payment,
      note: noteCtrl.text.trim(),
      items: widget.selectedItems,
    );

    if (!mounted) return;
    if (res['ok'] == true) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Đặt hàng thành công'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mã đơn: ${res['orderCode']}'),
              const SizedBox(height: 6),
              Text('Tổng tiền: ${money(res['finalAmount'] as num)}'),
              const SizedBox(height: 12),
              if (payment == 'bank')
                const Text(
                  'Vui lòng chuyển khoản theo hướng dẫn của shop. Đơn sẽ được xử lý sau khi xác nhận thanh toán.',
                  style: TextStyle(color: Colors.grey),
                )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
          ],
        ),
      ).then((_) => Navigator.pop(context)); // quay về giỏ / trang trước
    } else {
      _toast(res['error']?.toString() ?? 'Có lỗi xảy ra', ok: false);
    }
  }

  void _toast(String msg, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ok ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thông tin KH
          const Text('Thông tin khách hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Họ và tên *')),
          const SizedBox(height: 8),
          TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Số điện thoại *')),
          const SizedBox(height: 8),
          TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Địa chỉ nhận hàng *')),
          const SizedBox(height: 8),
          TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Ghi chú (không bắt buộc)')),

          const SizedBox(height: 16),
          const Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          RadioListTile(
            value: 'cod',
            groupValue: payment,
            onChanged: (v) => setState(() => payment = v.toString()),
            title: const Text('Thanh toán tiền mặt (COD)'),
          ),
          RadioListTile(
            value: 'bank',
            groupValue: payment,
            onChanged: (v) => setState(() => payment = v.toString()),
            title: const Text('Chuyển khoản ngân hàng'),
          ),

          const SizedBox(height: 16),
          const Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...widget.selectedItems.map((it) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(it['name']),
              subtitle: Text('SL: ${it['quantity']}${(it['size'] ?? '') != '' ? ' • Size: ${it['size']}' : ''}${(it['color'] ?? '') != '' ? ' • Màu: ${it['color']}' : ''}'),
              trailing: Text(money((it['price'] as double) * (it['quantity'] as int)), style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          }),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng cộng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(money(total), style: const TextStyle(fontSize: 18, color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _placeOrder,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
              child: const Text('Đặt hàng'),
            ),
          )
        ],
      ),
    );
  }
}
