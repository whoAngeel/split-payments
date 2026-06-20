class User {
  final int id;
  final String email;
  final String name;
  final String walletAddressUrl;
  final String role;
  const User({
    required this.id,
    required this.email,
    required this.name,
    this.walletAddressUrl = '',
    this.role = 'buyer',
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String? ?? '',
      walletAddressUrl: json['wallet_address_url'] as String? ?? '',
      role: json['role'] as String? ?? 'buyer',
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'wallet_address_url': walletAddressUrl,
    'role': role,
  };

  bool get isAdmin => role == 'gallery_admin';
}
