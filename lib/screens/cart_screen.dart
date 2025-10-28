import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import 'shipping_address_screen.dart'; // 👈 nhớ import

class CartScreen extends StatefulWidget {
  final int userId;
  const CartScreen({super.key, required this.userId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  final Set<int> _selectedCartIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _vnd(num v) => NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  ).format(v);

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await DBHelper.getCartItems(widget.userId);
    if (!mounted) return;
    setState(() {
      _items = list;
      _selectedCartIds.removeWhere((id) => !_items.any((e) => e['id'] == id));
      _loading = false;
    });
  }

  num get _selectedTotal {
    num t = 0;
    for (final it in _items) {
      if (_selectedCartIds.contains(it['id'])) {
        final price = (it['price'] as num?)?.toDouble() ?? 0;
        final qty = (it['quantity'] as num?)?.toInt() ?? 0;
        t += price * qty;
      }
    }
    return t;
  }

  bool get _isAllChecked =>
      _items.isNotEmpty &&
          _items.every((e) => _selectedCartIds.contains(e['id']));

  void _toggleAll(bool value) {
    setState(() {
      if (value) {
        _selectedCartIds.addAll(_items.map((e) => e['id'] as int));
      } else {
        _selectedCartIds.clear();
      }
    });
  }

  Future<void> _inc(Map<String, dynamic> it) async {
    final id = (it['id'] as num).toInt();
    final qty = (it['quantity'] as num?)?.toInt() ?? 1;
    await DBHelper.updateCartItemQuantity(id, qty + 1);
    await _load();
  }

  Future<void> _dec(Map<String, dynamic> it) async {
    final id = (it['id'] as num).toInt();
    final qty = (it['quantity'] as num?)?.toInt() ?? 1;
    await DBHelper.updateCartItemQuantity(id, qty - 1);
    await _load();
  }

  Future<void> _remove(Map<String, dynamic> it) async {
    final id = (it['id'] as num).toInt();
    await DBHelper.removeFromCart(id);
    await _load();
    _snack('Đã xoá khỏi giỏ hàng', ok: false);
  }

  void _snack(String m, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: ok ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Widget _imageOf(Map<String, dynamic> p,
      {double w = 64, double h = 64, BorderRadius? radius}) {
    final imgs = jsonDecode(p['images'] ?? '[]') as List;
    final path = imgs.isNotEmpty
        ? imgs.first as String
        : 'assets/images/anh_macdinh_sanpham_chuachonanh.png';
    final img = path.startsWith('/')
        ? Image.file(File(path), width: w, height: h, fit: BoxFit.cover)
        : Image.asset(path, width: w, height: h, fit: BoxFit.cover);
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.circular(8),
      child: img,
    );
  }

  // ====================================================
  // 🔹 MUA NGAY (Tự động điền thông tin người dùng + địa chỉ)
  // ====================================================
  Future<void> _checkout() async {
    final selected = _items.where((e) => _selectedCartIds.contains(e['id']));
    if (selected.isEmpty) {
      _snack('Bạn chưa chọn sản phẩm để mua', ok: false);
      return;
    }

    // 🔸 Lấy thông tin người dùng và địa chỉ mặc định
    final user = await DBHelper.getUserById(widget.userId);
    final addresses = await DBHelper.getAddressesByUser(widget.userId);
    Map<String, dynamic>? selectedAddr = addresses.firstWhere(
          (e) => (e['isDefault'] ?? 0) == 1,
      orElse: () => addresses.isNotEmpty ? addresses.first : {},
    );

    final nameCtrl = TextEditingController(text: user?['fullName'] ?? '');
    final phoneCtrl = TextEditingController(text: user?['phone'] ?? '');
    final addrCtrl = TextEditingController(
        text: selectedAddr?['fullAddress'] ?? (user?['address'] ?? ''));
    final noteCtrl = TextEditingController();
    String payment = 'cod';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setLocal) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin thanh toán',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // ✅ Tóm tắt số lượng + tổng tiền
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Đã chọn: ${selected.length} sản phẩm',
                          style: const TextStyle(color: Colors.grey)),
                      Text(_vnd(_selectedTotal),
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ✅ Họ tên
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Họ và tên *',
                        prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 8),

                  // ✅ Số điện thoại
                  TextField(
                    keyboardType: TextInputType.phone,
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Số điện thoại *',
                        prefixIcon: Icon(Icons.phone_outlined)),
                  ),
                  const SizedBox(height: 8),

                  // ✅ Địa chỉ giao hàng (có nút chọn)
                  TextField(
                    controller: addrCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Địa chỉ giao hàng *',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.map_outlined, color: Colors.orange),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShippingAddressScreen(userId: widget.userId),
                            ),
                          );

                          if (!mounted) return;

                          // ✅ Cập nhật tức thì nếu chọn địa chỉ mới
                          if (result != null && result is Map<String, dynamic>) {
                            setLocal(() {
                              selectedAddr = result;
                              addrCtrl.text = result['fullAddress'] ??
                                  '${result['label'] ?? ''} - ${result['city'] ?? ''}';
                            });
                            return;
                          }

                          // ✅ Nếu không trả về (người dùng chỉ thay đổi mặc định)
                          final addresses = await DBHelper.getAddressesByUser(widget.userId);
                          final defaultAddr = addresses.firstWhere(
                                (e) => (e['isDefault'] ?? 0) == 1,
                            orElse: () => addresses.isNotEmpty ? addresses.first : {},
                          );
                          setLocal(() {
                            selectedAddr = defaultAddr;
                            addrCtrl.text = defaultAddr['fullAddress'] ??
                                '${defaultAddr['label'] ?? ''} - ${defaultAddr['city'] ?? ''}';
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ✅ Ghi chú
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Ghi chú thêm (không bắt buộc)',
                        prefixIcon: Icon(Icons.note_alt_outlined)),
                  ),
                  const SizedBox(height: 12),

                  // ✅ Phương thức thanh toán
                  const Text('Phương thức thanh toán',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'cod',
                        groupValue: payment,
                        onChanged: (v) => setLocal(() => payment = v!),
                      ),
                      const Text('Tiền mặt (COD)'),
                      const SizedBox(width: 16),
                      Radio<String>(
                        value: 'bank',
                        groupValue: payment,
                        onChanged: (v) => setLocal(() => payment = v!),
                      ),
                      const Text('Chuyển khoản'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ✅ Nút xác nhận đặt hàng
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_bag),
                      label: const Text('Xác nhận đặt hàng'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            phoneCtrl.text.trim().isEmpty ||
                            addrCtrl.text.trim().isEmpty) {
                          _snack('Vui lòng nhập đủ thông tin bắt buộc',
                              ok: false);
                          return;
                        }

                        // Tạo danh sách item
                        final orderItems = <Map<String, dynamic>>[];
                        for (final it in selected) {
                          orderItems.add({
                            'productId': (it['productId'] as num).toInt(),
                            'name': it['name'].toString(),
                            'price': (it['price'] as num?)?.toDouble() ?? 0,
                            'quantity':
                            (it['quantity'] as num?)?.toInt() ?? 1,
                            'size': it['size'],
                            'color': it['color'],
                            'discount':
                            (it['discount'] as num?)?.toInt() ?? 0,
                          });
                        }

                        final res = await DBHelper.createOrder(
                          userId: widget.userId,
                          customerName: nameCtrl.text.trim(),
                          customerPhone: phoneCtrl.text.trim(),
                          shippingAddress: addrCtrl.text.trim(),
                          paymentMethod: payment,
                          note: noteCtrl.text.trim(),
                          items: orderItems,
                        );

                        if (res['ok'] == true) {
                          for (final it in selected) {
                            await DBHelper.removeFromCart(
                                (it['id'] as num).toInt());
                          }
                          if (!mounted) return;
                          Navigator.pop(context);
                          await _load();
                          _selectedCartIds.clear();
                          _snack('Đặt hàng thành công: ${res['orderCode']}');
                        } else {
                          _snack('Tạo đơn thất bại: ${res['error']}', ok: false);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ====================================================
  // UI CHÍNH
  // ====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () => _toggleAll(!_isAllChecked),
              child: Text(_isAllChecked ? 'Bỏ chọn' : 'Chọn tất cả'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? _empty()
          : Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final it = _items[i];
                final checked =
                _selectedCartIds.contains(it['id'] as int);
                final price =
                    (it['price'] as num?)?.toDouble() ?? 0.0;
                final qty =
                    (it['quantity'] as num?)?.toInt() ?? 1;
                final name = it['name'] ?? '';
                final size = it['size'] ?? '';
                final color = it['color'] ?? '';

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side:
                      BorderSide(color: Colors.grey[200]!)),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: checked,
                          onChanged: (_) {
                            setState(() {
                              if (checked) {
                                _selectedCartIds
                                    .remove(it['id'] as int);
                              } else {
                                _selectedCartIds
                                    .add(it['id'] as int);
                              }
                            });
                          },
                        ),
                        _imageOf(it, w: 64, h: 64),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight:
                                      FontWeight.w600)),
                              if (size.isNotEmpty ||
                                  color.isNotEmpty)
                                Padding(
                                  padding:
                                  const EdgeInsets.only(top: 4),
                                  child: Text(
                                    [
                                      if (size.isNotEmpty)
                                        'Size: $size',
                                      if (color.isNotEmpty)
                                        'Màu: $color'
                                    ].join('  ·  '),
                                    style: const TextStyle(
                                        color: Colors.grey),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_vnd(price),
                                      style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight:
                                          FontWeight.bold)),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle),
                                        onPressed: () => _dec(it),
                                      ),
                                      Text('$qty',
                                          style: const TextStyle(
                                              fontWeight:
                                              FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle),
                                        onPressed: () => _inc(it),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _remove(it),
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _empty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shopping_cart_outlined,
            size: 88, color: Colors.grey[400]),
        const SizedBox(height: 8),
        const Text('Giỏ hàng của bạn đang trống',
            style:
            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Hãy thêm vài món yêu thích nhé!',
            style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 16),
      ],
    ),
  );

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng thanh toán',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(_vnd(_selectedTotal),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
          ),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _checkout,
              child: const Text('Mua ngay'),
            ),
          ),
        ],
      ),
    );
  }
}
