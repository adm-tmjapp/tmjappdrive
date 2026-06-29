class User {
  String? id;
  String? name;
  String? email;
  String? phone;
  String? cpfMasked;
  String? walletAvailableMasked;
  String? role;
  String? password;
  String? creatAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.cpfMasked,
    this.walletAvailableMasked,
    required this.password,
    required this.role,
    required this.creatAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"],
      name: json["name"],
      email: json["email"],
      phone: json["phone"],
      cpfMasked: json["cpfMasked"] ?? json["cpf_masked"],
      walletAvailableMasked:
          json["walletAvailableMasked"] ?? json["wallet_available_masked"],
      role: json["role"],
      password: json["password"],
      creatAt: json["creatAt"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "phone": phone,
      "cpfMasked": cpfMasked,
      "walletAvailableMasked": walletAvailableMasked,
      "role": role,
      "password": password,
      "creatAt": creatAt,
    };
  }
}
