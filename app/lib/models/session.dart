import 'user.dart';

class Session {
  final String token;
  final User user;
  final int galleryId;
  const Session({required this.token, required this.user, this.galleryId = 0});
  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      galleryId: (json['gallery_id'] as num?)?.toInt() ?? 0,
    );
  }
  Map<String, dynamic> toJson() => {
    'token': token,
    'user': user.toJson(),
    'gallery_id': galleryId,
  };

  bool get isAdmin => user.role == 'gallery_admin';
}
