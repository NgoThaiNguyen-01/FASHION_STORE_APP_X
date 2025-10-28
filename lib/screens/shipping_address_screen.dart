import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class ShippingAddressScreen extends StatefulWidget {
  final int userId;
  const ShippingAddressScreen({super.key, required this.userId});

  @override
  State<ShippingAddressScreen> createState() => _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends State<ShippingAddressScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await DBHelper.getAddressesByUser(widget.userId);
    if (!mounted) return;
    setState(() {
      _addresses = list;
      _loading = false;
    });
  }

  void _snack(String m, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: ok ? Colors.green : Colors.redAccent,
      ),
    );
  }

  /// Thêm/Sửa địa chỉ — có checkbox ĐẶT LÀM MẶC ĐỊNH
  void _addOrEdit({Map<String, dynamic>? address}) {
    final labelCtrl = TextEditingController(text: address?['label'] ?? '');
    final fullCtrl  = TextEditingController(text: address?['fullAddress'] ?? '');
    final cityCtrl  = TextEditingController(text: address?['city'] ?? '');
    final stateCtrl = TextEditingController(text: address?['state'] ?? '');
    final zipCtrl   = TextEditingController(text: address?['zipCode'] ?? '');

    bool isDefault = (address?['isDefault'] ?? 0) == 1;
    final isEdit = address != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setLocal) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEdit ? 'Chỉnh sửa địa chỉ' : 'Thêm địa chỉ mới',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nhãn (VD: Nhà, Văn phòng)',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: fullCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ chi tiết',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: cityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Thành phố',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: stateCtrl,
                          decoration: const InputDecoration(labelText: 'Tỉnh/Bang'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: zipCtrl,
                          decoration: const InputDecoration(labelText: 'Mã ZIP'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ✅ Đặt làm mặc định
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isDefault,
                    onChanged: (v) => setLocal(() => isDefault = v ?? false),
                    title: const Text('Đặt làm địa chỉ mặc định'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(isEdit ? Icons.save : Icons.add_location),
                      label: Text(isEdit ? 'Cập nhật địa chỉ' : 'Lưu địa chỉ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        if (fullCtrl.text.trim().isEmpty) {
                          _snack('Vui lòng nhập địa chỉ hợp lệ', ok: false);
                          return;
                        }

                        if (isEdit) {
                          await DBHelper.updateAddress(
                            id: address!['id'],
                            label: labelCtrl.text.trim(),
                            fullAddress: fullCtrl.text.trim(),
                            city: cityCtrl.text.trim(),
                            state: stateCtrl.text.trim(),
                            zipCode: zipCtrl.text.trim(),
                            isDefault: isDefault, // 👈 cập nhật mặc định
                          );
                          if (isDefault) {
                            await DBHelper.setDefaultAddress(widget.userId, address['id']);
                          }
                          _snack('Cập nhật địa chỉ thành công');
                        } else {
                          final newId = await DBHelper.addAddress(
                            userId: widget.userId,
                            label: labelCtrl.text.trim(),
                            fullAddress: fullCtrl.text.trim(),
                            city: cityCtrl.text.trim(),
                            state: stateCtrl.text.trim(),
                            zipCode: zipCtrl.text.trim(),
                            isDefault: isDefault, // 👈 lưu mặc định
                          );
                          if (isDefault) {
                            await DBHelper.setDefaultAddress(widget.userId, newId);
                          }
                          _snack('Thêm địa chỉ mới thành công');
                        }

                        if (!mounted) return;
                        Navigator.pop(context);
                        await _load();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> addr) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá địa chỉ'),
        content: const Text('Bạn có chắc chắn muốn xoá địa chỉ này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await DBHelper.deleteAddress(addr['id']);
      await _load();
      _snack('Đã xoá địa chỉ', ok: false);
    }
  }

  Future<void> _setDefault(Map<String, dynamic> a) async {
    await DBHelper.setDefaultAddress(widget.userId, a['id']);
    await _load();
    _snack('Đã đặt làm địa chỉ mặc định');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Địa chỉ giao hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined, color: Colors.redAccent),
            onPressed: () => _addOrEdit(),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
          ? const Center(child: Text('Chưa có địa chỉ nào. Hãy thêm mới!'))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: _addresses.length,
        itemBuilder: (_, i) {
          final a = _addresses[i];
          final isDefault = (a['isDefault'] ?? 0) == 1;
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDefault ? Colors.redAccent : Colors.grey[300]!,
              ),
            ),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context, a), // 👉 chọn địa chỉ trả về
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: isDefault ? true : null,
                          onChanged: (_) => _setDefault(a),
                          activeColor: Colors.redAccent,
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  a['label'] ?? 'Chưa đặt nhãn',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isDefault)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Mặc định',
                                      style: TextStyle(fontSize: 10, color: Colors.white)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(a['fullAddress'] ?? '',
                        style: const TextStyle(color: Colors.black87)),
                    if ((a['city'] ?? '').toString().isNotEmpty)
                      Text('${a['city']} ${a['state'] ?? ''} ${a['zipCode'] ?? ''}',
                          style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Sửa'),
                          onPressed: () => _addOrEdit(address: a),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.star, color: Colors.amber, size: 18),
                          label: const Text('Đặt mặc định'),
                          onPressed: isDefault ? null : () => _setDefault(a),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 18),
                          label: const Text('Xoá',
                              style: TextStyle(color: Colors.redAccent)),
                          onPressed: () => _delete(a),
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
    );
  }
}
