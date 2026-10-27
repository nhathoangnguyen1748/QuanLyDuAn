import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/category_model.dart';
import '../models/cycle_count_session.dart';
import '../models/product_sku.dart';
import '../models/stock_in_order.dart';
import '../models/stock_out_order.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
      );
      _isInitialized = true;
      debugPrint('🚀 Supabase initialized successfully!');
    } catch (e) {
      debugPrint('⚠️ Supabase init warning: $e');
      _isInitialized = true;
    }
  }

  SupabaseClient get client => Supabase.instance.client;

  // --- REALTIME STREAMS ---
  Stream<List<ProductSKU>> streamProducts() {
    return client
        .from('products')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => ProductSKU.fromJson(r)).toList());
  }

  Stream<List<CategoryModel>> streamCategories() {
    return client
        .from('categories')
        .stream(primaryKey: ['id'])
        .order('id', ascending: true)
        .map((rows) => rows.map((r) => CategoryModel.fromJson(r)).toList());
  }

  Stream<List<StockInOrder>> streamStockInOrders() {
    return client
        .from('stock_in_orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => StockInOrder.fromJson(r)).toList());
  }

  Stream<List<StockOutOrder>> streamStockOutOrders() {
    return client
        .from('stock_out_orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => StockOutOrder.fromJson(r)).toList());
  }

  Stream<List<CycleCountSession>> streamCycleCounts() {
    return client
        .from('cycle_count_sessions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => CycleCountSession.fromJson(r)).toList());
  }

  // --- CRUD QUERIES ---
  Future<List<ProductSKU>> getAllProducts() async {
    final response = await client
        .from('products')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((r) => ProductSKU.fromJson(r)).toList();
  }

  Future<ProductSKU?> getProductById(String id) async {
    final response = await client
        .from('products')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return ProductSKU.fromJson(response);
  }

  Future<ProductSKU?> getProductByBarcode(String barcode) async {
    final response = await client
        .from('products')
        .select()
        .or('barcode.eq.$barcode,sku_code.eq.$barcode')
        .maybeSingle();
    if (response == null) return null;
    return ProductSKU.fromJson(response);
  }

  Future<void> saveProduct(ProductSKU product) async {
    await client.from('products').upsert(product.toJson());
  }

  Future<void> deleteProduct(String id) async {
    await client.from('products').delete().eq('id', id);
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final response = await client.from('categories').select().order('id');
    return (response as List).map((r) => CategoryModel.fromJson(r)).toList();
  }

  // --- STOCK IN CRUD & INVENTORY UPDATE ---
  Future<List<StockInOrder>> getAllStockInOrders() async {
    final response = await client
        .from('stock_in_orders')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((r) => StockInOrder.fromJson(r)).toList();
  }

  Future<void> saveStockInOrder(StockInOrder order) async {
    // 1. Lưu phiếu nhập
    await client.from('stock_in_orders').upsert(order.toJson());

    // 2. Cập nhật số lượng tồn kho và giá vốn MAC
    for (final item in order.items) {
      final existing = await getProductById(item.skuId);
      if (existing != null) {
        final updated = existing.copyWith(
          currentStock: existing.currentStock + item.quantity,
          costPrice: item.macAfter,
          locationTag: item.locationTag.isNotEmpty ? item.locationTag : existing.locationTag,
          expiryDate: item.expiryDate ?? existing.expiryDate,
        );
        await saveProduct(updated);
      }
    }
  }

  // --- STOCK OUT CRUD & INVENTORY DEDUCTION ---
  Future<List<StockOutOrder>> getAllStockOutOrders() async {
    final response = await client
        .from('stock_out_orders')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((r) => StockOutOrder.fromJson(r)).toList();
  }

  Future<void> saveStockOutOrder(StockOutOrder order) async {
    // 1. Lưu phiếu xuất
    await client.from('stock_out_orders').upsert(order.toJson());

    // 2. Trừ tồn kho và ghi nhận ngày xuất kho mới nhất
    for (final item in order.items) {
      final existing = await getProductById(item.skuId);
      if (existing != null) {
        final newStock = existing.currentStock - item.quantity;
        final updated = existing.copyWith(
          currentStock: newStock < 0 ? 0 : newStock,
          lastStockOutDate: order.createdAt,
        );
        await saveProduct(updated);
      }
    }
  }

  // --- CYCLE COUNT CRUD & RECONCILIATION ---
  Future<List<CycleCountSession>> getAllCycleCounts() async {
    final response = await client
        .from('cycle_count_sessions')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((r) => CycleCountSession.fromJson(r)).toList();
  }

  Future<CycleCountSession?> getCycleCountById(String id) async {
    final response = await client
        .from('cycle_count_sessions')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return CycleCountSession.fromJson(response);
  }

  Future<void> saveCycleCount(CycleCountSession session) async {
    await client.from('cycle_count_sessions').upsert(session.toJson());
  }

  Future<void> reconcileCycleCount(String sessionId) async {
    final session = await getCycleCountById(sessionId);
    if (session == null) return;

    for (final item in session.items) {
      if (item.isAudited) {
        final existing = await getProductById(item.skuId);
        if (existing != null) {
          final updated = existing.copyWith(
            currentStock: item.physicalCount,
          );
          await saveProduct(updated);
        }
      }
    }

    session.status = CycleCountStatus.reconciled;
    session.completedAt = DateTime.now();
    await saveCycleCount(session);
  }

  // --- WAREHOUSE SETTINGS ---
  Future<Map<String, String>> getWarehouseSettings() async {
    try {
      final response = await client.from('warehouse_settings').select();
      final map = <String, String>{};
      for (final r in (response as List)) {
        map[r['key'] as String] = r['value'] as String;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveWarehouseSetting(String key, String value) async {
    await client.from('warehouse_settings').upsert({
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
