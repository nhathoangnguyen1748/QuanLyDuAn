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
  final TextEditingController _receiverController = TextEditingController(text: 'Khách hàng / Đại lý');
  final TextEditingController _destinationBranchController = TextEditingController(text: 'Kho Chi nhánh Quận 7');
  final TextEditingController _notesController = TextEditingController();

  StockOutType _selectedType = StockOutType.retail;
  final List<StockOutItemDraft> _draftItems = [];

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
          content: Text('${sku.name} đã hết hàng tồn kho (Tồn: 0)!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _draftItems.add(StockOutItemDraft(
        sku: sku,
        quantity: 1,
        unitPrice: _selectedType == StockOutType.transfer
            ? sku.costPrice
            : (_selectedType == StockOutType.wholesale ? sku.sellingPrice * 0.9 : sku.sellingPrice),
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
            content: Text('Không tìm thấy mã: $barcode'),
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
              const Text('Chọn mặt hàng xuất kho', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final p = products[i];
                    final isOutOfStock = p.currentStock <= 0;
                    return ListTile(
                      title: Text(p.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isOutOfStock ? Colors.grey : Colors.black)),
                      subtitle: Text('${p.skuCode} • Tồn: ${p.currentStock} ${p.unit} • Giá bán: ${CurrencyFormatter.formatVND(p.sellingPrice)}'),
                      trailing: isOutOfStock
                          ? const Text('Hết hàng', style: TextStyle(color: Colors.red, fontSize: 11))
                          : const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      onTap: isOutOfStock
                          ? null
                          : () {
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
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 sản phẩm xuất!'), backgroundColor: AppColors.danger),
      );
      return;
    }

    // Validate available stock
    for (final draft in _draftItems) {
      if (draft.quantity > draft.sku.currentStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mặt hàng "${draft.sku.name}" chỉ còn ${draft.sku.currentStock} ${draft.sku.unit} tồn kho, không thể xuất ${draft.quantity}!'),
            backgroundColor: AppColors.danger,
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
      destinationBranch: _selectedType == StockOutType.transfer ? _destinationBranchController.text.trim() : null,
      items: items,
      createdAt: DateTime.now(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    await ref.read(stockOutListProvider.notifier).addOrder(order);

    if (mounted) {
      final shouldPrint = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xuất kho thành công!'),
          content: Text('Đã tạo phiếu xuất ${order.orderNumber}. Bạn có muốn in phiếu xuất kho PDF ngay không?'),
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
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HÌNH THỨC XUẤT KHO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondaryLight)),
                    const SizedBox(height: 10),
                    SegmentedButton<StockOutType>(
                      segments: const [
                        ButtonSegment(value: StockOutType.retail, label: Text('Bán lẻ'), icon: Icon(Icons.person, size: 16)),
                        ButtonSegment(value: StockOutType.wholesale, label: Text('Bán sỉ'), icon: Icon(Icons.store, size: 16)),
                        ButtonSegment(value: StockOutType.transfer, label: Text('Điều chuyển'), icon: Icon(Icons.swap_horiz, size: 16)),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (set) {
                        setState(() {
                          _selectedType = set.first;
                          if (_selectedType == StockOutType.transfer) {
                            _receiverController.text = 'Kho Chi nhánh Nhận';
                          } else if (_selectedType == StockOutType.wholesale) {
                            _receiverController.text = 'Đại lý phân phối';
                          } else {
                            _receiverController.text = 'Khách mua lẻ';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _orderNumberController,
                            decoration: const InputDecoration(labelText: 'Số Phiếu Xuất *', isDense: true),
                            validator: (v) => v == null || v.isEmpty ? 'Nhập mã phiếu' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _receiverController,
                            decoration: InputDecoration(
                              labelText: _selectedType == StockOutType.transfer ? 'Chi nhánh nhận' : 'Khách hàng / Đơn vị nhận *',
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Nhập tên người nhận' : null,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedType == StockOutType.transfer) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _destinationBranchController,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ kho nhận hàng nội bộ *',
                          prefixIcon: Icon(Icons.location_on_outlined, size: 16),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Nhập địa chỉ chi nhánh nhận' : null,
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Ghi chú xuất kho', isDense: true),
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
                Text(
                  'MẶT HÀNG XUẤT (${_draftItems.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondaryLight),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _showProductPickerDialog,
                      icon: const Icon(Icons.list, size: 16),
                      label: const Text('Chọn hàng'),
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
                      const Icon(Icons.outbox, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('Chưa có mặt hàng nào trong phiếu xuất', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _scanBarcodeToAdd,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Quét Barcode Thêm Hàng'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_draftItems.length, (index) {
                final draft = _draftItems[index];
                final isStockExceeded = draft.quantity > draft.sku.currentStock;

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

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: '${draft.quantity}',
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'SL xuất (${draft.sku.unit})',
                                  isDense: true,
                                  errorText: isStockExceeded ? 'Vượt quá tồn (${draft.sku.currentStock})' : null,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    draft.quantity = int.tryParse(val) ?? 1;
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
                                decoration: const InputDecoration(labelText: 'Đơn giá xuất (VND)', isDense: true),
                                onChanged: (val) {
                                  setState(() {
                                    draft.unitPrice = double.tryParse(val) ?? 0.0;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Kệ lưu: ${draft.sku.locationTag} • Khả dụng: ${draft.sku.currentStock} ${draft.sku.unit}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                            Text('Thành tiền: ${CurrencyFormatter.formatVND(draft.quantity * draft.unitPrice)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),

            // Valuation card
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
                          const Text('Tổng số lượng xuất:'),
                          Text('${CurrencyFormatter.formatNumber(totalQty)} đơn vị', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng giá vốn (COGS):'),
                          Text(CurrencyFormatter.formatVND(totalCogs), style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ước tính lợi nhuận gộp:'),
                          Text(
                            CurrencyFormatter.formatVND(estimatedProfit),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: estimatedProfit >= 0 ? AppColors.success : AppColors.danger),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TỔNG GIÁ TRỊ XUẤT KHO:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(CurrencyFormatter.formatVND(totalRevenue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
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
              label: const Text('XÁC NHẬN XUẤT KHO & TRỪ TỒN'),
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
