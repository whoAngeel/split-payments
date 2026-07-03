/// Resumen agregado de pagos de una galería (montos en unidades menores).
class GalleryPaymentsSummary {
  final int totalSold;
  final int galleryEarned;
  final int completedCount;
  final int pendingCount;
  final String assetCode;
  final int assetScale;

  const GalleryPaymentsSummary({
    this.totalSold = 0,
    this.galleryEarned = 0,
    this.completedCount = 0,
    this.pendingCount = 0,
    this.assetCode = 'USD',
    this.assetScale = 2,
  });

  factory GalleryPaymentsSummary.fromJson(Map<String, dynamic> json) {
    return GalleryPaymentsSummary(
      totalSold: json['total_sold'] as int? ?? 0,
      galleryEarned: json['gallery_earned'] as int? ?? 0,
      completedCount: json['completed_count'] as int? ?? 0,
      pendingCount: json['pending_count'] as int? ?? 0,
      assetCode: json['asset_code'] as String? ?? 'USD',
      assetScale: json['asset_scale'] as int? ?? 2,
    );
  }
}

/// Pagos de una galería junto con su resumen.
class GalleryPayments {
  final GalleryPaymentsSummary summary;
  final List<Payment> payments;

  const GalleryPayments({required this.summary, required this.payments});

  factory GalleryPayments.fromJson(Map<String, dynamic> json) {
    return GalleryPayments(
      summary: GalleryPaymentsSummary.fromJson(
        (json['summary'] as Map<String, dynamic>?) ?? const {},
      ),
      payments: ((json['payments'] as List<dynamic>?) ?? const [])
          .map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Payment {
  final int id;
  final String sessionId;
  final String productName;
  final String artisanName;
  final String galleryName;
  final int totalAmount;
  final String assetCode;
  final int assetScale;
  final int artisanShare;
  final int galleryShare;
  final String status;
  final DateTime? completedAt;
  final DateTime createdAt;
  const Payment({
    required this.id,
    required this.sessionId,
    required this.productName,
    required this.artisanName,
    this.galleryName = '',
    required this.totalAmount,
    required this.assetCode,
    this.assetScale = 2,
    this.artisanShare = 0,
    this.galleryShare = 0,
    required this.status,
    this.completedAt,
    required this.createdAt,
  });
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int? ?? 0,
      sessionId: json['session_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      artisanName: json['artisan_name'] as String? ?? '',
      galleryName: json['gallery_name'] as String? ?? '',
      totalAmount: json['total_amount'] as int? ?? 0,
      assetCode: json['asset_code'] as String? ?? '',
      assetScale: json['asset_scale'] as int? ?? 2,
      artisanShare: json['artisan_share'] as int? ?? 0,
      galleryShare: json['gallery_share'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
