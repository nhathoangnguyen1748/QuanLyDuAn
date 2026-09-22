import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
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
                          color: AppColors.primaryLight.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.type.label,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryLight),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Bên nhận: ${order.receiverName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (order.destinationBranch != null)
                    Text('Địa chỉ chi nhánh: ${order.destinationBranch}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 6),
                  Text('Thời gian xuất: ${DateFormatter.formatDateTime(order.createdAt)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                  Text('Thủ kho xuất: ${order.createdBy}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
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
            'DANH SÁCH MẶT HÀNG XUẤT (${order.items.length})',
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
                        Text('Mã vạch: ${item.barcode}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.skuName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Số lượng: ${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Đơn giá xuất: ${CurrencyFormatter.formatVND(item.unitPrice)}', style: const TextStyle(fontSize: 12)),
                        Text('Thành tiền: ${CurrencyFormatter.formatVND(item.totalRevenue)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Giá vốn xuất (COGS): ${CurrencyFormatter.formatVND(item.totalCogs)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                        Text('Lãi gộp: ${CurrencyFormatter.formatVND(item.profit)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
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
                      const Text('TỔNG GIÁ TRỊ XUẤT:'),
                      Text(CurrencyFormatter.formatVND(order.totalRevenue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () async {
              await PdfReportService.printStockOutOrder(order);
            },
            icon: const Icon(Icons.print),
            label: const Text('IN PHIẾU XUẤT KHO / BIÊN BẢN GIAO HÀNG'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
      ),
    );
  }
}
