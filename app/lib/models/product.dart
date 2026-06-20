class ProductSplit {
  final int artisanPercent;
  final int galleryPercent;
  final int platformPercent;
  const ProductSplit({
    required this.artisanPercent,
    required this.galleryPercent,
    required this.platformPercent,
  });
  factory ProductSplit.fromJson(Map<String, dynamic> json) {
    return ProductSplit(
      artisanPercent: json['artisan_percent'] as int? ?? 0,
      galleryPercent: json['gallery_percent'] as int? ?? 0,
      platformPercent: json['platform_percent'] as int? ?? 0,
    );
  }
}

class Product {
  final int id;
  final String name;
  final int basePrice;
  final String assetCode;
  final int assetScale;
  final String artisanName;
  final String imageUrl;
  final ProductSplit? split;
  final bool isFavorited;
  const Product({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.assetCode,
    this.assetScale = 2,
    required this.artisanName,
    this.imageUrl = '',
    this.split,
    this.isFavorited = false,
  });
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      basePrice: json['base_price'] as int? ?? 0,
      assetCode: json['asset_code'] as String? ?? '',
      assetScale: json['asset_scale'] as int? ?? 2,
      artisanName: json['artisan_name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      split: json['split'] != null
          ? ProductSplit.fromJson(json['split'] as Map<String, dynamic>)
          : null,
      isFavorited: json['is_favorited'] as bool? ?? false,
    );
  }
}
