import 'package:flutter_test/flutter_test.dart';
import 'package:smartstock_admin/core/models/cycle_count_session.dart';

void main() {
  group('Kiểm thử Phân hệ Kiểm kê Định kỳ (Cycle Counting) - Quang Minh', () {
    test('1. Kiểm thử CycleCountItem: Trạng thái Chưa kiểm', () {
      final item = CycleCountItem(
        skuId: 'sku-01',
        skuCode: 'SKU-TEST-01',
        skuName: 'Sản phẩm Test',
        barcode: '893000000001',
        locationTag: 'KHO-A-KAY-01',
        bookStock: 50,
        costPrice: 100000,
        isAudited: false,
      );

      expect(item.isAudited, isFalse);
      expect(item.discrepancyStatus, equals('CHƯA KIỂM'));
    });

    test('2. Kiểm thử CycleCountItem: Đối soát Khớp tồn sổ sách', () {
      final item = CycleCountItem(
        skuId: 'sku-01',
        skuCode: 'SKU-TEST-01',
        skuName: 'Sản phẩm Test',
        barcode: '893000000001',
        locationTag: 'KHO-A-KAY-01',
        bookStock: 40,
        physicalCount: 40,
        costPrice: 150000,
        isAudited: true,
      );

      expect(item.varianceQty, equals(0));
      expect(item.variancePercent, equals(0.0));
      expect(item.varianceValue, equals(0.0));
      expect(item.discrepancyStatus, equals('KHỚP'));
    });

    test('3. Kiểm thử CycleCountItem: Thừa hàng thực tế (Surplus)', () {
      // Sổ sách: 30, Thực tế: 35 => Thừa +5 cái (+16.67%)
      final item = CycleCountItem(
        skuId: 'sku-02',
        skuCode: 'SKU-TEST-02',
        skuName: 'Hàng Thừa Test',
        barcode: '893000000002',
        locationTag: 'KHO-A-KAY-02',
        bookStock: 30,
        physicalCount: 35,
        costPrice: 200000,
        isAudited: true,
      );

      expect(item.varianceQty, equals(5));
      expect(item.varianceValue, equals(1000000.0));
      expect(item.variancePercent, closeTo(16.67, 0.01));
      expect(item.discrepancyStatus, equals('THỪA'));
    });

    test('4. Kiểm thử CycleCountItem: Thiếu hụt hàng thực tế (Deficit)', () {
      // Sổ sách: 20, Thực tế: 17 => Thiếu -3 cái (-15%)
      final item = CycleCountItem(
        skuId: 'sku-03',
        skuCode: 'SKU-TEST-03',
        skuName: 'Hàng Thiếu Test',
        barcode: '893000000003',
        locationTag: 'KHO-B-KAY-01',
        bookStock: 20,
        physicalCount: 17,
        costPrice: 500000,
        isAudited: true,
      );

      expect(item.varianceQty, equals(-3));
      expect(item.varianceValue, equals(-1500000.0));
      expect(item.variancePercent, equals(-15.0));
      expect(item.discrepancyStatus, equals('THIẾU'));
    });

    test('5. Kiểm thử CycleCountItem: Trường hợp Sổ sách = 0 nhưng thực tế có hàng', () {
      final item = CycleCountItem(
        skuId: 'sku-04',
        skuCode: 'SKU-TEST-04',
        skuName: 'Hàng Phát Sinh Mới',
        barcode: '893000000004',
        locationTag: 'KHO-C-KAY-01',
        bookStock: 0,
        physicalCount: 10,
        costPrice: 80000,
        isAudited: true,
      );

      expect(item.varianceQty, equals(10));
      expect(item.variancePercent, equals(100.0));
      expect(item.varianceValue, equals(800000.0));
      expect(item.discrepancyStatus, equals('THỪA'));
    });

    test('6. Kiểm thử CycleCountSession: Tính tổng chỉ số kiểm kê toàn đợt', () {
      final items = [
        CycleCountItem(
          skuId: 'sku-1',
          skuCode: 'SKU-01',
          skuName: 'Mặt hàng 1',
          barcode: '893001',
          locationTag: 'A1',
          bookStock: 100,
          physicalCount: 100,
          costPrice: 50000,
          isAudited: true, // Khớp
        ),
        CycleCountItem(
          skuId: 'sku-2',
          skuCode: 'SKU-02',
          skuName: 'Mặt hàng 2',
          barcode: '893002',
          locationTag: 'A2',
          bookStock: 50,
          physicalCount: 52,
          costPrice: 100000,
          isAudited: true, // Thừa +2 (Trị giá +200k)
        ),
        CycleCountItem(
          skuId: 'sku-3',
          skuCode: 'SKU-03',
          skuName: 'Mặt hàng 3',
          barcode: '893003',
          locationTag: 'A3',
          bookStock: 40,
          physicalCount: 37,
          costPrice: 200000,
          isAudited: true, // Thiếu -3 (Trị giá -600k)
        ),
        CycleCountItem(
          skuId: 'sku-4',
          skuCode: 'SKU-04',
          skuName: 'Mặt hàng 4',
          barcode: '893004',
          locationTag: 'A4',
          bookStock: 20,
          physicalCount: 0,
          costPrice: 30000,
          isAudited: false, // Chưa kiểm
        ),
      ];

      final session = CycleCountSession(
        id: 'session-01',
        sessionCode: 'KK-2026-TEST',
        title: 'Đợt kiểm kê mẫu',
        scope: 'Khu vực A',
        items: items,
        createdAt: DateTime(2026, 9, 29),
      );

      expect(session.totalBookStock, equals(210));
      expect(session.auditedCount, equals(3));
      expect(session.matchedItemsCount, equals(1));
      expect(session.discrepancyItemsCount, equals(2));
      expect(session.totalSurplusQty, equals(2));
      expect(session.totalDeficitQty, equals(3));
      // Lệch giá trị: +200k - 600k = -400k
      expect(session.totalVarianceValue, equals(-400000.0));
    });

    test('7. Kiểm thử CycleCountSession JSON Serialization & Deserialization', () {
      final originalSession = CycleCountSession(
        id: 'sess-json-01',
        sessionCode: 'KK-JSON-001',
        title: 'Kiểm kê JSON test',
        scope: 'Toàn kho',
        status: CycleCountStatus.completed,
        createdAt: DateTime(2026, 9, 29, 10, 0),
        completedAt: DateTime(2026, 9, 29, 12, 0),
        auditorName: 'Quang Minh Tester',
        notes: 'Kiểm tra khớp dữ liệu',
        items: [
          CycleCountItem(
            skuId: 'sku-json',
            skuCode: 'SKU-JSON-1',
            skuName: 'Sản phẩm JSON',
            barcode: '89399999',
            locationTag: 'RACK-01',
            bookStock: 15,
            physicalCount: 15,
            costPrice: 250000,
            isAudited: true,
          ),
        ],
      );

      final json = originalSession.toJson();
      final restoredSession = CycleCountSession.fromJson(json);

      expect(restoredSession.id, equals(originalSession.id));
      expect(restoredSession.sessionCode, equals(originalSession.sessionCode));
      expect(restoredSession.title, equals(originalSession.title));
      expect(restoredSession.status, equals(CycleCountStatus.completed));
      expect(restoredSession.auditorName, equals('Quang Minh Tester'));
      expect(restoredSession.notes, equals('Kiểm tra khớp dữ liệu'));
      expect(restoredSession.items.length, equals(1));
      expect(restoredSession.items.first.skuCode, equals('SKU-JSON-1'));
      expect(restoredSession.items.first.isAudited, isTrue);
      expect(restoredSession.items.first.discrepancyStatus, equals('KHỚP'));
    });
  });
}
