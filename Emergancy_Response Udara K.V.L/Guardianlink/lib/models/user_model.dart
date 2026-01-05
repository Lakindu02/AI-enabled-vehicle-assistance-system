enum UserType { user, police, hospital, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoBase64;
  final String? nicNumber;
  final String? address;
  final String? bloodGroup;
  final UserType userType;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoBase64,
    this.nicNumber,
    this.address,
    this.bloodGroup,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<dynamic, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      photoBase64: json['photoBase64'],
      nicNumber: json['nicNumber'],
      address: json['address'],
      bloodGroup: json['bloodGroup'],
      userType: UserType.values.firstWhere(
        (e) => e.toString() == 'UserType.${json['userType']}',
        orElse: () => UserType.user,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoBase64': photoBase64,
      'nicNumber': nicNumber,
      'address': address,
      'bloodGroup': bloodGroup,
      'userType': userType.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoBase64,
    String? nicNumber,
    String? address,
    String? bloodGroup,
    UserType? userType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoBase64: photoBase64 ?? this.photoBase64,
      nicNumber: nicNumber ?? this.nicNumber,
      address: address ?? this.address,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
