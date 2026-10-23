import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/product_sku.dart';
import '../../../../core/providers/warehouse_providers.dart';
import '../../../../core/services/excel_export_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../scanner/presentation/barcode_scanner_sheet.dart';
import '../widgets/shopee_product_card.dart';
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
  bool _isGridView = true; // Default: Shopee 2-column Grid

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String s) {
    const withDia = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const withoutDia = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    var res = s.toLowerCase();
    for (int i = 0; i < withDia.length; i++) {
      res = res.replaceAll(withDia[i], withoutDia[i]);
    }
    return res;
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
        final q = _searchQuery.toLowerCase().trim();
        final qNorm = _normalize(q);
        final nameNorm = _normalize(p.name);
        final matchName = p.name.toLowerCase().contains(q) || nameNorm.contains(qNorm);
        final matchSku = p.skuCode.toLowerCase().contains(q);
        final matchBarcode = p.barcode.contains(q);
        final matchLoc = p.locationTag.toLowerCase().contains(q) || _normalize(p.locationTag).contains(qNorm);
        return matchName || matchSku || matchBarcode || matchLoc;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Bách Hóa Mai Hương', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        elevation: 0,
        actions: [
          // Toggle View: Grid vs List
          IconButton(
            tooltip: _isGridView ? 'Xem danh sách' : 'Xem dạng lưới Shopee',
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, color: Colors.white),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          // Export Excel
          IconButton(
            tooltip: 'Xuất file Excel tồn kho',
            icon: const Icon(Icons.file_download_outlined, color: Colors.white),
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
          // Shopee-style Search Header
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryLight),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sản phẩm, mã vạch, vị trí kệ...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMutedLight),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      IconButton(
                        tooltip: 'Quét Barcode Camera',
                        icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 20),
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
                    ],
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),
          ),

          // Horizontal Category Filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildCategoryChip('Tất cả ngành hàng', null),
                  ...categories.map((c) => _buildCategoryChip(c.name, c.id)),
                ],
              ),
            ),
          ),

          // Status Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildStatusChip('Tất cả', 'ALL'),
                  _buildStatusChip('Cần nhập hàng', 'LOW_STOCK', color: AppColors.danger),
                  _buildStatusChip('Cận date (FEFO)', 'EXPIRING', color: AppColors.warning),
                  _buildStatusChip('Chậm bán', 'DEAD_STOCK', color: AppColors.accentAmber),
                ],
              ),
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AppColors.borderLight),

          // Summary Info Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hiển thị: ${filtered.length} / ${products.length} sản phẩm',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
                ),
                Text(
                  'Tổng vốn: ${CurrencyFormatter.formatCompactVND(filtered.fold(0.0, (s, p) => s + p.totalInventoryValue))}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),

          // Product List / Grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 56, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('Không tìm thấy sản phẩm phù hợp', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                            child: const Text('Xóa toàn bộ bộ lọc', style: TextStyle(color: AppColors.primary)),
                          ),
                      ],
                    ),
                  )
                : _isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return ShopeeProductCard(product: filtered[index]);
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _buildProductListItem(filtered[index]);
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
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Thêm Sản Phẩm Mới', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? categoryId) {
    final isSelected = _selectedCategoryId == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _selectedCategoryId = categoryId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.shopeeBadgeBg : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String code, {Color? color}) {
    final isSelected = _selectedFilter == code;
    final chipColor = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => setState(() => _selectedFilter = code),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? chipColor : AppColors.borderLight,
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : (color ?? AppColors.textSecondaryLight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductListItem(ProductSKU p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product mini image
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                      ? Image.network(
                          p.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => _buildListFallbackIcon(),
                        )
                      : _buildListFallbackIcon(),
                ),
              ),
              const SizedBox(width: 10),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.shopeeMallRed,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text('BÁCH HÓA', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mã: ${p.skuCode} • Vị trí: ${p.locationTag}',
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₫${CurrencyFormatter.formatNumber(p.sellingPrice)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.shopeePrice),
                        ),
                        Text(
                          'Tồn: ${p.currentStock} ${p.unit}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: p.isLowStock ? AppColors.danger : AppColors.primary,
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
      ),
    );
  }

  Widget _buildListFallbackIcon() {
    return Container(
      color: AppColors.shopeeBadgeBg,
      child: const Center(
        child: Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 28),
      ),
    );
  }
}
