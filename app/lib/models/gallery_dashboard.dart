class GalleryInfo {
  final int id;
  final String name;
  final int userId;
  const GalleryInfo({required this.id, required this.name, required this.userId});
  factory GalleryInfo.fromJson(Map<String, dynamic> json) {
    return GalleryInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      userId: json['user_id'] as int,
    );
  }
}

class GalleryDashboard {
  final GalleryInfo gallery;
  final int activeArtisans;
  final int totalArtisans;
  final int activeProducts;
  final int totalProducts;
  final int commissionRate;

  const GalleryDashboard({
    required this.gallery,
    required this.activeArtisans,
    required this.totalArtisans,
    required this.activeProducts,
    required this.totalProducts,
    required this.commissionRate,
  });

  factory GalleryDashboard.fromJson(Map<String, dynamic> json) {
    return GalleryDashboard(
      gallery: GalleryInfo.fromJson(json['gallery'] as Map<String, dynamic>),
      activeArtisans: (json['active_artisans'] as num).toInt(),
      totalArtisans: (json['total_artisans'] as num).toInt(),
      activeProducts: (json['active_products'] as num).toInt(),
      totalProducts: (json['total_products'] as num).toInt(),
      commissionRate: (json['commission_rate'] as num).toInt(),
    );
  }

  double get commissionPercent => commissionRate / 100.0;
}
