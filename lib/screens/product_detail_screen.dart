import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final int userId;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.userId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  int _quantity = 1;
  String? _selectedSize;
  String? _selectedColor;

  late List<String> _images;
  late List<String> _sizes;
  late List<String> _colors;

  bool _isFavorite = false;
  double _rating = 0.0;
  int _reviewCount = 0;
  List<Map<String, dynamic>> _reviews = [];

  double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  List<String> _parseStringList(dynamic raw) {
    try {
      if (raw == null) return <String>[];
      final decoded = raw is String ? jsonDecode(raw) : raw;
      return List<String>.from(decoded.map((e) => e.toString()));
    } catch (_) {
      return <String>[];
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProductData();
    _loadReviews();
    _checkIfFavorite();
    DBHelper.incrementProductView(_asInt(widget.product['id']));
  }

  void _loadProductData() {
    _images = _parseStringList(widget.product['images']);
    _sizes = _parseStringList(widget.product['sizes']);
    _colors = _parseStringList(widget.product['colors']);

    _rating = _asDouble(widget.product['rating']);
    _reviewCount = _asInt(widget.product['reviewCount']);

    if (_sizes.isNotEmpty) _selectedSize = _sizes.first;
    if (_colors.isNotEmpty) _selectedColor = _colors.first;
  }

  Future<void> _loadReviews() async {
    final reviews =
    await DBHelper.getProductReviews(_asInt(widget.product['id']));
    if (!mounted) return;
    setState(() => _reviews = reviews);
  }

  Future<void> _checkIfFavorite() async {
    final ok = await DBHelper.isProductInFavorites(
      widget.userId,
      _asInt(widget.product['id']),
    );
    if (!mounted) return;
    setState(() => _isFavorite = ok);
  }

  Future<void> _toggleFavorite() async {
    final pid = _asInt(widget.product['id']);
    await DBHelper.toggleFavorite(widget.userId, pid);
    final nowFav = await DBHelper.isProductInFavorites(widget.userId, pid);
    if (!mounted) return;
    setState(() => _isFavorite = nowFav);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nowFav
            ? 'Đã thêm vào yêu thích'
            : 'Đã xóa khỏi yêu thích'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addToCart() {
    if (_sizes.isNotEmpty && _selectedSize == null) {
      _showMessage('Vui lòng chọn size');
      return;
    }
    if (_colors.isNotEmpty && _selectedColor == null) {
      _showMessage('Vui lòng chọn màu');
      return;
    }
    _showMessage('Đã thêm vào giỏ hàng');
  }

  void _buyNow() {
    _addToCart();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  String _formatPrice(double price) {
    final fmt =
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return fmt.format(price);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    // ---- SỬA LOGIC TÍNH GIÁ ----
    final double price = _asDouble(p['price']);       // thường là giá đã giảm
    final double oldPrice = _asDouble(p['oldPrice']); // giá gốc
    final int discount = _asInt(p['discount']);

    // base để tính giảm: nếu có oldPrice>0 thì base=oldPrice, ngược lại base=price
    final double base = oldPrice > 0 ? oldPrice : price;
    final double newPrice =
    discount > 0 ? base * (1 - discount / 100.0) : price;

    final int status = _asInt(p['status']);
    final int quantity = _asInt(p['quantity']);
    final int soldCount = _asInt(p['soldCount']);
    final int viewCount = _asInt(p['viewCount']);
    final String material = (p['material'] ?? 'Chưa cập nhật').toString();
    final String name = (p['name'] ?? '').toString();
    final String description = (p['description'] ?? '').toString();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildImageGallery(),
                    _buildProductInfo(
                      name,
                      newPrice,
                      oldPrice,
                      discount,
                      status,
                      quantity,
                      soldCount,
                      viewCount,
                    ),
                    if (_sizes.isNotEmpty || _colors.isNotEmpty)
                      _buildVariantSelectors(),
                    _buildProductDetails(material, description),
                    _buildReviewsSection(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    final imgs = _images.isEmpty
        ? <String>['assets/images/anh_macdinh_sanpham_chuachonanh.png']
        : _images;

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: imgs.length,
            onPageChanged: (i) => setState(() => _selectedImageIndex = i),
            itemBuilder: (context, index) {
              final path = imgs[index];
              final Widget img = path.startsWith('/')
                  ? Image.file(File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imageFallback())
                  : Image.asset(path,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imageFallback());
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: img,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(imgs.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                _selectedImageIndex == index ? Colors.blue : Colors.grey,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _imageFallback() => Container(
    color: Colors.grey[200],
    child: const Center(
      child: Icon(Icons.photo, size: 60, color: Colors.grey),
    ),
  );

  Widget _buildProductInfo(
      String name,
      double newPrice,
      double oldPrice,
      int discount,
      int status,
      int quantity,
      int soldCount,
      int viewCount,
      ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStarRating(_rating),
              const SizedBox(width: 8),
              Text('$_rating (${_reviewCount} đánh giá)',
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(_formatPrice(newPrice),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
              if (discount > 0 && oldPrice > 0) ...[
                const SizedBox(width: 8),
                Text(_formatPrice(oldPrice),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    )),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.red, borderRadius: BorderRadius.circular(4)),
                  child: Text('-$discount%',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusBadge(status),
              const SizedBox(width: 16),
              Text('Đã bán: $soldCount', style: const TextStyle(color: Colors.grey)),
              const SizedBox(width: 16),
              Text('Lượt xem: $viewCount', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          if (quantity <= 5 && status == 1) ...[
            const SizedBox(height: 8),
            Text('Chỉ còn $quantity sản phẩm',
                style: const TextStyle(color: Colors.orange)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(int status) {
    Color color;
    String text;
    switch (status) {
      case 0:
        color = Colors.red;
        text = 'Hết hàng';
        break;
      case 2:
        color = Colors.orange;
        text = 'Đang nhập';
        break;
      default:
        color = Colors.green;
        text = 'Còn hàng';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
      BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child:
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _buildVariantSelectors() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sizes.isNotEmpty) ...[
            const Text('Chọn size:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _sizes
                  .map((s) => ChoiceChip(
                label: Text(s),
                selected: _selectedSize == s,
                onSelected: (_) => setState(() => _selectedSize = s),
              ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (_colors.isNotEmpty) ...[
            const Text('Chọn màu:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colors
                  .map((c) => ChoiceChip(
                label: Text(c),
                selected: _selectedColor == c,
                onSelected: (_) => setState(() => _selectedColor = c),
              ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildProductDetails(String material, String description) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin sản phẩm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _detailRow('Chất liệu', material),
          const SizedBox(height: 12),
          const Text('Mô tả sản phẩm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$title: ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Đánh giá sản phẩm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_reviews.isEmpty)
            const Center(
              child:
              Text('Chưa có đánh giá nào', style: TextStyle(color: Colors.grey)),
            )
          else
            Column(
              children:
              _reviews.map((r) => _buildReviewItem(r)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final userName = (review['userName'] ?? 'Khách hàng').toString();
    final rating = _asInt(review['rating']).toDouble();
    final comment = (review['comment'] ?? '').toString();
    final createdAt = (review['createdAt'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundImage:
                  AssetImage('assets/images/anh_avata_macdinh.png'),
                ),
                const SizedBox(width: 8),
                Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                _buildStarRating(rating),
              ],
            ),
            const SizedBox(height: 8),
            if (comment.isNotEmpty) Text(comment),
            const SizedBox(height: 8),
            Text(_formatDate(createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  String _formatDate(String s) {
    try {
      final d = DateTime.parse(s);
      return DateFormat('dd/MM/yyyy').format(d);
    } catch (_) {
      return s;
    }
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
            (i) => Icon(Icons.star,
            size: 16, color: i < rating.floor() ? Colors.amber : Colors.grey[300]),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isOutOfStock = _asInt(widget.product['status']) == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (_quantity > 1) setState(() => _quantity--);
                  },
                ),
                Text('$_quantity',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => _quantity++),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (!isOutOfStock) ...[
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _addToCart,
                      child: const Text('Thêm giỏ'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _buyNow,
                      child: const Text('Mua ngay'),
                    ),
                  ),
                ] else
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: null,
                      child: const Text('Hết hàng'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
