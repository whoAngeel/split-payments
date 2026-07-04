import 'product.dart';

class ArtisanProfile {
  final int id;
  final String name;
  final String imageUrl;
  final String bio;
  final String walletAddressUrl;

  const ArtisanProfile({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.bio = '',
    this.walletAddressUrl = '',
  });

  factory ArtisanProfile.fromJson(Map<String, dynamic> json) {
    return ArtisanProfile(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      walletAddressUrl: json['wallet_address_url'] as String? ?? '',
    );
  }
}

class ProductDetail {
  final int id;
  final String name;
  final int basePrice;
  final String assetCode;
  final int assetScale;
  final String imageUrl;
  final String description;
  final String materials;
  final String dimensions;
  final List<String> tags;
  final List<String> images;
  final ArtisanProfile artisan;
  final ProductSplit? split;

  const ProductDetail({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.assetCode,
    this.assetScale = 2,
    this.imageUrl = '',
    this.description = '',
    this.materials = '',
    this.dimensions = '',
    this.tags = const [],
    this.images = const [],
    required this.artisan,
    this.split,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      basePrice: json['base_price'] as int? ?? 0,
      assetCode: json['asset_code'] as String? ?? '',
      assetScale: json['asset_scale'] as int? ?? 2,
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      materials: json['materials'] as String? ?? '',
      dimensions: json['dimensions'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      artisan: ArtisanProfile.fromJson(json['artisan'] as Map<String, dynamic>),
      split: json['split'] != null
          ? ProductSplit.fromJson(json['split'] as Map<String, dynamic>)
          : null,
    );
  }
}
