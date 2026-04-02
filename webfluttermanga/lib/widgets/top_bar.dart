import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';
import '../screens/profile_dialog.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _TopBarState extends State<TopBar> {
  // Thay vì check login thật (bằng SharedPreferences), tạm thời lưu trạng thái để demo giao diện
  // Nếu false = hiện nút Đăng Nhập, Nếu true = hiện Icon User
  bool _isLoggedIn = false;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final uname = prefs.getString('username');
    if (token != null) {
      if (mounted) setState(() { _isLoggedIn = true; _username = uname ?? 'User'; });
    }
  }

  void _showLoginDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const LoginScreen(),
    );
    
    // Nếu login dialog trả về true (thành công)
    if (result == true) {
      _checkLoginStatus();
    }
  }

  void _showProfile() {
    showDialog(
      context: context,
      builder: (context) => const ProfileDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Màu nền header cực tối giống mangaPlus
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              const Icon(Icons.book, color: Colors.redAccent, size: 36),
              const SizedBox(width: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic),
                  children: [
                    TextSpan(text: 'MANGA', style: TextStyle(color: Colors.white)),
                    TextSpan(
                        text: 'Plus', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 40),
          // Nav items
          Row(
            spacing: 24,
            children: [
              _buildNavItem('Cập nhật', isActive: true),
              _buildNavItem('Nổi bật'),
              _buildNavItem('Xếp hạng'),
              _buildNavItem('Danh sách truyện'),
              _buildNavItem('Yêu thích'),
              _buildNavItem('Về chúng tôi'),
            ],
          ),
          const Spacer(),
          // Search & Login
          Row(
            children: [
              Container(
                width: 250,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: const TextField(
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  textAlignVertical: TextAlignVertical.center,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm truyện hoặc tác giả',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: Colors.white70, size: 18),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Đổi nút Đăng nhập / User Profile tùy trạng thái
              if (!_isLoggedIn)
                ElevatedButton(
                  onPressed: _showLoginDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  child: const Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              else
                Row(
                  children: [
                    Text('Xin chào, $_username', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      radius: 20,
                      child: PopupMenuButton<int>(
                        icon: const Icon(Icons.person, color: Colors.white),
                        offset: const Offset(0, 48),
                        color: Colors.grey[900],
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 1, child: Text('Trang cá nhân', style: TextStyle(color: Colors.white))),
                          const PopupMenuItem(value: 2, child: Text('Đăng xuất', style: TextStyle(color: Colors.redAccent))),
                        ],
                        onSelected: (value) async {
                          if (value == 1) {
                            _showProfile();
                          } else if (value == 2) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            setState(() {
                              _isLoggedIn = false;
                              _username = '';
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, {bool isActive = false}) {
    return Text(
      title,
      style: TextStyle(
        color: isActive ? Colors.white : Colors.grey[400],
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        fontSize: 15,
      ),
    );
  }
}
