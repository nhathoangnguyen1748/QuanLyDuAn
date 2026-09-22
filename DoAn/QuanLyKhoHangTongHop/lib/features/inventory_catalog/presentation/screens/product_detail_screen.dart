import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/product_sku.dart';
import 'package:smartstock_admin/core/providers/warehouse_providers.dart';
import 'package:smartstock_admin/core/services/pdf_report_service.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';
import 'package:smartstock_admin/core/utils/date_formatter.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productListProvider);
    final product = products.firstWhere(
      (p) => p.id == productId,
      orElse: () => ProductSKU(
        id: '',
        skuCode: '',
        barcode: '',
        name: 'Không tìm thấy sản phẩm',
        categoryId: '',
        categoryName: '',
        costPrice: 0,
        sellingPrice: 0,
        currentStock: 0,
        minSafetyStock: 0,
        maxStock: 0,
        locationTag: '',
        createdAt: DateTime.now(),
      ),
    );

    if (product.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết SKU')),
        body: const Center(child: Text('Mặt hàng không tồn tại hoặc đã bị xóa')),
      );
    }

    final grossMarginPercent = product.sellingPrice > 0
        ? ((product.sellingPrice - product.costPrice) / product.sellingPrice) * 100
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.skuCode, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'In Tem Barcode Kệ',
            icon: const Icon(Icons.print_outlined, color: AppColors.primary),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang tạo tem nhãn mã vạch nhiệt...')),
              );
              await PdfReportService.printBarcodeLabel(product);
            },
          ),
          IconButton(
            tooltip: 'Chỉnh sửa mặt hàng',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xác nhận xóa mặt hàng'),
                    content: Text('Bạn có chắc chắn muốn xóa "${product.name}" khỏi danh mục kho?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Xóa vĩnh viễn'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await ref.read(productListProvider.notifier).deleteProduct(product.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã xóa ${product.name}')),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                    SizedBox(width: 8),
                    Text('Xóa SKU này', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card with Category & Name
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.categoryName,
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.place, size: 14, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              product.locationTag,
                              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.qr_code, size: 16, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 6),
                      Text(
                        'Mã vạch: ${product.barcode}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                      ),
                      const Spacer(),
                      Text(
                        'Đơn vị: ${product.unit}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status alerts
          if (product.isLowStock)
            _buildAlertBanner(
              color: AppColors.danger,
              icon: Icons.warning_amber_rounded,
              title: 'CẢNH BÁO: Tồn kho dưới mức an toàn!',
              subtitle: 'Số lượng tồn (${product.currentStock}) <= Ngưỡng an toàn tối thiểu (${product.minSafetyStock}). Hãy tạo phiếu nhập kho bổ sung.',
            ),
          if (product.isExpiringSoon)
            _buildAlertBanner(
              color: AppColors.warning,
              icon: Icons.timer,
              title: 'CẢNH BÁO FEFO: Sắp hết hạn sử dụng!',
              subtitle: 'Hạn dùng: ${DateFormatter.formatDate(product.expiryDate)} (còn ${DateFormatter.daysUntilExpiry(product.expiryDate)} ngày). Ưu tiên xuất trước.',
            ),
          if (product.isExpired)
            _buildAlertBanner(
              color: AppColors.danger,
              icon: Icons.event_busy,
              title: 'NGUY HIỂM: Hàng đã quá hạn sử dụng!',
              subtitle: 'Hạn dùng: ${DateFormatter.formatDate(product.expiryDate)}. Cần cách ly tiêu hủy hoặc hoàn trả NCC.',
            ),
          if (product.isDeadStock)
            _buildAlertBanner(
              color: AppColors.accentAmber,
              icon: Icons.hourglass_bottom_rounded,
              title: 'CẢNH BÁO: Hàng tồn kho chậm luân chuyển (Dead Stock)',
              subtitle: 'Đã ${product.daysSinceLastMovement} ngày không có giao dịch xuất hàng. Cần kích cầu hoặc xả kho.',
            ),
          const SizedBox(height: 16),

          // Stock Level Indicators
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tình Trạng Tồn Kho Thực Tế', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStockMetric('Tồn Hiện Tại', '${product.currentStock}', product.isLowStock ? AppColors.danger : AppColors.primary),
                      _buildStockMetric('Định Mức Min', '${product.minSafetyStock}', AppColors.warning),
                      _buildStockMetric('Sức Chứa Max', '${product.maxStock}', AppColors.textSecondaryLight),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: product.maxStock > 0 ? (product.currentStock / product.maxStock).clamp(0.0, 1.0) : 0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(product.isLowStock ? AppColors.danger : AppColors.primary),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tỷ lệ lấp đầy sức chứa SKU: ${((product.currentStock / (product.maxStock > 0 ? product.maxStock : 1)) * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Financial Valuation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Định Giá & Biên Lợi Nhuận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 14),
                  _buildFinancialRow('Giá vốn MAC (Bình quân gia quyền):', CurrencyFormatter.formatVND(product.costPrice), isBold: false),
                  const SizedBox(height: 8),
                  _buildFinancialRow('Giá bán lẻ niêm yết:', CurrencyFormatter.formatVND(product.sellingPrice), isBold: false),
                  const SizedBox(height: 8),
                  _buildFinancialRow('Biên lợi nhuận gộp (Margin):', '${grossMarginPercent.toStringAsFixed(1)}%', color: AppColors.success),
                  const Divider(height: 20),
                  _buildFinancialRow('TỔNG GIÁ TRỊ VỐN TỒN KHO:', CurrencyFormatter.formatVND(product.totalInventoryValue), isBold: true, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Metadata Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông Tin Quản Lý Khác', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  _buildMetaRow('Vị trí lưu kho:', product.locationTag),
                  _buildMetaRow('Hạn sử dụng (FEFO):', DateFormatter.formatDate(product.expiryDate)),
                  _buildMetaRow('Ngày tạo mã:', DateFormatter.formatDateTime(product.createdAt)),
                  _buildMetaRow('Xuất hàng gần nhất:', DateFormatter.formatDateTime(product.lastStockOutDate)),
                  if (product.notes != null) _buildMetaRow('Ghi chú SKU:', product.notes!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: color.withValues(alpha: 0.85), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
      ],
    );
  }

  Widget _buildFinancialRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isBold ? 13 : 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
