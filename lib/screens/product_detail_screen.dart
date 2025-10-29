import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';
import 'shipping_address_screen.dart';

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
  // --- state sản phẩm ---
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

  // --- state user & địa chỉ mặc định ---
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _defaultAddress;

  // ---------- Helpers ép kiểu an toàn ----------
  double asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  int asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  List<String> parseStringList(dynamic raw) {
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
    _loadUserAndDefaultAddress();
    DBHelper.incrementProductView(asInt(widget.product['id']));
  }

  Future<void> _loadUserAndDefaultAddress() async {
    final u = await DBHelper.getUserById(widget.userId);
    final addrs = await DBHelper.getAddressesByUser(widget.userId);
    Map<String, dynamic>? def;
    if (addrs.isNotEmpty) {
      def = addrs.firstWhere(
            (e) => (e['isDefault'] as int? ?? 0) == 1,
        orElse: () => addrs.first,
      );
    }
    if (!mounted) return;
    setState(() {
      _user = u;
      _defaultAddress = def;
    });
  }

  void _loadProductData() {
    _images = parseStringList(widget.product['images']);
    _sizes = parseStringList(widget.product['sizes']);
    _colors = parseStringList(widget.product['colors']);

    _rating = asDouble(widget.product['rating']);
    _reviewCount = asInt(widget.product['reviewCount']);

    if (_sizes.isNotEmpty) _selectedSize = _sizes.first;
    if (_colors.isNotEmpty) _selectedColor = _colors.first;
  }

  Future<void> _loadReviews() async {
    final id = asInt(widget.product['id']);
    final reviews = await DBHelper.getProductReviews(id);
    if (!mounted) return;
    setState(() {
      _reviews = reviews;
      _recalcRatingFromReviews();
    });
  }

  void _recalcRatingFromReviews() {
    if (_reviews.isEmpty) {
      // giữ nguyên rating mặc định từ product khi chưa có review
      _reviewCount = 0;
      return;
    }
    final nums = _reviews
        .map((r) => asInt(r['rating']))
        .where((v) => v >= 1 && v <= 5)
        .map((v) => v.toDouble())
        .toList();
    if (nums.isEmpty) {
      _reviewCount = 0;
      return;
    }
    final sum = nums.fold<double>(0, (a, b) => a + b);
    _reviewCount = nums.length;
    _rating = double.parse((sum / nums.length).toStringAsFixed(1));
  }

  Future<void> _checkIfFavorite() async {
    final ok = await DBHelper.isProductInFavorites(
      widget.userId,
      widget.product['id'] as int,
    );
    if (!mounted) return;
    setState(() => _isFavorite = ok);
  }

  Future<void> _toggleFavorite() async {
    await DBHelper.toggleFavorite(widget.userId, widget.product['id'] as int);
    final nowFav = await DBHelper.isProductInFavorites(
      widget.userId,
      widget.product['id'] as int,
    );
    if (!mounted) return;
    setState(() => _isFavorite = nowFav);

    _snack(nowFav ? 'Đã thêm vào yêu thích' : 'Đã xóa khỏi yêu thích');
  }

  Future<void> _addToCart() async {
    if (_sizes.isNotEmpty && _selectedSize == null) {
      _snack('Vui lòng chọn size', ok: false);
      return;
    }
    if (_colors.isNotEmpty && _selectedColor == null) {
      _snack('Vui lòng chọn màu', ok: false);
      return;
    }
    final stock = asInt(widget.product['quantity']);
    if (stock <= 0 || asInt(widget.product['status']) == 0) {
      _snack('Sản phẩm đã hết hàng', ok: false);
      return;
    }
    if (_quantity > stock) {
      _snack('Số lượng vượt quá tồn kho ($stock)', ok: false);
      return;
    }

    await DBHelper.addToCart(
      userId: widget.userId,
      productId: widget.product['id'] as int,
      quantity: _quantity,
      size: _selectedSize,
      color: _selectedColor,
    );
    _snack('Đã thêm vào giỏ hàng');
  }

  Future<void> _buyNow() async {
    if (_sizes.isNotEmpty && _selectedSize == null) {
      _snack('Vui lòng chọn size', ok: false);
      return;
    }
    if (_colors.isNotEmpty && _selectedColor == null) {
      _snack('Vui lòng chọn màu', ok: false);
      return;
    }
    final stock = asInt(widget.product['quantity']);
    if (stock <= 0 || asInt(widget.product['status']) == 0) {
      _snack('Sản phẩm đã hết hàng', ok: false);
      return;
    }
    if (_quantity > stock) {
      _snack('Số lượng vượt quá tồn kho ($stock)', ok: false);
      return;
    }

    await _openCheckoutSheet();
  }

  void _snack(String m, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: ok ? Colors.green : Colors.redAccent),
    );
  }

  String _formatPrice(num price) =>
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
          .format(price);

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    final double currentPrice = asDouble(p['price']);
    final double oldPrice = asDouble(p['oldPrice']);
    final int discount = asInt(p['discount']);

    final int status = asInt(p['status']);
    final int quantity = asInt(p['quantity']);
    final int soldCount = asInt(p['soldCount']);
    final int viewCount = asInt(p['viewCount']);
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
                      currentPrice,
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
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            _buildBottomBar(currentPrice),
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
            onPressed: () => _snack('Tính năng chia sẻ sẽ bổ sung sau'),
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
            onPageChanged: (index) => setState(() => _selectedImageIndex = index),
            itemBuilder: (context, index) {
              final imagePath = imgs[index];
              final isFile = imagePath.startsWith('/');

              final img = isFile
                  ? Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imageFallback(),
              )
                  : Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imageFallback(),
              );

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
                color: _selectedImageIndex == index ? Colors.blue : Colors.grey,
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
      double currentPrice,
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
              Text('$_rating ($_reviewCount đánh giá)', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _formatPrice(currentPrice),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              if (discount > 0 && oldPrice > currentPrice) ...[
                const SizedBox(width: 8),
                Text(
                  _formatPrice(oldPrice),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    '-$discount%',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
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
            Text('Chỉ còn $quantity sản phẩm', style: const TextStyle(color: Colors.orange)),
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
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _buildVariantSelectors() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sizes.isNotEmpty) ...[
            const Text('Chọn size:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _sizes
                  .map((size) => ChoiceChip(
                label: Text(size),
                selected: _selectedSize == size,
                onSelected: (_) => setState(() => _selectedSize = size),
              ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (_colors.isNotEmpty) ...[
            const Text('Chọn màu:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colors
                  .map((color) => ChoiceChip(
                label: Text(color),
                selected: _selectedColor == color,
                onSelected: (_) => setState(() => _selectedColor = color),
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
          const Text('Thông tin sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _detailRow('Chất liệu', material),
          const SizedBox(height: 12),
          const Text('Mô tả sản phẩm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
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
          Row(
            children: [
              const Expanded(
                child: Text('Đánh giá sản phẩm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              TextButton.icon(
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Viết đánh giá'),
                onPressed: _showReviewDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_reviews.isEmpty)
            const Center(child: Text('Chưa có đánh giá nào', style: TextStyle(color: Colors.grey)))
          else
            Column(children: _reviews.map((r) => _buildReviewItem(r)).toList()),
        ],
      ),
    );
  }

  Future<void> _showReviewDialog() async {
    final rating = ValueNotifier<double>(5);
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đánh giá sản phẩm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: rating,
              builder: (_, v, __) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                      (i) => IconButton(
                    icon: Icon(
                      Icons.star,
                      color: i < v ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () => rating.value = (i + 1).toDouble(),
                  ),
                ),
              ),
            ),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Nhập nhận xét của bạn...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              await DBHelper.addReview(
                userId: widget.userId,
                productId: asInt(widget.product['id']),
                rating: rating.value.toInt(),
                comment: controller.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(context);
              _snack('Đã gửi đánh giá thành công!');
              await _loadReviews();
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final userName = (review['userName'] ?? 'Khách hàng').toString();
    final rating = asInt(review['rating']).toDouble();
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
                  backgroundImage: AssetImage('assets/images/anh_avata_macdinh.png'),
                ),
                const SizedBox(width: 8),
                Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                _buildStarRating(rating),
              ],
            ),
            const SizedBox(height: 8),
            if (comment.isNotEmpty) Text(comment, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(_formatDate(createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateString;
    }
  }

  Widget _buildStarRating(double rating) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      5,
          (i) => Icon(Icons.star,
          size: 16, color: i < rating.floor() ? Colors.amber : Colors.grey[300]),
    ),
  );

  // ---- Bottom bar: căn nút đều, không lệch ----
  Widget _buildBottomBar(double currentPrice) {
    final status = asInt(widget.product['status']);
    final isOutOfStock = status == 0;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              // stepper
              Container(
                height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (_quantity > 1) setState(() => _quantity--);
                      },
                    ),
                    SizedBox(
                      width: 28,
                      child: Center(
                        child: Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // buttons
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: isOutOfStock ? null : _addToCart,
                        child: const Text('Thêm vào giỏ hàng'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: isOutOfStock ? null : _buyNow,
                        child: const Text('Mua ngay'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------- CHECKOUT SHEET (MUA NGAY) ----------
  Future<void> _openCheckoutSheet() async {
    // Prefill từ user + default address
    final nameCtrl = TextEditingController(text: (_user?['fullName'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (_user?['phone'] ?? '').toString());
    final addrText = _composeAddress(_defaultAddress);
    final addrCtrl = TextEditingController(text: addrText);
    final noteCtrl = TextEditingController();

    String payment = 'cod'; // 'cod' | 'bank'

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setLocal) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin đặt hàng',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Khối địa chỉ nhanh
                  _addressQuickCard(
                    address: _defaultAddress,
                    onChange: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShippingAddressScreen(userId: widget.userId),
                        ),
                      );
                      // reload địa chỉ mặc định sau khi quay lại
                      await _loadUserAndDefaultAddress();
                      setLocal(() {
                        addrCtrl.text = _composeAddress(_defaultAddress);
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Họ và tên *'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Số điện thoại *'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: addrCtrl,
                    decoration: const InputDecoration(labelText: 'Địa chỉ nhận hàng *'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Ghi chú'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Phương thức thanh toán',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            phoneCtrl.text.trim().isEmpty ||
                            addrCtrl.text.trim().isEmpty) {
                          _snack('Vui lòng nhập đủ thông tin bắt buộc', ok: false);
                          return;
                        }

                        final currentPrice = asDouble(widget.product['price']);

                        final orderRes = await DBHelper.createOrder(
                          userId: widget.userId,
                          customerName: nameCtrl.text.trim(),
                          customerPhone: phoneCtrl.text.trim(),
                          shippingAddress: addrCtrl.text.trim(),
                          paymentMethod: payment,
                          note: noteCtrl.text.trim(),
                          items: [
                            {
                              'productId': widget.product['id'] as int,
                              'name': (widget.product['name'] ?? '').toString(),
                              'price': currentPrice,
                              'quantity': _quantity,
                              'size': _selectedSize,
                              'color': _selectedColor,
                              'discount': asInt(widget.product['discount']),
                            }
                          ],
                        );

                        if (!mounted) return;
                        if (orderRes['ok'] == true) {
                          Navigator.pop(context);
                          _snack('Đặt hàng thành công: ${orderRes['orderCode']}');
                        } else {
                          _snack('Tạo đơn thất bại: ${orderRes['error'] ?? 'Lỗi không xác định'}',
                              ok: false);
                        }
                      },
                      label: const Text('Xác nhận đặt hàng'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Hiển thị thẻ địa chỉ nhanh + nút thay đổi
  Widget _addressQuickCard({
    required Map<String, dynamic>? address,
    required VoidCallback onChange,
  }) {
    final has = address != null;
    final title = has
        ? '${address['label'] ?? ''}${(address['isDefault'] == 1) ? ' (Mặc định)' : ''}'
        : 'Chưa có địa chỉ';
    final subtitle = has ? _composeAddress(address) : 'Thêm địa chỉ giao hàng để mua nhanh hơn';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: Text(has ? 'Thay đổi' : 'Thêm địa chỉ'),
          ),
        ],
      ),
    );
  }

  String _composeAddress(Map<String, dynamic>? addr) {
    if (addr == null) return '';
    final parts = <String>[
      (addr['fullAddress'] ?? '').toString(),
      (addr['city'] ?? '').toString(),
      (addr['state'] ?? '').toString(),
      (addr['zipCode'] ?? '').toString(),
    ].where((e) => e.trim().isNotEmpty).toList();
    return parts.join(', ');
  }
}
