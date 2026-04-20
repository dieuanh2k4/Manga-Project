class AuthSessionEntity {
  final String userName;
  final String role;
  final String token;

  const AuthSessionEntity({
    required this.userName,
    required this.role,
    required this.token,
  });
}
