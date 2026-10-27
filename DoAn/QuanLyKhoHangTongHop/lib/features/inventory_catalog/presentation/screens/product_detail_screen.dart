import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/product_sku.dart';
import '../../../../core/providers/warehouse_providers.dart';
import '../../../../core/services/pdf_report_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../operations_stock_in/presentation/screens/create_stock_in_screen.dart';
import '../../../operations_stock_out/presentation/screens/create_stock_out_screen.dart';
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
        appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
        body: const Center(child: Text('Mặt hàng không tồn tại hoặc đã bị xóa')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        actions: [
          IconButton(
            tooltip: 'In tem nhãn mã vạch',
            icon: const Icon(Icons.print_outlined, color: Colors.white),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang tạo tem nhãn mã vạch nhiệt...')),
              );
              await PdfReportService.printBarcodeLabel(product);
            },
          ),
          IconButton(
            tooltip: 'Sửa sản phẩm',
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Image Container (Shopee Style)
            Container(
              color: Colors.white,
              width: double.infinity,
              height: 240,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => _buildHeroFallback(),
                        )
                      : _buildHeroFallback(),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.shopeeMallRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'BÁCH HÓA MAI HƯƠNG',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Vị trí: ${product.locationTag}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Shopee Price & Promotion Banner
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        '₫',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.shopeePrice,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        CurrencyFormatter.formatNumber(product.sellingPrice),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.shopeePrice,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.shopeeBadgeBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Lãi +${product.grossProfitMarginPercent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Vốn: ${CurrencyFormatter.formatVND(product.costPrice)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Product Title
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // SKU Code & Barcode
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SKU: ${product.skuCode}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.qr_code_2, size: 16, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 4),
                      Text(
                        product.barcode,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 3. Stock Level & Inventory Status Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Tình Trạng Tồn Kho Thực Tế',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stock progress bar
                  LinearProgressIndicator(
                    value: (product.currentStock / product.maxStock).clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFEEEEEE),
                    color: product.isLowStock ? AppColors.danger : AppColors.primary,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStockStat('Tồn hiện tại', '${product.currentStock} ${product.unit}', isBold: true),
                      _buildStockStat('Tồn tối thiểu', '${product.minSafetyStock} ${product.unit}'),
                      _buildStockStat('Sức chứa tối đa', '${product.maxStock} ${product.unit}'),
                    ],
                  ),

                  if (product.isLowStock) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.danger),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Cảnh báo: Mặt hàng đang dưới mức tồn an toàn. Hãy tạo phiếu nhập kho!',
                              style: TextStyle(fontSize: 11.5, color: AppColors.danger, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 4. Specifications & Date
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chi Tiết Thông Số Mặt Hàng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildSpecRow('Ngành hàng', product.categoryName),
                  _buildSpecRow('Đơn vị tính', product.unit),
                  _buildSpecRow('Vị trí lưu kho', product.locationTag),
                  _buildSpecRow('Hạn sử dụng (FEFO)', DateFormatter.formatDate(product.expiryDate)),
                  _buildSpecRow('Ngày tạo', DateFormatter.formatDateTime(product.createdAt)),
                  if (product.notes != null && product.notes!.isNotEmpty)
                    _buildSpecRow('Ghi chú nghiệp vụ', product.notes!),
                ],
              ),
            ),

            const SizedBox(height: 80), // Padding for bottom action bar
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateStockInScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Nhập Thêm Hàng'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateStockOutScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.point_of_sale, size: 18),
                  label: const Text('Bán / Xuất Kho'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroFallback() {
    return Container(
      color: const Color(0xFFFFF7ED),
      child: const Center(
        child: Icon(Icons.shopping_bag_outlined, size: 72, color: AppColors.primary),
      ),
    );
  }

  Widget _buildStockStat(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight)),
          ),
          Expanded(
            child: Text(val, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
          ),
        ],
      ),
    );
  }
}
