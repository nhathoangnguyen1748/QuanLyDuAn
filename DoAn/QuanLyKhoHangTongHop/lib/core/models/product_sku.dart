class ProductSKU {
  final String id;
  final String skuCode; // Mã quản lý nội bộ: SKU-xxx
  final String barcode; // EAN-13, Code 128
  final String name;
  final String categoryId;
  final String categoryName;
  final double costPrice; // Giá vốn bình quân gia quyền (MAC)
  final double sellingPrice; // Giá bán lẻ đề xuất
  final int currentStock;
  final int minSafetyStock;
  final int maxStock;
  final String locationTag; // VD: KHO-A-KAY-03, ZONE-B-RACK-02
  final String unit; // Cái, Hộp, Thùng, Kg, Bộ
  final DateTime? expiryDate;
  final DateTime? lastStockOutDate; // Dùng để xác định Dead Stock
  final DateTime createdAt;
  final String? notes;

  const ProductSKU({
    required this.id,
    required this.skuCode,
    required this.barcode,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.costPrice,
    required this.sellingPrice,
    required this.currentStock,
    required this.minSafetyStock,
    required this.maxStock,
    required this.locationTag,
    this.unit = 'Cái',
    this.expiryDate,
    this.lastStockOutDate,
    required this.createdAt,
    this.notes,
  });

  /// Tổng giá trị vốn tồn kho của mặt hàng
  double get totalInventoryValue => currentStock * costPrice;

  /// Kiểm tra cảnh báo tồn kho dưới ngưỡng an toàn
  bool get isLowStock => currentStock <= minSafetyStock;

  /// Kiểm tra cảnh báo vượt mức tồn trữ tối đa
  bool get isOverStock => currentStock > maxStock;

  /// Kiểm tra hàng cận hạn sử dụng (< 30 ngày)
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final diff = expiryDate!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 30;
  }

  /// Kiểm tra hàng đã hết hạn sử dụng
  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  /// Kiểm tra hàng tồn kho chậm luân chuyển (Dead Stock: không có xuất hàng trong > 60 ngày)
  bool get isDeadStock {
    if (currentStock <= 0) return false;
    if (lastStockOutDate == null) {
      return DateTime.now().difference(createdAt).inDays >= 60;
    }
    return DateTime.now().difference(lastStockOutDate!).inDays >= 60;
  }

  /// Số ngày tồn đọng không xuất hàng
  int get daysSinceLastMovement {
    final refDate = lastStockOutDate ?? createdAt;
    return DateTime.now().difference(refDate).inDays;
  }

  ProductSKU copyWith({
    String? id,
    String? skuCode,
    String? barcode,
    String? name,
    String? categoryId,
    String? categoryName,
    double? costPrice,
    double? sellingPrice,
    int? currentStock,
    int? minSafetyStock,
    int? maxStock,
    String? locationTag,
    String? unit,
    DateTime? expiryDate,
    DateTime? lastStockOutDate,
    DateTime? createdAt,
    String? notes,
  }) {
    return ProductSKU(
      id: id ?? this.id,
      skuCode: skuCode ?? this.skuCode,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      currentStock: currentStock ?? this.currentStock,
      minSafetyStock: minSafetyStock ?? this.minSafetyStock,
      maxStock: maxStock ?? this.maxStock,
      locationTag: locationTag ?? this.locationTag,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      lastStockOutDate: lastStockOutDate ?? this.lastStockOutDate,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skuCode': skuCode,
      'barcode': barcode,
      'name': name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'currentStock': currentStock,
      'minSafetyStock': minSafetyStock,
      'maxStock': maxStock,
      'locationTag': locationTag,
      'unit': unit,
      'expiryDate': expiryDate?.toIso8601String(),
      'lastStockOutDate': lastStockOutDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory ProductSKU.fromJson(Map<String, dynamic> json) {
    return ProductSKU(
      id: json['id'] as String,
      skuCode: json['skuCode'] as String,
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String? ?? 'Chung',
      costPrice: (json['costPrice'] as num).toDouble(),
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      currentStock: json['currentStock'] as int,
      minSafetyStock: json['minSafetyStock'] as int,
      maxStock: json['maxStock'] as int,
      locationTag: json['locationTag'] as String,
      unit: json['unit'] as String? ?? 'Cái',
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      lastStockOutDate: json['lastStockOutDate'] != null
          ? DateTime.parse(json['lastStockOutDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
    );
  }
}
