import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_admin/core/constants/constants.dart';
import 'package:web_admin/core/utils/auth_token_storage.dart';
import 'package:web_admin/injection_container.dart';
import 'package:web_admin/presentation/controllers/remote_manga_controller.dart';
import 'package:web_admin/presentation/controllers/theme_controller.dart';
import 'package:web_admin/presentation/widgets/manage_manga_sidebar.dart';
import 'package:web_admin/presentation/widgets/manage_manga_top_header.dart';
import 'manage_authors.dart';
import 'manage_overview.dart';
import 'manage_manga.dart';
import 'manage_notifications.dart';
import 'manage_users.dart';

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

class ManageVipPackages extends StatefulWidget {
  final RemoteMangaController mangaController;
  final Future<void> Function()? onLogout;

  const ManageVipPackages({
    super.key,
    required this.mangaController,
    this.onLogout,
  });

  @override
  State<ManageVipPackages> createState() => _ManageVipPackagesState();
}

class _ManageVipPackagesState extends State<ManageVipPackages> {
  final Dio _dio = sl<Dio>();
  final AuthTokenStorage _tokenStorage = sl<AuthTokenStorage>();

  final List<_VipPackage> _vipPackages = <_VipPackage>[];
  final List<_VipPrivilege> _vipPrivileges = <_VipPrivilege>[];

  bool _vipLoading = false;
  String? _vipError;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchVipData();
  }

  // ── JSON Helpers ─────────────────────────────────────────────────────────

  dynamic _readField(Map<String, dynamic> data, List<String> keys) {
    for (final String key in keys) {
      if (data.containsKey(key)) {
        return data[key];
      }
    }
    return null;
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

  // ── Network Operations ───────────────────────────────────────────────────

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

  // ── Modals & Dialogs ─────────────────────────────────────────────────────

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
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

  Future<void> _showVipPackageForm({_VipPackage? package}) async {
    final TextEditingController titleController = TextEditingController(
      text: package?.title ?? '',
    );
    final TextEditingController priceController = TextEditingController(
      text: package?.price.toString() ?? '',
    );
    final TextEditingController durationController = TextEditingController(
      text: package?.durationDays.toString() ?? '',
    );

    final Set<int> selectedPrivilegeIds = package?.privileges
            .map((priv) => priv.id)
            .toSet() ??
        <int>{};

    await showDialog<void>(
      context: context,
      barrierColor: const Color(0xAA0B1220),
      builder: (BuildContext dialogContext) {
        bool isSaving = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> submit() async {
              final String title = titleController.text.trim();
              final String priceRaw = priceController.text.trim();
              final String durationRaw = durationController.text.trim();

              if (title.isEmpty || priceRaw.isEmpty || durationRaw.isEmpty) {
                setStateDialog(() {
                  errorMessage = 'Vui lòng điền đầy đủ các thông tin.';
                });
                return;
              }

              final int? price = int.tryParse(priceRaw);
              final int? duration = int.tryParse(durationRaw);

              if (price == null || duration == null) {
                setStateDialog(() {
                  errorMessage = 'Giá trị giá/thời hạn không hợp lệ.';
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
                durationDays: duration,
                privilegeIds: selectedPrivilegeIds.toList(),
              );

              if (!success) {
                setStateDialog(() {
                  isSaving = false;
                  errorMessage = 'Không thể lưu gói VIP. Vui lòng thử lại.';
                });
                return;
              }

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(package == null ? 'Tạo gói VIP mới' : 'Chỉnh sửa gói VIP'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Tên gói VIP',
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
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
      barrierColor: const Color(0xAA0B1220),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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

  // ── Layout & View Builders ───────────────────────────────────────────────

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

  void _openUsersPage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ManageUsers(
          mangaController: widget.mangaController,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  void _openNotificationsPage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ManageNotifications(
          mangaController: widget.mangaController,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = sl<ThemeController>();
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final isDark = themeController.isDarkMode;
        final scaffoldBg = isDark ? const Color(0xFF1A1D2E) : const Color(0xFFDFE3ED);
        final shellBg = isDark ? const Color(0xFF0E1326) : Colors.white;
        final shellBorder = isDark ? const Color(0xFF1E2640) : const Color(0xFFE2E8F0);

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isCompactSidebar = constraints.maxWidth < 1120;
            final double shellHeight = (constraints.maxHeight - 24)
                .clamp(620.0, 920.0)
                .toDouble();

            return Scaffold(
              backgroundColor: scaffoldBg,
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
                            color: shellBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: shellBorder, width: 1),
                          ),
                          child: Row(
                            children: [
                              ManageMangaSidebar(
                                compact: isCompactSidebar,
                                selectedKey: sidebarKeyVip,
                                onSelect: (key) {
                                  if (key == sidebarKeyOverview) {
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  } else if (key == sidebarKeyManga) {
                                    _openMangaPage();
                                  } else if (key == sidebarKeyAuthors) {
                                    _openAuthorsPage();
                                  } else if (key == sidebarKeyUsers) {
                                    _openUsersPage();
                                  } else if (key == sidebarKeyNotifications) {
                                    _openNotificationsPage();
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
                                    color: isDark ? const Color(0xFF080C1B) : const Color(0xFFF7F8FC),
                                    child: Column(
                                      children: [
                                        ManageMangaTopHeader(
                                          searchController: _searchController,
                                          onLogout: widget.onLogout,
                                          onNotificationTap: _openNotificationsPage,
                                          hintText: 'Tìm kiếm gói VIP...',
                                          customHeaderWidget: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? const Color(0xFF452200) : const Color(0xFFFFF4D6),
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                    ),
                                                    child: Icon(
                                                      Icons.stars_rounded,
                                                      size: 18,
                                                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    'Quản lý gói VIP',
                                                    style: TextStyle(
                                                      color: isDark ? Colors.white : const Color(0xFF1D2638),
                                                      fontSize: 26,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: -0.3,
                                                      height: 1.1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 2),
                                                child: Text(
                                                  'Thiết lập ưu đãi & thời hạn cho từng gói hội viên VIP',
                                                  style: TextStyle(
                                                    color: isDark ? Colors.white70 : const Color(0xFF7B879B),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    if (_vipLoading)
                                      const LinearProgressIndicator(minHeight: 3),
                                    if (_vipError != null)
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF1F2),
                                          borderRadius: BorderRadius.circular(12),
                                          border:
                                              Border.all(color: const Color(0xFFFBC8CE)),
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
                                              onPressed: () => _fetchVipData(),
                                              child: const Text('Tải lại'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: _buildMainContentPanel(context),
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
      },
    );
  }

  Widget _buildMainContentPanel(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool stacked = constraints.maxWidth < 900;

        final Widget packagePanel = _buildVipPackagePanel(
          onEditPackage: (pkg) => _showVipPackageForm(package: pkg),
          onDeletePackage: _confirmDeleteVipPackage,
          shrinkWrap: stacked,
        );
        final Widget privilegePanel = _buildVipPrivilegePanel(
          onCreatePrivilege: _showCreatePrivilegeDialog,
          shrinkWrap: stacked,
        );

        if (stacked) {
          return ListView(
            children: <Widget>[
              packagePanel,
              const SizedBox(height: 20),
              privilegePanel,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(flex: 3, child: packagePanel),
            const SizedBox(width: 20),
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
      padding: const EdgeInsets.all(16),
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
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showVipPackageForm(),
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
            ],
          ),
          const SizedBox(height: 16),
          if (_vipPackages.isEmpty && !_vipLoading)
            Expanded(
              child: _buildVipEmptyState(
                title: 'Chưa có gói VIP',
                subtitle: 'Thêm gói đầu tiên để áp dụng cho người dùng',
              ),
            )
          else if (shrinkWrap)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _vipPackages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
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
                separatorBuilder: (_, __) => const SizedBox(height: 14),
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
      padding: const EdgeInsets.all(16),
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
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onCreatePrivilege,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm đặc quyền', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_vipPrivileges.isEmpty && !_vipLoading)
            Expanded(
              child: _buildVipEmptyState(
                title: 'Chưa có đặc quyền',
                subtitle: 'Thêm đặc quyền để gán vào gói VIP',
                icon: Icons.add_moderator_rounded,
              ),
            )
          else if (shrinkWrap)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _vipPrivileges.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final _VipPrivilege item = _vipPrivileges[index];
                return _buildVipPrivilegeItem(item);
              },
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _vipPrivileges.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final _VipPrivilege item = _vipPrivileges[index];
                  return _buildVipPrivilegeItem(item);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVipPrivilegeItem(_VipPrivilege item) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
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
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
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
                    children: package.privileges.map((priv) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.check,
                              color: Color(0xFF475569),
                              size: 10,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              priv.content,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('Chỉnh sửa', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 14,
                        color: Color(0xFFEF4444),
                      ),
                      label: const Text(
                        'Xóa',
                        style: TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
    IconData icon = Icons.local_offer_outlined,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 44,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
