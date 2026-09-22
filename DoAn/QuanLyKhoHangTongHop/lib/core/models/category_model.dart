class CategoryModel {
  final String id;
  final String code;
  final String name;
  final int colorHex;
  final String? description;

  const CategoryModel({
    required this.id,
    required this.code,
    required this.name,
    required this.colorHex,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'colorHex': colorHex,
      'description': description,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      colorHex: json['colorHex'] as int,
      description: json['description'] as String?,
    );
  }
}
