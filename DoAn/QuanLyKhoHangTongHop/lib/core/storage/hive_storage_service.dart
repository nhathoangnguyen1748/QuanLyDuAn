import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product_sku.dart';
import '../models/category_model.dart';
import '../models/stock_in_order.dart';
import '../models/stock_out_order.dart';
import '../models/cycle_count_session.dart';
import 'seed_data.dart';

class HiveStorageService {
  static const String _boxProducts = 'smartstock_products';
  static const String _boxCategories = 'smartstock_categories';
  static const String _boxStockIn = 'smartstock_stock_in';
  static const String _boxStockOut = 'smartstock_stock_out';
  static const String _boxCycleCounts = 'smartstock_cycle_counts';
  static const String _boxSettings = 'smartstock_settings';

  static final HiveStorageService instance = HiveStorageService._internal();
  HiveStorageService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox<String>(_boxProducts),
      Hive.openBox<String>(_boxCategories),
      Hive.openBox<String>(_boxStockIn),
      Hive.openBox<String>(_boxStockOut),
      Hive.openBox<String>(_boxCycleCounts),
      Hive.openBox<dynamic>(_boxSettings),
    ]);

    _isInitialized = true;
    await _checkAndSeedData();
  }

  Box<String> get _productsBox => Hive.box<String>(_boxProducts);
  Box<String> get _categoriesBox => Hive.box<String>(_boxCategories);
  Box<String> get _stockInBox => Hive.box<String>(_boxStockIn);
  Box<String> get _stockOutBox => Hive.box<String>(_boxStockOut);
  Box<String> get _cycleCountsBox => Hive.box<String>(_boxCycleCounts);
  Box<dynamic> get _settingsBox => Hive.box<dynamic>(_boxSettings);

  Future<void> _checkAndSeedData() async {
    if (_productsBox.isEmpty) {
      debugPrint('🌱 Kho rỗng, đang nạp dữ liệu Seed Data cho SmartStock Admin...');
      await resetToSeedData();
    }
  }

  Future<void> resetToSeedData() async {
    await Future.wait([
      _productsBox.clear(),
      _categoriesBox.clear(),
      _stockInBox.clear(),
      _stockOutBox.clear(),
      _cycleCountsBox.clear(),
    ]);

    for (final cat in SeedData.categories) {
      await _categoriesBox.put(cat.id, jsonEncode(cat.toJson()));
    }
    for (final prod in SeedData.products) {
      await _productsBox.put(prod.id, jsonEncode(prod.toJson()));
    }
    for (final inOrder in SeedData.stockInOrders) {
      await _stockInBox.put(inOrder.id, jsonEncode(inOrder.toJson()));
    }
    for (final outOrder in SeedData.stockOutOrders) {
      await _stockOutBox.put(outOrder.id, jsonEncode(outOrder.toJson()));
    }
    for (final cc in SeedData.cycleCounts) {
      await _cycleCountsBox.put(cc.id, jsonEncode(cc.toJson()));
    }

    // Default warehouse capacity: 2000 units
    await _settingsBox.put('warehouseCapacity', 2000);
    await _settingsBox.put('warehouseName', 'Tổng Kho Thông Minh Miền Nam');
    await _settingsBox.put('warehouseAddress', 'Khu Công Nghệ Cao, TP. Thủ Đức, TP.HCM');
  }

  // --- PRODUCTS CRUD ---
  List<ProductSKU> getAllProducts() {
    return _productsBox.values.map((str) {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return ProductSKU.fromJson(map);
    }).toList();
  }

  ProductSKU? getProductById(String id) {
    final str = _productsBox.get(id);
    if (str == null) return null;
    return ProductSKU.fromJson(jsonDecode(str) as Map<String, dynamic>);
  }

  ProductSKU? getProductByBarcode(String barcode) {
    for (final str in _productsBox.values) {
      final map = jsonDecode(str) as Map<String, dynamic>;
      if (map['barcode'] == barcode || map['skuCode'] == barcode) {
        return ProductSKU.fromJson(map);
      }
    }
    return null;
  }

  Future<void> saveProduct(ProductSKU product) async {
    await _productsBox.put(product.id, jsonEncode(product.toJson()));
  }

  Future<void> deleteProduct(String id) async {
    await _productsBox.delete(id);
  }

  // --- CATEGORIES ---
  List<CategoryModel> getAllCategories() {
    return _categoriesBox.values.map((str) {
      return CategoryModel.fromJson(jsonDecode(str) as Map<String, dynamic>);
    }).toList();
  }

  // --- STOCK IN CRUD ---
  List<StockInOrder> getAllStockInOrders() {
    final list = _stockInBox.values.map((str) {
      return StockInOrder.fromJson(jsonDecode(str) as Map<String, dynamic>);
    }).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveStockInOrder(StockInOrder order) async {
    await _stockInBox.put(order.id, jsonEncode(order.toJson()));

    // Cập nhật tăng số lượng tồn kho và cập nhật giá vốn bình quân (MAC)
    for (final item in order.items) {
      final existingProduct = getProductById(item.skuId);
      if (existingProduct != null) {
        final updatedProduct = existingProduct.copyWith(
          currentStock: existingProduct.currentStock + item.quantity,
          costPrice: item.macAfter,
          locationTag: item.locationTag.isNotEmpty ? item.locationTag : existingProduct.locationTag,
          expiryDate: item.expiryDate ?? existingProduct.expiryDate,
        );
        await saveProduct(updatedProduct);
      }
    }
  }

  // --- STOCK OUT CRUD ---
  List<StockOutOrder> getAllStockOutOrders() {
    final list = _stockOutBox.values.map((str) {
      return StockOutOrder.fromJson(jsonDecode(str) as Map<String, dynamic>);
    }).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveStockOutOrder(StockOutOrder order) async {
    await _stockOutBox.put(order.id, jsonEncode(order.toJson()));

    // Cập nhật trừ số lượng tồn kho và ghi nhận ngày xuất mới nhất
    for (final item in order.items) {
      final existingProduct = getProductById(item.skuId);
      if (existingProduct != null) {
        final newStock = (existingProduct.currentStock - item.quantity);
        final updatedProduct = existingProduct.copyWith(
          currentStock: newStock < 0 ? 0 : newStock,
          lastStockOutDate: order.createdAt,
        );
        await saveProduct(updatedProduct);
      }
    }
  }

  // --- CYCLE COUNT CRUD ---
  List<CycleCountSession> getAllCycleCounts() {
    final list = _cycleCountsBox.values.map((str) {
      return CycleCountSession.fromJson(jsonDecode(str) as Map<String, dynamic>);
    }).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  CycleCountSession? getCycleCountById(String id) {
    final str = _cycleCountsBox.get(id);
    if (str == null) return null;
    return CycleCountSession.fromJson(jsonDecode(str) as Map<String, dynamic>);
  }

  Future<void> saveCycleCount(CycleCountSession session) async {
    await _cycleCountsBox.put(session.id, jsonEncode(session.toJson()));
  }

  /// Áp dụng điều chỉnh số tồn kho hệ thống theo số lượng thực tế kiểm kê
  Future<void> reconcileCycleCount(String sessionId) async {
    final session = getCycleCountById(sessionId);
    if (session == null) return;

    for (final item in session.items) {
      if (item.isAudited) {
        final existingProduct = getProductById(item.skuId);
        if (existingProduct != null) {
          final updatedProduct = existingProduct.copyWith(
            currentStock: item.physicalCount,
          );
          await saveProduct(updatedProduct);
        }
      }
    }

    session.status = CycleCountStatus.reconciled;
    session.completedAt = DateTime.now();
    await saveCycleCount(session);
  }

  // --- SETTINGS ---
  int getWarehouseCapacity() {
    return _settingsBox.get('warehouseCapacity', defaultValue: 2000) as int;
  }

  String getWarehouseName() {
    return _settingsBox.get('warehouseName', defaultValue: 'Tổng Kho Thông Minh Miền Nam') as String;
  }

  String getWarehouseAddress() {
    return _settingsBox.get('warehouseAddress', defaultValue: 'Khu Công Nghệ Cao, TP. Thủ Đức, TP.HCM') as String;
  }
}
