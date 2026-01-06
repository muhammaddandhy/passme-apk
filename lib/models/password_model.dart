class PasswordModel {
  int? id;
  String title;
  String username;
  String password;
  String? url;
  String? notes;
  String createdAt;
  String iconType;
  String category;
  String? passwordHistory; // New: JSON string to store history

  PasswordModel({
    this.id,
    required this.title,
    required this.username,
    required this.password,
    this.url,
    this.notes,
    required this.createdAt,
    this.iconType = 'default',
    this.category = 'Lainnya',
    this.passwordHistory,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'password': password,
      'url': url,
      'notes': notes,
      'createdAt': createdAt,
      'iconType': iconType,
      'category': category,
      'passwordHistory': passwordHistory,
    };
  }

  factory PasswordModel.fromMap(Map<String, dynamic> map) {
    return PasswordModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
      url: map['url'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] as String,
      iconType: map['iconType'] as String? ?? 'default',
      category: map['category'] as String? ?? 'Lainnya',
      passwordHistory: map['passwordHistory'] as String?,
    );
  }
}

