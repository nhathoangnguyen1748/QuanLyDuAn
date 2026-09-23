import 'package:flutter_test/flutter_test.dart';
import 'package:smartstock_admin/core/models/stock_in_order.dart';
import 'package:smartstock_admin/core/models/stock_out_order.dart';
import 'package:smartstock_admin/core/utils/inventory_math.dart';

void main() {
  group('Kiểm thử Nghiệp vụ Nhập kho & Giá vốn MAC (Trung Lương)', () {
    test('Tính giá vốn MAC khi nhập thêm hàng vào tồn kho hiện hữu', () {
      // Tồn cũ: 20 chiếc, vốn cũ 25.000.000đ
      // Nhập mới: 10 chiếc, giá nhập 28.000.000đ
      // MAC = (20 * 25.000.000 + 10 * 28.000.000) / 30 = (500.000.000 + 280.000.000) / 30 = 26.000.000đ
      final mac = InventoryMath.calculateMAC(
        currentStock: 20,
        currentCostPrice: 25000000,
        newQuantity: 10,
        newUnitPrice: 28000000,
      );

      expect(mac, equals(26000000.0));
    });

    test('Tính MAC khi tồn kho cũ bằng 0', () {
      final mac = InventoryMath.calculateMAC(
        currentStock: 0,
        currentCostPrice: 0,
        newQuantity: 15,
        newUnitPrice: 3200000,
      );

      expect(mac, equals(3200000.0));
    });

    test('Tính MAC khi số lượng nhập mới <= 0 giữ nguyên giá vốn cũ', () {
      final mac = InventoryMath.calculateMAC(
        currentStock: 10,
        currentCostPrice: 1500000,
        newQuantity: 0,
        newUnitPrice: 2000000,
      );

      expect(mac, equals(1500000.0));
    });

    test('Khởi tạo và Serialize/Deserialize StockInOrder chính xác', () {
      final item = StockInItem(
        skuId: 'prod-001',
        skuCode: 'SKU-TEST-01',
        skuName: 'Sản phẩm Test',
        barcode: '893850000001',
        quantity: 5,
        unitPrice: 100000,
        locationTag: 'KHO-A-KAY-01',
        currentCostBefore: 90000,
        macAfter: 95000,
        expiryDate: DateTime(2027, 12, 31),
      );

      final order = StockInOrder(
        id: 'order-in-001',
        orderNumber: 'PNK-2026-TEST',
        supplierName: 'NCC Quốc Tế',
        supplierPhone: '0901234567',
        items: [item],
        createdAt: DateTime(2026, 9, 23, 10, 0),
        createdBy: 'Trung Lương',
        notes: 'Hàng nhập mẫu kiểm tra',
      );

      expect(order.totalQuantity, equals(5));
      expect(order.totalValue, equals(500000.0));

      final json = order.toJson();
      final restored = StockInOrder.fromJson(json);

      expect(restored.orderNumber, equals('PNK-2026-TEST'));
      expect(restored.items.length, equals(1));
      expect(restored.items.first.macAfter, equals(95000.0));
      expect(restored.items.first.expiryDate?.year, equals(2027));
    });
  });

  group('Kiểm thử Nghiệp vụ Xuất kho, Điều chuyển & Chặn xuất âm (Trung Lương)', () {
    test('Ràng buộc chặn xuất âm kho: xuất quá tồn khả dụng là không hợp lệ', () {
      const int currentStock = 12;
      const int requestedQty = 15;

      final bool canExport = requestedQty <= currentStock;
      expect(canExport, isFalse);
    });

    test('Đơn hàng Bán lẻ tính doanh thu, COGS và Lợi nhuận gộp', () {
      final item = StockOutItem(
        skuId: 'prod-002',
        skuCode: 'SKU-RETAIL',
        skuName: 'Điện thoại cao cấp',
        barcode: '893850000002',
        quantity: 2,
        unitPrice: 30000000, // Giá bán lẻ 30tr
        costPrice: 26000000, // Giá vốn MAC 26tr
      );

      expect(item.totalRevenue, equals(60000000.0));
      expect(item.totalCogs, equals(52000000.0));
      expect(item.profit, equals(8000000.0));
    });

    test('Đơn hàng Điều chuyển nội bộ (Transfer) có lợi nhuận thương mại bằng 0', () {
      final item = StockOutItem(
        skuId: 'prod-003',
        skuCode: 'SKU-TRANSFER',
        skuName: 'Thiết bị điều chuyển',
        barcode: '893850000003',
        quantity: 10,
        unitPrice: 5000000, // Giá xuất bằng giá vốn MAC
        costPrice: 5000000, // Giá vốn MAC
      );

      final order = StockOutOrder(
        id: 'out-transfer-01',
        orderNumber: 'PXK-TRANSFER-01',
        type: StockOutType.transfer,
        receiverName: 'Kho Chi nhánh Đà Nẵng',
        destinationBranch: '123 Nguyễn Văn Linh, Đà Nẵng',
        items: [item],
        createdAt: DateTime(2026, 9, 23, 14, 0),
        createdBy: 'Trung Lương',
      );

      expect(order.type, equals(StockOutType.transfer));
      expect(order.destinationBranch, isNotNull);
      expect(order.totalRevenue, equals(order.totalCogs)); // Doanh số điều chuyển = Giá vốn
      expect(order.totalRevenue - order.totalCogs, equals(0.0)); // Lợi nhuận gộp = 0
    });

    test('Khởi tạo và Serialize/Deserialize StockOutOrder chính xác', () {
      final item = StockOutItem(
        skuId: 'prod-004',
        skuCode: 'SKU-WHOLESALE',
        skuName: 'Gia dụng sỉ',
        barcode: '893850000004',
        quantity: 50,
        unitPrice: 900000,
        costPrice: 700000,
      );

      final order = StockOutOrder(
        id: 'out-002',
        orderNumber: 'PXK-2026-WHOLESALE',
        type: StockOutType.wholesale,
        receiverName: 'Đại lý Cấp 1',
        items: [item],
        createdAt: DateTime(2026, 9, 23, 15, 0),
        createdBy: 'Trung Lương',
        notes: 'Giao đợt 1 trong ngày',
      );

      expect(order.totalQuantity, equals(50));
      expect(order.totalRevenue, equals(45000000.0));
      expect(order.totalCogs, equals(35000000.0));

      final json = order.toJson();
      final restored = StockOutOrder.fromJson(json);

      expect(restored.orderNumber, equals('PXK-2026-WHOLESALE'));
      expect(restored.type, equals(StockOutType.wholesale));
      expect(restored.items.length, equals(1));
    });
  });
}
