import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/product_sku.dart';
import 'package:smartstock_admin/core/models/stock_in_order.dart';
import 'package:smartstock_admin/core/providers/warehouse_providers.dart';
import 'package:smartstock_admin/core/services/pdf_report_service.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';
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
    setState(() {
      _draftItems.add(StockInItemDraft(
        sku: sku,
        quantity: 10,
        unitPrice: sku.costPrice,
        locationTag: sku.locationTag,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã thêm ${product.name} vào phiếu')),
        );
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
    final products = ref.read(productListProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chọn mặt hàng nhập kho', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final p = products[i];
                    return ListTile(
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('${p.skuCode} • Kệ: ${p.locationTag} • Vốn hiện tại: ${CurrencyFormatter.formatVND(p.costPrice)}'),
                      trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      onTap: () {
                        Navigator.pop(ctx);
                        _addItemDraft(p);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_draftItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 mặt hàng vào phiếu nhập!'), backgroundColor: AppColors.danger),
      );
      return;
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
        locationTag: draft.locationTag,
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
          title: const Text('Nhập kho thành công!'),
          content: Text('Đã tạo phiếu nhập ${order.orderNumber}. Bạn có muốn in phiếu nhập kho PDF ngay không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Để sau'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.print),
              label: const Text('In Phiếu PDF'),
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
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('THÔNG TIN ĐƠN VỊ CUNG CẤP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondaryLight)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _orderNumberController,
                            decoration: const InputDecoration(labelText: 'Số Phiếu Nhập *', isDense: true),
                            validator: (v) => v == null || v.isEmpty ? 'Nhập mã phiếu' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _supplierPhoneController,
                            decoration: const InputDecoration(labelText: 'SĐT Nhà Cung Cấp', isDense: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _supplierNameController,
                      decoration: const InputDecoration(labelText: 'Tên Nhà Cung Cấp / Đối Tác *', isDense: true),
                      validator: (v) => v == null || v.isEmpty ? 'Nhập tên nhà cung cấp' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Ghi chú đơn hàng (Hợp đồng, số xe...)', isDense: true),
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
                Text(
                  'MẶT HÀNG NHẬP (${_draftItems.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondaryLight),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _showProductPickerDialog,
                      icon: const Icon(Icons.list, size: 16),
                      label: const Text('Chọn từ danh sách'),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      onPressed: _scanBarcodeToAdd,
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: const Text('Quét mã'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
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
                      const Text('Chưa có mặt hàng nào trong phiếu', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _scanBarcodeToAdd,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Quét Barcode Ngay'),
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

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(draft.sku.skuCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(draft.sku.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                              onPressed: () => setState(() => _draftItems.removeAt(index)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Form nhập SL và Đơn giá
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: '${draft.quantity}',
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: 'Số lượng (${draft.sku.unit})', isDense: true),
                                onChanged: (val) {
                                  setState(() {
                                    draft.quantity = int.tryParse(val) ?? 0;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: draft.unitPrice.toStringAsFixed(0),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Đơn giá nhập (VND)', isDense: true),
                                onChanged: (val) {
                                  setState(() {
                                    draft.unitPrice = double.tryParse(val) ?? 0.0;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Phân bổ kệ lưu trữ
                        TextFormField(
                          initialValue: draft.locationTag,
                          decoration: const InputDecoration(
                            labelText: 'Phân bổ Vị trí kệ (Aisle/Rack/Bin)',
                            prefixIcon: Icon(Icons.place, size: 16),
                            isDense: true,
                          ),
                          onChanged: (val) => draft.locationTag = val.trim(),
                        ),
                        const SizedBox(height: 10),

                        // Live Moving Average Cost (MAC) calculation preview
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Dự toán Giá Vốn Bình Quân Gia Quyền (MAC):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent)),
                                  Text(
                                    CurrencyFormatter.formatVND(newMAC),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Vốn cũ: ${CurrencyFormatter.formatVND(draft.sku.costPrice)} (Tồn ${draft.sku.currentStock}) ➔ Sau nhập: ${CurrencyFormatter.formatVND(newMAC)} (Tổng tồn ${draft.sku.currentStock + draft.quantity})',
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
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

            // Summary card
            if (_draftItems.isNotEmpty)
              Card(
                color: AppColors.primary.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng số lượng nhập:'),
                          Text('${CurrencyFormatter.formatNumber(totalQty)} đơn vị', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TỔNG TIỀN PHIẾU NHẬP:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(CurrencyFormatter.formatVND(totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
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
              label: const Text('XÁC NHẬN NHẬP KHO & CẬP NHẬT TỒN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
