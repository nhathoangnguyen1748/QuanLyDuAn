import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/product_sku.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../screens/product_detail_screen.dart';

class ShopeeProductCard extends StatelessWidget {
  final ProductSKU product;
  final VoidCallback? onStockIn;
  final VoidCallback? onStockOut;

  const ShopeeProductCard({
    super.key,
    required this.product,
    this.onStockIn,
    this.onStockOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(productId: product.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Container with Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: AspectRatio(
                    aspectRatio: 1.25,
                    child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => _buildFallbackImage(),
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: const Color(0xFFFAFAFA),
                                child: const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  ),
                                ),
                              );
                            },
                          )
                        : _buildFallbackImage(),
                  ),
                ),
                // Shopee Mall / Official Badge
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.shopeeMallRed,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'BÁCH HÓA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Expiry or Low Stock Badge
                if (product.isLowStock || product.isExpiringSoon || product.isExpired)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: product.isExpired || product.isLowStock ? AppColors.danger : AppColors.warning,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        product.isExpired
                            ? 'HẾT HẠN'
                            : product.isLowStock
                                ? 'CẦN NHẬP'
                                : 'CẬN DATE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(7.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Name (Clean, full display without ...)
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                        height: 1.25,
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location Tag & Unit
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                border: Border.all(color: const Color(0xFF86EFAC), width: 0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                product.locationTag,
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'ĐVT: ${product.unit}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Selling Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              '₫',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.shopeePrice,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatNumber(product.sellingPrice),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.shopeePrice,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.shopeeBadgeBg,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                '+${product.grossProfitMarginPercent.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),

                        // Cost price & Stock quantity
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Vốn: ${CurrencyFormatter.formatCompactVND(product.costPrice)}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: AppColors.textMutedLight,
                              ),
                            ),
                            Text(
                              'Kho: ${product.currentStock}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: product.isLowStock ? AppColors.danger : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      color: const Color(0xFFFFF7ED),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(product.categoryId),
              size: 32,
              color: AppColors.primary.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 2),
            Text(
              product.categoryName,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String catId) {
    switch (catId) {
      case 'CAT-GRO':
        return Icons.rice_bowl;
      case 'CAT-BEV':
        return Icons.local_drink;
      case 'CAT-SPICE':
        return Icons.soup_kitchen;
      case 'CAT-SNACK':
        return Icons.cookie;
      case 'CAT-CHEM':
        return Icons.cleaning_services;
      case 'CAT-MILK':
        return Icons.breakfast_dining;
      default:
        return Icons.shopping_bag;
    }
  }
}
