import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_admin/core/constants/constants.dart';
import 'package:web_admin/core/utils/auth_token_storage.dart';
import 'package:web_admin/injection_container.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

enum _SortField {
  fullName,
  email,
  userName,
  phone,
  address,
  gender,
  registeredAt,
  membership,
  comment,
  account,
}

class _AdminUser {
  final int id;
  String fullName;
  String email;
  String userName;
  String phone;
  String address;
  String gender;
  DateTime registeredAt;
  bool isCommentMuted;
  bool isBanned;
  String membershipTier;

  _AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.userName,
    required this.phone,
    required this.address,
    required this.gender,
    required this.registeredAt,
    required this.isCommentMuted,
    required this.isBanned,
    required this.membershipTier,
  });
}

class _ManageUsersState extends State<ManageUsers> {
  static const int _pageSize = 8;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  final Dio _dio = sl<Dio>();
  final AuthTokenStorage _tokenStorage = sl<AuthTokenStorage>();

  final List<_AdminUser> _users = <_AdminUser>[];
  final Set<int> _selectedUserIds = <int>{};

  String _selectedMembership = 'Tất cả';
  int _currentPage = 0;
  int? _editingUserId;
  bool _isLoading = false;
  String? _errorMessage;
  _SortField? _sortField;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onFilterChanged);
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onFilterChanged);
    _searchController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _userNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _currentPage = 0;
    });
  }

  dynamic _readField(Map<String, dynamic> data, List<String> keys) {
    for (final String key in keys) {
      if (data.containsKey(key)) {
        return data[key];
      }
    }
    return null;
  }

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final String lowered = value.toLowerCase().trim();
      return lowered == 'true' || lowered == '1';
    }
    return false;
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final dynamic values = data[r'$values'];
      if (values is List) {
        return values;
      }
    }
    return <dynamic>[];
  }

  _AdminUser _fromReaderJson(Map<String, dynamic> data) {
    final dynamic idRaw = _readField(data, <String>['id', 'Id']);
    final String registeredAtRaw =
        (_readField(data, <String>['registeredAt', 'RegisteredAt']) ?? '')
            .toString();
    final DateTime registeredAt =
        DateTime.tryParse(registeredAtRaw)?.toLocal() ?? DateTime.now();

    return _AdminUser(
      id: idRaw is num ? idRaw.toInt() : 0,
      fullName: (_readField(data, <String>['fullName', 'FullName']) ?? '')
          .toString(),
      email: (_readField(data, <String>['email', 'Email']) ?? '').toString(),
      userName: (_readField(data, <String>['userName', 'UserName']) ?? '')
          .toString(),
      phone: (_readField(data, <String>['phone', 'Phone']) ?? '').toString(),
      address: (_readField(data, <String>['address', 'Address']) ?? '')
          .toString(),
      gender: (_readField(data, <String>['gender', 'Gender']) ?? '').toString(),
      registeredAt: registeredAt,
      isCommentMuted: _toBool(
        _readField(data, <String>['isCommentMuted', 'IsCommentMuted']),
      ),
      isBanned: _toBool(_readField(data, <String>['isBanned', 'IsBanned'])),
      membershipTier:
          (_readField(data, <String>['membershipTier', 'MembershipTier']) ??
                  'Standard')
              .toString(),
    );
  }

  Future<Options> _authorizedOptions() async {
    final String? token = await _tokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      return Options();
    }

    return Options(
      headers: <String, dynamic>{
        'Authorization': _tokenStorage.formatBearerValue(token),
      },
    );
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Options options = await _authorizedOptions();
      final Response<dynamic> response = await _dio.get(
        '${newAPIBaseURL}Admin/reader-management',
        options: options,
        queryParameters: <String, dynamic>{'Page': 1, 'PageSize': 1000},
      );

      final dynamic body = response.data;
      final Map<String, dynamic> page = body is Map<String, dynamic>
          ? body
          : <String, dynamic>{};

      final dynamic itemsRaw = _readField(page, <String>['items', 'Items']);
      final List<dynamic> items = _extractList(itemsRaw);
      final List<_AdminUser> mapped = items
          .whereType<Map<String, dynamic>>()
          .map(_fromReaderJson)
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _users
          ..clear()
          ..addAll(mapped);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<_AdminUser> _getFilteredAndSortedUsers() {
    final String keyword = _searchController.text.trim().toLowerCase();

    final List<_AdminUser> filtered = _users.where((_AdminUser user) {
      final bool matchesKeyword =
          keyword.isEmpty ||
          user.fullName.toLowerCase().contains(keyword) ||
          user.email.toLowerCase().contains(keyword) ||
          user.userName.toLowerCase().contains(keyword);

      final bool matchesMembership =
          _selectedMembership == 'Tất cả' ||
          user.membershipTier == _selectedMembership;

      return matchesKeyword && matchesMembership;
    }).toList();

    if (_sortField != null) {
      filtered.sort((_AdminUser a, _AdminUser b) {
        int result;
        switch (_sortField!) {
          case _SortField.fullName:
            result = a.fullName.toLowerCase().compareTo(
              b.fullName.toLowerCase(),
            );
          case _SortField.email:
            result = a.email.toLowerCase().compareTo(b.email.toLowerCase());
          case _SortField.userName:
            result = a.userName.toLowerCase().compareTo(
              b.userName.toLowerCase(),
            );
          case _SortField.phone:
            result = a.phone.toLowerCase().compareTo(b.phone.toLowerCase());
          case _SortField.address:
            result = a.address.toLowerCase().compareTo(b.address.toLowerCase());
          case _SortField.gender:
            result = a.gender.toLowerCase().compareTo(b.gender.toLowerCase());
          case _SortField.registeredAt:
            result = a.registeredAt.compareTo(b.registeredAt);
          case _SortField.membership:
            result = a.membershipTier.compareTo(b.membershipTier);
          case _SortField.comment:
            result = a.isCommentMuted == b.isCommentMuted
                ? 0
                : (a.isCommentMuted ? 1 : -1);
          case _SortField.account:
            result = a.isBanned == b.isBanned ? 0 : (a.isBanned ? 1 : -1);
        }
        return _sortAscending ? result : -result;
      });
    }

    return filtered;
  }

  List<_AdminUser> _getPagedUsers(List<_AdminUser> users) {
    if (users.isEmpty) {
      return const <_AdminUser>[];
    }

    final int totalPages = ((users.length - 1) ~/ _pageSize) + 1;
    final int safePage = _currentPage.clamp(0, totalPages - 1);
    final int start = safePage * _pageSize;
    final int end = (start + _pageSize) > users.length
        ? users.length
        : start + _pageSize;

    return users.sublist(start, end);
  }

  void _setSort(_SortField field, bool ascending) {
    setState(() {
      _sortField = field;
      _sortAscending = ascending;
      _currentPage = 0;
    });
  }

  void _resetSort() {
    setState(() {
      _sortField = null;
      _sortAscending = true;
      _currentPage = 0;
    });
  }

  void _handleResetSortPressed() {
    if (_sortField == null) {
      _showMessage('Đang ở chế độ xem mặc định.');
      return;
    }

    _resetSort();
    _showMessage('Đã trở về chế độ xem mặc định.');
  }

  int? _sortColumnIndex() {
    if (_sortField == null) {
      return null;
    }

    switch (_sortField) {
      case _SortField.fullName:
        return 1;
      case _SortField.email:
        return 2;
      case _SortField.userName:
        return 3;
      case _SortField.phone:
        return 4;
      case _SortField.address:
        return 5;
      case _SortField.gender:
        return 6;
      case _SortField.registeredAt:
        return 7;
      case _SortField.membership:
        return 8;
      case _SortField.comment:
        return 9;
      case _SortField.account:
        return 10;
      case null:
        return null;
    }
  }

  String _formatDateTime(DateTime value) {
    final String dd = value.day.toString().padLeft(2, '0');
    final String mm = value.month.toString().padLeft(2, '0');
    final String yyyy = value.year.toString();
    return '$dd/$mm/$yyyy';
  }

  Future<void> _showValueDialog({
    required String title,
    required String value,
  }) async {
    final String displayValue = value.trim().isEmpty ? '(Trống)' : value;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SelectableText(displayValue),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Đóng'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: displayValue));
                if (mounted) {
                  _showMessage('Đã copy nội dung vào clipboard.');
                }
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactText(String value, {double width = 120}) {
    final String displayValue = value.trim().isEmpty ? '(Trống)' : value;

    return SizedBox(
      width: width,
      child: Tooltip(
        message: displayValue,
        waitDuration: const Duration(milliseconds: 250),
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _buildPreviewButton({
    required String label,
    required String title,
    required String value,
  }) {
    final String displayValue = value.trim().isEmpty ? '(Trống)' : value;

    return SizedBox(
      width: 84,
      height: 32,
      child: Tooltip(
        message: displayValue,
        waitDuration: const Duration(milliseconds: 250),
        child: OutlinedButton.icon(
          onPressed: () => _showValueDialog(title: title, value: value),
          icon: const Icon(Icons.visibility_outlined, size: 14),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: const BorderSide(color: Color(0xFFD7DEEE)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          label: Text(label, style: const TextStyle(fontSize: 11)),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildDialogInput(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _showUserDialog({_AdminUser? user}) async {
    _fullNameController.text = user?.fullName ?? '';
    _emailController.text = user?.email ?? '';
    _userNameController.text = user?.userName ?? '';
    _phoneController.text = user?.phone ?? '';
    _addressController.text = user?.address ?? '';
    _genderController.text = user?.gender ?? '';
    _editingUserId = user?.id;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(user == null ? 'Thêm độc giả mới' : 'Chỉnh sửa độc giả'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildDialogInput(_fullNameController, 'Họ và tên'),
                  const SizedBox(height: 12),
                  _buildDialogInput(_emailController, 'Email'),
                  const SizedBox(height: 12),
                  _buildDialogInput(_userNameController, 'Username'),
                  const SizedBox(height: 12),
                  _buildDialogInput(_phoneController, 'Số điện thoại'),
                  const SizedBox(height: 12),
                  _buildDialogInput(_addressController, 'Địa chỉ'),
                  const SizedBox(height: 12),
                  _buildDialogInput(_genderController, 'Giới tính'),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final Options options = await _authorizedOptions();
                  if (_editingUserId == null) {
                    await _dio.post(
                      '${newAPIBaseURL}Admin/reader-management',
                      options: options,
                      data: <String, dynamic>{
                        'FullName': _fullNameController.text.trim(),
                        'Email': _emailController.text.trim(),
                        'UserName': _userNameController.text.trim(),
                        'Password': 'Temp@123',
                        'Phone': _phoneController.text.trim(),
                        'Address': _addressController.text.trim(),
                        'Gender': _genderController.text.trim(),
                      },
                    );
                  } else {
                    await _dio.put(
                      '${newAPIBaseURL}Admin/reader-management/$_editingUserId',
                      options: options,
                      data: <String, dynamic>{
                        'FullName': _fullNameController.text.trim(),
                        'Email': _emailController.text.trim(),
                        'UserName': _userNameController.text.trim(),
                        'Phone': _phoneController.text.trim(),
                        'Address': _addressController.text.trim(),
                        'Gender': _genderController.text.trim(),
                      },
                    );
                  }

                  if (!mounted) {
                    return;
                  }
                  Navigator.of(this.context).pop();

                  await _loadUsers();
                  _showMessage(
                    _editingUserId == null
                        ? 'Đã thêm tài khoản mới.'
                        : 'Đã cập nhật thông tin người dùng.',
                  );
                } catch (e) {
                  _showMessage('Không thể lưu người dùng: $e');
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetPassword(_AdminUser user) async {
    try {
      final Options options = await _authorizedOptions();
      final Response<dynamic> response = await _dio.post(
        '${newAPIBaseURL}Admin/reader-management/${user.id}/reset-password',
        options: options,
        data: <String, dynamic>{},
      );

      String? tempPassword;
      final dynamic raw = response.data;
      if (raw is Map<String, dynamic>) {
        tempPassword =
            (_readField(raw, <String>['tempPassword', 'TempPassword'])
                as String?);
      }

      await _loadUsers();
      if (tempPassword != null && tempPassword.isNotEmpty) {
        _showMessage('Mật khẩu tạm của ${user.userName}: $tempPassword');
      } else {
        _showMessage('Đã khôi phục mật khẩu cho ${user.userName}.');
      }
    } catch (e) {
      _showMessage('Không thể khôi phục mật khẩu: $e');
    }
  }

  Future<void> _grantVip(_AdminUser user) async {
    try {
      final Options options = await _authorizedOptions();
      await _dio.post(
        '${newAPIBaseURL}Admin/reader-management/${user.id}/grant-vip',
        options: options,
        data: <String, dynamic>{'Days': 0},
      );
      await _loadUsers();
      _showMessage('Đã nâng hạng VIP cho ${user.userName}.');
    } catch (e) {
      _showMessage('Không thể cấp VIP: $e');
    }
  }

  Future<void> _revokeVip(_AdminUser user) async {
    try {
      final Options options = await _authorizedOptions();
      await _dio.post(
        '${newAPIBaseURL}Admin/reader-management/${user.id}/revoke-vip',
        options: options,
      );
      await _loadUsers();
      _showMessage('Đã hủy hạng VIP của ${user.userName}.');
    } catch (e) {
      _showMessage('Không thể hủy VIP: $e');
    }
  }

  Future<void> _muteComment(_AdminUser user) async {
    try {
      final Options options = await _authorizedOptions();
      await _dio.post(
        '${newAPIBaseURL}Admin/reader-management/${user.id}/mute-comment',
        options: options,
      );
      await _loadUsers();
      _showMessage('Đã cấm bình luận cho ${user.userName}.');
    } catch (e) {
      _showMessage('Không thể cấm bình luận: $e');
    }
  }

  Future<void> _unmuteComment(_AdminUser user) async {
    try {
      final Options options = await _authorizedOptions();
      await _dio.post(
        '${newAPIBaseURL}Admin/reader-management/${user.id}/unmute-comment',
        options: options,
      );
      await _loadUsers();
      _showMessage('Đã mở bình luận cho ${user.userName}.');
    } catch (e) {
      _showMessage('Không thể mở bình luận: $e');
    }
  }

  Future<void> _banUser(_AdminUser user) async {
    try {
      final Options options = await _authorizedOptions();
      await _dio.post(
        '${newAPIBaseURL}Admin/reader-management/${user.id}/ban',
        options: options,
      );
      await _loadUsers();
      _showMessage('Đã khóa tài khoản ${user.userName}.');
    } catch (e) {
      _showMessage('Không thể khóa tài khoản: $e');
    }
  }

  Future<void> _unbanUser(_AdminUser user) async {
    try {
      final Options options = await _authorizedOptions();
      await _dio.post(
        '${newAPIBaseURL}Admin/reader-management/${user.id}/unban',
        options: options,
      );
      await _loadUsers();
      _showMessage('Đã mở khóa tài khoản ${user.userName}.');
    } catch (e) {
      _showMessage('Không thể mở khóa tài khoản: $e');
    }
  }

  Future<void> _forceLogout(_AdminUser user) async {
    try {
      final Options options = await _authorizedOptions();
      await _dio.post(
        '${newAPIBaseURL}Admin/reader-management/${user.id}/force-logout',
        options: options,
      );
      _showMessage('Đã buộc đăng xuất toàn bộ phiên của ${user.userName}.');
    } catch (e) {
      _showMessage('Không thể buộc đăng xuất: $e');
    }
  }

  Future<void> _bulkNotify() async {
    if (_selectedUserIds.isEmpty) {
      return;
    }

    try {
      final Options options = await _authorizedOptions();
      await _dio.post(
        '${newAPIBaseURL}Admin/reader-management/bulk-notify',
        options: options,
        data: <String, dynamic>{
          'ReaderIds': _selectedUserIds.toList(),
          'Title': 'Thông báo từ quản trị viên',
          'Content': 'Bạn có thông báo mới từ hệ thống quản trị.',
        },
      );
      _showMessage(
        'Đã gửi thông báo tới ${_selectedUserIds.length} tài khoản.',
      );
    } catch (e) {
      _showMessage('Không thể gửi thông báo hàng loạt: $e');
    }
  }

  Future<void> _bulkExportCsv(List<_AdminUser> selectedUsers) async {
    final StringBuffer csv = StringBuffer();
    csv.writeln('ID,Ho ten,Email,Username,Phone,Address,Gender,Hang');

    for (final _AdminUser user in selectedUsers) {
      csv.writeln(
        '${user.id},${user.fullName},${user.email},${user.userName},${user.phone},${user.address},${user.gender},${user.membershipTier}',
      );
    }

    await Clipboard.setData(ClipboardData(text: csv.toString()));
    _showMessage('Đã export danh sách CSV vào clipboard.');
  }

  Widget _buildMembershipBadge(String tier) {
    final bool vip = tier == 'VIP';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: vip ? const Color(0xFFFFF4D6) : const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tier,
        style: TextStyle(
          color: vip ? const Color(0xFFB54708) : const Color(0xFF175CD3),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFlagBadge({
    required bool active,
    required String activeLabel,
    required String inactiveLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFEECEE) : const Color(0xFFEFFAF0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        active ? activeLabel : inactiveLabel,
        style: TextStyle(
          color: active ? const Color(0xFFB42318) : const Color(0xFF067647),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required String label,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      width: 220,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label),
          items: options
              .map(
                (String option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_AdminUser> filteredUsers = _getFilteredAndSortedUsers();
    final List<_AdminUser> pageUsers = _getPagedUsers(filteredUsers);
    final int totalPages = filteredUsers.isEmpty
        ? 1
        : ((filteredUsers.length - 1) ~/ _pageSize) + 1;
    final int safePage = _currentPage.clamp(0, totalPages - 1);

    final bool allSelectedOnPage =
        pageUsers.isNotEmpty &&
        pageUsers.every((_AdminUser u) => _selectedUserIds.contains(u.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Quản lý người dùng',
                      style: TextStyle(
                        color: Color(0xFF1D2638),
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Quản lý tài khoản độc giả theo dữ liệu thực tế',
                      style: TextStyle(color: Color(0xFF7B879B), fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: _handleResetSortPressed,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        side: const BorderSide(color: Color(0xFFCCD6EA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.restart_alt, size: 16),
                      label: const Text(
                        'Xem mặc định',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _showUserDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF040617),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.person_add_alt_1, size: 16),
                      label: const Text(
                        'Thêm tài khoản',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEECEE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFBC8CE)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFB42318),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFB42318),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadUsers,
                    child: const Text('Tải lại'),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4E8F2)),
            ),
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                SizedBox(
                  width: 380,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên, email, username...',
                      hintStyle: const TextStyle(
                        color: Color(0xFFABB3C2),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFABB3C2),
                        size: 18,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      filled: true,
                      fillColor: const Color(0xFFF7F8FC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                _buildFilterDropdown(
                  value: _selectedMembership,
                  label: 'Hạng thành viên',
                  options: const <String>['Tất cả', 'VIP', 'Standard'],
                  onChanged: (String value) {
                    setState(() {
                      _selectedMembership = value;
                      _currentPage = 0;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_selectedUserIds.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD7E3FF)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text('Đã chọn ${_selectedUserIds.length} tài khoản'),
                  FilledButton.tonal(
                    onPressed: _bulkNotify,
                    child: const Text('Gửi thông báo'),
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      final List<_AdminUser> selected = _users
                          .where(
                            (_AdminUser u) => _selectedUserIds.contains(u.id),
                          )
                          .toList();
                      _bulkExportCsv(selected);
                    },
                    child: const Text('Export CSV'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE4E8F2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Text(
                      'Danh sách người dùng (${filteredUsers.length})',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2A3C),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFEEF1F6)),
                  Expanded(
                    child: filteredUsers.isEmpty
                        ? const Center(
                            child: Text(
                              'Không tìm thấy người dùng phù hợp',
                              style: TextStyle(color: Color(0xFF8491A7)),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            child: LayoutBuilder(
                              builder: (BuildContext context, BoxConstraints constraints) {
                                return DataTable(
                                  sortColumnIndex: _sortColumnIndex(),
                                  sortAscending: _sortAscending,
                                  horizontalMargin: 6,
                                  checkboxHorizontalMargin: 4,
                                  columnSpacing: 8,
                                  dataRowMinHeight: 46,
                                  dataRowMaxHeight: 52,
                                  headingRowHeight: 44,
                                  columns: <DataColumn>[
                                    DataColumn(
                                      label: Checkbox(
                                        value: allSelectedOnPage,
                                        onChanged: (bool? checked) {
                                          setState(() {
                                            if (checked ?? false) {
                                              for (final _AdminUser user
                                                  in pageUsers) {
                                                _selectedUserIds.add(user.id);
                                              }
                                            } else {
                                              for (final _AdminUser user
                                                  in pageUsers) {
                                                _selectedUserIds.remove(
                                                  user.id,
                                                );
                                              }
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    DataColumn(
                                      label: const Text('Họ tên'),
                                      onSort: (int _, bool asc) =>
                                          _setSort(_SortField.fullName, asc),
                                    ),
                                    DataColumn(
                                      label: const Text('Email'),
                                      onSort: (int _, bool asc) =>
                                          _setSort(_SortField.email, asc),
                                    ),
                                    DataColumn(
                                      label: const Text('Username'),
                                      onSort: (int _, bool asc) =>
                                          _setSort(_SortField.userName, asc),
                                    ),
                                    DataColumn(
                                      label: const Text('SĐT'),
                                      onSort: (int _, bool asc) =>
                                          _setSort(_SortField.phone, asc),
                                    ),
                                    DataColumn(
                                      label: const Text('Địa chỉ'),
                                      onSort: (int _, bool asc) =>
                                          _setSort(_SortField.address, asc),
                                    ),
                                    DataColumn(
                                      label: const Text('Giới tính'),
                                      onSort: (int _, bool asc) =>
                                          _setSort(_SortField.gender, asc),
                                    ),
                                    DataColumn(
                                      label: const Text('Ngày đăng ký'),
                                      onSort: (int _, bool asc) => _setSort(
                                        _SortField.registeredAt,
                                        asc,
                                      ),
                                    ),
                                    DataColumn(
                                      label: const Text('Hạng'),
                                      onSort: (int _, bool asc) =>
                                          _setSort(_SortField.membership, asc),
                                    ),
                                    DataColumn(
                                      label: const Text('Bình luận'),
                                      onSort: (int _, bool asc) =>
                                          _setSort(_SortField.comment, asc),
                                    ),
                                    DataColumn(
                                      label: const Text('Tài khoản'),
                                      onSort: (int _, bool asc) =>
                                          _setSort(_SortField.account, asc),
                                    ),
                                    const DataColumn(label: Text('Thao tác')),
                                  ],
                                  rows: pageUsers.map((_AdminUser user) {
                                    final bool selected = _selectedUserIds
                                        .contains(user.id);
                                    final bool isVip =
                                        user.membershipTier == 'VIP';
                                    final bool isMuted = user.isCommentMuted;
                                    final bool isBanned = user.isBanned;

                                    return DataRow(
                                      selected: selected,
                                      cells: <DataCell>[
                                        DataCell(
                                          Checkbox(
                                            value: selected,
                                            onChanged: (bool? checked) {
                                              setState(() {
                                                if (checked ?? false) {
                                                  _selectedUserIds.add(user.id);
                                                } else {
                                                  _selectedUserIds.remove(
                                                    user.id,
                                                  );
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                        DataCell(
                                          _buildCompactText(
                                            user.fullName,
                                            width: 120,
                                          ),
                                        ),
                                        DataCell(
                                          _buildCompactText(
                                            user.email,
                                            width: 165,
                                          ),
                                        ),
                                        DataCell(
                                          _buildCompactText(
                                            user.userName,
                                            width: 94,
                                          ),
                                        ),
                                        DataCell(
                                          _buildPreviewButton(
                                            label: 'Xem',
                                            title: 'Số điện thoại',
                                            value: user.phone,
                                          ),
                                        ),
                                        DataCell(
                                          _buildPreviewButton(
                                            label: 'Xem',
                                            title: 'Địa chỉ',
                                            value: user.address,
                                          ),
                                        ),
                                        DataCell(
                                          _buildCompactText(
                                            user.gender,
                                            width: 84,
                                          ),
                                        ),
                                        DataCell(
                                          _buildCompactText(
                                            _formatDateTime(user.registeredAt),
                                            width: 88,
                                          ),
                                        ),
                                        DataCell(
                                          _buildMembershipBadge(
                                            user.membershipTier,
                                          ),
                                        ),
                                        DataCell(
                                          _buildFlagBadge(
                                            active: isMuted,
                                            activeLabel: 'Đang mute',
                                            inactiveLabel: 'Bình thường',
                                          ),
                                        ),
                                        DataCell(
                                          _buildFlagBadge(
                                            active: isBanned,
                                            activeLabel: 'Đã khóa',
                                            inactiveLabel: 'Hoạt động',
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 17,
                                                ),
                                                onPressed: () =>
                                                    _showUserDialog(user: user),
                                                tooltip: 'Sửa thông tin',
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                              PopupMenuButton<String>(
                                                tooltip: 'Thao tác',
                                                onSelected: (String action) {
                                                  switch (action) {
                                                    case 'reset_password':
                                                      _resetPassword(user);
                                                    case 'grant_vip':
                                                      _grantVip(user);
                                                    case 'revoke_vip':
                                                      _revokeVip(user);
                                                    case 'mute_comment':
                                                      _muteComment(user);
                                                    case 'unmute_comment':
                                                      _unmuteComment(user);
                                                    case 'ban_user':
                                                      _banUser(user);
                                                    case 'unban_user':
                                                      _unbanUser(user);
                                                    case 'force_logout':
                                                      _forceLogout(user);
                                                  }
                                                },
                                                itemBuilder:
                                                    (
                                                      BuildContext context,
                                                    ) => <PopupMenuEntry<String>>[
                                                      const PopupMenuItem<
                                                        String
                                                      >(
                                                        value: 'reset_password',
                                                        child: Text(
                                                          'Khôi phục mật khẩu',
                                                        ),
                                                      ),
                                                      if (!isVip)
                                                        const PopupMenuItem<
                                                          String
                                                        >(
                                                          value: 'grant_vip',
                                                          child: Text(
                                                            'Nâng hạng VIP',
                                                          ),
                                                        ),
                                                      if (isVip)
                                                        const PopupMenuItem<
                                                          String
                                                        >(
                                                          value: 'revoke_vip',
                                                          child: Text(
                                                            'Hạ hạng Standard',
                                                          ),
                                                        ),
                                                      if (!isMuted)
                                                        const PopupMenuItem<
                                                          String
                                                        >(
                                                          value: 'mute_comment',
                                                          child: Text(
                                                            'Cấm bình luận',
                                                          ),
                                                        ),
                                                      if (isMuted)
                                                        const PopupMenuItem<
                                                          String
                                                        >(
                                                          value:
                                                              'unmute_comment',
                                                          child: Text(
                                                            'Mở bình luận',
                                                          ),
                                                        ),
                                                      if (!isBanned)
                                                        const PopupMenuItem<
                                                          String
                                                        >(
                                                          value: 'ban_user',
                                                          child: Text(
                                                            'Khóa tài khoản',
                                                          ),
                                                        ),
                                                      if (isBanned)
                                                        const PopupMenuItem<
                                                          String
                                                        >(
                                                          value: 'unban_user',
                                                          child: Text(
                                                            'Mở khóa tài khoản',
                                                          ),
                                                        ),
                                                      const PopupMenuItem<
                                                        String
                                                      >(
                                                        value: 'force_logout',
                                                        child: Text(
                                                          'Buộc đăng xuất',
                                                        ),
                                                      ),
                                                    ],
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                                  child: Icon(
                                                    Icons.more_vert,
                                                    size: 17,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Trang ${safePage + 1}/$totalPages - ${filteredUsers.length} người dùng',
                          style: const TextStyle(
                            color: Color(0xFF6C7B92),
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            OutlinedButton(
                              onPressed: safePage > 0
                                  ? () {
                                      setState(() {
                                        _currentPage = safePage - 1;
                                      });
                                    }
                                  : null,
                              child: const Text('Trước'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: safePage < totalPages - 1
                                  ? () {
                                      setState(() {
                                        _currentPage = safePage + 1;
                                      });
                                    }
                                  : null,
                              child: const Text('Sau'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
