class UserModel {
  int? id;
  String email;
  String password; // hashed password
  String createdAt;

  UserModel({
    this.id,
    required this.email,
    required this.password,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      email: map['email'] as String,
      password: map['password'] as String,
      createdAt: map['createdAt'] as String,
    );
  }
}

