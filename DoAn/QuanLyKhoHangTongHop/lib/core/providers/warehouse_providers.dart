import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_sku.dart';
import '../models/category_model.dart';
import '../models/stock_in_order.dart';
import '../models/stock_out_order.dart';
import '../models/cycle_count_session.dart';
import '../models/analytics_models.dart';
import '../storage/hive_storage_service.dart';
import '../utils/inventory_math.dart';

// Hive service provider
final storageServiceProvider = Provider<HiveStorageService>((ref) {
  return HiveStorageService.instance;
});

// Category List Provider
final categoryListProvider = Provider<List<CategoryModel>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getAllCategories();
});

// Product List Notifier
class ProductListNotifier extends Notifier<List<ProductSKU>> {
  @override
  List<ProductSKU> build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getAllProducts();
  }

  void refresh() {
    final storage = ref.read(storageServiceProvider);
    state = storage.getAllProducts();
  }

  Future<void> saveProduct(ProductSKU product) async {
    await ref.read(storageServiceProvider).saveProduct(product);
    refresh();
  }

  Future<void> deleteProduct(String id) async {
    await ref.read(storageServiceProvider).deleteProduct(id);
    refresh();
  }

  ProductSKU? findByBarcode(String barcode) {
    return ref.read(storageServiceProvider).getProductByBarcode(barcode);
  }
}

final productListProvider = NotifierProvider<ProductListNotifier, List<ProductSKU>>(ProductListNotifier.new);

// Stock In Orders Notifier
class StockInListNotifier extends Notifier<List<StockInOrder>> {
  @override
  List<StockInOrder> build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getAllStockInOrders();
  }

  void refresh() {
    final storage = ref.read(storageServiceProvider);
    state = storage.getAllStockInOrders();
  }

  Future<void> addOrder(StockInOrder order) async {
    await ref.read(storageServiceProvider).saveStockInOrder(order);
    refresh();
    ref.read(productListProvider.notifier).refresh();
  }
}

final stockInListProvider = NotifierProvider<StockInListNotifier, List<StockInOrder>>(StockInListNotifier.new);

// Stock Out Orders Notifier
class StockOutListNotifier extends Notifier<List<StockOutOrder>> {
  @override
  List<StockOutOrder> build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getAllStockOutOrders();
  }

  void refresh() {
    final storage = ref.read(storageServiceProvider);
    state = storage.getAllStockOutOrders();
  }

  Future<void> addOrder(StockOutOrder order) async {
    await ref.read(storageServiceProvider).saveStockOutOrder(order);
    refresh();
    ref.read(productListProvider.notifier).refresh();
  }
}

final stockOutListProvider = NotifierProvider<StockOutListNotifier, List<StockOutOrder>>(StockOutListNotifier.new);

// Cycle Count List Notifier
class CycleCountListNotifier extends Notifier<List<CycleCountSession>> {
  @override
  List<CycleCountSession> build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getAllCycleCounts();
  }

  void refresh() {
    final storage = ref.read(storageServiceProvider);
    state = storage.getAllCycleCounts();
  }

  Future<void> saveSession(CycleCountSession session) async {
    await ref.read(storageServiceProvider).saveCycleCount(session);
    refresh();
  }

  Future<void> reconcile(String sessionId) async {
    await ref.read(storageServiceProvider).reconcileCycleCount(sessionId);
    refresh();
    ref.read(productListProvider.notifier).refresh();
  }
}

final cycleCountListProvider = NotifierProvider<CycleCountListNotifier, List<CycleCountSession>>(CycleCountListNotifier.new);

// Warehouse Settings
class WarehouseSettings {
  final String name;
  final String address;
  final int capacity;
  const WarehouseSettings({
    required this.name,
    required this.address,
    required this.capacity,
  });
}

final warehouseSettingsProvider = Provider<WarehouseSettings>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return WarehouseSettings(
    name: storage.getWarehouseName(),
    address: storage.getWarehouseAddress(),
    capacity: storage.getWarehouseCapacity(),
  );
});

// Analytics Dashboard Provider: Reactive computation of KPIs and Charts
final executiveKPIProvider = Provider<ExecutiveKPI>((ref) {
  final products = ref.watch(productListProvider);
  final settings = ref.watch(warehouseSettingsProvider);

  final double totalValue = products.fold(0.0, (sum, p) => sum + p.totalInventoryValue);
  final int totalUnits = products.fold(0, (sum, p) => sum + p.currentStock);
  final int lowStockCount = products.where((p) => p.isLowStock).length;
  final int deadStockCount = products.where((p) => p.isDeadStock).length;
  final int expiringSoon = products.where((p) => p.isExpiringSoon).length;
  final int expired = products.where((p) => p.isExpired).length;

  final double utilization = InventoryMath.calculateUtilizationRate(
    totalCurrentUnits: totalUnits,
    totalCapacityUnits: settings.capacity,
  );

  return ExecutiveKPI(
    totalInventoryValue: totalValue,
    warehouseUtilizationRate: utilization,
    lowStockCount: lowStockCount,
    deadStockCount: deadStockCount,
    totalSKUs: products.length,
    totalUnits: totalUnits,
    totalCapacityUnits: settings.capacity,
    expiringSoonCount: expiringSoon,
    expiredCount: expired,
  );
});

// Pareto ABC Analysis Provider
final paretoABCProvider = Provider<ParetoAnalysisResult>((ref) {
  final products = ref.watch(productListProvider);
  final stockOutOrders = ref.watch(stockOutListProvider);

  final Map<String, double> revenueMap = {};
  for (final prod in products) {
    revenueMap[prod.id] = 0.0;
  }

  for (final order in stockOutOrders) {
    for (final item in order.items) {
      revenueMap[item.skuId] = (revenueMap[item.skuId] ?? 0.0) + item.totalRevenue;
    }
  }

  for (final prod in products) {
    if ((revenueMap[prod.id] ?? 0.0) == 0.0) {
      revenueMap[prod.id] = prod.totalInventoryValue * 0.15;
    }
  }

  final double totalRevenue = revenueMap.values.fold(0.0, (sum, v) => sum + v);

  final sortedEntries = revenueMap.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  double cumulativeSum = 0.0;
  final List<ParetoABCItem> paretoItems = [];

  for (final entry in sortedEntries) {
    final prod = products.firstWhere(
      (p) => p.id == entry.key,
      orElse: () => ProductSKU(
        id: entry.key,
        skuCode: 'UNKNOWN',
        barcode: '',
        name: 'Sản phẩm khác',
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

    cumulativeSum += entry.value;
    final double cumulativePercent = totalRevenue > 0
        ? (cumulativeSum / totalRevenue) * 100
        : 0.0;
    final double valueShare = totalRevenue > 0
        ? (entry.value / totalRevenue) * 100
        : 0.0;

    final String group = InventoryMath.getABCClassification(cumulativePercent);

    paretoItems.add(ParetoABCItem(
      skuId: prod.id,
      skuCode: prod.skuCode,
      name: prod.name,
      revenueValue: entry.value,
      valueSharePercent: valueShare,
      cumulativePercent: cumulativePercent > 100 ? 100.0 : cumulativePercent,
      group: group,
    ));
  }

  final groupA = paretoItems.where((i) => i.group == 'A').toList();
  final groupB = paretoItems.where((i) => i.group == 'B').toList();
  final groupC = paretoItems.where((i) => i.group == 'C').toList();

  final double groupAShare = groupA.fold(0.0, (s, i) => s + i.valueSharePercent);
  final double groupBShare = groupB.fold(0.0, (s, i) => s + i.valueSharePercent);
  final double groupCShare = groupC.fold(0.0, (s, i) => s + i.valueSharePercent);

  return ParetoAnalysisResult(
    items: paretoItems,
    groupAValueShare: groupAShare,
    groupBValueShare: groupBShare,
    groupCValueShare: groupCShare,
    groupACount: groupA.length,
    groupBCount: groupB.length,
    groupCCount: groupC.length,
  );
});

// ITR (Inventory Turnover Ratio) Trend Provider
final itrTrendProvider = Provider<List<ITRDataPoint>>((ref) {
  final products = ref.watch(productListProvider);
  final currentStockValue = products.fold(0.0, (s, p) => s + p.totalInventoryValue);

  return [
    ITRDataPoint(
      month: 'T4',
      itr: 4.2,
      cogs: currentStockValue * 0.35,
      avgStock: currentStockValue * 1.05,
    ),
    ITRDataPoint(
      month: 'T5',
      itr: 4.5,
      cogs: currentStockValue * 0.38,
      avgStock: currentStockValue * 1.02,
    ),
    ITRDataPoint(
      month: 'T6',
      itr: 5.1,
      cogs: currentStockValue * 0.44,
      avgStock: currentStockValue * 1.00,
    ),
    ITRDataPoint(
      month: 'T7',
      itr: 4.8,
      cogs: currentStockValue * 0.41,
      avgStock: currentStockValue * 0.98,
    ),
    ITRDataPoint(
      month: 'T8',
      itr: 5.6,
      cogs: currentStockValue * 0.49,
      avgStock: currentStockValue * 0.96,
    ),
    ITRDataPoint(
      month: 'T9',
      itr: 5.9,
      cogs: currentStockValue * 0.52,
      avgStock: currentStockValue,
    ),
  ];
});

// Holding Cost Provider
final holdingCostProvider = Provider<List<HoldingCostDataPoint>>((ref) {
  return const [
    HoldingCostDataPoint(
      period: 'T4',
      storageCost: 18500000,
      shrinkageCost: 2800000,
      revenue: 125000000,
    ),
    HoldingCostDataPoint(
      period: 'T5',
      storageCost: 19000000,
      shrinkageCost: 2100000,
      revenue: 142000000,
    ),
    HoldingCostDataPoint(
      period: 'T6',
      storageCost: 18800000,
      shrinkageCost: 3500000,
      revenue: 168000000,
    ),
    HoldingCostDataPoint(
      period: 'T7',
      storageCost: 19200000,
      shrinkageCost: 1800000,
      revenue: 155000000,
    ),
    HoldingCostDataPoint(
      period: 'T8',
      storageCost: 19500000,
      shrinkageCost: 2400000,
      revenue: 185000000,
    ),
    HoldingCostDataPoint(
      period: 'T9',
      storageCost: 19800000,
      shrinkageCost: 1500000,
      revenue: 210000000,
    ),
  ];
});

// Category Distribution Provider
final categoryDistributionProvider = Provider<List<CategoryDistributionItem>>((ref) {
  final products = ref.watch(productListProvider);
  final categories = ref.watch(categoryListProvider);

  final double totalValue = products.fold(0.0, (s, p) => s + p.totalInventoryValue);

  return categories.map((cat) {
    final catProducts = products.where((p) => p.categoryId == cat.id).toList();
    final double catValue = catProducts.fold(0.0, (s, p) => s + p.totalInventoryValue);
    final int catUnits = catProducts.fold(0, (s, p) => s + p.currentStock);
    final double percentage = totalValue > 0 ? (catValue / totalValue) * 100 : 0.0;

    return CategoryDistributionItem(
      categoryId: cat.id,
      categoryName: cat.name,
      colorHex: cat.colorHex,
      skuCount: catProducts.length,
      totalStockUnits: catUnits,
      totalValue: catValue,
      percentage: percentage,
    );
  }).toList();
});
