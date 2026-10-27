import 'package:flutter_test/flutter_test.dart';
import 'package:smartstock_admin/core/models/category_model.dart';
import 'package:smartstock_admin/core/models/product_sku.dart';
import 'package:smartstock_admin/core/models/stock_in_order.dart';
import 'package:smartstock_admin/core/models/stock_out_order.dart';
import 'package:smartstock_admin/core/models/cycle_count_session.dart';

void main() {
  group('Kiểm thử Tích hợp Mô hình Dữ liệu Supabase Backend', () {
    test('Parse ProductSKU từ bản ghi Supabase (snake_case)', () {
      final supabaseRecord = {
        'id': 'prod-001',
        'sku_code': 'SKU-GRO-HAOHAO',
        'barcode': '8934563138164',
        'name': 'Mì Hảo Hảo Tôm Chua Cay Acecook 75g',
        'category_id': 'CAT-GRO',
        'category_name': 'Lương thực & Đồ khô',
        'cost_price': 3800.0,
        'selling_price': 4500.0,
        'current_stock': 280,
        'min_safety_stock': 50,
        'max_stock': 500,
        'location_tag': 'KỆ-MÌ-01',
        'unit': 'Gói',
        'image_url': 'https://example.com/haohao.jpg',
        'expiry_date': '2027-03-26T19:26:47.502461Z',
        'last_stock_out_date': '2026-10-27T15:26:47.503461Z',
        'created_at': '2026-07-29T19:26:47.503461Z',
        'notes': 'Sản phẩm bán chạy nhất',
      };

      final product = ProductSKU.fromJson(supabaseRecord);

      expect(product.id, equals('prod-001'));
      expect(product.skuCode, equals('SKU-GRO-HAOHAO'));
      expect(product.name, equals('Mì Hảo Hảo Tôm Chua Cay Acecook 75g'));
      expect(product.costPrice, equals(3800.0));
      expect(product.sellingPrice, equals(4500.0));
      expect(product.currentStock, equals(280));
      expect(product.isLowStock, isFalse);
      expect(product.totalInventoryValue, equals(280 * 3800.0));

      final exportJson = product.toJson();
      expect(exportJson['sku_code'], equals('SKU-GRO-HAOHAO'));
      expect(exportJson['category_id'], equals('CAT-GRO'));
    });

    test('Parse CategoryModel từ bản ghi Supabase', () {
      final supabaseCategory = {
        'id': 'CAT-GRO',
        'code': 'GRO',
        'name': 'Lương thực & Đồ khô',
        'color_hex': 4008740141,
        'description': 'Mì, gạo, bún, miến',
      };

      final cat = CategoryModel.fromJson(supabaseCategory);
      expect(cat.id, equals('CAT-GRO'));
      expect(cat.name, equals('Lương thực & Đồ khô'));
      expect(cat.colorHex, equals(4008740141));
    });

    test('Parse StockInOrder với items dạng JSONB từ Supabase', () {
      final supabaseOrder = {
        'id': 'PNK-2026-001',
        'order_number': 'PNK-2026-001',
        'supplier_name': 'Acecook Việt Nam',
        'supplier_phone': '02838154064',
        'items': [
          {
            'skuId': 'prod-001',
            'skuCode': 'SKU-GRO-HAOHAO',
            'skuName': 'Mì Hảo Hảo Tôm Chua Cay',
            'barcode': '8934563138164',
            'quantity': 200,
            'unitPrice': 3800,
            'locationTag': 'KỆ-MÌ-01',
            'currentCostBefore': 3800,
            'macAfter': 3800,
          }
        ],
        'created_at': '2026-10-20T08:30:00Z',
        'created_by': 'Admin Kho',
        'status': 'COMPLETED',
      };

      final order = StockInOrder.fromJson(supabaseOrder);
      expect(order.orderNumber, equals('PNK-2026-001'));
      expect(order.supplierName, equals('Acecook Việt Nam'));
      expect(order.items.length, equals(1));
      expect(order.totalQuantity, equals(200));
      expect(order.totalValue, equals(760000.0));
    });

    test('Parse StockOutOrder với items dạng JSONB từ Supabase', () {
      final supabaseOrder = {
        'id': 'PXK-2026-001',
        'order_number': 'PXK-2026-001',
        'type': 'retail',
        'receiver_name': 'Khách Mua Lẻ',
        'items': [
          {
            'skuId': 'prod-001',
            'skuCode': 'SKU-GRO-HAOHAO',
            'skuName': 'Mì Hảo Hảo',
            'barcode': '8934563138164',
            'quantity': 10,
            'unitPrice': 4500,
            'costPrice': 3800,
          }
        ],
        'created_at': '2026-10-27T10:00:00Z',
        'created_by': 'Admin Kho',
        'status': 'COMPLETED',
      };

      final order = StockOutOrder.fromJson(supabaseOrder);
      expect(order.orderNumber, equals('PXK-2026-001'));
      expect(order.type, equals(StockOutType.retail));
      expect(order.totalQuantity, equals(10));
      expect(order.totalRevenue, equals(45000.0));
      expect(order.totalCogs, equals(38000.0));
      expect(order.items.first.profit, equals(7000.0));
    });

    test('Parse CycleCountSession với items dạng JSONB từ Supabase', () {
      final supabaseSession = {
        'id': 'KK-2026-001',
        'session_code': 'KK-2026-001',
        'title': 'Kiểm kê định kỳ tháng 10',
        'scope': 'Toàn kho',
        'status': 'completed',
        'items': [
          {
            'skuId': 'prod-001',
            'skuCode': 'SKU-GRO-HAOHAO',
            'skuName': 'Mì Hảo Hảo',
            'barcode': '8934563138164',
            'locationTag': 'KỆ-MÌ-01',
            'bookStock': 280,
            'physicalCount': 280,
            'costPrice': 3800,
            'isAudited': true,
          }
        ],
        'created_at': '2026-10-25T07:00:00Z',
        'auditor_name': 'Quang Minh',
      };

      final session = CycleCountSession.fromJson(supabaseSession);
      expect(session.sessionCode, equals('KK-2026-001'));
      expect(session.status, equals(CycleCountStatus.completed));
      expect(session.items.length, equals(1));
      expect(session.items.first.varianceQty, equals(0));
      expect(session.items.first.discrepancyStatus, equals('KHỚP'));
    });
  });
}
