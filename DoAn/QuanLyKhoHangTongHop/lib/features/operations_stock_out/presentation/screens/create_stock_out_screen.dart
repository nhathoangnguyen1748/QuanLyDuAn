import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/product_sku.dart';
import 'package:smartstock_admin/core/models/stock_out_order.dart';
import 'package:smartstock_admin/core/providers/warehouse_providers.dart';
import 'package:smartstock_admin/core/services/pdf_report_service.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';
import 'package:smartstock_admin/features/scanner/presentation/barcode_scanner_sheet.dart';

class CreateStockOutScreen extends ConsumerStatefulWidget {
  const CreateStockOutScreen({super.key});

  @override
  ConsumerState<CreateStockOutScreen> createState() => _CreateStockOutScreenState();
}

class _CreateStockOutScreenState extends ConsumerState<CreateStockOutScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _orderNumberController = TextEditingController();
  final TextEditingController _receiverController = TextEditingController(text: 'Khách mua lẻ');
  final TextEditingController _destinationBranchController = TextEditingController(text: 'Kho Chi nhánh Quận 7');
  final TextEditingController _notesController = TextEditingController();

  StockOutType _selectedType = StockOutType.retail;
  final List<StockOutItemDraft> _draftItems = [];

  static const List<String> _quickBranches = [
    'Chi nhánh Hà Nội - Cầu Giấy',
    'Chi nhánh Đà Nẵng - Hải Châu',
    'Chi nhánh Cần Thơ - Ninh Kiều',
    'Kho Phụ Bình Dương - Dĩ An',
    'Kho Chi nhánh Quận 7 - TP.HCM',
  ];

  static const List<String> _quickReceiversRetail = [
    'Khách mua lẻ tại quầy',
    'Khách đặt qua Website / App',
    'Khách VIP thân thiết',
  ];

  static const List<String> _quickReceiversWholesale = [
    'Đại lý Phân phối Cấp 1 Miền Nam',
    'Hệ thống Siêu thị Tiêu dùng',
    'Công ty TNHH Bán lẻ Toàn Cầu',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _orderNumberController.text = 'PXK-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.minute}${now.second}';
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _receiverController.dispose();
    _destinationBranchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addItemDraft(ProductSKU sku) {
    if (sku.currentStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mặt hàng "${sku.name}" đã hết tồn kho (Tồn: 0)!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final existingIndex = _draftItems.indexWhere((i) => i.sku.id == sku.id);
    if (existingIndex != -1) {
      final existing = _draftItems[existingIndex];
      if (existing.quantity >= sku.currentStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Đã đạt giới hạn tồn khả dụng của "${sku.name}" (${sku.currentStock} ${sku.unit})!'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
      setState(() {
        existing.quantity += 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tăng số lượng "${sku.name}" lên ${existing.quantity}'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    double defaultPrice;
    if (_selectedType == StockOutType.transfer) {
      defaultPrice = sku.costPrice; // Điều chuyển nội bộ theo giá vốn MAC
    } else if (_selectedType == StockOutType.wholesale) {
      defaultPrice = sku.sellingPrice * 0.9; // Bán sỉ chiết khấu 10%
    } else {
      defaultPrice = sku.sellingPrice; // Bán lẻ giá niêm yết
    }

    setState(() {
      _draftItems.add(StockOutItemDraft(
        sku: sku,
        quantity: 1,
        unitPrice: defaultPrice,
      ));
    });
  }

  Future<void> _scanBarcodeToAdd() async {
    final barcode = await BarcodeScannerSheet.scan(
      context,
      title: 'Quét Barcode xuất kho',
      prompt: 'Quét mã vạch sản phẩm để xuất kho',
    );

    if (barcode != null && barcode.isNotEmpty && mounted) {
      final product = ref.read(productListProvider.notifier).findByBarcode(barcode);
      if (product != null) {
        _addItemDraft(product);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không tìm thấy mã vạch "$barcode" trong hệ thống!'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showProductPickerDialog() {
    final products = ref.read(productListProvider);
    final categories = ref.read(categoryListProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _StockOutProductPickerSheet(
          products: products,
          categories: categories,
          onSelected: (product) {
            Navigator.pop(ctx);
            _addItemDraft(product);
          },
        );
      },
    );
  }

  void _onTypeChanged(StockOutType newType) {
    setState(() {
      _selectedType = newType;
      if (newType == StockOutType.transfer) {
        _receiverController.text = 'Kho Chi nhánh Nhận';
        for (final draft in _draftItems) {
          draft.unitPrice = draft.sku.costPrice;
        }
      } else if (newType == StockOutType.wholesale) {
        _receiverController.text = 'Đại lý phân phối cấp 1';
        for (final draft in _draftItems) {
          draft.unitPrice = draft.sku.sellingPrice * 0.9;
        }
      } else {
        _receiverController.text = 'Khách mua lẻ tại quầy';
        for (final draft in _draftItems) {
          draft.unitPrice = draft.sku.sellingPrice;
        }
      }
    });
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_draftItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 mặt hàng vào phiếu xuất!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // CHẶN XUẤT ÂM KHO NGHIÊM NGẶT
    for (final draft in _draftItems) {
      if (draft.quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Số lượng xuất của "${draft.sku.name}" phải lớn hơn 0!'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
      if (draft.quantity > draft.sku.currentStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ CHẶN XUẤT ÂM KHO: Mặt hàng "${draft.sku.name}" chỉ còn ${draft.sku.currentStock} ${draft.sku.unit} tồn kho, không thể xuất ${draft.quantity}!',
            ),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    final items = _draftItems.map((draft) {
      return StockOutItem(
        skuId: draft.sku.id,
        skuCode: draft.sku.skuCode,
        skuName: draft.sku.name,
        barcode: draft.sku.barcode,
        quantity: draft.quantity,
        unitPrice: draft.unitPrice,
        costPrice: draft.sku.costPrice,
      );
    }).toList();

    final order = StockOutOrder(
      id: const Uuid().v4(),
      orderNumber: _orderNumberController.text.trim(),
      type: _selectedType,
      receiverName: _receiverController.text.trim(),
      destinationBranch: _selectedType == StockOutType.transfer
          ? _destinationBranchController.text.trim()
          : null,
      items: items,
      createdAt: DateTime.now(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    await ref.read(stockOutListProvider.notifier).addOrder(order);

    if (mounted) {
      final shouldPrint = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('Xuất kho thành công!'),
            ],
          ),
          content: Text(
            'Đã tạo phiếu xuất ${order.orderNumber} (${order.type.label}) và trừ tồn kho cho ${order.items.length} mặt hàng.\n\nBạn có muốn in phiếu xuất kho / biên bản giao nhận ngay không?',
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
        await PdfReportService.printStockOutOrder(order);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalRevenue = _draftItems.fold(0.0, (s, d) => s + (d.quantity * d.unitPrice));
    final double totalCogs = _draftItems.fold(0.0, (s, d) => s + (d.quantity * d.sku.costPrice));
    final double estimatedProfit = totalRevenue - totalCogs;
    final double profitMargin = totalRevenue > 0 ? (estimatedProfit / totalRevenue) * 100 : 0.0;
    final int totalQty = _draftItems.fold(0, (s, d) => s + d.quantity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Phiếu Xuất Kho', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            tooltip: 'Quét Barcode xuất',
            onPressed: _scanBarcodeToAdd,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Mode selector (Retail, Wholesale, Transfer)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.alt_route, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'HÌNH THỨC XUẤT KHO',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<StockOutType>(
                      segments: const [
                        ButtonSegment(
                          value: StockOutType.retail,
                          label: Text('Bán lẻ'),
                          icon: Icon(Icons.person, size: 16),
                        ),
                        ButtonSegment(
                          value: StockOutType.wholesale,
                          label: Text('Bán sỉ'),
                          icon: Icon(Icons.store, size: 16),
                        ),
                        ButtonSegment(
                          value: StockOutType.transfer,
                          label: Text('Điều chuyển'),
                          icon: Icon(Icons.swap_horiz, size: 16),
                        ),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (set) => _onTypeChanged(set.first),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _orderNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Số Phiếu Xuất *',
                              prefixIcon: Icon(Icons.receipt_outlined, size: 18),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Nhập mã phiếu' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 4,
                          child: TextFormField(
                            controller: _receiverController,
                            decoration: InputDecoration(
                              labelText: _selectedType == StockOutType.transfer
                                  ? 'Đơn vị / Bộ phận nhận'
                                  : 'Khách hàng / Đại lý nhận *',
                              prefixIcon: const Icon(Icons.person_pin_outlined, size: 18),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên người nhận' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Quick receiver presets
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text('Gợi ý: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          ...(_selectedType == StockOutType.wholesale
                                  ? _quickReceiversWholesale
                                  : _quickReceiversRetail)
                              .map((rec) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ActionChip(
                                      label: Text(rec, style: const TextStyle(fontSize: 10)),
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                                      onPressed: () => setState(() => _receiverController.text = rec),
                                    ),
                                  )),
                        ],
                      ),
                    ),

                    if (_selectedType == StockOutType.transfer) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _destinationBranchController,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ kho nhận hàng nội bộ *',
                          prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nhập địa chỉ chi nhánh nhận' : null,
                      ),
                      const SizedBox(height: 8),
                      // Branch quick selector
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Text('Chi nhánh: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                            ..._quickBranches.map((branch) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ActionChip(
                                    label: Text(branch, style: const TextStyle(fontSize: 10)),
                                    backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                                    onPressed: () => setState(() => _destinationBranchController.text = branch),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú xuất kho (Số phiếu giao nhận, tài xế, v.v.)',
                        prefixIcon: Icon(Icons.note_alt_outlined, size: 18),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Products Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.outbox, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'MẶT HÀNG XUẤT (${_draftItems.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryLight),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _showProductPickerDialog,
                      icon: const Icon(Icons.list, size: 18),
                      label: const Text('Chọn hàng'),
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
                      const Icon(Icons.outbox_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text(
                        'Chưa có mặt hàng nào trong phiếu xuất',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _showProductPickerDialog,
                            icon: const Icon(Icons.search),
                            label: const Text('Chọn từ kho'),
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
                final isOverStock = draft.quantity > draft.sku.currentStock;
                final bool isBelowCost = _selectedType != StockOutType.transfer && draft.unitPrice < draft.sku.costPrice;

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: isOverStock
                        ? const BorderSide(color: AppColors.danger, width: 1.5)
                        : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

                        // Form nhập SL xuất kèm Stepper chặn vượt tồn kho
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'SL xuất (${draft.sku.unit}):',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        'Tồn: ${draft.sku.currentStock}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isOverStock ? AppColors.danger : AppColors.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isOverStock ? AppColors.danger : AppColors.borderLight,
                                        width: isOverStock ? 1.5 : 1.0,
                                      ),
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
                                            key: ValueKey('out_qty_${draft.sku.id}_${draft.quantity}'),
                                            initialValue: '${draft.quantity}',
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: isOverStock ? AppColors.danger : Colors.black,
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            onChanged: (val) {
                                              final parsed = int.tryParse(val);
                                              if (parsed != null) {
                                                setState(() => draft.quantity = parsed);
                                              }
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 16),
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
                                          padding: EdgeInsets.zero,
                                          tooltip: draft.quantity >= draft.sku.currentStock
                                              ? 'Đã đạt giới hạn tồn khả dụng'
                                              : 'Tăng số lượng',
                                          // CHẶN STEPPER VƯỢT QUÁ TỒN HIỆN TẠI
                                          onPressed: draft.quantity < draft.sku.currentStock
                                              ? () => setState(() => draft.quantity += 1)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Unit Selling Price
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedType == StockOutType.transfer ? 'Giá vốn điều chuyển:' : 'Đơn giá xuất (VND):',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    key: ValueKey('out_price_${draft.sku.id}_${_selectedType.name}'),
                                    initialValue: draft.unitPrice.toStringAsFixed(0),
                                    readOnly: _selectedType == StockOutType.transfer,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      suffixText: 'đ',
                                      filled: _selectedType == StockOutType.transfer,
                                      fillColor: _selectedType == StockOutType.transfer ? Colors.grey.shade100 : null,
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

                        // Cảnh báo xuất quá tồn kho nếu gõ tay
                        if (isOverStock) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, size: 14, color: AppColors.danger),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Vượt quá số lượng tồn kho khả dụng (${draft.sku.currentStock} ${draft.sku.unit})!',
                                    style: const TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Cảnh báo bán dưới giá vốn (Below-cost selling warning)
                        if (isBelowCost) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Cảnh báo: Đơn giá xuất thấp hơn giá vốn (${CurrencyFormatter.formatVND(draft.sku.costPrice)}) - Nguy cơ lỗ!',
                                    style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Kệ: ${draft.sku.locationTag} • Giá vốn: ${CurrencyFormatter.formatVND(draft.sku.costPrice)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                            ),
                            Text(
                              'Thành tiền: ${CurrencyFormatter.formatVND(draft.quantity * draft.unitPrice)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),

            // Financial Valuation Card
            if (_draftItems.isNotEmpty)
              Card(
                elevation: 1,
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng số lượng xuất:'),
                          Text(
                            '${CurrencyFormatter.formatNumber(totalQty)} đơn vị (${_draftItems.length} mặt hàng)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng giá vốn hàng bán (COGS):'),
                          Text(
                            CurrencyFormatter.formatVND(totalCogs),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                      if (_selectedType != StockOutType.transfer) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ước tính Lợi nhuận gộp:'),
                            Row(
                              children: [
                                Text(
                                  CurrencyFormatter.formatVND(estimatedProfit),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: estimatedProfit >= 0 ? AppColors.success : AppColors.danger,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (estimatedProfit >= 0 ? AppColors.success : AppColors.danger).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${profitMargin.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: estimatedProfit >= 0 ? AppColors.success : AppColors.danger,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedType == StockOutType.transfer ? 'TỔNG GIÁ TRỊ ĐIỀU CHUYỂN:' : 'TỔNG DOANH THU XUẤT KHO:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            CurrencyFormatter.formatVND(totalRevenue),
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
              label: Text(
                _selectedType == StockOutType.transfer
                    ? 'XÁC NHẬN ĐIỀU CHUYỂN & TRỪ TỒN KHO'
                    : 'XÁC NHẬN XUẤT KHO & TRỪ TỒN KHO',
              ),
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

class StockOutItemDraft {
  final ProductSKU sku;
  int quantity;
  double unitPrice;

  StockOutItemDraft({
    required this.sku,
    required this.quantity,
    required this.unitPrice,
  });
}

/// Bottom Sheet chọn sản phẩm xuất kho có tìm kiếm và chặn sản phẩm hết tồn
class _StockOutProductPickerSheet extends StatefulWidget {
  final List<ProductSKU> products;
  final List<dynamic> categories;
  final ValueChanged<ProductSKU> onSelected;

  const _StockOutProductPickerSheet({
    required this.products,
    required this.categories,
    required this.onSelected,
  });

  @override
  State<_StockOutProductPickerSheet> createState() => _StockOutProductPickerSheetState();
}

class _StockOutProductPickerSheetState extends State<_StockOutProductPickerSheet> {
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
                'Chọn mặt hàng xuất kho',
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
              hintText: 'Tìm theo tên, mã SKU, barcode...',
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
                      final isOutOfStock = p.currentStock <= 0;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        leading: CircleAvatar(
                          backgroundColor: isOutOfStock
                              ? Colors.grey.shade200
                              : AppColors.primary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.outbox,
                            color: isOutOfStock ? Colors.grey : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          p.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isOutOfStock ? Colors.grey : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          '${p.skuCode} • Tồn: ${p.currentStock} ${p.unit} • Giá bán: ${CurrencyFormatter.formatVND(p.sellingPrice)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isOutOfStock ? Colors.grey : AppColors.textSecondaryLight,
                          ),
                        ),
                        trailing: isOutOfStock
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Hết hàng',
                                  style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              )
                            : const Icon(Icons.add_circle_outline, color: AppColors.primary),
                        onTap: isOutOfStock ? null : () => widget.onSelected(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
