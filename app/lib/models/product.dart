class Product {
  final int id;
  final String name;
  final int basePrice;
  final String assetCode;
  final int artisanId;
  final int assetScale;
  final String artisanName;
  final String imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.assetCode,
    this.assetScale = 2,
    required this.artisanId,
    required this.artisanName,
    this.imageUrl = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      basePrice: json['base_price'] as int? ?? 0,
      assetCode: json['asset_code'] as String? ?? '',
      assetScale: json['asset_scale'] as int? ?? 2,
      artisanId: json['artisan_id'] as int? ?? 0,
      artisanName: json['artisan_name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'base_price': basePrice,
    'asset_code': assetCode,
    'asset_scale': assetScale,
    'artisan_id': artisanId,
    'image_url': imageUrl,
  };
}
