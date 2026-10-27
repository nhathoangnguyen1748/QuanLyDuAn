import 'dart:convert';

enum CycleCountStatus {
  inProgress('Đang kiểm kê'),
  completed('Đã hoàn tất kiểm đếm'),
  reconciled('Đã điều chỉnh kho');

  final String label;
  const CycleCountStatus(this.label);
}

class CycleCountItem {
  final String skuId;
  final String skuCode;
  final String skuName;
  final String barcode;
  final String locationTag;
  final int bookStock; // Tồn trên sổ sách
  int physicalCount; // Số lượng thực tế kiểm đếm
  final double costPrice;
  bool isAudited;

  CycleCountItem({
    required this.skuId,
    required this.skuCode,
    required this.skuName,
    required this.barcode,
    required this.locationTag,
    required this.bookStock,
    this.physicalCount = 0,
    required this.costPrice,
    this.isAudited = false,
  });

  /// Chênh lệch số lượng (Thực tế - Sổ sách)
  int get varianceQty => physicalCount - bookStock;

  /// Phần trăm chênh lệch
  double get variancePercent {
    if (bookStock == 0) return physicalCount > 0 ? 100.0 : 0.0;
    return ((physicalCount - bookStock) / bookStock) * 100;
  }

  /// Giá trị tiền chênh lệch (VND)
  double get varianceValue => varianceQty * costPrice;

  /// Trạng thái: 'KHỚP', 'THỪA', 'THIẾU', 'CHƯA KIỂM'
  String get discrepancyStatus {
    if (!isAudited) return 'CHƯA KIỂM';
    if (varianceQty == 0) return 'KHỚP';
    if (varianceQty > 0) return 'THỪA';
    return 'THIẾU';
  }

  Map<String, dynamic> toJson() {
    return {
      'skuId': skuId,
      'skuCode': skuCode,
      'skuName': skuName,
      'barcode': barcode,
      'locationTag': locationTag,
      'bookStock': bookStock,
      'physicalCount': physicalCount,
      'costPrice': costPrice,
      'isAudited': isAudited,
    };
  }

  factory CycleCountItem.fromJson(Map<String, dynamic> json) {
    return CycleCountItem(
      skuId: (json['skuId'] ?? json['sku_id'] ?? '') as String,
      skuCode: (json['skuCode'] ?? json['sku_code'] ?? '') as String,
      skuName: (json['skuName'] ?? json['sku_name'] ?? '') as String,
      barcode: (json['barcode'] ?? '') as String,
      locationTag: (json['locationTag'] ?? json['location_tag'] ?? '') as String,
      bookStock: ((json['bookStock'] ?? json['book_stock'] ?? 0) as num).toInt(),
      physicalCount: ((json['physicalCount'] ?? json['physical_count'] ?? 0) as num).toInt(),
      costPrice: ((json['costPrice'] ?? json['cost_price'] ?? 0) as num).toDouble(),
      isAudited: (json['isAudited'] ?? json['is_audited'] ?? false) as bool,
    );
  }
}

class CycleCountSession {
  final String id;
  final String sessionCode; // KK-2026-001
  final String title;
  final String scope; // Toàn kho, Kệ A, Ngành Điện tử,...
  CycleCountStatus status;
  final List<CycleCountItem> items;
  final DateTime createdAt;
  DateTime? completedAt;
  final String auditorName;
  String? notes;

  CycleCountSession({
    required this.id,
    required this.sessionCode,
    required this.title,
    required this.scope,
    this.status = CycleCountStatus.inProgress,
    required this.items,
    required this.createdAt,
    this.completedAt,
    this.auditorName = 'Admin Kho',
    this.notes,
  });

  int get totalBookStock => items.fold(0, (sum, i) => sum + i.bookStock);
  int get totalPhysicalCount => items.fold(0, (sum, i) => sum + i.physicalCount);
  int get auditedCount => items.where((i) => i.isAudited).length;

  int get discrepancyItemsCount => items.where((i) => i.isAudited && i.varianceQty != 0).length;
  int get matchedItemsCount => items.where((i) => i.isAudited && i.varianceQty == 0).length;

  int get totalSurplusQty => items.where((i) => i.isAudited && i.varianceQty > 0).fold(0, (sum, i) => sum + i.varianceQty);
  int get totalDeficitQty => items.where((i) => i.isAudited && i.varianceQty < 0).fold(0, (sum, i) => sum + i.varianceQty.abs());

  double get totalVarianceValue => items.where((i) => i.isAudited).fold(0.0, (sum, i) => sum + i.varianceValue);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_code': sessionCode,
      'title': title,
      'scope': scope,
      'status': status.name,
      'items': items.map((i) => i.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'auditor_name': auditorName,
      'notes': notes,
    };
  }

  factory CycleCountSession.fromJson(Map<String, dynamic> json) {
    List<CycleCountItem> parsedItems = [];
    final rawItems = json['items'];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          parsedItems.add(CycleCountItem.fromJson(Map<String, dynamic>.from(item)));
        } else if (item is String) {
          parsedItems.add(CycleCountItem.fromJson(jsonDecode(item) as Map<String, dynamic>));
        }
      }
    }

    final rawStatus = (json['status'] ?? 'inProgress') as String;
    return CycleCountSession(
      id: (json['id'] ?? '') as String,
      sessionCode: (json['session_code'] ?? json['sessionCode'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      scope: (json['scope'] ?? 'Toàn kho') as String,
      status: CycleCountStatus.values.firstWhere(
        (e) => e.name == rawStatus,
        orElse: () => CycleCountStatus.inProgress,
      ),
      items: parsedItems,
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.parse((json['created_at'] ?? json['createdAt']) as String)
          : DateTime.now(),
      completedAt: (json['completed_at'] ?? json['completedAt']) != null
          ? DateTime.parse((json['completed_at'] ?? json['completedAt']) as String)
          : null,
      auditorName: (json['auditor_name'] ?? json['auditorName'] ?? 'Admin Kho') as String,
      notes: json['notes'] as String?,
    );
  }
}
