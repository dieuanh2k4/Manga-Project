import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _gender = 'Nam'; // Default
  bool _obscurePassword = true;

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final res = await _authService.register(
      fullName: _fullNameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      birth: _birthCtrl.text.trim().isEmpty ? null : _birthCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      gender: _gender,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (res['success'] == true) {
        Navigator.pop(context, true); // Return true when done
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Đăng ký thành công, vui lòng đăng nhập.',
                style: TextStyle(color: Colors.green))));
      } else {
        setState(() {
          _errorMessage = res['message'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ĐĂNG KÝ',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 24),
                  _buildInput('Họ và tên', _fullNameCtrl, required: true),
                  const SizedBox(height: 16),
                  _buildInput('Tên đăng nhập', _usernameCtrl, required: true),
                  const SizedBox(height: 16),
                  _buildInput('Mật khẩu', _passwordCtrl,
                      required: true, isPassword: true),
                  const SizedBox(height: 16),
                  _buildInput('Email', _emailCtrl, required: true),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _buildInput('SĐT', _phoneCtrl,
                              required: true)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildDatePicker(
                              'Ngày sinh', _birthCtrl,
                              required: true)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInput('Địa chỉ', _addressCtrl),
                  const SizedBox(height: 16),
                  // Dropdown Gender
                  DropdownButtonFormField<String>(
                    value: _gender,
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Giới tính',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                    ),
                    items: ['Nam', 'Nữ', 'Khác'].map((String val) {
                      return DropdownMenuItem(value: val, child: Text(val));
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _gender = val!);
                    },
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(_errorMessage,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white))
                          : const Text('Tạo tài khoản',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Trở lại đăng nhập
                      },
                      child: const Text('Đã có tài khoản? Đăng nhập ngay',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller,
      {bool required = false, bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: Colors.white),
      validator: (val) {
        if (required && (val == null || val.isEmpty)) {
          return 'Bắt buộc nhập $label';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: '$label${required ? ' *' : ''}',
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
      ),
    );
  }

  Widget _buildDatePicker(String label, TextEditingController controller,
      {bool required = false}) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(color: Colors.white),
      validator: (val) {
        if (required && (val == null || val.isEmpty)) {
          return 'Bắt buộc chọn $label';
        }
        return null;
      },
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Colors.redAccent,
                  onPrimary: Colors.white,
                  surface: Color(0xFF141414),
                  onSurface: Colors.white,
                ),
                dialogBackgroundColor: Colors.grey[900],
              ),
              child: child!,
            );
          },
        );

        if (pickedDate != null) {
          String formattedDate =
              "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
          setState(() {
            controller.text = formattedDate;
          });
        }
      },
      decoration: InputDecoration(
        labelText: '$label${required ? ' *' : ''}',
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
      ),
    );
  }
}
