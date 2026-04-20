class ReaderProfileEntity {
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

  const ReaderProfileEntity({
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
}
