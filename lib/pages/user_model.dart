// lib/models/user_model.dart
class User {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String role;
  final DateTime? createdAt;

  User({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.role = 'user',
    this.createdAt,
  });

  // Convertir a mapa para SharedPreferences
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  // Crear desde mapa
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      role: map['role'] ?? 'user',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
    );
  }
}
