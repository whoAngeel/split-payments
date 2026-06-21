class Artisan {
  final int id;
  final String name;
  final String walletAddressUrl;
  final String imageUrl;
  final String bio;
  final String location;
  final String specialty;
  final String craftType;
  final String tags;
  final bool isActive;

  const Artisan({
    required this.id,
    required this.name,
    this.walletAddressUrl = '',
    this.imageUrl = '',
    this.bio = '',
    this.location = '',
    this.specialty = '',
    this.craftType = '',
    this.tags = '',
    this.isActive = true,
  });

  factory Artisan.fromJson(Map<String, dynamic> json) {
    return Artisan(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      walletAddressUrl: json['wallet_address_url'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      location: json['location'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      craftType: json['craft_type'] as String? ?? '',
      tags: json['tags'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'wallet_address_url': walletAddressUrl,
    'image_url': imageUrl,
    'bio': bio,
    'location': location,
    'specialty': specialty,
    'craft_type': craftType,
    'tags': tags,
    'is_active': isActive,
  };

  Artisan copyWith({
    String? name,
    String? walletAddressUrl,
    String? imageUrl,
    String? bio,
    String? location,
    String? specialty,
    String? craftType,
    String? tags,
    bool? isActive,
  }) {
    return Artisan(
      id: id,
      name: name ?? this.name,
      walletAddressUrl: walletAddressUrl ?? this.walletAddressUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      specialty: specialty ?? this.specialty,
      craftType: craftType ?? this.craftType,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
    );
  }

  String get subtitle {
    final parts = <String>[];
    if (location.isNotEmpty) parts.add(location);
    if (specialty.isNotEmpty) parts.add(specialty);
    return parts.join(' · ');
  }
}
