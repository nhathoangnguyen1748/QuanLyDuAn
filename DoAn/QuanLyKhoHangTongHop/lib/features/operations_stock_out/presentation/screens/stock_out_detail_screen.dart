import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/stock_out_order.dart';
import 'package:smartstock_admin/core/services/pdf_report_service.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';
import 'package:smartstock_admin/core/utils/date_formatter.dart';

class StockOutDetailScreen extends StatelessWidget {
  final StockOutOrder order;

  const StockOutDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final double profit = order.totalRevenue - order.totalCogs;
    final double marginPercent = order.totalRevenue > 0 ? (profit / order.totalRevenue) * 100 : 0.0;

    Color typeColor;
    IconData typeIcon;
    if (order.type == StockOutType.transfer) {
      typeColor = AppColors.purple;
      typeIcon = Icons.swap_horiz;
    } else if (order.type == StockOutType.wholesale) {
      typeColor = AppColors.accent;
      typeIcon = Icons.store;
    } else {
      typeColor = AppColors.primary;
      typeIcon = Icons.person;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Sao chép mã phiếu',
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: order.orderNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã sao chép mã phiếu "${order.orderNumber}"'),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'In Phiếu Xuất Kho PDF',
            icon: const Icon(Icons.print_outlined, color: AppColors.primary),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang tạo phiếu xuất kho PDF...')),
              );
              await PdfReportService.printStockOutOrder(order);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Order Header Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            order.orderNumber,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeIcon, size: 13, color: typeColor),
                            const SizedBox(width: 4),
                            Text(
                              order.type.label,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: typeColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Icon(
                        order.type == StockOutType.transfer ? Icons.location_city : Icons.person_pin,
                        size: 16,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đơn vị nhận: ${order.receiverName}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  if (order.destinationBranch != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppColors.purple),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Kho nhận điều chuyển: ${order.destinationBranch}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.purple),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 8),
                      Text(
                        'Thời gian xuất: ${DateFormatter.formatDateTime(order.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 8),
                      Text(
                        'Thủ kho xuất hàng: ${order.createdBy}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Ghi chú: ${order.notes}',
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Items List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DANH SÁCH MẶT HÀNG XUẤT (${order.items.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryLight),
              ),
              Text(
                'Tổng: ${CurrencyFormatter.formatNumber(order.totalQuantity)} sp',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...order.items.map((item) {
            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.skuCode,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                          ),
                        ),
                        if (item.barcode.isNotEmpty)
                          Text('Barcode: ${item.barcode}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(item.skuName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Số lượng xuất: ${CurrencyFormatter.formatNumber(item.quantity)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('Đơn giá: ${CurrencyFormatter.formatVND(item.unitPrice)}', style: const TextStyle(fontSize: 12)),
                        Text(
                          'Thành tiền: ${CurrencyFormatter.formatVND(item.totalRevenue)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const Divider(height: 14),
                    // COGS vs Profit Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Giá vốn (COGS): ${CurrencyFormatter.formatVND(item.totalCogs)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                          if (order.type != StockOutType.transfer) ...[
                            Text(
                              'Lãi gộp: ${CurrencyFormatter.formatVND(item.profit)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: item.profit >= 0 ? AppColors.success : AppColors.danger,
                              ),
                            ),
                          ] else ...[
                            const Text(
                              'Điều chuyển nội bộ',
                              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.purple),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),

          // Total Summary Card
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
                      const Text('Tổng số lượng hàng:'),
                      Text(
                        '${CurrencyFormatter.formatNumber(order.totalQuantity)} đơn vị (${order.items.length} mặt hàng)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng giá vốn (COGS):'),
                      Text(
                        CurrencyFormatter.formatVND(order.totalCogs),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                  if (order.type != StockOutType.transfer) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Lợi nhuận gộp ước tính:'),
                        Row(
                          children: [
                            Text(
                              CurrencyFormatter.formatVND(profit),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: profit >= 0 ? AppColors.success : AppColors.danger,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (profit >= 0 ? AppColors.success : AppColors.danger).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${marginPercent.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: profit >= 0 ? AppColors.success : AppColors.danger,
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
                        order.type == StockOutType.transfer ? 'TỔNG GIÁ TRỊ ĐIỀU CHUYỂN:' : 'TỔNG DOANH THU XUẤT KHO:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        CurrencyFormatter.formatVND(order.totalRevenue),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () async {
              await PdfReportService.printStockOutOrder(order);
            },
            icon: const Icon(Icons.print),
            label: Text(
              order.type == StockOutType.transfer
                  ? 'IN BIÊN BẢN ĐIỀU CHUYỂN KHO (PDF)'
                  : 'IN PHIẾU XUẤT KHO / HÓA ĐƠN (PDF)',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
