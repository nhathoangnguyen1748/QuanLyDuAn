import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/barcode_scanner_sheet.dart';

/// Model đại diện cho thông tin hàng hóa và phân tích giá vốn
class InventoryItem {
  final String id;
  final String sku;
  final String name;
  final String unit;
  final int stockQuantity;
  final int minSafetyStock;
  final double currentCostPrice;
  final double latestImportPrice;

  const InventoryItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.unit,
    required this.stockQuantity,
    required this.minSafetyStock,
    required this.currentCostPrice,
    required this.latestImportPrice,
  });

  bool get isLowStock => stockQuantity <= minSafetyStock;

  /// Tính phần trăm biến động giá vốn theo thời gian thực
  double get priceVariancePercentage {
    if (currentCostPrice <= 0) return 0.0;
    return ((latestImportPrice - currentCostPrice) / currentCostPrice) * 100;
  }
}

class InventoryDashboardScreen extends StatefulWidget {
  const InventoryDashboardScreen({super.key});

  @override
  State<InventoryDashboardScreen> createState() => _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState extends State<InventoryDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isLoading = false;

  final List<InventoryItem> _masterData = const [
    InventoryItem(
      id: 'ITM-001',
      sku: 'BAR-8935001',
      name: 'Thép Cuộn Cán Nóng Posco Grade A (Cuộn 5T)',
      unit: 'Cuộn',
      stockQuantity: 145,
      minSafetyStock: 20,
      currentCostPrice: 15200000,
      latestImportPrice: 16100000,
    ),
    InventoryItem(
      id: 'ITM-002',
      sku: 'BAR-8935002',
      name: 'Ống Nhựa HDPE Tiêu Chuẩn Phi 110 PN10',
      unit: 'Cây',
      stockQuantity: 8,
      minSafetyStock: 15,
      currentCostPrice: 420000,
      latestImportPrice: 395000,
    ),
    InventoryItem(
      id: 'ITM-003',
      sku: 'BAR-8935003',
      name: 'Sơn Công Nghiệp Epoxy Kháng Hóa Chất 20L',
      unit: 'Thùng',
      stockQuantity: 4,
      minSafetyStock: 10,
      currentCostPrice: 1250000,
      latestImportPrice: 1250000,
    ),
    InventoryItem(
      id: 'ITM-004',
      sku: 'BAR-8935004',
      name: 'Van Cổng Ty Chìm Gang Cầu DN100 PN16',
      unit: 'Bộ',
      stockQuantity: 62,
      minSafetyStock: 12,
      currentCostPrice: 2890000,
      latestImportPrice: 3150000,
    ),
    InventoryItem(
      id: 'ITM-005',
      sku: 'BAR-8935005',
      name: 'Bulong Neo Cường Độ Cao M24x800 Grade 8.8',
      unit: 'Bộ',
      stockQuantity: 820,
      minSafetyStock: 100,
      currentCostPrice: 78000,
      latestImportPrice: 74500,
    ),
  ];

  late List<InventoryItem> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(_masterData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() => _isLoading = true);

      // Mô phỏng xử lý lọc trên background
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        setState(() {
          final q = query.trim().toLowerCase();
          if (q.isEmpty) {
            _filteredItems = List.from(_masterData);
          } else {
            _filteredItems = _masterData
                .where((item) =>
                    item.name.toLowerCase().contains(q) ||
                    item.sku.toLowerCase().contains(q))
                .toList();
          }
          _isLoading = false;
        });
      });
    });
  }

  void _openBarcodeScannerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BarcodeScannerSheet(
        onBarcodeDetected: (scannedSku) {
          _searchController.text = scannedSku;
          _onSearchChanged(scannedSku);
        },
      ),
    );
  }

  String _formatCurrency(double value) {
    return '${value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )} ₫';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản Lý Tồn Kho & Giá Vốn',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Hệ thống điều phối vật tư công nghiệp',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Quét Barcode / Nhập SKU',
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
            onPressed: _openBarcodeScannerModal,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildKpiSummary(context),
                  const SizedBox(height: 16),
                  _buildSearchAndControlBar(context),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredItems.isEmpty
                            ? _buildEmptyState(context)
                            : isDesktop
                                ? _buildDesktopDataTable(context)
                                : _buildMobileListView(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildKpiSummary(BuildContext context) {
    final totalItems = _filteredItems.length;
    final lowStockCount = _filteredItems.where((e) => e.isLowStock).length;
    final totalStockCount = _filteredItems.fold<int>(0, (sum, e) => sum + e.stockQuantity);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 600
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 24) / 3;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              title: 'Mã vật tư quản lý',
              value: '$totalItems SKU',
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFF0F4C81),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Tổng số lượng tồn',
              value: '$totalStockCount SP',
              icon: Icons.warehouse_outlined,
              iconColor: const Color(0xFF0D9488),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Cảnh báo tồn thấp',
              value: '$lowStockCount Mã',
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFEF4444),
              isAlert: lowStockCount > 0,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required double width,
    bool isAlert = false,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        color: isAlert ? const Color(0xFFFEF2F2) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isAlert ? const Color(0xFF991B1B) : const Color(0xFF0F172A),
                        height: 1.3,
                      ),
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

  Widget _buildSearchAndControlBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Tìm theo mã SKU, tên vật tư kho...',
                prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.filter_list, size: 18),
            label: const Text('Lọc nâng cao'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bộ lọc nâng cao: Đang hiển thị danh mục kho tổng')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileListView(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final variance = item.priceVariancePercentage;
        final isVariancePositive = variance > 0;
        final isVarianceZero = variance == 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.isLowStock
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.isLowStock ? 'Tồn thấp: ${item.stockQuantity}' : 'Tồn: ${item.stockQuantity}',
                        style: TextStyle(
                          color: item.isLowStock
                              ? const Color(0xFF991B1B)
                              : const Color(0xFF166534),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.sku,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Đơn vị: ${item.unit}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                const Divider(height: 20, thickness: 0.8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Giá vốn bình quân', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text(
                          _formatCurrency(item.currentCostPrice),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Biến động giá nhập', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (!isVarianceZero)
                              Icon(
                                isVariancePositive ? Icons.trending_up : Icons.trending_down,
                                size: 16,
                                color: isVariancePositive ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                              ),
                            const SizedBox(width: 4),
                            Text(
                              isVarianceZero ? '0.0%' : '${isVariancePositive ? '+' : '-'}${variance.abs().toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isVarianceZero
                                    ? const Color(0xFF64748B)
                                    : (isVariancePositive ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopDataTable(BuildContext context) {
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              horizontalMargin: 20,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('Mã SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Tên Vật Tư Hàng Hóa', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ĐVT', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Tồn Thực Tế', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Giá Vốn (VNĐ)', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Giá Nhập Mới Nhất', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Biến Động %', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _filteredItems.map((item) {
                final variance = item.priceVariancePercentage;
                final isPositive = variance > 0;
                final isZero = variance == 0;

                return DataRow(
                  cells: [
                    DataCell(Text(item.sku, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600))),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text(item.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    DataCell(Text(item.unit)),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.isLowStock ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.stockQuantity}',
                          style: TextStyle(
                            color: item.isLowStock ? const Color(0xFF991B1B) : const Color(0xFF166534),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(_formatCurrency(item.currentCostPrice))),
                    DataCell(Text(_formatCurrency(item.latestImportPrice))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isZero)
                            Icon(
                              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 14,
                              color: isPositive ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                            ),
                          const SizedBox(width: 4),
                          Text(
                            isZero ? '0.0%' : '${isPositive ? '+' : '-'}${variance.abs().toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: isZero
                                  ? const Color(0xFF64748B)
                                  : (isPositive ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy dữ liệu vật tư phù hợp',
            style: theme.textTheme.titleMedium?.copyWith(color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Text(
            'Vui lòng thử lại với mã SKU khác hoặc quét barcode kiểm tra.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
