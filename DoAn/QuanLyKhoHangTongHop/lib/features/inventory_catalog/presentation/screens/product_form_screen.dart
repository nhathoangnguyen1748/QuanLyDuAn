import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/product_sku.dart';
import 'package:smartstock_admin/core/providers/warehouse_providers.dart';
import 'package:smartstock_admin/core/utils/date_formatter.dart';
import 'package:smartstock_admin/features/scanner/presentation/barcode_scanner_sheet.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final ProductSKU? product;

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _skuCodeController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _nameController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _currentStockController;
  late final TextEditingController _minStockController;
  late final TextEditingController _maxStockController;
  late final TextEditingController _locationTagController;
  late final TextEditingController _unitController;
  late final TextEditingController _notesController;

  String? _selectedCategoryId;
  DateTime? _selectedExpiryDate;

  bool get isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _skuCodeController = TextEditingController(text: p?.skuCode ?? 'SKU-');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _nameController = TextEditingController(text: p?.name ?? '');
    _costPriceController = TextEditingController(text: p != null ? p.costPrice.toStringAsFixed(0) : '0');
    _sellingPriceController = TextEditingController(text: p != null ? p.sellingPrice.toStringAsFixed(0) : '0');
    _currentStockController = TextEditingController(text: p != null ? '${p.currentStock}' : '0');
    _minStockController = TextEditingController(text: p != null ? '${p.minSafetyStock}' : '10');
    _maxStockController = TextEditingController(text: p != null ? '${p.maxStock}' : '100');
    _locationTagController = TextEditingController(text: p?.locationTag ?? 'KHO-A-KAY-01');
    _unitController = TextEditingController(text: p?.unit ?? 'Cái');
    _notesController = TextEditingController(text: p?.notes ?? '');
    _selectedCategoryId = p?.categoryId;
    _selectedExpiryDate = p?.expiryDate;
  }

  @override
  void dispose() {
    _skuCodeController.dispose();
    _barcodeController.dispose();
    _nameController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _currentStockController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    _locationTagController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerSheet.scan(
      context,
      title: 'Quét Barcode cho mặt hàng',
    );
    if (barcode != null && barcode.isNotEmpty) {
      setState(() {
        _barcodeController.text = barcode;
      });
    }
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedExpiryDate = picked);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final categories = ref.read(categoryListProvider);
    final categoryId = _selectedCategoryId ?? (categories.isNotEmpty ? categories.first.id : 'CAT-ELC');
    final category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => categories.first,
    );

    final productToSave = ProductSKU(
      id: widget.product?.id ?? const Uuid().v4(),
      skuCode: _skuCodeController.text.trim().toUpperCase(),
      barcode: _barcodeController.text.trim(),
      name: _nameController.text.trim(),
      categoryId: category.id,
      categoryName: category.name,
      costPrice: double.tryParse(_costPriceController.text) ?? 0.0,
      sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0.0,
      currentStock: int.tryParse(_currentStockController.text) ?? 0,
      minSafetyStock: int.tryParse(_minStockController.text) ?? 0,
      maxStock: int.tryParse(_maxStockController.text) ?? 100,
      locationTag: _locationTagController.text.trim().toUpperCase(),
      unit: _unitController.text.trim(),
      expiryDate: _selectedExpiryDate,
      lastStockOutDate: widget.product?.lastStockOutDate,
      createdAt: widget.product?.createdAt ?? DateTime.now(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    await ref.read(productListProvider.notifier).saveProduct(productToSave);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditMode ? 'Đã cập nhật ${productToSave.name}' : 'Đã thêm mới mặt hàng ${productToSave.skuCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Chỉnh sửa mặt hàng' : 'Thêm mới SKU'),
        actions: [
          TextButton.icon(
            onPressed: _saveProduct,
            icon: const Icon(Icons.check, color: AppColors.primary),
            label: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Thông tin cơ bản
            const Text('THÔNG TIN ĐỊNH DANH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _skuCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Mã Quản Lý (SKU Code) *',
                      hintText: 'VD: SKU-ELC-001',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc nhập SKU' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _barcodeController,
                    decoration: InputDecoration(
                      labelText: 'Mã Vạch Barcode *',
                      hintText: 'EAN-13 / Code 128',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                        onPressed: _scanBarcode,
                        tooltip: 'Quét mã vạch camera',
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc có Barcode' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên Mặt Hàng / Sản Phẩm *',
                hintText: 'VD: Điện thoại iPhone 15 Pro Max 256GB',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc nhập tên sản phẩm' : null,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Ngành Hàng / Danh Mục'),
              items: categories.map((c) {
                return DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategoryId = val;
                });
              },
            ),
            const SizedBox(height: 20),

            // Vị trí lưu kho & Đơn vị tính
            const Text('VỊ TRÍ LƯU TRỮ & ĐƠN VỊ TÍNH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _locationTagController,
                    decoration: const InputDecoration(
                      labelText: 'Vị Trí Kệ (Aisle/Rack/Bin) *',
                      hintText: 'VD: KHO-A-KAY-03',
                      prefixIcon: Icon(Icons.place, size: 18),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc có vị trí kệ' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Đơn Vị Tính',
                      hintText: 'Cái, Thùng, Hộp, Can...',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Định mức số lượng tồn kho
            const Text('ĐỊNH MỨC SỐ LƯỢNG TỒN TRỮ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _currentStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tồn Kho Hiện Tại',
                      hintText: '0',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _minStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tồn Min An Toàn',
                      hintText: '10',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _maxStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sức Chứa Max',
                      hintText: '100',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Định giá & Giá vốn MAC
            const Text('ĐỊNH GIÁ & TÀI CHÍNH (VND)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá Vốn MAC (Nhập)',
                      suffixText: '₫',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sellingPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá Bán Lẻ Đề Xuất',
                      suffixText: '₫',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hạn sử dụng (FEFO) & Ghi chú
            const Text('QUẢN LÝ HẠN DÙNG (FEFO) & GHI CHÚ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 8),

            InkWell(
              onTap: _pickExpiryDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Hạn Sử Dụng (Nếu có - Quản lý theo FEFO)',
                  suffixIcon: _selectedExpiryDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _selectedExpiryDate = null),
                        )
                      : const Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(
                  _selectedExpiryDate != null
                      ? DateFormatter.formatDate(_selectedExpiryDate)
                      : 'Không có hạn sử dụng',
                  style: TextStyle(
                    color: _selectedExpiryDate != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi Chú SKU (Tùy chọn)',
                hintText: 'Nhà cung cấp chính, đặc tính bảo quản...',
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _saveProduct,
              icon: const Icon(Icons.save),
              label: Text(isEditMode ? 'LƯU CẬP NHẬT MẶT HÀNG' : 'TẠO MỚI MẶT HÀNG'),
            ),
          ],
        ),
      ),
    );
  }
}
