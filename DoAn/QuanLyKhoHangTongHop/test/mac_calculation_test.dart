import 'package:flutter_test/flutter_test.dart';
import 'package:smartstock_admin/core/utils/inventory_math.dart';

void main() {
  group('Kiểm thử Thuật toán Giá vốn bình quân gia quyền (Moving Average Cost - MAC)', () {
    test('Tính MAC với số lượng và đơn giá bình thường', () {
      // Tồn cũ: 10 cái giá 100.000 (Tổng = 1.000.000)
      // Nhập mới: 10 cái giá 120.000 (Tổng = 1.200.000)
      // Tổng tồn mới: 20 cái, tổng vốn: 2.200.000 => MAC mới = 110.000
      final mac = InventoryMath.calculateMAC(
        currentStock: 10,
        currentCostPrice: 100000,
        newQuantity: 10,
        newUnitPrice: 120000,
      );

      expect(mac, equals(110000.0));
    });

    test('Tính MAC với trọng số số lượng không đều nhau', () {
      // Tồn cũ: 40 cái giá 50.000 (Tổng = 2.000.000)
      // Nhập mới: 10 cái giá 100.000 (Tổng = 1.000.000)
      // Tổng tồn: 50 cái, tổng vốn: 3.000.000 => MAC mới = 60.000
      final mac = InventoryMath.calculateMAC(
        currentStock: 40,
        currentCostPrice: 50000,
        newQuantity: 10,
        newUnitPrice: 100000,
      );

      expect(mac, equals(60000.0));
    });

    test('Tính MAC khi tồn kho cũ bằng 0', () {
      // Tồn cũ = 0, nhập mới giá 250.000 => MAC mới phải bằng 250.000
      final mac = InventoryMath.calculateMAC(
        currentStock: 0,
        currentCostPrice: 0,
        newQuantity: 15,
        newUnitPrice: 250000,
      );

      expect(mac, equals(250000.0));
    });

    test('Tính MAC khi số lượng nhập mới <= 0', () {
      // Không nhập thêm hàng => giữ nguyên giá vốn cũ
      final mac = InventoryMath.calculateMAC(
        currentStock: 25,
        currentCostPrice: 85000,
        newQuantity: 0,
        newUnitPrice: 100000,
      );

      expect(mac, equals(85000.0));
    });
  });
}
