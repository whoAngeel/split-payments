class User {
  final int id;
  final String email;
  final String name;
  final String walletAddressUrl;
  const User({
    required this.id,
    required this.email,
    required this.name,
    this.walletAddressUrl = '',
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String? ?? '',
      walletAddressUrl: json['wallet_address_url'] as String? ?? '',
    );
  }
  Map<String, dynamic> toJson() => {
    'dD': id,
    'email': email,
    'name': name,
    'wallet_address_url': walletAddressUrl,
  };
}
