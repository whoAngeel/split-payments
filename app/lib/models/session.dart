import 'user.dart';

class Session {
  final String token;
  final User user;
  const Session({required this.token, required this.user});
  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
  Map<String, dynamic> toJson() => {'token': token, 'user': user.toJson()};
}
