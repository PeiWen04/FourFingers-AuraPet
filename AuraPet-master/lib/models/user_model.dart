class UserModel {
  final String id;
  final String name;
  final String email;
  final String registrationDate;
  final String avatar;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.registrationDate,
    required this.avatar,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      registrationDate: data['registrationDate'] ?? '',
      avatar: data['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'registrationDate': registrationDate,
      'avatar': avatar,
    };
  }
}
