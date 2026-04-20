import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _loginUserName = TextEditingController(text: 'reader01');
  final _loginPassword = TextEditingController(text: 'reader123');

  final _regFullName = TextEditingController();
  final _regUserName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPhone = TextEditingController();
  final _regBirth = TextEditingController();
  final _regAddress = TextEditingController();
  final _regPassword = TextEditingController();
  String _gender = 'Male';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUserName.dispose();
    _loginPassword.dispose();
    _regFullName.dispose();
    _regUserName.dispose();
    _regEmail.dispose();
    _regPhone.dispose();
    _regBirth.dispose();
    _regAddress.dispose();
    _regPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFE9E9E9),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  Container(
                    width: 122,
                    height: 122,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF6B00),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'M-',
                      style: TextStyle(fontSize: 42, color: Color(0xFF2B2B2B)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Welcome to MangaMinus',
                    style: TextStyle(
                      color: Color(0xFFBC5308),
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white,
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF7A7A7A),
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFFF6B00),
                      ),
                      tabs: const [
                        Tab(text: 'LOGIN'),
                        Tab(text: 'REGISTER'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (auth.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        auth.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF9B1B1B), fontSize: 13),
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLoginTab(auth),
                        _buildRegisterTab(auth),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab(AuthController auth) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _FieldLabel('Username'),
          _RoundedInput(controller: _loginUserName),
          const SizedBox(height: 8),
          _FieldLabel('Password'),
          _RoundedInput(controller: _loginPassword, obscureText: true),
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('Tài khoản seed: reader01/reader123', style: TextStyle(fontSize: 11, color: Colors.black45)),
          ),
          const SizedBox(height: 10),
          _MainButton(
            label: auth.isBusy ? 'LOADING...' : 'LOG IN',
            onTap: auth.isBusy
                ? null
                : () async {
                    final ok = await auth.login(
                      _loginUserName.text.trim(),
                      _loginPassword.text,
                    );
                    if (!mounted) {
                      return;
                    }
                    if (!ok) {
                      return;
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterTab(AuthController auth) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel('Full Name'),
          _RoundedInput(controller: _regFullName),
          const SizedBox(height: 8),
          _FieldLabel('Username'),
          _RoundedInput(controller: _regUserName),
          const SizedBox(height: 8),
          _FieldLabel('Email'),
          _RoundedInput(controller: _regEmail),
          const SizedBox(height: 8),
          _FieldLabel('Phone'),
          _RoundedInput(controller: _regPhone),
          const SizedBox(height: 8),
          _FieldLabel('Birth (yyyy-MM-dd)'),
          _RoundedInput(controller: _regBirth),
          const SizedBox(height: 8),
          _FieldLabel('Address'),
          _RoundedInput(controller: _regAddress),
          const SizedBox(height: 8),
          _FieldLabel('Gender'),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (value) {
              setState(() {
                _gender = value ?? 'Male';
              });
            },
            decoration: _roundedDecoration(),
          ),
          const SizedBox(height: 8),
          _FieldLabel('Password'),
          _RoundedInput(controller: _regPassword, obscureText: true),
          const SizedBox(height: 10),
          _MainButton(
            label: auth.isBusy ? 'LOADING...' : 'REGISTER',
            onTap: auth.isBusy
                ? null
                : () async {
                    final payload = RegisterPayload(
                      userName: _regUserName.text.trim(),
                      password: _regPassword.text,
                      fullName: _regFullName.text.trim(),
                      email: _regEmail.text.trim(),
                      phone: _regPhone.text.trim(),
                      birth: _regBirth.text.trim(),
                      gender: _gender,
                      address: _regAddress.text.trim(),
                    );

                    final ok = await auth.register(payload);
                    if (!mounted) {
                      return;
                    }

                    if (!ok) {
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dang ky thanh cong, vui long dang nhap.')),
                    );
                    _tabController.animateTo(0);
                  },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  InputDecoration _roundedDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFF2F2F2),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF4A4A4A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 1.5),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 3),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF3F3F3F))),
    );
  }
}

class _RoundedInput extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;

  const _RoundedInput({required this.controller, this.obscureText = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF4A4A4A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 1.5),
        ),
      ),
    );
  }
}

class _MainButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _MainButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B00),
          foregroundColor: const Color(0xFF222222),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(label),
      ),
    );
  }
}
