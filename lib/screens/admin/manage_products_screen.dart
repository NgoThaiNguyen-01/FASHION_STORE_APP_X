import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../database/db_helper.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  int? selectedCategoryId;
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _pickedImages = [];
  int _defaultImageIndex = 0;
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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final categoriesData = await DBHelper.getAllCategories();
      final productsData = await DBHelper.getAllProducts();
      if (mounted) {
        setState(() {
          categories = categoriesData;
          products = productsData;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    }
  }

  Future<void> _loadProductsByCategory(int? categoryId) async {
    setState(() => isLoading = true);
    try {
      final data = categoryId == null
          ? await DBHelper.getAllProducts()
          : await DBHelper.getProductsByCategory(categoryId);
      if (mounted) {
        setState(() {
          products = data;
          selectedCategoryId = categoryId;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải sản phẩm: $e')));
      }
    }
  }

  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên danh mục')),
                );
                return;
              }
              await DBHelper.addCategory(name, descCtrl.text.trim());
              if (mounted) {
                Navigator.pop(context);
                await _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã thêm danh mục "$name"')),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(Map<String, dynamic> category) {
    final nameCtrl = TextEditingController(text: category['name']);
    final descCtrl = TextEditingController(text: category['description']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await DBHelper.deleteCategory(category['id']);
              if (mounted) {
                Navigator.pop(context);
                if (selectedCategoryId == category['id']) {
                  selectedCategoryId = null;
                }
                await _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa danh mục')),
                );
              }
            },
            child: const Text('Xóa'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên danh mục')),
                );
                return;
              }
              await DBHelper.updateCategory(
                category['id'],
                name,
                descCtrl.text.trim(),
              );
              if (mounted) {
                Navigator.pop(context);
                await _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật danh mục')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _pickedImages.addAll(images);
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );
    if (photo != null) {
      setState(() {
        _pickedImages.add(photo);
      });
    }
  }

  void _showImagePreview(List<XFile> images, [int initialIndex = 0]) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) {
          return Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(
                    'Xem trước (${initialIndex + 1}/${images.length})',
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setLocal(() {
                          images.removeAt(initialIndex);
                          if (images.isEmpty) {
                            Navigator.pop(context);
                          } else if (initialIndex >= images.length) {
                            initialIndex = images.length - 1;
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle),
                      onPressed: () {
                        setState(() => _defaultImageIndex = initialIndex);
                        Navigator.pop(context);
                      },
                      tooltip: 'Đặt làm ảnh đại diện',
                    ),
                  ],
                ),
                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    itemCount: images.length,
                    controller: PageController(initialPage: initialIndex),
                    onPageChanged: (index) =>
                        setLocal(() => initialIndex = index),
                    itemBuilder: (context, index) {
                      return Image.file(
                        File(images[index].path),
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddProductDialog({Map<String, dynamic>? product}) {
    _pickedImages.clear();
    _defaultImageIndex = 0;
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

    // Load existing images
    if (isEditing && product['images'] != null) {
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
    if (isEditing && product['sizes'] != null) {
      try {
        selectedSizes = List<String>.from(jsonDecode(product['sizes']));
      } catch (_) {}
    }

    List<String> selectedColors = [];
    if (isEditing && product['colors'] != null) {
      try {
        selectedColors = List<String>.from(jsonDecode(product['colors']));
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quantityCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Số lượng *',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _pickImages();
                            if (_pickedImages.isNotEmpty) {
                              _showImagePreview(_pickedImages);
                            }
                          },
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Thư viện'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _takePhoto();
                            if (_pickedImages.isNotEmpty) {
                              _showImagePreview(
                                _pickedImages,
                                _pickedImages.length - 1,
                              );
                            }
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Chụp'),
                        ),
                      ],
                    ),
                    if (_pickedImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _pickedImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () =>
                                    _showImagePreview(_pickedImages, index),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_pickedImages[index].path),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    if (index == _defaultImageIndex)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedCatId,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục *',
                      ),
                      items: categories.map((c) {
                        return DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text(c['name']),
                        );
                      }).toList(),
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
                    // Sizes
                    const Text(
                      'Kích thước:',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                              if (selected) {
                                selectedSizes.add(size);
                              } else {
                                selectedSizes.remove(size);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Colors
                    const Text(
                      'Màu sắc:',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                              if (selected) {
                                selectedColors.add(color);
                              } else {
                                selectedColors.remove(color);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    // Add custom color
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
                            final color = customColorCtrl.text.trim();
                            if (color.isNotEmpty &&
                                !selectedColors.contains(color)) {
                              setLocal(() {
                                selectedColors.add(color);
                                customColorCtrl.clear();
                              });
                            }
                          },
                          child: const Text('Thêm'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: materialCtrl,
                      decoration: const InputDecoration(labelText: 'Chất liệu'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _pickedImages.clear();
                  Navigator.pop(context);
                },
                child: const Text('Hủy'),
              ),
              if (isEditing)
                TextButton(
                  onPressed: () async {
                    await DBHelper.deleteProduct(product['id']);
                    if (!mounted) return;
                    Navigator.pop(context);
                    _pickedImages.clear();
                    await _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa sản phẩm')),
                    );
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Vui lòng nhập đầy đủ thông tin bắt buộc (*)',
                        ),
                      ),
                    );
                    return;
                  }

                  final oldPrice = double.tryParse(oldPriceText);
                  final quantity = int.tryParse(quantityText);

                  if (oldPrice == null || oldPrice <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Giá không hợp lệ')),
                    );
                    return;
                  }

                  if (quantity == null || quantity < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Số lượng không hợp lệ')),
                    );
                    return;
                  }

                  final discount = int.tryParse(discountCtrl.text.trim()) ?? 0;
                  if (discount < 0 || discount > 100) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Giảm giá phải từ 0-100%')),
                    );
                    return;
                  }

                  final price = oldPrice * (1 - discount / 100);

                  // Reorder images to make default image first
                  if (_defaultImageIndex > 0 && _pickedImages.isNotEmpty) {
                    final defaultImage = _pickedImages.removeAt(
                      _defaultImageIndex,
                    );
                    _pickedImages.insert(0, defaultImage);
                  }

                  final data = {
                    'name': name,
                    'categoryId': selectedCatId,
                    'price': price,
                    'oldPrice': oldPrice,
                    'description': descCtrl.text.trim(),
                    'discount': discount,
                    'quantity': quantity,
                    'status': status,
                    'sizes': jsonEncode(selectedSizes),
                    'colors': jsonEncode(selectedColors),
                    'material': materialCtrl.text.trim(),
                    'images': jsonEncode(
                      _pickedImages.map((e) => e.path).toList(),
                    ),
                  };

                  if (isEditing) {
                    await DBHelper.updateProduct(product['id'], data);
                  } else {
                    await DBHelper.addProduct(data);
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                  _pickedImages.clear();
                  await _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? 'Đã cập nhật sản phẩm'
                            : 'Đã thêm sản phẩm mới',
                      ),
                    ),
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

  void _confirmDeleteProduct(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${product['name']}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await DBHelper.deleteProduct(product['id']);
              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  products.removeWhere((p) => p['id'] == product['id']);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa sản phẩm')),
                );
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(Map<String, dynamic> product) {
    List<String> images = [];
    try {
      images = List<String>.from(jsonDecode(product['images'] ?? '[]'));
    } catch (_) {}

    List<String> sizes = [];
    try {
      sizes = List<String>.from(jsonDecode(product['sizes'] ?? '[]'));
    } catch (_) {}

    List<String> colors = [];
    try {
      colors = List<String>.from(jsonDecode(product['colors'] ?? '[]'));
    } catch (_) {}

    final category = categories.firstWhere(
      (c) => c['id'] == product['categoryId'],
      orElse: () => {'name': 'Không có'},
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Chi tiết sản phẩm'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddProductDialog(product: product);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDeleteProduct(product);
                  },
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (images.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: PageView.builder(
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            final imagePath = images[index];
                            return Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                _formatPrice(
                                  (product['price'] as num).toDouble(),
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red,
                                ),
                              ),
                              if ((product['discount'] ?? 0) > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  _formatPrice(
                                    (product['oldPrice'] as num).toDouble(),
                                  ),
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '-${product['discount']}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          _detailItem('Danh mục:', category['name']),
                          _detailItem(
                            'Trạng thái:',
                            switch (product['status'] ?? 1) {
                              0 => 'Hết hàng',
                              1 => 'Còn hàng',
                              2 => 'Đang nhập hàng',
                              _ => 'Không xác định',
                            },
                          ),
                          _detailItem(
                            'Kho:',
                            'Còn ${product['quantity']} | Đã bán: ${product['soldCount']}',
                          ),
                          if (sizes.isNotEmpty)
                            _detailItem('Kích thước:', sizes.join(', ')),
                          if (colors.isNotEmpty)
                            _detailItem('Màu sắc:', colors.join(', ')),
                          if (product['material']?.isNotEmpty ?? false)
                            _detailItem('Chất liệu:', product['material']),
                          if (product['description']?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Mô tả:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(product['description']),
                          ],
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
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0)}₫';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Làm mới',
          ),
          IconButton(
            onPressed: () => _showAddProductDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Thêm sản phẩm',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      const Text(
                        'Danh mục:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _showAddCategoryDialog,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Thêm mới'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      ActionChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selectedCategoryId == null)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            const Text('Tất cả'),
                          ],
                        ),
                        backgroundColor: selectedCategoryId == null
                            ? Colors.white
                            : null,
                        side: BorderSide(
                          color: selectedCategoryId == null
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                        ),
                        onPressed: () => _loadProductsByCategory(null),
                      ),
                      const SizedBox(width: 8),
                      ...categories.map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onLongPress: () => _showEditCategoryDialog(cat),
                            child: ActionChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selectedCategoryId == cat['id'])
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  Text(cat['name']),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.more_vert,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                              backgroundColor: selectedCategoryId == cat['id']
                                  ? Colors.white
                                  : null,
                              side: BorderSide(
                                color: selectedCategoryId == cat['id']
                                    ? Theme.of(context).primaryColor
                                    : Colors.transparent,
                              ),
                              onPressed: () =>
                                  _loadProductsByCategory(cat['id']),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                ? const Center(child: Text('Chưa có sản phẩm nào'))
                : ListView.builder(
                    itemCount: products.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      List<String> images = [];
                      try {
                        images = List<String>.from(
                          jsonDecode(product['images'] ?? '[]'),
                        );
                      } catch (_) {}
                      final imagePath = images.isNotEmpty
                          ? images.first
                          : 'assets/images/anh_macdinh_sanpham_chuachonanh.png';

                      return Card(
                        child: InkWell(
                          onTap: () => _showProductDetails(product),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imagePath.startsWith('/')
                                      ? Image.file(
                                          File(imagePath),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.asset(
                                          imagePath,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatPrice(
                                          (product['price'] as num).toDouble(),
                                        ),
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Còn ${product['quantity']} | Đã bán: ${product['soldCount']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _showAddProductDialog(
                                        product: product,
                                      ),
                                      tooltip: 'Sửa',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _confirmDeleteProduct(product),
                                      tooltip: 'Xóa',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
