import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
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

  Future<void> _addAllToCart() async {
    if (_items.isEmpty) return;
    for (final p in _items) {
      final stock = (p['quantity'] ?? 0) as int;
      if (stock > 0) {
        await DBHelper.addToCart(
          userId: widget.userId,
          productId: p['id'] as int,
          quantity: 1,
        );
      }
    }
    _showSnack('Đã thêm tất cả sản phẩm còn hàng vào giỏ');
  }

  Widget _imageOf(Map<String, dynamic> p, {double w = 56, double h = 56}) {
    final imgs = jsonDecode(p['images'] ?? '[]') as List;
    final path = imgs.isNotEmpty ? imgs.first as String : 'assets/images/anh_macdinh_sanpham_chuachonanh.png';
    final widgetImage = path.startsWith('/')
        ? Image.file(File(path), width: w, height: h, fit: BoxFit.cover)
        : Image.asset(path, width: w, height: h, fit: BoxFit.cover);
    return ClipRRect(borderRadius: BorderRadius.circular(8), child: widgetImage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu thích', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: _addAllToCart,
              child: const Text('Thêm tất cả vào giỏ'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text('Sản phẩm yêu thích', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Chưa có sản phẩm yêu thích', style: TextStyle(color: Colors.grey[600])),
        ],
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) {
          final p = _items[i];
          final name = (p['name'] ?? '').toString();
          final price = (p['price'] ?? 0).toDouble();
          final priceText = '${price.toStringAsFixed(0)}₫';

          return Dismissible(
            key: ValueKey('fav-${p['id']}'),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.redAccent,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              await _removeOne(p['id'] as int);
              return false; // tự reload nên không cần xoá item tại chỗ
            },
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
              child: ListTile(
                leading: _imageOf(p),
                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(priceText, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                onTap: widget.onOpenProduct == null ? null : () => widget.onOpenProduct!(p),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      tooltip: 'Thêm vào giỏ',
                      onPressed: () => _addOneToCart(p),
                      icon: const Icon(Icons.add_shopping_cart),
                      color: Colors.orange,
                    ),
                    IconButton(
                      tooltip: 'Xóa',
                      onPressed: () => _removeOne(p['id'] as int),
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
    );
  }
}
