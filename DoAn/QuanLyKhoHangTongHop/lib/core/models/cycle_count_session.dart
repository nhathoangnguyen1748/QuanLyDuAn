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
      skuId: json['skuId'] as String,
      skuCode: json['skuCode'] as String,
      skuName: json['skuName'] as String,
      barcode: json['barcode'] as String? ?? '',
      locationTag: json['locationTag'] as String,
      bookStock: json['bookStock'] as int,
      physicalCount: json['physicalCount'] as int? ?? 0,
      costPrice: (json['costPrice'] as num).toDouble(),
      isAudited: json['isAudited'] as bool? ?? false,
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
      'sessionCode': sessionCode,
      'title': title,
      'scope': scope,
      'status': status.name,
      'items': items.map((i) => i.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'auditorName': auditorName,
      'notes': notes,
    };
  }

  factory CycleCountSession.fromJson(Map<String, dynamic> json) {
    return CycleCountSession(
      id: json['id'] as String,
      sessionCode: json['sessionCode'] as String,
      title: json['title'] as String,
      scope: json['scope'] as String,
      status: CycleCountStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CycleCountStatus.inProgress,
      ),
      items: (json['items'] as List)
          .map((i) => CycleCountItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      auditorName: json['auditorName'] as String? ?? 'Admin Kho',
      notes: json['notes'] as String?,
    );
  }
}
