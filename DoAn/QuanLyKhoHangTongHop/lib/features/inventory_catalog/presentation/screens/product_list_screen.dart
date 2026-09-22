import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/product_sku.dart';
import 'package:smartstock_admin/core/providers/warehouse_providers.dart';
import 'package:smartstock_admin/core/services/excel_export_service.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';
import 'package:smartstock_admin/core/utils/date_formatter.dart';
import 'package:smartstock_admin/features/scanner/presentation/barcode_scanner_sheet.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
  String _selectedFilter = 'ALL'; // 'ALL', 'LOW_STOCK', 'EXPIRING', 'DEAD_STOCK'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListProvider);
    final categories = ref.watch(categoryListProvider);

    // Apply filters
    List<ProductSKU> filtered = products.where((p) {
      if (_selectedCategoryId != null && p.categoryId != _selectedCategoryId) {
        return false;
      }

      if (_selectedFilter == 'LOW_STOCK' && !p.isLowStock) return false;
      if (_selectedFilter == 'EXPIRING' && !p.isExpiringSoon && !p.isExpired) return false;
      if (_selectedFilter == 'DEAD_STOCK' && !p.isDeadStock) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = p.name.toLowerCase().contains(q);
        final matchSku = p.skuCode.toLowerCase().contains(q);
        final matchBarcode = p.barcode.contains(q);
        final matchLoc = p.locationTag.toLowerCase().contains(q);
        return matchName || matchSku || matchBarcode || matchLoc;
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh Mục Tồn Kho', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Quét Barcode tìm kiếm',
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            onPressed: () async {
              final barcode = await BarcodeScannerSheet.scan(context);
              if (barcode != null && barcode.isNotEmpty) {
                setState(() {
                  _searchController.text = barcode;
                  _searchQuery = barcode;
                });
              }
            },
          ),
          IconButton(
            tooltip: 'Xuất file Excel tồn kho',
            icon: const Icon(Icons.file_download_outlined, color: AppColors.primary),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang xuất danh mục tồn kho ra Excel...')),
              );
              await ExcelExportService.exportInventory(products);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo Tên, SKU, Barcode, Vị trí kệ...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // Horizontal Category Filter
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('Tất cả ngành hàng', null),
                ...categories.map((c) => _buildCategoryChip(c.name, c.id)),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Status Filter Tabs
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildStatusChip('Tất cả', 'ALL'),
                _buildStatusChip('Cảnh báo tồn thiếu', 'LOW_STOCK', color: AppColors.danger),
                _buildStatusChip('Hạn dùng (FEFO)', 'EXPIRING', color: AppColors.warning),
                _buildStatusChip('Chậm luân chuyển', 'DEAD_STOCK', color: AppColors.accentAmber),
              ],
            ),
          ),
          const Divider(height: 16),

          // Count summary bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hiển thị: ${filtered.length} / ${products.length} mặt hàng',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
                ),
                Text(
                  'Tổng vốn: ${CurrencyFormatter.formatCompactVND(filtered.fold(0.0, (s, p) => s + p.totalInventoryValue))}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('Không tìm thấy mặt hàng phù hợp', style: TextStyle(color: Colors.grey)),
                        if (_searchQuery.isNotEmpty || _selectedCategoryId != null || _selectedFilter != 'ALL')
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedCategoryId = null;
                                _selectedFilter = 'ALL';
                              });
                            },
                            child: const Text('Xóa toàn bộ bộ lọc'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      return _buildProductCard(p);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm SKU Mới'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? categoryId) {
    final isSelected = _selectedCategoryId == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategoryId = categoryId);
        },
      ),
    );
  }

  Widget _buildStatusChip(String label, String code, {Color? color}) {
    final isSelected = _selectedFilter == code;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : (color ?? AppColors.textPrimaryLight),
          ),
        ),
        selected: isSelected,
        selectedColor: color ?? AppColors.primary,
        onSelected: (selected) {
          if (selected) setState(() => _selectedFilter = code);
        },
      ),
    );
  }

  Widget _buildProductCard(ProductSKU p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top line: SKU Code, Location Tag, Category
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.skuCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.locationTag,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    p.categoryName,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Product Name
              Text(
                p.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Barcode
              Row(
                children: [
                  const Icon(Icons.qr_code, size: 14, color: AppColors.textMutedLight),
                  const SizedBox(width: 4),
                  Text(
                    p.barcode,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stock and Financial metrics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Tồn: ',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                          Text(
                            '${CurrencyFormatter.formatNumber(p.currentStock)} ${p.unit}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: p.isLowStock ? AppColors.danger : AppColors.primary,
                            ),
                          ),
                          if (p.isLowStock)
                            Text(
                              ' (Min: ${p.minSafetyStock})',
                              style: const TextStyle(fontSize: 11, color: AppColors.danger),
                            ),
                        ],
                      ),
                      Text(
                        'Vốn MAC: ${CurrencyFormatter.formatVND(p.costPrice)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Giá trị tồn',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMutedLight),
                      ),
                      Text(
                        CurrencyFormatter.formatCompactVND(p.totalInventoryValue),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),

              // Status badges if any
              if (p.isLowStock || p.isExpiringSoon || p.isExpired || p.isDeadStock) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (p.isLowStock)
                      _buildMiniBadge('Thiếu tồn an toàn', AppColors.danger),
                    if (p.isExpired)
                      _buildMiniBadge('Đã hết hạn', AppColors.danger),
                    if (p.isExpiringSoon)
                      _buildMiniBadge('Cận date (${DateFormatter.daysUntilExpiry(p.expiryDate)} ngày)', AppColors.warning),
                    if (p.isDeadStock)
                      _buildMiniBadge('Chậm luân chuyển', AppColors.accentAmber),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
