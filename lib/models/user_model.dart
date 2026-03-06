class AppUser {
  final int id; // This is the auto-increment ID from your users table
  final String authId; // This is the UUID from auth.users
  final String name;
  final String email;

  AppUser({
    required this.id,
    required this.authId,
    required this.name,
    required this.email,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      authId: json['auth_id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_id': authId,
      'name': name,
      'email': email,
    };
  }
}