import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../database/db_helper.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'account_screen.dart';
import 'admin/admin_home_screen.dart';
import '../widgets/ai_chat_box.dart';

class HomeScreen extends StatefulWidget {
  final String fullName;
  final bool isAdmin;
  final int userId;

  const HomeScreen({
    super.key,
    required this.fullName,
    required this.isAdmin,
    required this.userId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ======= State =======
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> wishlist = [];
  int? selectedCategoryId;
  bool showSaleOnly = false;
  double salePercent = 40;
  String searchQuery = "";

  // Bottom Navigation Bar
  int _currentIndex = 0;

  // Ảnh khi thêm/sửa SP
  final List<XFile> _pickedImages = [];
  final List<String> _availableSizes = ['S', 'M', 'L', 'XL', 'XXL'];
  final List<String> _availableColors = [
    'Đen',
    'Trắng',
    'Xám',
    'Đỏ',
    'Xanh dương',
    'Xanh lá',
    'Vàng',
    'Nâu',
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadCategories(), _loadProducts()]);
  }

  Future<void> _loadCategories() async {
    final list = await DBHelper.getAllCategories();
    if (!mounted) return;
    setState(() => categories = list);
  }

  Future<void> _loadProducts() async {
    final list = await DBHelper.getAllProducts();
    if (!mounted) return;
    setState(() => products = list);
  }

  Future<void> _loadProductsByCategory(int id) async {
    final list = await DBHelper.getProductsByCategory(id);
    if (!mounted) return;
    setState(() => products = list);
  }

  Future<void> _loadWishlist() async {
    final list = await DBHelper.getUserFavorites(widget.userId);
    if (!mounted) return;
    setState(() => wishlist = list);
  }

  // ======= Helper UI =======
  void _showNotification(String msg, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        leading: Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: Colors.white,
        ),
        actions: [
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('Đóng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    });
  }

  // Mở chi tiết SP
  Future<void> _viewProductDetail(Map<String, dynamic> product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailScreen(product: product, userId: widget.userId),
      ),
    );
    // Nếu đang ở tab Yêu thích thì refresh danh sách
    if (_currentIndex == 2) await _loadWishlist();
  }

  // ============== CHỌN ẢNH ==============
  Future<void> _pickImages(void Function(void Function()) setLocal) async {
    try {
      final picker = ImagePicker();
      final imgs = await picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (imgs.isNotEmpty) {
        setLocal(() => _pickedImages.addAll(imgs));
      }
    } on PlatformException catch (e) {
      _showNotification(
        'Không thể mở thư viện ảnh: ${e.message}',
        isSuccess: false,
      );
    } catch (e) {
      _showNotification('Lỗi khi chọn ảnh: $e', isSuccess: false);
    }
  }

  Future<void> _takePhoto(void Function(void Function()) setLocal) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (photo != null) setLocal(() => _pickedImages.add(photo));
    } on PlatformException catch (e) {
      _showNotification('Không thể mở máy ảnh: ${e.message}', isSuccess: false);
    } catch (e) {
      _showNotification('Lỗi khi chụp ảnh: $e', isSuccess: false);
    }
  }

  Future<void> _pickFromDownloads(
    void Function(void Function()) setLocal,
  ) async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        initialDirectory: '/storage/emulated/0/Download',
      );
      if (res != null && res.files.isNotEmpty) {
        final files = res.files
            .where((f) => f.path != null)
            .map((f) => XFile(f.path!))
            .toList();
        setLocal(() => _pickedImages.addAll(files));
      }
    } on PlatformException catch (e) {
      _showNotification(
        'Không mở được thư mục Tải xuống: ${e.message}',
        isSuccess: false,
      );
    } catch (e) {
      _showNotification('Lỗi chọn ảnh: $e', isSuccess: false);
    }
  }

  void _clearPickedImages() {
    _pickedImages.clear();
  }

  /// Sao chép ảnh đã chọn vào thư mục ứng dụng
  Future<List<String>> _persistPickedImages() async {
    final dir = await getApplicationDocumentsDirectory();
    final saveDir = Directory(p.join(dir.path, 'product_images'));
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }

    final List<String> savedPaths = [];
    for (final xf in _pickedImages) {
      try {
        final file = File(xf.path);
        if (await file.exists()) {
          final newName =
              '${DateTime.now().millisecondsSinceEpoch}_${p.basename(xf.path)}';
          final newPath = p.join(saveDir.path, newName);
          await file.copy(newPath);
          savedPaths.add(newPath);
        }
      } catch (_) {}
    }
    return savedPaths;
  }

  // ======= ĐỊNH DẠNG GIÁ (duy nhất) =======
  String _formatPrice(double price) {
    final fmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return fmt.format(price);
  }

  double _calculateCurrentPrice(String oldPriceStr, String discountStr) {
    final basePrice = double.tryParse(oldPriceStr) ?? 0;
    final discount = int.tryParse(discountStr) ?? 0;
    if (basePrice <= 0) return 0;
    if (discount < 0 || discount > 100) return basePrice;
    return double.parse((basePrice * (1 - discount / 100)).toStringAsFixed(2));
  }

  // ======= CRUD DANH MỤC =======
  Future<void> _addCategory() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm danh mục mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên danh mục *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Mô tả'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                _showNotification(
                  'Vui lòng nhập tên danh mục!',
                  isSuccess: false,
                );
                return;
              }
              await DBHelper.addCategory(name, descCtrl.text.trim());
              if (!mounted) return;
              Navigator.pop(context);
              await _loadCategories();
              _showNotification('Đã thêm danh mục "$name" thành công!');
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _editCategory(Map<String, dynamic> cat) {
    final nameCtrl = TextEditingController(text: cat['name'] ?? '');
    final descCtrl = TextEditingController(text: cat['description'] ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sửa danh mục'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên danh mục *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Mô tả'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                _showNotification(
                  'Tên danh mục không được để trống!',
                  isSuccess: false,
                );
                return;
              }
              await DBHelper.updateCategory(
                cat['id'],
                name,
                descCtrl.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(context);
              await _loadCategories();
              _showNotification('Cập nhật danh mục thành công!');
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(int categoryId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc muốn xóa danh mục này? Tất cả sản phẩm trong danh mục cũng sẽ bị xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DBHelper.deleteCategory(categoryId);
      if (selectedCategoryId == categoryId) {
        selectedCategoryId = null;
        showSaleOnly = false;
      }
      await _loadCategories();
      await _loadProducts();
      _showNotification('Đã xóa danh mục!', isSuccess: false);
    }
  }

  void _showCategoryOptions(Map<String, dynamic> cat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cat['name'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Sửa danh mục'),
              onTap: () {
                Navigator.pop(context);
                _editCategory(cat);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa danh mục'),
              onTap: () {
                Navigator.pop(context);
                _deleteCategory(cat['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ======= CRUD SẢN PHẨM =======
  Future<void> _deleteProduct(int productId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: const Text('Bạn có chắc muốn xóa sản phẩm này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DBHelper.deleteProduct(productId);
      await _reloadProducts();
      _showNotification('Đã xóa sản phẩm!', isSuccess: false);
    }
  }

  void _showSaleDialog(Map<String, dynamic> product) {
    final discountCtrl = TextEditingController(
      text: (product['discount'] ?? 0).toString(),
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thiết lập giảm giá'),
        content: TextField(
          controller: discountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Phần trăm giảm giá',
            suffixText: '%',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final discount = int.tryParse(discountCtrl.text) ?? 0;
              await DBHelper.updateSaleDiscount(product['id'], discount);
              if (!mounted) return;
              Navigator.pop(context);
              await _reloadProducts();
              _showNotification('Đã cập nhật giảm giá!');
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showProductOptions(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Sửa sản phẩm'),
              onTap: () {
                Navigator.pop(context);
                _showAddProductDialog(product: product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_offer, color: Colors.orange),
              title: const Text('Thiết lập giảm giá'),
              onTap: () {
                Navigator.pop(context);
                _showSaleDialog(product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa sản phẩm'),
              onTap: () {
                Navigator.pop(context);
                _deleteProduct(product['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog({Map<String, dynamic>? product}) {
    _clearPickedImages();
    final isEditing = product != null;
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    final oldPriceCtrl = TextEditingController(
      text: product?['oldPrice']?.toString() ?? '',
    );
    final descCtrl = TextEditingController(text: product?['description'] ?? '');
    final materialCtrl = TextEditingController(
      text: product?['material']?.toString() ?? '',
    );
    final quantityCtrl = TextEditingController(
      text: product?['quantity']?.toString() ?? '0',
    );
    final discountCtrl = TextEditingController(
      text: product?['discount']?.toString() ?? '0',
    );

    // Load existing images nếu sửa
    if (isEditing && product!['images'] != null) {
      try {
        final existingImages = List<String>.from(jsonDecode(product['images']));
        for (var imagePath in existingImages) {
          if (imagePath.startsWith('/')) {
            _pickedImages.add(XFile(imagePath));
          }
        }
      } catch (_) {}
    }

    int? selectedCatId =
        product?['categoryId'] ??
        selectedCategoryId ??
        (categories.isNotEmpty ? categories.first['id'] : null);
    int status = product?['status'] ?? 1;

    List<String> selectedSizes = [];
    if (isEditing && product?['sizes'] != null) {
      try {
        selectedSizes = List<String>.from(jsonDecode(product!['sizes']));
      } catch (_) {}
    }

    List<String> selectedColors = [];
    if (isEditing && product?['colors'] != null) {
      try {
        selectedColors = List<String>.from(jsonDecode(product!['colors']));
      } catch (_) {}
    }
    final customColorCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text(isEditing ? 'Sửa sản phẩm' : 'Thêm sản phẩm mới'),
            content: SizedBox(
              width: double.maxFinite,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tên sản phẩm *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: oldPriceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Giá gốc *',
                              ),
                              onChanged: (_) => setLocal(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: discountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Giảm giá %',
                              ),
                              onChanged: (_) => setLocal(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Giá sau giảm:'),
                            Text(
                              _formatPrice(
                                _calculateCurrentPrice(
                                  oldPriceCtrl.text,
                                  discountCtrl.text,
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: quantityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số lượng *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedCatId,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục *',
                        ),
                        items: categories
                            .map(
                              (c) => DropdownMenuItem<int>(
                                value: c['id'],
                                child: Text(c['name']),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setLocal(() => selectedCatId = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: status,
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái *',
                        ),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Hết hàng')),
                          DropdownMenuItem(value: 1, child: Text('Còn hàng')),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('Đang nhập hàng'),
                          ),
                        ],
                        onChanged: (v) => setLocal(() => status = v!),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả sản phẩm',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Size
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Chọn size có sẵn:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: _availableSizes.map((size) {
                          final isSelected = selectedSizes.contains(size);
                          return FilterChip(
                            label: Text(size),
                            selected: isSelected,
                            onSelected: (selected) {
                              setLocal(() {
                                selected
                                    ? selectedSizes.add(size)
                                    : selectedSizes.remove(size);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Color
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Chọn màu có sẵn:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: _availableColors.map((color) {
                          final isSelected = selectedColors.contains(color);
                          return FilterChip(
                            label: Text(color),
                            selected: isSelected,
                            onSelected: (selected) {
                              setLocal(() {
                                selected
                                    ? selectedColors.add(color)
                                    : selectedColors.remove(color);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customColorCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Thêm màu khác',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final c = customColorCtrl.text.trim();
                              if (c.isNotEmpty && !selectedColors.contains(c)) {
                                setLocal(() {
                                  selectedColors.add(c);
                                  customColorCtrl.clear();
                                });
                              }
                            },
                            child: const Text('Thêm'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Material
                      TextField(
                        controller: materialCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Chất liệu',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Ảnh
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickImages(setLocal),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Thư viện'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _takePhoto(setLocal),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Máy ảnh'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _pickFromDownloads(setLocal),
                          icon: const Icon(Icons.download),
                          label: const Text('Chọn từ thư mục Tải xuống'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pickedImages.isEmpty
                            ? 'Chưa chọn ảnh'
                            : 'Đã chọn ${_pickedImages.length} ảnh',
                      ),
                      const SizedBox(height: 8),
                      if (_pickedImages.isNotEmpty)
                        Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 200,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_pickedImages.first.path),
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 90,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _pickedImages.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final image = _pickedImages[index];
                                  return GestureDetector(
                                    onTap: () {
                                      setLocal(() {
                                        final temp = _pickedImages.removeAt(
                                          index,
                                        );
                                        _pickedImages.insert(0, temp);
                                      });
                                    },
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            border: index == 0
                                                ? Border.all(
                                                    color: Colors.redAccent,
                                                    width: 2,
                                                  )
                                                : null,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Image.file(
                                              File(image.path),
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              gaplessPlayback: true,
                                            ),
                                          ),
                                        ),
                                        if (_pickedImages.length > 1)
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: InkWell(
                                              onTap: () => setLocal(
                                                () => _pickedImages.removeAt(
                                                  index,
                                                ),
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (index == 0)
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Chính',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _clearPickedImages();
                  Navigator.pop(context);
                },
                child: const Text('Hủy'),
              ),
              if (isEditing)
                TextButton(
                  onPressed: () async {
                    await _deleteProduct(product!['id']);
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Xóa'),
                ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final oldPriceText = oldPriceCtrl.text.trim();
                  final quantityText = quantityCtrl.text.trim();
                  if (name.isEmpty ||
                      oldPriceText.isEmpty ||
                      selectedCatId == null ||
                      quantityText.isEmpty) {
                    _showNotification(
                      'Vui lòng nhập đầy đủ thông tin bắt buộc (*)',
                      isSuccess: false,
                    );
                    return;
                  }
                  final oldPrice = double.tryParse(oldPriceText);
                  final quantity = int.tryParse(quantityText);
                  if (oldPrice == null || oldPrice <= 0) {
                    _showNotification(
                      'Giá gốc không hợp lệ!',
                      isSuccess: false,
                    );
                    return;
                  }
                  if (quantity == null || quantity < 0) {
                    _showNotification(
                      'Số lượng không hợp lệ!',
                      isSuccess: false,
                    );
                    return;
                  }
                  final discount = int.tryParse(discountCtrl.text.trim()) ?? 0;
                  if (discount < 0 || discount > 100) {
                    _showNotification(
                      'Giảm giá phải từ 0-100%!',
                      isSuccess: false,
                    );
                    return;
                  }

                  final price = oldPrice * (1 - discount / 100);

                  // Lưu ảnh đã chọn vào thư mục app
                  List<String> images;
                  if (_pickedImages.isNotEmpty) {
                    images = await _persistPickedImages();
                  } else if (isEditing && product!['images'] != null) {
                    images = List<String>.from(jsonDecode(product['images']));
                  } else {
                    images = [
                      'assets/images/anh_macdinh_sanpham_chuachonanh.png',
                    ];
                  }

                  final data = {
                    'name': name,
                    'categoryId': selectedCatId,
                    'price': price,
                    'oldPrice': oldPrice,
                    'description': descCtrl.text.trim(),
                    'images': jsonEncode(images),
                    'discount': discount,
                    'quantity': quantity,
                    'status': status,
                    'sizes': jsonEncode(selectedSizes),
                    'colors': jsonEncode(selectedColors),
                    'material': materialCtrl.text.trim(),
                  };

                  if (isEditing) {
                    await DBHelper.updateProduct(product!['id'], data);
                  } else {
                    await DBHelper.addProduct(data);
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                  _clearPickedImages();
                  await _reloadProducts();
                  _showNotification(
                    isEditing
                        ? 'Đã cập nhật sản phẩm!'
                        : 'Đã thêm sản phẩm mới!',
                  );
                },
                child: Text(isEditing ? 'Cập nhật' : 'Thêm'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _reloadProducts() async {
    if (selectedCategoryId == null) {
      await _loadProducts();
    } else {
      await _loadProductsByCategory(selectedCategoryId!);
    }
  }

  // ======= FILTERED LIST =======
  List<Map<String, dynamic>> get _filteredProducts {
    Iterable<Map<String, dynamic>> list = products;
    if (showSaleOnly) list = list.where((p) => (p['discount'] ?? 0) > 0);
    if (selectedCategoryId != null) {
      list = list.where((p) => p['categoryId'] == selectedCategoryId);
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where(
        (p) => (p['name'] ?? '').toString().toLowerCase().contains(q),
      );
    }
    return list.toList();
  }

  // ======= UI =======
  @override
  Widget build(BuildContext context) {
    // Nếu là admin, chuyển qua màn hình quản lý riêng
    if (widget.isAdmin) {
      return AdminHomeScreen(fullName: widget.fullName, userId: widget.userId);
    }

    // Giao diện cho người dùng thường
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildCurrentScreen(),
      bottomNavigationBar: _buildBottomNavigationBar(),

      // 👉 Nút tròn AI nổi
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.smart_toy),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiChatBox()),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    const baseStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
    final title = switch (_currentIndex) {
      0 => 'Trang chủ',
      1 => 'Giỏ hàng',
      2 => 'Yêu thích',
      3 => 'Tài khoản',
      _ => 'Trang chủ',
    };
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      title: Text(title, style: baseStyle),
      actions: _currentIndex == 0
          ? [
              IconButton(
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.black87,
                ),
                onPressed: () => setState(() => _currentIndex = 1),
                tooltip: 'Giỏ hàng',
              ),
            ]
          : null,
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return CartScreen(userId: widget.userId);
      case 2:
        return _buildWishlistScreen();
      case 3:
        return FutureBuilder<Map<String, dynamic>?>(
          future: DBHelper.getUserById(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = snapshot.data;
            if (user == null) {
              return const Center(child: Text('Không tìm thấy thông tin người dùng'));
            }
            return AccountScreen(user: user);
          },
        );
      default:
        return _buildHomeScreen();
    }
  }

  // ----- Trang chủ -----
  Widget _buildHomeScreen() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 16),
              _buildSearch(),
              const SizedBox(height: 16),
              _buildSaleBanner(),
              const SizedBox(height: 20),
              _buildCategoryHeader(),
              const SizedBox(height: 12),
              _buildCategoryChips(),
              const SizedBox(height: 16),
              _buildProductSectionTitle(),
              const SizedBox(height: 12),
              _buildProductGrid(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ----- Các trang tạm -----
  Widget _buildCartScreen() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shopping_cart, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 12),
        const Text(
          'Giỏ hàng của bạn',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Chưa có sản phẩm nào trong giỏ',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => setState(() => _currentIndex = 0),
          child: const Text('Tiếp tục mua sắm'),
        ),
      ],
    ),
  );

  // ===== YÊU THÍCH: hiển thị thật =====
  Widget _buildWishlistScreen() {
    if (wishlist.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'Sản phẩm yêu thích',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Chưa có sản phẩm yêu thích',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: wishlist.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final p = wishlist[i];
        List imgs;
        try {
          imgs = jsonDecode(p['images'] ?? '[]') as List;
        } catch (_) {
          imgs = const [];
        }
        final imagePath = imgs.isNotEmpty
            ? imgs.first as String
            : 'assets/images/anh_macdinh_sanpham_chuachonanh.png';
        final price = (p['price'] as num?)?.toDouble() ?? 0.0;

        return Card(
          child: ListTile(
            onTap: () => _viewProductDetail(p),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imagePath.startsWith('/')
                  ? Image.file(
                      File(imagePath),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      imagePath,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
            ),
            title: Text(p['name'] ?? ''),
            subtitle: Text(_formatPrice(price)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                await DBHelper.toggleFavorite(widget.userId, p['id'] as int);
                await _loadWishlist();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa khỏi yêu thích')),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileScreen() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage(
                  'assets/images/anh_avata_macdinh.png',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.fullName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(
                  widget.isAdmin ? 'Quản trị viên' : 'Khách hàng',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: widget.isAdmin
                    ? Colors.redAccent
                    : Colors.blue,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Card(
        child: ListTile(leading: Icon(Icons.settings), title: Text('Cài đặt')),
      ),
      const Card(
        child: ListTile(
          leading: Icon(Icons.history),
          title: Text('Lịch sử mua hàng'),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          onTap: () {},
        ),
      ),
    ],
  );

  // ======= Bottom Nav =======
  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) async {
        setState(() => _currentIndex = i);
        if (i == 2) await _loadWishlist(); // khi chuyển sang tab Yêu thích
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.redAccent,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Giỏ hàng',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Yêu thích'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
      ],
    );
  }

  // ======= Các block UI con =======
  Widget _buildGreeting() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: DBHelper.getUserById(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final user = snapshot.data;
        final avatarPath = user?['avatar'] as String?;
        final fullName = user?['fullName'] ?? widget.fullName;

        return Row(
          children: [
            CircleAvatar(
              backgroundImage: (avatarPath != null && avatarPath.isNotEmpty)
                  ? FileImage(File(avatarPath))
                  : const AssetImage('assets/images/anh_avata_macdinh.png')
              as ImageProvider,
              radius: 22,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, $fullName 👋',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  'Chúc bạn một ngày tốt lành!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearch() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Tìm kiếm sản phẩm...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
      onChanged: (v) => setState(() => searchQuery = v),
    );
  }

  Widget _buildSaleBanner() {
    return GestureDetector(
      onLongPress: widget.isAdmin
          ? () {
              final ctrl = TextEditingController(
                text: salePercent.toInt().toString(),
              );
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sửa phần trăm giảm giá'),
                  content: TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Phần trăm giảm giá',
                      suffixText: '%',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final v = int.tryParse(ctrl.text);
                        if (v != null && v >= 0 && v <= 100) {
                          setState(() => salePercent = v.toDouble());
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Lưu'),
                    ),
                  ],
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.redAccent, Colors.orangeAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ưu đãi đặc biệt hôm nay',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Giảm giá đến ${salePercent.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.redAccent,
              ),
              onPressed: () {
                setState(() {
                  showSaleOnly = true;
                  selectedCategoryId = null;
                });
              },
              child: const Text('Mua ngay'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return const Text(
      'Danh mục nổi bật',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  void _openCategoryManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Quản lý danh mục',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: categories.length,
                  itemBuilder: (_, i) {
                    final c = categories[i];
                    return Card(
                      child: ListTile(
                        title: Text(c['name']),
                        subtitle: Text(c['description'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.pop(context);
                                _editCategory(c);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteCategory(c['id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _addCategory();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm danh mục'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    if (categories.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có danh mục nào',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ChoiceChip(
            label: const Text('Tất cả'),
            selected: selectedCategoryId == null && !showSaleOnly,
            selectedColor: Colors.redAccent,
            backgroundColor: Colors.redAccent.withOpacity(0.15),
            labelStyle: TextStyle(
              color: selectedCategoryId == null && !showSaleOnly
                  ? Colors.white
                  : Colors.black,
            ),
            onSelected: (_) async {
              setState(() {
                selectedCategoryId = null;
                showSaleOnly = false;
              });
              await _loadProducts();
            },
          ),
          const SizedBox(width: 8),
          ...categories.map((cat) {
            final selected = selectedCategoryId == cat['id'] && !showSaleOnly;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onLongPress: null,
                child: ChoiceChip(
                  label: Text(cat['name']),
                  selected: selected,
                  selectedColor: Colors.redAccent,
                  backgroundColor: Colors.redAccent.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black,
                  ),
                  onSelected: (_) async {
                    setState(() {
                      selectedCategoryId = cat['id'];
                      showSaleOnly = false;
                    });
                    await _loadProductsByCategory(cat['id']);
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductSectionTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          showSaleOnly ? 'Sản phẩm khuyến mãi' : 'Sản phẩm nổi bật',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        TextButton(
          onPressed: () async {
            setState(() {
              selectedCategoryId = null;
              showSaleOnly = false;
            });
            await _loadProducts();
          },
          child: const Text('Tất cả'),
        ),
      ],
    );
  }

  Widget _buildProductGrid() {
    final list = _filteredProducts;
    if (list.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không có sản phẩm nào phù hợp',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      key: ValueKey(
        '${selectedCategoryId ?? 'all'}-$showSaleOnly-$searchQuery',
      ),
      itemCount: list.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, i) {
        final pdt = list[i];
        final sale = (pdt['discount'] as int?) ?? 0;

        List imgs;
        try {
          imgs =
              jsonDecode(
                    pdt['images'] ??
                        '["assets/images/anh_macdinh_sanpham_chuachonanh.png"]',
                  )
                  as List;
        } catch (_) {
          imgs = const [];
        }
        final imagePath = imgs.isNotEmpty
            ? imgs.first as String
            : 'assets/images/anh_macdinh_sanpham_chuachonanh.png';

        final currentPrice =
            (pdt['price'] as num?)?.toDouble() ?? 0.0; // giá sau giảm
        final oldPrice = (pdt['oldPrice'] as num?)?.toDouble() ?? 0.0;

        final status = (pdt['status'] as int?) ?? 1;
        final quantity = (pdt['quantity'] as int?) ?? 0;
        final soldCount = (pdt['soldCount'] as int?) ?? 0;
        final rating = (pdt['rating'] as num?)?.toDouble() ?? 0.0;
        final reviewCount = (pdt['reviewCount'] as int?) ?? 0;

        Color statusColor;
        String statusText;
        switch (status) {
          case 0:
            statusColor = Colors.red;
            statusText = 'Hết hàng';
            break;
          case 2:
            statusColor = Colors.orange;
            statusText = 'Đang nhập';
            break;
          default:
            statusColor = Colors.green;
            statusText = 'Còn hàng';
        }

        return GestureDetector(
          onTap: () => _viewProductDetail(pdt),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  spreadRadius: 1,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 12,
                    child: imagePath.startsWith('/')
                        ? Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imageFallback(),
                          )
                        : Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imageFallback(),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
                  child: Row(
                    children: [
                      if (sale > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-$sale%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pdt['name'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (rating > 0) ...[
                          Row(
                            children: [
                              _buildStarRating(rating),
                              const SizedBox(width: 4),
                              Text(
                                '($reviewCount)',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          _formatPrice(currentPrice),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (sale > 0 && oldPrice > 0)
                          Text(
                            _formatPrice(oldPrice),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        const Spacer(),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Text(
                                'SL: $quantity',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (soldCount > 0)
                                Text(
                                  'Đã bán: $soldCount',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget hiển thị sao đánh giá
  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          Icons.star,
          size: 12,
          color: index < rating.floor() ? Colors.amber : Colors.grey[300],
        );
      }),
    );
  }

  Widget _imageFallback() => Container(
    color: Colors.grey[200],
    child: const Center(child: Icon(Icons.photo, size: 40, color: Colors.grey)),
  );


}
