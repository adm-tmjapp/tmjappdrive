class User {
  String? id;
  String? name;
  String? email;
  String? phone;
  String? cpfMasked;
  String? walletAvailableMasked;
  String? role;
  bool? emailVerified;
  bool? phoneVerified;
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
    this.emailVerified,
    this.phoneVerified,
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
      emailVerified: _asBool(json["emailVerified"] ?? json["email_verified"]),
      phoneVerified: _asBool(json["phoneVerified"] ?? json["phone_verified"]),
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
      "emailVerified": emailVerified,
      "phoneVerified": phoneVerified,
      "password": password,
      "creatAt": creatAt,
    };
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }
}
