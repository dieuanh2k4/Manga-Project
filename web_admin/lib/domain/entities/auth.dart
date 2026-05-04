class AuthEntity {
  final String userName;
  final String role;
  final String token;

  const AuthEntity({
    required this.userName,
    required this.role,
    required this.token,
  });
}
