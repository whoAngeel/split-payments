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
    );
  }
}
