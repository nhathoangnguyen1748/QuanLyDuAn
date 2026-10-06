import 'package:flutter_test/flutter_test.dart';
import 'package:smartstock_admin/core/models/product_sku.dart';
import 'package:smartstock_admin/core/utils/date_formatter.dart';

void main() {
  group('Kiểm thử Cảnh báo Tồn an toàn, Dead Stock & Hạn dùng FEFO - Quang Minh', () {
    test('1. Kiểm thử Cảnh báo Thiếu Tồn An Toàn (Low Stock)', () {
      // Tồn hiện tại (5) <= Định mức an toàn (10) => isLowStock = true
      final lowStockProd = ProductSKU(
        id: 'p-low',
        skuCode: 'SKU-LOW',
        barcode: '8930001',
        name: 'Hàng thiếu tồn',
        categoryId: 'cat-1',
        categoryName: 'Điện tử',
        costPrice: 100000,
        sellingPrice: 150000,
        currentStock: 5,
        minSafetyStock: 10,
        maxStock: 50,
        locationTag: 'KHO-A',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      expect(lowStockProd.isLowStock, isTrue);

      // Tồn hiện tại bằng đúng định mức an toàn (10) => vẫn cảnh báo
      final boundaryProd = lowStockProd.copyWith(currentStock: 10);
      expect(boundaryProd.isLowStock, isTrue);

      // Tồn hiện tại (11) > Định mức an toàn (10) => isLowStock = false
      final safeProd = lowStockProd.copyWith(currentStock: 11);
      expect(safeProd.isLowStock, isFalse);
    });

    test('2. Kiểm thử Cảnh báo Hàng Chậm Luân Chuyển (Dead Stock > 60 ngày)', () {
      final now = DateTime.now();

      // Trường hợp 1: Có ngày xuất kho gần nhất cách đây 70 ngày (> 60)
      final deadStockWithOutDate = ProductSKU(
        id: 'p-dead-1',
        skuCode: 'SKU-DEAD-1',
        barcode: '8930002',
        name: 'Hàng đọng 70 ngày',
        categoryId: 'cat-1',
        categoryName: 'Gia dụng',
        costPrice: 200000,
        sellingPrice: 300000,
        currentStock: 15,
        minSafetyStock: 5,
        maxStock: 30,
        locationTag: 'KHO-B',
        lastStockOutDate: now.subtract(const Duration(days: 70)),
        createdAt: now.subtract(const Duration(days: 100)),
      );

      expect(deadStockWithOutDate.isDeadStock, isTrue);
      expect(deadStockWithOutDate.daysSinceLastMovement, greaterThanOrEqualTo(70));

      // Trường hợp 2: Hàng mới xuất kho 10 ngày trước (< 60) => Không phải Dead Stock
      final activeProduct = deadStockWithOutDate.copyWith(
        lastStockOutDate: now.subtract(const Duration(days: 10)),
      );
      expect(activeProduct.isDeadStock, isFalse);

      // Trường hợp 3: Hàng chưa từng xuất kho, ngày nhập cách đây 65 ngày (> 60)
      final neverSoldDeadProduct = ProductSKU(
        id: 'p-dead-2',
        skuCode: 'SKU-DEAD-2',
        barcode: '8930003',
        name: 'Hàng chưa từng xuất',
        categoryId: 'cat-2',
        categoryName: 'Thực phẩm',
        costPrice: 50000,
        sellingPrice: 80000,
        currentStock: 50,
        minSafetyStock: 10,
        maxStock: 100,
        locationTag: 'KHO-C',
        lastStockOutDate: null,
        createdAt: now.subtract(const Duration(days: 65)),
      );
      expect(neverSoldDeadProduct.isDeadStock, isTrue);

      // Trường hợp 4: Tồn kho = 0 thì không tính là Dead stock
      final zeroStockDead = deadStockWithOutDate.copyWith(currentStock: 0);
      expect(zeroStockDead.isDeadStock, isFalse);
    });

    test('3. Kiểm thử Quản lý Hạn dùng FEFO: Cận date <= 30 ngày và Quá hạn', () {
      final now = DateTime.now();

      // Hàng còn 15 ngày hết hạn => Cận date (isExpiringSoon = true, isExpired = false)
      final expiringSoonProd = ProductSKU(
        id: 'p-exp-1',
        skuCode: 'SKU-EXP-1',
        barcode: '8930004',
        name: 'Sữa tươi cận date',
        categoryId: 'cat-3',
        categoryName: 'Thực phẩm',
        costPrice: 30000,
        sellingPrice: 42000,
        currentStock: 100,
        minSafetyStock: 20,
        maxStock: 200,
        locationTag: 'KHO-D',
        expiryDate: now.add(const Duration(days: 15)),
        createdAt: now.subtract(const Duration(days: 60)),
      );

      expect(expiringSoonProd.isExpiringSoon, isTrue);
      expect(expiringSoonProd.isExpired, isFalse);

      // Hàng đã hết hạn 5 ngày trước => isExpired = true
      final expiredProd = expiringSoonProd.copyWith(
        expiryDate: now.subtract(const Duration(days: 5)),
      );

      expect(expiredProd.isExpired, isTrue);

      // Hàng còn 90 ngày hết hạn => An toàn (không cận date, không quá hạn)
      final safeExpiryProd = expiringSoonProd.copyWith(
        expiryDate: now.add(const Duration(days: 90)),
      );

      expect(safeExpiryProd.isExpiringSoon, isFalse);
      expect(safeExpiryProd.isExpired, isFalse);
    });

    test('4. Kiểm thử Nguyên tắc FEFO: Sắp xếp theo hạn sử dụng sớm nhất lên trước', () {
      final now = DateTime.now();

      final p1 = ProductSKU(
        id: 'p1',
        skuCode: 'SKU-01',
        barcode: '1',
        name: 'Hạn dùng 20 ngày',
        categoryId: 'c',
        categoryName: 'F&B',
        costPrice: 10,
        sellingPrice: 20,
        currentStock: 10,
        minSafetyStock: 2,
        maxStock: 50,
        locationTag: 'A',
        expiryDate: now.add(const Duration(days: 20)),
        createdAt: now,
      );

      final p2 = ProductSKU(
        id: 'p2',
        skuCode: 'SKU-02',
        barcode: '2',
        name: 'Hạn dùng 5 ngày (Cần xuất trước nhất)',
        categoryId: 'c',
        categoryName: 'F&B',
        costPrice: 10,
        sellingPrice: 20,
        currentStock: 10,
        minSafetyStock: 2,
        maxStock: 50,
        locationTag: 'A',
        expiryDate: now.add(const Duration(days: 5)),
        createdAt: now,
      );

      final p3 = ProductSKU(
        id: 'p3',
        skuCode: 'SKU-03',
        barcode: '3',
        name: 'Hạn dùng 45 ngày',
        categoryId: 'c',
        categoryName: 'F&B',
        costPrice: 10,
        sellingPrice: 20,
        currentStock: 10,
        minSafetyStock: 2,
        maxStock: 50,
        locationTag: 'A',
        expiryDate: now.add(const Duration(days: 45)),
        createdAt: now,
      );

      final list = [p1, p2, p3];

      // Sắp xếp theo FEFO
      list.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));

      expect(list[0].skuCode, equals('SKU-02')); // Hạn 5 ngày
      expect(list[1].skuCode, equals('SKU-01')); // Hạn 20 ngày
      expect(list[2].skuCode, equals('SKU-03')); // Hạn 45 ngày
    });

    test('5. Kiểm thử DateFormatter: Số ngày còn lại đến khi hết hạn', () {
      final now = DateTime.now();
      final targetDate = now.add(const Duration(days: 12));
      final daysLeft = DateFormatter.daysUntilExpiry(targetDate);

      expect(daysLeft, closeTo(12, 1));
    });
  });
}
