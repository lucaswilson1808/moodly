class UserModel {
  final String id;
  final String email;
  final String username;
  final String? profilePictureUrl; // Nullable - user might not have one yet
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.profilePictureUrl,       //Need firebase_storage for this
    required this.createdAt,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'profilePictureUrl': profilePictureUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Firebase Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'],
      username: map['username'],
      profilePictureUrl: map['profilePictureUrl'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? id,                            //? means it can be null
    String? email,
    String? username,
    String? profilePictureUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}