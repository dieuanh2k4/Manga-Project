import '../../domain/entities/reader_profile_entity.dart';

class ReaderProfileModel {
  final int id;
  final int userId;
  final String? fullName;
  final String? email;
  final String? avatar;
  final bool isPremium;
  final String? birth;
  final String? gender;
  final String? phone;
  final String? address;

  const ReaderProfileModel({
    required this.id,
    required this.userId,
    this.fullName,
    this.email,
    this.avatar,
    required this.isPremium,
    this.birth,
    this.gender,
    this.phone,
    this.address,
  });

  factory ReaderProfileModel.fromJson(Map<String, dynamic> json) {
    return ReaderProfileModel(
      id: json['id'] ?? json['Id'] ?? 0,
      userId: json['userId'] ?? json['UserId'] ?? 0,
      fullName: (json['fullName'] ?? json['FullName'])?.toString(),
      email: (json['email'] ?? json['Email'])?.toString(),
      avatar: (json['avatar'] ?? json['Avatar'])?.toString(),
      isPremium: json['isPremium'] ?? json['IsPremium'] ?? false,
      birth: (json['birth'] ?? json['Birth'])?.toString(),
      gender: (json['gender'] ?? json['Gender'])?.toString(),
      phone: (json['phone'] ?? json['Phone'])?.toString(),
      address: (json['address'] ?? json['Address'])?.toString(),
    );
  }

  ReaderProfileEntity toEntity() {
    return ReaderProfileEntity(
      id: id,
      userId: userId,
      fullName: fullName,
      email: email,
      avatar: avatar,
      isPremium: isPremium,
      birth: birth,
      gender: gender,
      phone: phone,
      address: address,
    );
  }
}
