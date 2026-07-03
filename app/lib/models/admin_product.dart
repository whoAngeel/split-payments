class AdminProduct {
  final int id;
  final int artisanId;
  final String artisanName;
  final String name;
  final int basePrice;
  final String assetCode;
  final int assetScale;
  final String imageUrl;
  final bool isActive;
  final int commissionRate;
  final String description;
  final String materials;
  final String dimensions;
  final String tags;

  const AdminProduct({
    required this.id,
    required this.artisanId,
    required this.artisanName,
    required this.name,
    required this.basePrice,
    required this.assetCode,
    this.assetScale = 2,
    this.imageUrl = '',
    this.isActive = true,
    this.commissionRate = 0,
    this.description = '',
    this.materials = '',
    this.dimensions = '',
    this.tags = '',
  });

  factory AdminProduct.fromJson(Map<String, dynamic> json) {
    final artisan = json['artisan'] as Map<String, dynamic>?;
    return AdminProduct(
      id: json['id'] as int,
      artisanId: json['artisan_id'] as int? ?? 0,
      artisanName: artisan?['name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      basePrice: json['base_price'] as int? ?? 0,
      assetCode: json['asset_code'] as String? ?? '',
      assetScale: json['asset_scale'] as int? ?? 2,
      imageUrl: json['image_url'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      commissionRate: json['commission_rate'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      materials: json['materials'] as String? ?? '',
      dimensions: json['dimensions'] as String? ?? '',
      tags: json['tags'] as String? ?? '',
    );
  }

  double get commissionPercent => commissionRate / 100.0;

  factory AdminProduct.fromDetailJson(Map<String, dynamic> json) {
    final artisan = json['artisan'] as Map<String, dynamic>?;
    return AdminProduct(
      id: json['id'] as int,
      artisanId: artisan?['id'] as int? ?? 0,
      artisanName: artisan?['name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      basePrice: json['base_price'] as int? ?? 0,
      assetCode: json['asset_code'] as String? ?? '',
      assetScale: json['asset_scale'] as int? ?? 2,
      imageUrl: json['image_url'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      commissionRate: json['commission_rate'] as int? ?? (json['split'] != null ? (100 - ((json['split'] as Map)['artisan_percent'] as int)) * 100 : 0),
      description: json['description'] as String? ?? '',
      materials: json['materials'] as String? ?? '',
      dimensions: json['dimensions'] as String? ?? '',
      tags: json['tags'] is List ? (json['tags'] as List).join(', ') : (json['tags'] as String? ?? ''),
    );
  }
}
