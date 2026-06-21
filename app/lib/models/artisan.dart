class Artisan {
  final int id;
  final String name;
  final String walletAddressUrl;
  final String imageUrl;
  final String bio;
  final bool isActive;

  const Artisan({
    required this.id,
    required this.name,
    this.walletAddressUrl = '',
    this.imageUrl = '',
    this.bio = '',
    this.isActive = true,
  });

  factory Artisan.fromJson(Map<String, dynamic> json) {
    return Artisan(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      walletAddressUrl: json['wallet_address_url'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'wallet_address_url': walletAddressUrl,
    'image_url': imageUrl,
    'bio': bio,
    'is_active': isActive,
  };

  Artisan copyWith({
    String? name,
    String? walletAddressUrl,
    String? imageUrl,
    String? bio,
    bool? isActive,
  }) {
    return Artisan(
      id: id,
      name: name ?? this.name,
      walletAddressUrl: walletAddressUrl ?? this.walletAddressUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      isActive: isActive ?? this.isActive,
    );
  }
}
