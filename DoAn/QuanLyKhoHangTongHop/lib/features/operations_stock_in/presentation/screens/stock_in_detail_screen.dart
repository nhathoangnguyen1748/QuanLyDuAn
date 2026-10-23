import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/stock_in_order.dart';
import 'package:smartstock_admin/core/services/pdf_report_service.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';
import 'package:smartstock_admin/core/utils/date_formatter.dart';

class StockInDetailScreen extends StatelessWidget {
  final StockInOrder order;

  const StockInDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
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
            tooltip: 'In Phiếu Nhập Kho PDF',
            icon: const Icon(Icons.print_outlined, color: AppColors.primary),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang tạo phiếu nhập kho PDF...')),
              );
              await PdfReportService.printStockInOrder(order);
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
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          order.status,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.business, size: 16, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nhà cung cấp: ${order.supplierName}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  if (order.supplierPhone != null && order.supplierPhone!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 8),
                        Text(
                          'Hotline: ${order.supplierPhone}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 8),
                      Text(
                        'Thời gian nhập: ${DateFormatter.formatDateTime(order.createdAt)}',
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
                        'Thủ kho thực hiện: ${order.createdBy}',
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
                'DANH SÁCH MẶT HÀNG NHẬP (${order.items.length})',
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
            final double priceDiff = item.macAfter - item.currentCostBefore;
            final double percentChange = item.currentCostBefore > 0
                ? (priceDiff / item.currentCostBefore) * 100
                : 0.0;

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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shelves, size: 12, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Text(
                                item.locationTag,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(item.skuName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    if (item.barcode.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Mã vạch: ${item.barcode}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    ],
                    if (item.expiryDate != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.event_available, size: 13, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            'Hạn sử dụng: ${DateFormatter.formatDate(item.expiryDate!)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Số lượng: ${CurrencyFormatter.formatNumber(item.quantity)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('Đơn giá nhập: ${CurrencyFormatter.formatVND(item.unitPrice)}', style: const TextStyle(fontSize: 12)),
                        Text(
                          'Thành tiền: ${CurrencyFormatter.formatVND(item.totalAmount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const Divider(height: 14),
                    // MAC impact badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Vốn cũ: ${CurrencyFormatter.formatVND(item.currentCostBefore)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.arrow_forward, size: 12, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Text(
                                'MAC mới: ${CurrencyFormatter.formatVND(item.macAfter)}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${percentChange >= 0 ? "+" : ""}${percentChange.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: percentChange > 0 ? AppColors.warning : AppColors.success,
                                ),
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
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TỔNG GIÁ TRỊ NHẬP KHO:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        CurrencyFormatter.formatVND(order.totalValue),
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
              await PdfReportService.printStockInOrder(order);
            },
            icon: const Icon(Icons.print),
            label: const Text('IN PHIẾU NHẬP KHO (PDF / MÁY IN NHIỆT)'),
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
