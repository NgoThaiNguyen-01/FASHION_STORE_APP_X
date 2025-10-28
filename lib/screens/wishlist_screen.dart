import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';

class WishlistScreen extends StatefulWidget {
  final int userId;
  final void Function(Map<String, dynamic> product)? onOpenProduct;

  const WishlistScreen({
    super.key,
    required this.userId,
    this.onOpenProduct,
  });

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  /// Tập các productId được chọn để mua
  final Set<int> _selected = {};

  bool get _allSelected => _items.isNotEmpty && _selected.length == _items.length;

  double get _selectedTotal {
    double sum = 0;
    for (final p in _items) {
      final id = p['id'] as int;
      if (_selected.contains(id)) {
        final stock = (p['quantity'] ?? 0) as int;
        if (stock > 0) {
          sum += (p['price'] ?? 0).toDouble(); // giá sau giảm
        }
      }
    }
    return sum;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _selected.clear();
    });
    final list = await DBHelper.getUserFavorites(widget.userId);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  void _showSnack(String msg, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _removeOne(int productId) async {
    await DBHelper.toggleFavorite(widget.userId, productId);
    await _load();
    _showSnack('Đã xóa khỏi yêu thích', ok: false);
  }

  Future<void> _addOneToCart(Map<String, dynamic> p) async {
    final stock = (p['quantity'] ?? 0) as int;
    if (stock <= 0) {
      _showSnack('Sản phẩm đã hết hàng', ok: false);
      return;
    }
    await DBHelper.addToCart(
      userId: widget.userId,
      productId: p['id'] as int,
      quantity: 1,
      size: null,
      color: null,
    );
    _showSnack('Đã thêm vào giỏ');
  }

  Future<void> _addSelectedToCart() async {
    if (_selected.isEmpty) {
      _showSnack('Chưa chọn sản phẩm nào', ok: false);
      return;
    }
    int added = 0, skipped = 0;
    for (final p in _items) {
      final id = p['id'] as int;
      if (!_selected.contains(id)) continue;
      final stock = (p['quantity'] ?? 0) as int;
      if (stock > 0) {
        await DBHelper.addToCart(
          userId: widget.userId,
          productId: id,
          quantity: 1,
        );
        added++;
      } else {
        skipped++;
      }
    }
    if (added > 0) _showSnack('Đã thêm $added sản phẩm vào giỏ');
    if (skipped > 0) _showSnack('$skipped sản phẩm hết hàng', ok: false);
  }

  Future<void> _buySelectedNow() async {
    // Ở phiên bản này: thêm vào giỏ rồi nhắc người dùng vào giỏ để thanh toán.
    await _addSelectedToCart();
    // TODO: nếu bạn đã có màn giỏ hàng thực, có thể điều hướng sang tab giỏ:
    // Navigator.of(context).pushNamed('/cart');
  }

  void _toggleSelect(int productId, bool value) {
    setState(() {
      if (value) {
        _selected.add(productId);
      } else {
        _selected.remove(productId);
      }
    });
  }

  void _toggleSelectAll(bool value) {
    setState(() {
      _selected.clear();
      if (value) {
        _selected.addAll(_items.map((e) => e['id'] as int));
      }
    });
  }

  Widget _imageOf(Map<String, dynamic> p, {double w = 56, double h = 56}) {
    final imgs = jsonDecode(p['images'] ?? '[]') as List;
    final path = imgs.isNotEmpty
        ? imgs.first as String
        : 'assets/images/anh_macdinh_sanpham_chuachonanh.png';
    final widgetImage = path.startsWith('/')
        ? Image.file(File(path), width: w, height: h, fit: BoxFit.cover)
        : Image.asset(path, width: w, height: h, fit: BoxFit.cover);
    return ClipRRect(borderRadius: BorderRadius.circular(8), child: widgetImage);
  }

  String _format(double v) => currency.format(v);

  @override
  Widget build(BuildContext context) {
    final hasItems = _items.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu thích', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        actions: [
          if (hasItems)
            Row(
              children: [
                const Text('Chọn tất cả'),
                Checkbox(
                  value: _allSelected,
                  onChanged: (v) => _toggleSelectAll(v ?? false),
                ),
                const SizedBox(width: 8),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !hasItems
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text('Sản phẩm yêu thích',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Chưa có sản phẩm yêu thích',
              style: TextStyle(color: Colors.grey[600])),
        ],
      )
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110), // chừa chỗ cho bottom bar
        itemBuilder: (_, i) {
          final p = _items[i];
          final id = p['id'] as int;
          final name = (p['name'] ?? '').toString();
          final price = (p['price'] ?? 0).toDouble(); // sau giảm
          final stock = (p['quantity'] ?? 0) as int;
          final selected = _selected.contains(id);

          return Dismissible(
            key: ValueKey('fav-$id'),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.redAccent,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              await _removeOne(id);
              return false; // tự reload
            },
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: ListTile(
                onTap: widget.onOpenProduct == null
                    ? null
                    : () => widget.onOpenProduct!(p),
                leading: _imageOf(p),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Checkbox(
                      value: selected,
                      onChanged: (v) => _toggleSelect(id, v ?? false),
                    ),
                  ],
                ),
                subtitle: Row(
                  children: [
                    Text(
                      _format(price),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent),
                    ),
                    const SizedBox(width: 10),
                    if (stock <= 0)
                      const Text('Hết hàng',
                          style: TextStyle(color: Colors.red)),
                  ],
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      tooltip: 'Thêm 1 vào giỏ',
                      onPressed: () => _addOneToCart(p),
                      icon: const Icon(Icons.add_shopping_cart),
                      color: Colors.orange,
                    ),
                    IconButton(
                      tooltip: 'Xóa',
                      onPressed: () => _removeOne(id),
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.redAccent,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: _items.length,
      ),
      bottomNavigationBar: hasItems
          ? Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selected.isEmpty
                          ? 'Chưa chọn sản phẩm'
                          : 'Đã chọn: ${_selected.length} • Tổng: ${_format(_selectedTotal)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  TextButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => _toggleSelectAll(false),
                    child: const Text('Bỏ chọn'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed:
                      _selected.isEmpty ? null : _addSelectedToCart,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Thêm vào giỏ (đã chọn)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed:
                      _selected.isEmpty ? null : _buySelectedNow,
                      icon: const Icon(Icons.flash_on),
                      label: const Text('Mua ngay (đã chọn)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }
}
