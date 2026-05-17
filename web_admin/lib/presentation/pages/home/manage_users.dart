import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_admin/core/constants/constants.dart';
import 'package:web_admin/core/utils/auth_token_storage.dart';
import 'package:web_admin/injection_container.dart';
import 'package:web_admin/presentation/controllers/remote_manga_controller.dart';
import 'package:web_admin/presentation/pages/home/manage_manga.dart';
import 'package:web_admin/presentation/widgets/manage_manga_sidebar.dart';
import 'package:web_admin/presentation/widgets/manage_manga_top_header.dart';
import 'package:web_admin/presentation/pages/home/manage_authors.dart';

class ManageUsers extends StatefulWidget {
  final RemoteMangaController mangaController;
  final Future<void> Function()? onLogout;

  const ManageUsers({super.key, required this.mangaController, this.onLogout});

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
  final String uniqueKey;
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
  String role;

  _AdminUser({
    required this.id,
    required this.uniqueKey,
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
    required this.role,
  });
}

class _VipPrivilege {
  final int id;
  final String content;

  const _VipPrivilege({required this.id, required this.content});
}

class _VipPackage {
  final int id;
  String title;
  int price;
  int durationDays;
  List<_VipPrivilege> privileges;

  _VipPackage({
    required this.id,
    required this.title,
    required this.price,
    required this.durationDays,
    required this.privileges,
  });
}

class _ManageUsersState extends State<ManageUsers> {
  static const int _pageSize = 8;
  static const double _tableMinWidth = 1400;
  static const double _scrollbarHeight = 18;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  final Dio _dio = sl<Dio>();
  final AuthTokenStorage _tokenStorage = sl<AuthTokenStorage>();
  final ScrollController _tableHorizontalController = ScrollController();
  final ScrollController _gutterHorizontalController = ScrollController();
  final ScrollController _leftGutterController = ScrollController();
  final ScrollController _leftTableController = ScrollController();
  bool _isSyncingScroll = false;
  bool _isSyncingLeftScroll = false;

  final List<_AdminUser> _users = <_AdminUser>[];
  final Set<String> _selectedUserIds = <String>{};
  final List<_VipPackage> _vipPackages = <_VipPackage>[];
  final List<_VipPrivilege> _vipPrivileges = <_VipPrivilege>[];

  String _selectedMembership = 'Tất cả';
  int _currentPage = 0;
  int? _editingUserId;
  String _editingRole = 'User';
  bool _isLoading = false;
  String? _errorMessage;
  _SortField? _sortField;
  bool _sortAscending = true;
  bool _vipLoading = false;
  String? _vipError;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onFilterChanged);
    _loadUsers();
    _tableHorizontalController.addListener(() {
      _syncHorizontalScroll(
        source: _tableHorizontalController,
        target: _gutterHorizontalController,
      );
    });
    _gutterHorizontalController.addListener(() {
      _syncHorizontalScroll(
        source: _gutterHorizontalController,
        target: _tableHorizontalController,
      );
    });
    _leftTableController.addListener(() {
      _syncLeftHorizontalScroll(
        source: _leftTableController,
        target: _leftGutterController,
      );
    });
    _leftGutterController.addListener(() {
      _syncLeftHorizontalScroll(
        source: _leftGutterController,
        target: _leftTableController,
      );
    });
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
    _tableHorizontalController.dispose();
    _gutterHorizontalController.dispose();
    _leftGutterController.dispose();
    _leftTableController.dispose();
    super.dispose();
  }

  void _syncHorizontalScroll({
    required ScrollController source,
    required ScrollController target,
  }) {
    if (_isSyncingScroll || !target.hasClients) {
      return;
    }

    _isSyncingScroll = true;
    final double clamped = source.offset
        .clamp(target.position.minScrollExtent, target.position.maxScrollExtent)
        .toDouble();
    target.jumpTo(clamped);
    _isSyncingScroll = false;
  }

  void _syncLeftHorizontalScroll({
    required ScrollController source,
    required ScrollController target,
  }) {
    if (_isSyncingLeftScroll || !target.hasClients) {
      return;
    }

    _isSyncingLeftScroll = true;
    final double clamped = source.offset
        .clamp(target.position.minScrollExtent, target.position.maxScrollExtent)
        .toDouble();
    target.jumpTo(clamped);
    _isSyncingLeftScroll = false;
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

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
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

  String _makeUniqueKey({
    required String role,
    required dynamic idRaw,
    required String email,
    required String userName,
  }) {
    final String idText = idRaw is num
        ? idRaw.toInt().toString()
        : (idRaw?.toString().trim().isNotEmpty ?? false)
        ? idRaw.toString()
        : '';
    final String fallback = email.isNotEmpty
        ? email
        : (userName.isNotEmpty ? userName : 'unknown');
    return '$role:$idText:$fallback'.toLowerCase();
  }

  _AdminUser _fromAdminJson(Map<String, dynamic> data) {
    final dynamic idRaw = _readField(data, <String>['id', 'Id']);
    final dynamic usersData =
        _readField(data, <String>['users', 'Users']) ?? <String, dynamic>{};
    final String email = (_readField(data, <String>['email', 'Email']) ?? '')
        .toString();
    final String userName =
        (_readField(usersData, <String>['userName', 'UserName']) ?? '')
            .toString();

    return _AdminUser(
      id: idRaw is num ? idRaw.toInt() : 0,
      uniqueKey: _makeUniqueKey(
        role: 'admin',
        idRaw: idRaw,
        email: email,
        userName: userName,
      ),
      fullName: (_readField(data, <String>['name', 'Name']) ?? '').toString(),
      email: email,
      userName: userName,
      phone: (_readField(data, <String>['phone', 'Phone']) ?? '').toString(),
      address: (_readField(data, <String>['address', 'Address']) ?? '')
          .toString(),
      gender: (_readField(data, <String>['gender', 'Gender']) ?? '').toString(),
      registeredAt: DateTime.now(),
      isCommentMuted: false,
      isBanned: false,
      membershipTier: 'Admin',
      role: 'Admin',
    );
  }

  _AdminUser _fromReaderJson(Map<String, dynamic> data) {
    final dynamic idRaw = _readField(data, <String>['id', 'Id']);
    final String registeredAtRaw =
        (_readField(data, <String>['registeredAt', 'RegisteredAt']) ?? '')
            .toString();
    final DateTime registeredAt =
        DateTime.tryParse(registeredAtRaw)?.toLocal() ?? DateTime.now();
    final String email = (_readField(data, <String>['email', 'Email']) ?? '')
        .toString();
    final String userName =
        (_readField(data, <String>['userName', 'UserName']) ?? '').toString();

    return _AdminUser(
      id: idRaw is num ? idRaw.toInt() : 0,
      uniqueKey: _makeUniqueKey(
        role: 'reader',
        idRaw: idRaw,
        email: email,
        userName: userName,
      ),
      fullName: (_readField(data, <String>['fullName', 'FullName']) ?? '')
          .toString(),
      email: email,
      userName: userName,
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
      role: 'User',
    );
  }

  _VipPrivilege _fromPrivilegeJson(Map<String, dynamic> data) {
    return _VipPrivilege(
      id: _toInt(_readField(data, <String>['id', 'Id'])),
      content: (_readField(data, <String>['content', 'Content']) ?? '')
          .toString(),
    );
  }

  _VipPackage _fromPackageJson(Map<String, dynamic> data) {
    final dynamic privilegesRaw = _readField(data, <String>[
      'previlages',
      'Previlages',
      'privileges',
      'Privileges',
    ]);
    final List<_VipPrivilege> privileges = _extractList(privilegesRaw)
        .whereType<Map<String, dynamic>>()
        .map(_fromPrivilegeJson)
        .where((item) => item.id > 0)
        .toList();

    return _VipPackage(
      id: _toInt(_readField(data, <String>['id', 'Id'])),
      title: (_readField(data, <String>['title', 'Title']) ?? '').toString(),
      price: _toInt(_readField(data, <String>['price', 'Price'])),
      durationDays: _toInt(
        _readField(data, <String>['durationDays', 'DurationDays']),
        fallback: 30,
      ),
      privileges: privileges,
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

      final Response<dynamic> resAdmins = await _dio.get(
        '${newAPIBaseURL}Admin/get-info-admin',
        options: options,
      );
      final dynamic adminsBody = resAdmins.data;
      final List<dynamic> adminItems = _extractList(adminsBody);
      final List<_AdminUser> mappedAdmins = adminItems
          .whereType<Map<String, dynamic>>()
          .map(_fromAdminJson)
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _users
          ..clear()
          ..addAll(mappedAdmins)
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

  Future<void> _fetchVipData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _vipLoading = true;
        _vipError = null;
      });
    }

    try {
      final Options options = await _authorizedOptions();

      final Response<dynamic> packageResponse = await _dio.get(
        '${newAPIBaseURL}Package/get-all-package',
        options: options,
      );
      final dynamic packageBody = packageResponse.data;
      final Map<String, dynamic> packageMap =
          packageBody is Map<String, dynamic>
          ? packageBody
          : <String, dynamic>{};
      final dynamic packageData =
          _readField(packageMap, <String>['data', 'Data']) ?? packageBody;
      final List<_VipPackage> packages = _extractList(packageData)
          .whereType<Map<String, dynamic>>()
          .map(_fromPackageJson)
          .where((item) => item.id > 0 && item.title.trim().isNotEmpty)
          .toList();

      final Response<dynamic> privilegeResponse = await _dio.get(
        '${newAPIBaseURL}Previlages/get-all-previlage',
        options: options,
      );
      final dynamic privilegeBody = privilegeResponse.data;
      final Map<String, dynamic> privilegeMap =
          privilegeBody is Map<String, dynamic>
          ? privilegeBody
          : <String, dynamic>{};
      final dynamic privilegeData =
          _readField(privilegeMap, <String>['data', 'Data']) ?? privilegeBody;
      final List<_VipPrivilege> privileges = _extractList(privilegeData)
          .whereType<Map<String, dynamic>>()
          .map(_fromPrivilegeJson)
          .where((item) => item.id > 0 && item.content.trim().isNotEmpty)
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _vipPackages
          ..clear()
          ..addAll(packages);
        _vipPrivileges
          ..clear()
          ..addAll(privileges);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _vipError = e.toString();
      });
    } finally {
      if (mounted && showLoading) {
        setState(() {
          _vipLoading = false;
        });
      }
    }
  }

  Future<bool> _createPrivilege(String content) async {
    final String trimmed = content.trim();
    if (trimmed.isEmpty) {
      _showMessage('Nội dung đặc quyền không được để trống.');
      return false;
    }

    try {
      final Options options = await _authorizedOptions();
      await _dio.post(
        '${newAPIBaseURL}Previlages/create-previlage',
        options: options,
        data: <String, dynamic>{'Content': trimmed},
      );
      await _fetchVipData();
      _showMessage('Đã thêm đặc quyền mới.');
      return true;
    } catch (e) {
      _showMessage('Không thể thêm đặc quyền: $e');
      return false;
    }
  }

  Future<bool> _saveVipPackage({
    _VipPackage? package,
    required String title,
    required int price,
    required int durationDays,
    required List<int> privilegeIds,
  }) async {
    try {
      final Options options = await _authorizedOptions();
      final Map<String, dynamic> payload = <String, dynamic>{
        'Title': title.trim(),
        'Price': price,
        'DurationDays': durationDays,
        'PrevilageIds': privilegeIds,
      };

      if (package == null) {
        await _dio.post(
          '${newAPIBaseURL}Package/create-package',
          options: options,
          data: payload,
        );
      } else {
        await _dio.put(
          '${newAPIBaseURL}Package/update-package/${package.id}',
          options: options,
          data: payload,
        );
      }

      await _fetchVipData();
      _showMessage(
        package == null ? 'Đã tạo gói VIP mới.' : 'Đã cập nhật gói VIP.',
      );
      return true;
    } catch (e) {
      _showMessage('Không thể lưu gói VIP: $e');
      return false;
    }
  }

  Future<void> _deleteVipPackage(_VipPackage package) async {
    try {
      final Options options = await _authorizedOptions();
      await _dio.put(
        '${newAPIBaseURL}Package/delete-package/${package.id}',
        options: options,
      );
      await _fetchVipData();
      _showMessage('Đã xóa gói ${package.title}.');
    } catch (e) {
      _showMessage('Không thể xóa gói VIP: $e');
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

  String _formatCurrency(int value) {
    final String raw = value.abs().toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final int remaining = raw.length - i;
      buffer.write(raw[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }
    final String formatted = buffer.toString();
    return value < 0 ? '-$formatted' : formatted;
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
    _editingRole = user?.role ?? 'User';

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                user == null ? 'Thêm người dùng mới' : 'Chỉnh sửa người dùng',
              ),
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
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _editingRole,
                        decoration: InputDecoration(
                          labelText: 'Vai trò',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFDCDFEA),
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Admin',
                            child: Text('Admin'),
                          ),
                          DropdownMenuItem(value: 'User', child: Text('User')),
                        ],
                        onChanged: _editingUserId == null
                            ? (String? val) {
                                if (val != null)
                                  setStateDialog(() {
                                    _editingRole = val;
                                  });
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final Options options = await _authorizedOptions();
                      if (_editingRole == 'Admin') {
                        final Map<String, dynamic> payload = <String, dynamic>{
                          'Name': _fullNameController.text.trim(),
                          'Email': _emailController.text.trim(),
                          'UserName': _userNameController.text.trim(),
                          'Birth': '1990-01-01',
                          'Phone': _phoneController.text.trim(),
                          'Address': _addressController.text.trim(),
                          'Gender': _genderController.text.trim(),
                        };
                        if (_editingUserId == null) {
                          payload['Password'] = 'Temp@123';
                          await _dio.post(
                            '${newAPIBaseURL}Admin/create-admin',
                            options: options,
                            data: FormData.fromMap(payload),
                          );
                        } else {
                          await _dio.put(
                            '${newAPIBaseURL}Admin/update-admin/$_editingUserId',
                            options: options,
                            data: FormData.fromMap(payload),
                          );
                        }
                      } else {
                        final Map<String, dynamic> payload = <String, dynamic>{
                          'FullName': _fullNameController.text.trim(),
                          'Email': _emailController.text.trim(),
                          'UserName': _userNameController.text.trim(),
                          'Phone': _phoneController.text.trim(),
                          'Address': _addressController.text.trim(),
                          'Gender': _genderController.text.trim(),
                        };
                        if (_editingUserId == null) {
                          payload['Password'] = 'Temp@123';
                          await _dio.post(
                            '${newAPIBaseURL}Admin/create-reader',
                            options: options,
                            data: FormData.fromMap(payload),
                          );
                        } else {
                          await _dio.put(
                            '${newAPIBaseURL}Admin/update-reader/$_editingUserId',
                            options: options,
                            data: FormData.fromMap(payload),
                          );
                        }
                      }

                      if (!mounted) return;
                      Navigator.of(dialogContext).pop();

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

    final List<int> readerIds = _users
        .where(
          (_AdminUser u) =>
              u.role == 'User' && _selectedUserIds.contains(u.uniqueKey),
        )
        .map((_AdminUser u) => u.id)
        .toList();

    if (readerIds.isEmpty) {
      return;
    }

    try {
      final Options options = await _authorizedOptions();
      await _dio.post(
        '${newAPIBaseURL}Admin/reader-management/bulk-notify',
        options: options,
        data: <String, dynamic>{
          'ReaderIds': readerIds,
          'Title': 'Thông báo từ quản trị viên',
          'Content': 'Bạn có thông báo mới từ hệ thống quản trị.',
        },
      );
      _showMessage('Đã gửi thông báo tới ${readerIds.length} tài khoản.');
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

  Future<void> _openVipPackageManager() async {
    await _fetchVipData();
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierColor: const Color(0xAA0B1220),
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> refresh() async {
              await _fetchVipData();
              if (dialogContext.mounted) {
                setStateDialog(() {});
              }
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 980,
                  maxHeight: 720,
                ),
                child: Column(
                  children: <Widget>[
                    _buildVipDialogHeader(
                      onClose: () => Navigator.of(dialogContext).pop(),
                      onRefresh: refresh,
                      onCreate: () async {
                        await _showVipPackageForm();
                        if (dialogContext.mounted) {
                          setStateDialog(() {});
                        }
                      },
                      onCreatePrivilege: () async {
                        await _showCreatePrivilegeDialog();
                        if (dialogContext.mounted) {
                          setStateDialog(() {});
                        }
                      },
                    ),
                    if (_vipLoading)
                      const LinearProgressIndicator(minHeight: 3),
                    if (_vipError != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(12),
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
                                _vipError!,
                                style: const TextStyle(
                                  color: Color(0xFFB42318),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: refresh,
                              child: const Text('Tải lại'),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildVipDialogBody(
                          onEditPackage: (pkg) async {
                            await _showVipPackageForm(package: pkg);
                            if (dialogContext.mounted) {
                              setStateDialog(() {});
                            }
                          },
                          onDeletePackage: (pkg) async {
                            await _confirmDeleteVipPackage(pkg);
                            if (dialogContext.mounted) {
                              setStateDialog(() {});
                            }
                          },
                          onCreatePrivilege: () async {
                            await _showCreatePrivilegeDialog();
                            if (dialogContext.mounted) {
                              setStateDialog(() {});
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVipDialogHeader({
    required VoidCallback onClose,
    required VoidCallback onRefresh,
    required VoidCallback onCreate,
    required VoidCallback onCreatePrivilege,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Colors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý gói VIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Thiết lập ưu đãi & thời hạn cho từng gói hội viên',
                  style: TextStyle(color: Color(0xFFB6C2D6), fontSize: 12),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onRefresh,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF334155)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Làm mới', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onCreatePrivilege,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF7C3AED)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text('Thêm đặc quyền', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              'Tạo gói VIP',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildVipDialogBody({
    required ValueChanged<_VipPackage> onEditPackage,
    required ValueChanged<_VipPackage> onDeletePackage,
    required VoidCallback onCreatePrivilege,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool stacked = constraints.maxWidth < 860;

        final Widget packagePanel = _buildVipPackagePanel(
          onEditPackage: onEditPackage,
          onDeletePackage: onDeletePackage,
          shrinkWrap: stacked,
        );
        final Widget privilegePanel = _buildVipPrivilegePanel(
          onCreatePrivilege: onCreatePrivilege,
          shrinkWrap: stacked,
        );

        if (stacked) {
          return ListView(
            children: <Widget>[
              packagePanel,
              const SizedBox(height: 16),
              privilegePanel,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(flex: 3, child: packagePanel),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: privilegePanel),
          ],
        );
      },
    );
  }

  Widget _buildVipPackagePanel({
    required ValueChanged<_VipPackage> onEditPackage,
    required ValueChanged<_VipPackage> onDeletePackage,
    bool shrinkWrap = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E8F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  color: Color(0xFFB45309),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Gói VIP (${_vipPackages.length})',
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_vipPackages.isEmpty)
            _buildVipEmptyState(
              title: 'Chưa có gói VIP',
              subtitle: 'Thêm gói đầu tiên để áp dụng cho người dùng',
            )
          else if (shrinkWrap)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _vipPackages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final _VipPackage package = _vipPackages[index];
                return _buildVipPackageCard(
                  package,
                  onEdit: () => onEditPackage(package),
                  onDelete: () => onDeletePackage(package),
                );
              },
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _vipPackages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final _VipPackage package = _vipPackages[index];
                  return _buildVipPackageCard(
                    package,
                    onEdit: () => onEditPackage(package),
                    onDelete: () => onDeletePackage(package),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVipPrivilegePanel({
    required VoidCallback onCreatePrivilege,
    bool shrinkWrap = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E8F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF1F5BFF),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Đặc quyền (${_vipPrivileges.length})',
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onCreatePrivilege,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_vipPrivileges.isEmpty)
            _buildVipEmptyState(
              title: 'Chưa có đặc quyền',
              subtitle: 'Thêm đặc quyền để gán vào gói VIP',
              icon: Icons.add_moderator_rounded,
            )
          else if (shrinkWrap)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _vipPrivileges.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final _VipPrivilege item = _vipPrivileges[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE0E7FF)),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF2563EB),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.content,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _vipPrivileges.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final _VipPrivilege item = _vipPrivileges[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE0E7FF)),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF2563EB),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.content,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVipPackageCard(
    _VipPackage package, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E8F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        package.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thời hạn ${package.durationDays} ngày',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_formatCurrency(package.price)}đ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Đặc quyền (${package.privileges.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (package.privileges.isEmpty)
                  const Text(
                    'Chưa có đặc quyền được gán',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: package.privileges
                        .map(
                          (priv) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFD6E0FF),
                              ),
                            ),
                            child: Text(
                              priv.content,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1E3A8A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB42318),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text(
                        'Xóa gói',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text(
                        'Chỉnh sửa',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVipEmptyState({
    required String title,
    required String subtitle,
    IconData icon = Icons.workspace_premium_outlined,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, color: const Color(0xFF94A3B8), size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showVipPackageForm({_VipPackage? package}) async {
    final TextEditingController titleController = TextEditingController(
      text: package?.title ?? '',
    );
    final TextEditingController priceController = TextEditingController(
      text: package?.price.toString() ?? '',
    );
    final TextEditingController durationController = TextEditingController(
      text: package?.durationDays.toString() ?? '30',
    );

    final Set<int> selectedPrivilegeIds = <int>{
      if (package != null) ...package.privileges.map((p) => p.id),
    };

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        bool isSaving = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> submit() async {
              final String title = titleController.text.trim();
              final int price = int.tryParse(priceController.text.trim()) ?? 0;
              final int days =
                  int.tryParse(durationController.text.trim()) ?? 0;

              if (title.isEmpty) {
                setStateDialog(() {
                  errorMessage = 'Vui lòng nhập tên gói.';
                });
                return;
              }
              if (price <= 0) {
                setStateDialog(() {
                  errorMessage = 'Giá gói phải lớn hơn 0.';
                });
                return;
              }
              if (days <= 0) {
                setStateDialog(() {
                  errorMessage = 'Thời hạn phải lớn hơn 0 ngày.';
                });
                return;
              }

              setStateDialog(() {
                isSaving = true;
                errorMessage = null;
              });

              final bool success = await _saveVipPackage(
                package: package,
                title: title,
                price: price,
                durationDays: days,
                privilegeIds: selectedPrivilegeIds.toList(),
              );

              if (!success) {
                setStateDialog(() {
                  isSaving = false;
                  errorMessage =
                      'Không thể lưu gói VIP. Vui lòng kiểm tra lại.';
                });
                return;
              }

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            }

            return AlertDialog(
              title: Text(
                package == null ? 'Tạo gói VIP mới' : 'Chỉnh sửa gói VIP',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Tên gói',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Giá (VNĐ)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Thời hạn (ngày)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          const Text(
                            'Đặc quyền',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () async {
                              await _showCreatePrivilegeDialog();
                              if (dialogContext.mounted) {
                                setStateDialog(() {});
                              }
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Thêm'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_vipPrivileges.isEmpty)
                        const Text(
                          'Chưa có đặc quyền nào. Vui lòng tạo đặc quyền trước.',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _vipPrivileges.map((priv) {
                            final bool selected = selectedPrivilegeIds.contains(
                              priv.id,
                            );
                            return FilterChip(
                              label: Text(priv.content),
                              selected: selected,
                              onSelected: (bool value) {
                                setStateDialog(() {
                                  if (value) {
                                    selectedPrivilegeIds.add(priv.id);
                                  } else {
                                    selectedPrivilegeIds.remove(priv.id);
                                  }
                                });
                              },
                              selectedColor: const Color(0xFFDBEAFE),
                              checkmarkColor: const Color(0xFF1D4ED8),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                color: selected
                                    ? const Color(0xFF1D4ED8)
                                    : const Color(0xFF475569),
                              ),
                            );
                          }).toList(),
                        ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : submit,
                  child: Text(package == null ? 'Tạo gói' : 'Lưu thay đổi'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    priceController.dispose();
    durationController.dispose();
  }

  Future<void> _showCreatePrivilegeDialog() async {
    final TextEditingController contentController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        bool isSaving = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> submit() async {
              final String content = contentController.text.trim();
              if (content.isEmpty) {
                setStateDialog(() {
                  errorMessage = 'Nội dung không được để trống.';
                });
                return;
              }

              setStateDialog(() {
                isSaving = true;
                errorMessage = null;
              });

              final bool success = await _createPrivilege(content);

              if (!success) {
                setStateDialog(() {
                  isSaving = false;
                  errorMessage = 'Không thể thêm đặc quyền. Vui lòng thử lại.';
                });
                return;
              }

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            }

            return AlertDialog(
              title: const Text('Thêm đặc quyền mới'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: contentController,
                      decoration: InputDecoration(
                        labelText: 'Nội dung đặc quyền',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : submit,
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    contentController.dispose();
  }

  Future<void> _confirmDeleteVipPackage(_VipPackage package) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xóa gói VIP'),
          content: Text('Bạn chắc chắn muốn xóa gói "${package.title}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteVipPackage(package);
    }
  }

  Widget _buildUserStatsSection({
    required int totalUsers,
    required int totalAdmins,
    required int totalVip,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool stacked = constraints.maxWidth < 680;
        final bool twoColumn =
            constraints.maxWidth >= 680 && constraints.maxWidth < 980;

        final List<Widget> cards = <Widget>[
          _UserStatCard(
            label: 'Người dùng',
            value: totalUsers.toString(),
            icon: Icons.people_alt_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF1F5BFF), Color(0xFF3B82F6)],
            ),
          ),
          _UserStatCard(
            label: 'Quản trị viên',
            value: totalAdmins.toString(),
            icon: Icons.shield_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
          ),
          _UserStatCard(
            label: 'VIP đang hoạt động',
            value: totalVip.toString(),
            icon: Icons.stars_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
            ),
            actionLabel: 'Quản lý gói VIP',
            onTap: _openVipPackageManager,
          ),
        ];

        if (stacked) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        if (twoColumn) {
          final double cardWidth =
              (constraints.maxWidth - 12).clamp(320.0, 720.0).toDouble() / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map((card) => SizedBox(width: cardWidth, child: card))
                .toList(),
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  void _openMangaPage() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ManageManga(
          mangaController: widget.mangaController,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  void _openAuthorsPage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ManageAuthors(
          mangaController: widget.mangaController,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  Future<void> _onNestedRouteLogout() async {
    Navigator.of(context).popUntil((route) => route.isFirst);
    await widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompactSidebar = constraints.maxWidth < 1120;
        final double shellHeight = (constraints.maxHeight - 24)
            .clamp(620.0, 920.0)
            .toDouble();

        return Scaffold(
          backgroundColor: const Color(0xFF2F3034),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: SizedBox(
                    height: shellHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          ManageMangaSidebar(
                            compact: isCompactSidebar,
                            selectedKey: sidebarKeyUsers,
                            onSelect: (key) {
                              if (key == sidebarKeyManga) {
                                _openMangaPage();
                              } else if (key == sidebarKeyAuthors) {
                                _openAuthorsPage();
                              }
                            },
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(14),
                                bottomRight: Radius.circular(14),
                              ),
                              child: Container(
                                color: const Color(0xFFF7F8FC),
                                child: Column(
                                  children: [
                                    ManageMangaTopHeader(
                                      searchController: _searchController,
                                      onLogout: widget.onLogout,
                                      hintText: 'Tìm kiếm người dùng...',
                                      customHeaderWidget: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFEFF4FF,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.people_alt_rounded,
                                                  size: 18,
                                                  color: Color(0xFF1F5BFF),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Text(
                                                'Quản lý người dùng',
                                                style: TextStyle(
                                                  color: Color(0xFF1D2638),
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -0.3,
                                                  height: 1.1,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          const Padding(
                                            padding: EdgeInsets.only(left: 2),
                                            child: Text(
                                              'Quản lý tài khoản độc giả theo dữ liệu thực tế',
                                              style: TextStyle(
                                                color: Color(0xFF7B879B),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          20,
                                          20,
                                          16,
                                        ),
                                        child: _buildMainContent(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final List<_AdminUser> filteredUsers = _getFilteredAndSortedUsers();
    final List<_AdminUser> pageUsers = _getPagedUsers(filteredUsers);
    final int totalPages = filteredUsers.isEmpty
        ? 1
        : ((filteredUsers.length - 1) ~/ _pageSize) + 1;
    final int safePage = _currentPage.clamp(0, totalPages - 1);
    final int totalUsers = _users
        .where((_AdminUser u) => u.role == 'User')
        .length;
    final int totalAdmins = _users
        .where((_AdminUser u) => u.role == 'Admin')
        .length;
    final int totalVip = _users
        .where((_AdminUser u) => u.role == 'User' && u.membershipTier == 'VIP')
        .length;

    final bool allSelectedOnPage =
        pageUsers.isNotEmpty &&
        pageUsers.every(
          (_AdminUser u) => _selectedUserIds.contains(u.uniqueKey),
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
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
          _buildUserStatsSection(
            totalUsers: totalUsers,
            totalAdmins: totalAdmins,
            totalVip: totalVip,
          ),
          const SizedBox(height: 16),
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
                            (_AdminUser u) =>
                                _selectedUserIds.contains(u.uniqueKey),
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
                        : LayoutBuilder(
                            builder: (BuildContext context, BoxConstraints constraints) {
                              const double leftTableWidth = 380;
                              const double leftScrollWidth = 720;
                              final ScrollBehavior dragScrollBehavior =
                                  const ScrollBehavior().copyWith(
                                    dragDevices: <PointerDeviceKind>{
                                      PointerDeviceKind.mouse,
                                      PointerDeviceKind.touch,
                                      PointerDeviceKind.stylus,
                                      PointerDeviceKind.unknown,
                                    },
                                  );
                              final double rightTableWidth = math.max(
                                _tableMinWidth,
                                constraints.maxWidth + 240,
                              );

                              final List<DataRow> leftRows = pageUsers.map((
                                _AdminUser user,
                              ) {
                                final bool selected = _selectedUserIds.contains(
                                  user.uniqueKey,
                                );
                                return DataRow(
                                  selected: selected,
                                  color: MaterialStateProperty.resolveWith((
                                    Set<MaterialState> states,
                                  ) {
                                    if (states.contains(
                                      MaterialState.selected,
                                    )) {
                                      return const Color(0xFFF3F6FF);
                                    }
                                    return null;
                                  }),
                                  cells: <DataCell>[
                                    DataCell(
                                      Checkbox(
                                        value: selected,
                                        onChanged: (bool? checked) {
                                          setState(() {
                                            if (checked ?? false) {
                                              _selectedUserIds.add(
                                                user.uniqueKey,
                                              );
                                            } else {
                                              _selectedUserIds.remove(
                                                user.uniqueKey,
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
                                      _buildCompactText(user.email, width: 165),
                                    ),
                                    DataCell(
                                      _buildCompactText(
                                        user.userName,
                                        width: 94,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList();

                              final List<DataRow> rightRows = pageUsers.map((
                                _AdminUser user,
                              ) {
                                final bool isVip = user.membershipTier == 'VIP';
                                final bool isMuted = user.isCommentMuted;
                                final bool isBanned = user.isBanned;

                                return DataRow(
                                  selected: _selectedUserIds.contains(
                                    user.uniqueKey,
                                  ),
                                  color: MaterialStateProperty.resolveWith((
                                    Set<MaterialState> states,
                                  ) {
                                    if (states.contains(
                                      MaterialState.selected,
                                    )) {
                                      return const Color(0xFFF3F6FF);
                                    }
                                    return null;
                                  }),
                                  cells: <DataCell>[
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
                                      _buildCompactText(user.gender, width: 84),
                                    ),
                                    DataCell(
                                      _buildCompactText(
                                        _formatDateTime(user.registeredAt),
                                        width: 88,
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        user.role,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: user.role == 'Admin'
                                              ? Colors.red
                                              : Colors.blue,
                                        ),
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
                                                  const PopupMenuItem<String>(
                                                    value: 'reset_password',
                                                    child: Text(
                                                      'Khôi phục mật khẩu',
                                                    ),
                                                  ),
                                                  if (!isVip)
                                                    const PopupMenuItem<String>(
                                                      value: 'grant_vip',
                                                      child: Text(
                                                        'Nâng hạng VIP',
                                                      ),
                                                    ),
                                                  if (isVip)
                                                    const PopupMenuItem<String>(
                                                      value: 'revoke_vip',
                                                      child: Text(
                                                        'Hạ hạng Standard',
                                                      ),
                                                    ),
                                                  if (!isMuted)
                                                    const PopupMenuItem<String>(
                                                      value: 'mute_comment',
                                                      child: Text(
                                                        'Cấm bình luận',
                                                      ),
                                                    ),
                                                  if (isMuted)
                                                    const PopupMenuItem<String>(
                                                      value: 'unmute_comment',
                                                      child: Text(
                                                        'Mở bình luận',
                                                      ),
                                                    ),
                                                  if (!isBanned)
                                                    const PopupMenuItem<String>(
                                                      value: 'ban_user',
                                                      child: Text(
                                                        'Khóa tài khoản',
                                                      ),
                                                    ),
                                                  if (isBanned)
                                                    const PopupMenuItem<String>(
                                                      value: 'unban_user',
                                                      child: Text(
                                                        'Mở khóa tài khoản',
                                                      ),
                                                    ),
                                                  const PopupMenuItem<String>(
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
                              }).toList();

                              final int? leftSortIndex = () {
                                switch (_sortField) {
                                  case _SortField.fullName:
                                    return 1;
                                  case _SortField.email:
                                    return 2;
                                  case _SortField.userName:
                                    return 3;
                                  default:
                                    return null;
                                }
                              }();

                              final int? rightSortIndex = () {
                                switch (_sortField) {
                                  case _SortField.phone:
                                    return 0;
                                  case _SortField.address:
                                    return 1;
                                  case _SortField.gender:
                                    return 2;
                                  case _SortField.registeredAt:
                                    return 3;
                                  case _SortField.membership:
                                    return 5;
                                  case _SortField.comment:
                                    return 6;
                                  case _SortField.account:
                                    return 7;
                                  default:
                                    return null;
                                }
                              }();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          width: leftTableWidth,
                                          height: _scrollbarHeight,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF2F5FB),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE3E8F4),
                                            ),
                                          ),
                                          child: ScrollbarTheme(
                                            data: ScrollbarThemeData(
                                              thickness:
                                                  MaterialStateProperty.all(8),
                                              radius: const Radius.circular(8),
                                              thumbColor:
                                                  MaterialStateProperty.all(
                                                    const Color(0xFFB5C0D6),
                                                  ),
                                              trackColor:
                                                  MaterialStateProperty.all(
                                                    const Color(0xFFE7ECF5),
                                                  ),
                                              trackBorderColor:
                                                  MaterialStateProperty.all(
                                                    const Color(0xFFD5DDEA),
                                                  ),
                                            ),
                                            child: Scrollbar(
                                              controller: _leftGutterController,
                                              thumbVisibility: true,
                                              trackVisibility: true,
                                              interactive: true,
                                              scrollbarOrientation:
                                                  ScrollbarOrientation.bottom,
                                              child: ScrollConfiguration(
                                                behavior: dragScrollBehavior,
                                                child: SingleChildScrollView(
                                                  controller:
                                                      _leftGutterController,
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  physics:
                                                      const ClampingScrollPhysics(),
                                                  child: SizedBox(
                                                    width: leftScrollWidth,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Container(
                                            height: _scrollbarHeight,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF2F5FB),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(0xFFE3E8F4),
                                              ),
                                            ),
                                            child: ScrollbarTheme(
                                              data: ScrollbarThemeData(
                                                thickness:
                                                    MaterialStateProperty.all(
                                                      8,
                                                    ),
                                                radius: const Radius.circular(
                                                  8,
                                                ),
                                                thumbColor:
                                                    MaterialStateProperty.all(
                                                      const Color(0xFFB5C0D6),
                                                    ),
                                                trackColor:
                                                    MaterialStateProperty.all(
                                                      const Color(0xFFE7ECF5),
                                                    ),
                                                trackBorderColor:
                                                    MaterialStateProperty.all(
                                                      const Color(0xFFD5DDEA),
                                                    ),
                                              ),
                                              child: Scrollbar(
                                                controller:
                                                    _gutterHorizontalController,
                                                thumbVisibility: true,
                                                trackVisibility: true,
                                                interactive: true,
                                                scrollbarOrientation:
                                                    ScrollbarOrientation.bottom,
                                                child: SingleChildScrollView(
                                                  controller:
                                                      _gutterHorizontalController,
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: SizedBox(
                                                    width: rightTableWidth,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Container(
                                          width: leftTableWidth,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border(
                                              right: BorderSide(
                                                color: const Color(0xFFE4E8F2),
                                              ),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: ScrollConfiguration(
                                              behavior: dragScrollBehavior,
                                              child: SingleChildScrollView(
                                                controller:
                                                    _leftTableController,
                                                scrollDirection:
                                                    Axis.horizontal,
                                                physics:
                                                    const ClampingScrollPhysics(),
                                                child: SizedBox(
                                                  width: leftScrollWidth,
                                                  child: DataTable(
                                                    sortColumnIndex:
                                                        leftSortIndex,
                                                    sortAscending:
                                                        _sortAscending,
                                                    horizontalMargin: 6,
                                                    checkboxHorizontalMargin: 4,
                                                    columnSpacing: 8,
                                                    dataRowMinHeight: 46,
                                                    dataRowMaxHeight: 52,
                                                    headingRowHeight: 44,
                                                    columns: <DataColumn>[
                                                      DataColumn(
                                                        label: Checkbox(
                                                          value:
                                                              allSelectedOnPage,
                                                          onChanged: (bool? checked) {
                                                            setState(() {
                                                              if (checked ??
                                                                  false) {
                                                                for (final _AdminUser
                                                                    user
                                                                    in pageUsers) {
                                                                  _selectedUserIds
                                                                      .add(
                                                                        user.uniqueKey,
                                                                      );
                                                                }
                                                              } else {
                                                                for (final _AdminUser
                                                                    user
                                                                    in pageUsers) {
                                                                  _selectedUserIds
                                                                      .remove(
                                                                        user.uniqueKey,
                                                                      );
                                                                }
                                                              }
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: const Text(
                                                          'Họ tên',
                                                        ),
                                                        onSort:
                                                            (int _, bool asc) =>
                                                                _setSort(
                                                                  _SortField
                                                                      .fullName,
                                                                  asc,
                                                                ),
                                                      ),
                                                      DataColumn(
                                                        label: const Text(
                                                          'Email',
                                                        ),
                                                        onSort:
                                                            (
                                                              int _,
                                                              bool asc,
                                                            ) => _setSort(
                                                              _SortField.email,
                                                              asc,
                                                            ),
                                                      ),
                                                      DataColumn(
                                                        label: const Text(
                                                          'Username',
                                                        ),
                                                        onSort:
                                                            (int _, bool asc) =>
                                                                _setSort(
                                                                  _SortField
                                                                      .userName,
                                                                  asc,
                                                                ),
                                                      ),
                                                    ],
                                                    rows: leftRows,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            controller:
                                                _tableHorizontalController,
                                            scrollDirection: Axis.horizontal,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 8,
                                            ),
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minWidth: rightTableWidth,
                                              ),
                                              child: DataTable(
                                                sortColumnIndex: rightSortIndex,
                                                sortAscending: _sortAscending,
                                                horizontalMargin: 6,
                                                checkboxHorizontalMargin: 4,
                                                columnSpacing: 8,
                                                dataRowMinHeight: 46,
                                                dataRowMaxHeight: 52,
                                                headingRowHeight: 44,
                                                columns: <DataColumn>[
                                                  DataColumn(
                                                    label: const Text('SĐT'),
                                                    onSort: (int _, bool asc) =>
                                                        _setSort(
                                                          _SortField.phone,
                                                          asc,
                                                        ),
                                                  ),
                                                  DataColumn(
                                                    label: const Text(
                                                      'Địa chỉ',
                                                    ),
                                                    onSort: (int _, bool asc) =>
                                                        _setSort(
                                                          _SortField.address,
                                                          asc,
                                                        ),
                                                  ),
                                                  DataColumn(
                                                    label: const Text(
                                                      'Giới tính',
                                                    ),
                                                    onSort: (int _, bool asc) =>
                                                        _setSort(
                                                          _SortField.gender,
                                                          asc,
                                                        ),
                                                  ),
                                                  DataColumn(
                                                    label: const Text(
                                                      'Ngày đăng ký',
                                                    ),
                                                    onSort: (int _, bool asc) =>
                                                        _setSort(
                                                          _SortField
                                                              .registeredAt,
                                                          asc,
                                                        ),
                                                  ),
                                                  DataColumn(
                                                    label: const Text(
                                                      'Vai trò',
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: const Text('Hạng'),
                                                    onSort: (int _, bool asc) =>
                                                        _setSort(
                                                          _SortField.membership,
                                                          asc,
                                                        ),
                                                  ),
                                                  DataColumn(
                                                    label: const Text(
                                                      'Bình luận',
                                                    ),
                                                    onSort: (int _, bool asc) =>
                                                        _setSort(
                                                          _SortField.comment,
                                                          asc,
                                                        ),
                                                  ),
                                                  DataColumn(
                                                    label: const Text(
                                                      'Tài khoản',
                                                    ),
                                                    onSort: (int _, bool asc) =>
                                                        _setSort(
                                                          _SortField.account,
                                                          asc,
                                                        ),
                                                  ),
                                                  const DataColumn(
                                                    label: Text('Thao tác'),
                                                  ),
                                                ],
                                                rows: rightRows,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
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

class _UserStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;
  final String? actionLabel;

  const _UserStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.onTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    final BorderRadius borderRadius = BorderRadius.circular(14);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: borderRadius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: content,
        ),
      ),
    );
  }
}
