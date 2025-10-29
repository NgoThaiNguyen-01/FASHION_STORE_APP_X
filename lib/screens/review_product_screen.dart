import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../database/db_helper.dart';

class ReviewProductScreen extends StatefulWidget {
  final int userId; // ✅ cần để ghi review
  final int orderId;
  final List<Map<String, dynamic>> items; // danh sách item từ getOrderDetail hoặc getOrderItemsNeedingReview

  const ReviewProductScreen({
    super.key,
    required this.userId,
    required this.orderId,
    required this.items,
  });

  @override
  State<ReviewProductScreen> createState() => _ReviewProductScreenState();
}

class _ReviewProductScreenState extends State<ReviewProductScreen> {
  // productId -> rating/comment
  final Map<int, int> _ratings = {}; // ✅ lưu int 1..5
  final Map<int, TextEditingController> _comments = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // khởi tạo mặc định 5 sao
    for (final it in widget.items) {
      final pid = (it['productId'] as num).toInt();
      _ratings[pid] = 5;
      _comments[pid] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _comments.values) {
      c.dispose();
    }
    super.dispose();
  }

  // -------- Helpers --------
  Widget _buildProductImage(String? imagesJson) {
    String? first;
    try {
      final list = (imagesJson == null || imagesJson.isEmpty)
          ? const <dynamic>[]
          : jsonDecode(imagesJson) as List<dynamic>;
      if (list.isNotEmpty) first = list.first.toString();
    } catch (_) {
      first = null;
    }

    if (first == null) {
      return const Icon(Icons.image_not_supported, size: 60, color: Colors.grey);
    }

    if (first!.startsWith('http')) {
      return Image.network(first!, width: 60, height: 60, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image, size: 60, color: Colors.grey));
    } else if (first!.startsWith('/')) {
      // file local (đường dẫn tuyệt đối)
      return Image.file(File(first!), width: 60, height: 60, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image, size: 60, color: Colors.grey));
    } else {
      // asset
      return Image.asset(first!, width: 60, height: 60, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image, size: 60, color: Colors.grey));
    }
  }

  Future<void> _submitReviews() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      for (final it in widget.items) {
        final productId = (it['productId'] as num).toInt();
        final rating = (_ratings[productId] ?? 5).clamp(1, 5);
        final comment = _comments[productId]?.text.trim() ?? '';

        // ✅ Upsert review + auto update rating sản phẩm
        await DBHelper.addOrUpdateReview(
          userId: widget.userId,
          productId: productId,
          rating: rating,
          comment: comment.isEmpty ? null : comment,
          images: null,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã gửi/cập nhật đánh giá thành công!'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi khi gửi đánh giá: $e'),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final productId = (item['productId'] as num).toInt();
    final name = (item['productName'] ?? '').toString();
    final imagesJson = item['productImages']?.toString();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildProductImage(imagesJson),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ⭐ Rating: dùng int cho chắc, tắt half rating để khớp DB
            RatingBar.builder(
              initialRating: (_ratings[productId] ?? 5).toDouble(),
              minRating: 1,
              allowHalfRating: false, // ✅ DB yêu cầu int
              itemCount: 5,
              glow: false,
              itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
              itemBuilder: (context, _) =>
              const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (r) =>
                  setState(() => _ratings[productId] = r.toInt()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _comments[productId],
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập nhận xét của bạn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đánh giá sản phẩm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _submitting
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Không còn sản phẩm nào cần đánh giá.',
            textAlign: TextAlign.center,
          ),
        ),
      )
          : ListView(
        children: [
          const SizedBox(height: 12),
          ...items.map(_buildProductCard).toList(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submitReviews,
              icon: const Icon(Icons.send),
              label: const Text('Gửi đánh giá'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
