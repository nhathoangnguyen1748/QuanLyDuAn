import 'package:flutter/material.dart';
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.orderNumber,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.status,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Nhà cung cấp: ${order.supplierName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (order.supplierPhone != null)
                    Text('Điện thoại: ${order.supplierPhone}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 6),
                  Text('Thời gian nhập: ${DateFormatter.formatDateTime(order.createdAt)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                  Text('Thủ kho thực hiện: ${order.createdBy}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                  if (order.notes != null) ...[
                    const SizedBox(height: 6),
                    Text('Ghi chú: ${order.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Items List
          Text(
            'DANH SÁCH MẶT HÀNG NHẬP (${order.items.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 8),

          ...order.items.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.skuCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Text(
                          'Kệ: ${item.locationTag}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.skuName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Số lượng: ${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Đơn giá: ${CurrencyFormatter.formatVND(item.unitPrice)}', style: const TextStyle(fontSize: 12)),
                        Text('Thành tiền: ${CurrencyFormatter.formatVND(item.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Vốn cũ: ${CurrencyFormatter.formatVND(item.currentCostBefore)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                        Text('➔ Giá vốn MAC mới: ${CurrencyFormatter.formatVND(item.macAfter)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // Total Summary Card
          Card(
            color: AppColors.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng số lượng:'),
                      Text('${CurrencyFormatter.formatNumber(order.totalQuantity)} đơn vị', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TỔNG GIÁ TRỊ NHẬP:'),
                      Text(CurrencyFormatter.formatVND(order.totalValue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () async {
              await PdfReportService.printStockInOrder(order);
            },
            icon: const Icon(Icons.print),
            label: const Text('IN PHIẾU NHẬP KHO (PDF / MÁY IN NHIỆT)'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
      ),
    );
  }
}
