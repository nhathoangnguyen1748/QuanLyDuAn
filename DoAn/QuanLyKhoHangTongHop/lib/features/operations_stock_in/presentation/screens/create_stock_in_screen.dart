import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/product_sku.dart';
import 'package:smartstock_admin/core/models/stock_in_order.dart';
import 'package:smartstock_admin/core/providers/warehouse_providers.dart';
import 'package:smartstock_admin/core/services/pdf_report_service.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';
import 'package:smartstock_admin/core/utils/date_formatter.dart';
import 'package:smartstock_admin/core/utils/inventory_math.dart';
import 'package:smartstock_admin/features/scanner/presentation/barcode_scanner_sheet.dart';

class CreateStockInScreen extends ConsumerStatefulWidget {
  final ProductSKU? preselectedSku;

  const CreateStockInScreen({super.key, this.preselectedSku});

  @override
  ConsumerState<CreateStockInScreen> createState() => _CreateStockInScreenState();
}

class _CreateStockInScreenState extends ConsumerState<CreateStockInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _orderNumberController = TextEditingController();
  final TextEditingController _supplierNameController = TextEditingController(text: 'Công ty Cổ phần Phân phối Quốc tế');
  final TextEditingController _supplierPhoneController = TextEditingController(text: '028 3822 6868');
  final TextEditingController _notesController = TextEditingController();

  final List<StockInItemDraft> _draftItems = [];

  static const List<String> _quickSuppliers = [
    'Công ty Cổ phần Phân phối Quốc tế',
    'Tập đoàn DigiWorld Việt Nam',
    'Công ty CP Bách Hóa Xanh',
    'Tổng kho Gia dụng Sunhouse',
  ];

  static const List<String> _quickLocations = [
    'KHO-A-KAY-01',
    'KHO-A-KAY-02',
    'KHO-A-KAY-03',
    'KHO-B-RACK-01',
    'KHO-B-RACK-02',
    'KHO-C-PALLET-01',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _orderNumberController.text = 'PNK-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.minute}${now.second}';

    if (widget.preselectedSku != null) {
      _addItemDraft(widget.preselectedSku!);
    }
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _supplierNameController.dispose();
    _supplierPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addItemDraft(ProductSKU sku) {
    // Nếu sản phẩm đã có trong phiếu, tăng số lượng lên 1
    final existingIndex = _draftItems.indexWhere((item) => item.sku.id == sku.id);
    if (existingIndex != -1) {
      setState(() {
        _draftItems[existingIndex].quantity += 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tăng số lượng ${sku.name} lên ${_draftItems[existingIndex].quantity}'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _draftItems.add(StockInItemDraft(
        sku: sku,
        quantity: 10,
        unitPrice: sku.costPrice,
        locationTag: sku.locationTag.isNotEmpty ? sku.locationTag : 'KHO-A-KAY-01',
        expiryDate: sku.expiryDate,
      ));
    });
  }

  Future<void> _scanBarcodeToAdd() async {
    final barcode = await BarcodeScannerSheet.scan(
      context,
      title: 'Quét Barcode nhập hàng',
      prompt: 'Quét mã vạch sản phẩm để thêm vào phiếu nhập kho',
    );

    if (barcode != null && barcode.isNotEmpty && mounted) {
      final product = ref.read(productListProvider.notifier).findByBarcode(barcode);
      if (product != null) {
        _addItemDraft(product);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chưa có mã hàng "$barcode" trong hệ thống.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showProductPickerDialog() {
    final allProducts = ref.read(productListProvider);
    final categories = ref.read(categoryListProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _ProductPickerSheet(
          products: allProducts,
          categories: categories,
          onSelected: (product) {
            Navigator.pop(ctx);
            _addItemDraft(product);
          },
        );
      },
    );
  }

  Future<void> _pickExpiryDate(StockInItemDraft draft) async {
    final initial = draft.expiryDate ?? DateTime.now().add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(DateTime.now()) ? DateTime.now() : initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      helpText: 'CHỌN HẠN SỬ DỤNG (FEFO)',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
    );

    if (picked != null) {
      setState(() {
        draft.expiryDate = picked;
      });
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_draftItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất 1 mặt hàng vào phiếu nhập!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Kiểm tra ràng buộc số lượng và đơn giá từng dòng
    for (final item in _draftItems) {
      if (item.quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mặt hàng "${item.sku.name}" phải có số lượng lớn hơn 0!'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
      if (item.unitPrice < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đơn giá của "${item.sku.name}" không thể nhỏ hơn 0!'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    final items = _draftItems.map((draft) {
      final mac = InventoryMath.calculateMAC(
        currentStock: draft.sku.currentStock,
        currentCostPrice: draft.sku.costPrice,
        newQuantity: draft.quantity,
        newUnitPrice: draft.unitPrice,
      );

      return StockInItem(
        skuId: draft.sku.id,
        skuCode: draft.sku.skuCode,
        skuName: draft.sku.name,
        barcode: draft.sku.barcode,
        quantity: draft.quantity,
        unitPrice: draft.unitPrice,
        locationTag: draft.locationTag.trim().isNotEmpty ? draft.locationTag.trim() : draft.sku.locationTag,
        currentCostBefore: draft.sku.costPrice,
        macAfter: mac,
        expiryDate: draft.expiryDate,
      );
    }).toList();

    final order = StockInOrder(
      id: const Uuid().v4(),
      orderNumber: _orderNumberController.text.trim(),
      supplierName: _supplierNameController.text.trim(),
      supplierPhone: _supplierPhoneController.text.trim().isEmpty ? null : _supplierPhoneController.text.trim(),
      items: items,
      createdAt: DateTime.now(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    await ref.read(stockInListProvider.notifier).addOrder(order);

    if (mounted) {
      final shouldPrint = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('Nhập kho thành công!'),
            ],
          ),
          content: Text(
            'Đã tạo phiếu nhập ${order.orderNumber} và cập nhật giá vốn bình quân (MAC) cho ${order.items.length} mặt hàng.\n\nBạn có muốn in phiếu nhập kho PDF ngay không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Để sau'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.print),
              label: const Text('In Phiếu PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );

      if (shouldPrint == true) {
        await PdfReportService.printStockInOrder(order);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalAmount = _draftItems.fold(0.0, (s, d) => s + (d.quantity * d.unitPrice));
    final int totalQty = _draftItems.fold(0, (s, d) => s + d.quantity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Phiếu Nhập Kho', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            tooltip: 'Quét Barcode thêm hàng',
            onPressed: _scanBarcodeToAdd,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Thông tin phiếu & Nhà cung cấp
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.business_center_outlined, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'THÔNG TIN ĐƠN VỊ CUNG CẤP',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _orderNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Số Phiếu Nhập *',
                              prefixIcon: Icon(Icons.receipt_outlined, size: 18),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Nhập mã phiếu' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _supplierPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'SĐT Nhà Cung Cấp',
                              prefixIcon: Icon(Icons.phone_outlined, size: 18),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _supplierNameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên Nhà Cung Cấp / Đối Tác *',
                        prefixIcon: Icon(Icons.business_outlined, size: 18),
                        isDense: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên nhà cung cấp' : null,
                    ),
                    const SizedBox(height: 8),
                    // Supplier quick chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text('Gợi ý NCC: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          ..._quickSuppliers.map((supplier) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(supplier, style: const TextStyle(fontSize: 10)),
                              backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              onPressed: () {
                                setState(() {
                                  _supplierNameController.text = supplier;
                                });
                              },
                            ),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú đơn hàng (Hợp đồng, số xe vận chuyển, v.v.)',
                        prefixIcon: Icon(Icons.note_alt_outlined, size: 18),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header danh sách mặt hàng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'MẶT HÀNG NHẬP (${_draftItems.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryLight),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _showProductPickerDialog,
                      icon: const Icon(Icons.list, size: 18),
                      label: const Text('Chọn từ kho'),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      onPressed: _scanBarcodeToAdd,
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: const Text('Quét mã'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_draftItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text(
                        'Chưa có mặt hàng nào trong phiếu nhập',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _showProductPickerDialog,
                            icon: const Icon(Icons.search),
                            label: const Text('Chọn từ danh sách'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _scanBarcodeToAdd,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Quét Barcode'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_draftItems.length, (index) {
                final draft = _draftItems[index];
                final newMAC = InventoryMath.calculateMAC(
                  currentStock: draft.sku.currentStock,
                  currentCostPrice: draft.sku.costPrice,
                  newQuantity: draft.quantity,
                  newUnitPrice: draft.unitPrice,
                );

                final double priceDiff = newMAC - draft.sku.costPrice;
                final double percentChange = draft.sku.costPrice > 0 ? (priceDiff / draft.sku.costPrice) * 100 : 0.0;

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Title Bar
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                draft.sku.skuCode,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                draft.sku.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Xóa khỏi phiếu',
                              icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                              onPressed: () => setState(() => _draftItems.removeAt(index)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Form nhập SL và Đơn giá kèm stepper
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Stepper Quantity
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Số lượng nhập (${draft.sku.unit}):',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.borderLight),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 16),
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
                                          padding: EdgeInsets.zero,
                                          onPressed: draft.quantity > 1
                                              ? () => setState(() => draft.quantity -= 1)
                                              : null,
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            key: ValueKey('qty_${draft.sku.id}_${draft.quantity}'),
                                            initialValue: '${draft.quantity}',
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            onChanged: (val) {
                                              final parsed = int.tryParse(val);
                                              if (parsed != null && parsed > 0) {
                                                setState(() => draft.quantity = parsed);
                                              }
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 16),
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
                                          padding: EdgeInsets.zero,
                                          onPressed: () => setState(() => draft.quantity += 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Unit Price
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Đơn giá nhập (VND):',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    initialValue: draft.unitPrice.toStringAsFixed(0),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      suffixText: 'đ',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    ),
                                    onChanged: (val) {
                                      final parsed = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
                                      if (parsed != null && parsed >= 0) {
                                        setState(() => draft.unitPrice = parsed);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Shelf Location Tag with quick presets
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: ValueKey('loc_${draft.sku.id}_${draft.locationTag}'),
                                initialValue: draft.locationTag,
                                decoration: InputDecoration(
                                  labelText: 'Vị trí kệ phân bổ (Aisle/Rack/Bin)',
                                  prefixIcon: const Icon(Icons.shelves, size: 18),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (val) => draft.locationTag = val.trim(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Quick location popup menu
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AppColors.primary),
                              tooltip: 'Chọn kệ mẫu',
                              onSelected: (loc) {
                                setState(() {
                                  draft.locationTag = loc;
                                });
                              },
                              itemBuilder: (ctx) => _quickLocations
                                  .map((loc) => PopupMenuItem(value: loc, child: Text(loc)))
                                  .toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Expiry Date (FEFO) Picker Chip
                        Row(
                          children: [
                            const Icon(Icons.event_outlined, size: 16, color: AppColors.textSecondaryLight),
                            const SizedBox(width: 6),
                            Text(
                              draft.expiryDate != null
                                  ? 'Hạn dùng: ${DateFormatter.formatDate(draft.expiryDate!)}'
                                  : 'Hạn sử dụng: Chưa thiết lập',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: draft.expiryDate != null ? FontWeight.bold : FontWeight.normal,
                                color: draft.expiryDate != null ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _pickExpiryDate(draft),
                              icon: const Icon(Icons.edit_calendar, size: 15),
                              label: Text(draft.expiryDate == null ? 'Đặt ngày' : 'Đổi ngày'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Live Moving Average Cost (MAC) calculation preview card
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.auto_graph, size: 15, color: AppColors.accent),
                                      SizedBox(width: 6),
                                      Text(
                                        'Dự toán Giá Vốn Bình Quân (MAC):',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: percentChange > 0
                                          ? AppColors.warning.withValues(alpha: 0.2)
                                          : (percentChange < 0 ? AppColors.success.withValues(alpha: 0.2) : Colors.grey.shade200),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${percentChange >= 0 ? "+" : ""}${percentChange.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: percentChange > 0
                                            ? AppColors.warning
                                            : (percentChange < 0 ? AppColors.success : Colors.grey.shade700),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Vốn cũ: ${CurrencyFormatter.formatVND(draft.sku.costPrice)} (Tồn ${draft.sku.currentStock})',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                                  ),
                                  const Icon(Icons.arrow_forward, size: 12, color: AppColors.accent),
                                  Text(
                                    'Vốn mới: ${CurrencyFormatter.formatVND(newMAC)} (Tổng ${draft.sku.currentStock + draft.quantity})',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),

            // Summary Card
            if (_draftItems.isNotEmpty)
              Card(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng số lượng nhập kho:'),
                          Text(
                            '${CurrencyFormatter.formatNumber(totalQty)} đơn vị (${_draftItems.length} mặt hàng)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TỔNG TIỀN PHIẾU NHẬP:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            CurrencyFormatter.formatVND(totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _submitOrder,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('XÁC NHẬN NHẬP KHO & CẬP NHẬT TỒN (MAC)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StockInItemDraft {
  final ProductSKU sku;
  int quantity;
  double unitPrice;
  String locationTag;
  DateTime? expiryDate;

  StockInItemDraft({
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.locationTag,
    this.expiryDate,
  });
}

/// Bottom Sheet chọn sản phẩm nhập kho với tìm kiếm tức thì
class _ProductPickerSheet extends StatefulWidget {
  final List<ProductSKU> products;
  final List<dynamic> categories;
  final ValueChanged<ProductSKU> onSelected;

  const _ProductPickerSheet({
    required this.products,
    required this.categories,
    required this.onSelected,
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = widget.products.where((p) {
      if (_selectedCategory != 'ALL' && p.categoryId != _selectedCategory) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchName = p.name.toLowerCase().contains(query);
        final matchCode = p.skuCode.toLowerCase().contains(query);
        final matchBarcode = p.barcode.toLowerCase().contains(query);
        return matchName || matchCode || matchBarcode;
      }
      return true;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chọn mặt hàng nhập kho',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên sản phẩm, mã SKU, barcode...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: const Text('Tất cả', style: TextStyle(fontSize: 11)),
                    selected: _selectedCategory == 'ALL',
                    onSelected: (_) => setState(() => _selectedCategory = 'ALL'),
                  ),
                ),
                ...widget.categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat.name, style: const TextStyle(fontSize: 11)),
                    selected: _selectedCategory == cat.id,
                    onSelected: (_) => setState(() => _selectedCategory = cat.id),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Products List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Không tìm thấy sản phẩm phù hợp', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
                        ),
                        title: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        subtitle: Text(
                          '${p.skuCode} • Kệ: ${p.locationTag} • Vốn hiện tại: ${CurrencyFormatter.formatVND(p.costPrice)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                        onTap: () => widget.onSelected(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
