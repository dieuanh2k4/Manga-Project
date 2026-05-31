import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:web_admin/core/constants/constants.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/core/utils/auth_token_storage.dart';
import 'package:web_admin/domain/entities/genre.dart';
import 'package:web_admin/domain/usecases/get_genres.dart';
import 'package:web_admin/injection_container.dart';
import 'package:web_admin/presentation/controllers/remote_manga_controller.dart';
import 'package:web_admin/presentation/controllers/theme_controller.dart';
import 'package:web_admin/presentation/pages/home/manage_authors.dart';
import 'package:web_admin/presentation/pages/home/manage_manga.dart';
import 'package:web_admin/presentation/pages/home/manage_notifications.dart';
import 'package:web_admin/presentation/pages/home/manage_users.dart';
import 'package:web_admin/presentation/pages/home/manage_vip_packages.dart';
import 'package:web_admin/presentation/widgets/manage_genres_body.dart';
import 'package:web_admin/presentation/widgets/manage_manga_sidebar.dart';
import 'package:web_admin/presentation/widgets/manage_manga_top_header.dart';

class ManageGenres extends StatefulWidget {
  final RemoteMangaController mangaController;
  final Future<void> Function()? onLogout;

  const ManageGenres({
    super.key,
    required this.mangaController,
    this.onLogout,
  });

  @override
  State<ManageGenres> createState() => _ManageGenresState();
}

class _ManageGenresState extends State<ManageGenres> {
  final Dio _dio = sl<Dio>();
  final AuthTokenStorage _tokenStorage = sl<AuthTokenStorage>();
  final GetGenresUseCase _getGenresUseCase = sl<GetGenresUseCase>();

  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  List<GenreEntity> _genres = const <GenreEntity>[];
  String _selectedSort = 'A-Z';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onFilterChanged);
    _loadGenres();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onFilterChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadGenres() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final DataState<List<GenreEntity>> state = await _getGenresUseCase();

    if (!mounted) {
      return;
    }

    if (state is DataSuccess<List<GenreEntity>> && state.data != null) {
      setState(() {
        _genres = state.data!;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = 'Không thể tải danh sách thể loại';
    });
  }

  Future<Map<String, dynamic>> _buildAuthHeaders() async {
    final String? token = await _tokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      return <String, dynamic>{};
    }
    return <String, dynamic>{
      'Authorization': _tokenStorage.formatBearerValue(token),
    };
  }

  Future<void> _showGenreForm({GenreEntity? genre}) async {
    final TextEditingController nameController = TextEditingController(
      text: genre?.name ?? '',
    );

    final bool? submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = sl<ThemeController>().isDarkMode;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            genre == null ? 'Thêm thể loại mới' : 'Chỉnh sửa thể loại',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Tên thể loại',
                labelStyle: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              ),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F5BFF),
                foregroundColor: Colors.white,
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

    if (submitted != true) {
      nameController.dispose();
      return;
    }

    final String name = nameController.text.trim();
    nameController.dispose();

    if (name.isEmpty) {
      _showMessage('Tên thể loại không được để trống');
      return;
    }

    if (genre == null) {
      await _createGenre(name);
    } else {
      await _updateGenre(genre.id ?? 0, name);
    }
  }

  Future<void> _createGenre(String name) async {
    try {
      final Map<String, dynamic> headers = await _buildAuthHeaders();
      await _dio.post<dynamic>(
        '${newAPIBaseURL}Genre/create-genre',
        data: {'Name': name},
        options: Options(headers: headers),
      );

      await _loadGenres();
      _showMessage('Thêm thể loại thành công');
    } catch (_) {
      _showMessage('Không thể thêm thể loại');
    }
  }

  Future<void> _updateGenre(int id, String name) async {
    if (id <= 0) {
      _showMessage('Thể loại không hợp lệ');
      return;
    }

    try {
      final Map<String, dynamic> headers = await _buildAuthHeaders();
      await _dio.put<dynamic>(
        '${newAPIBaseURL}Genre/update-genre/$id',
        data: {'Name': name},
        options: Options(headers: headers),
      );

      await _loadGenres();
      _showMessage('Cập nhật thể loại thành công');
    } catch (_) {
      _showMessage('Không thể cập nhật thể loại');
    }
  }

  Future<void> _deleteGenre(GenreEntity genre) async {
    final int genreId = genre.id ?? 0;
    if (genreId <= 0) {
      _showMessage('Thể loại không hợp lệ');
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = sl<ThemeController>().isDarkMode;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Xóa thể loại',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          content: Text(
            'Bạn có chắc muốn xóa "${genre.name ?? 'thể loại'}"?',
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final Map<String, dynamic> headers = await _buildAuthHeaders();
      await _dio.delete<dynamic>(
        '${newAPIBaseURL}Genre/delete-genre/$genreId',
        options: Options(headers: headers),
      );

      await _loadGenres();
      _showMessage('Đã xóa thể loại');
    } catch (_) {
      _showMessage('Không thể xóa thể loại');
    }
  }

  List<GenreEntity> _filterGenres() {
    final String keyword = _searchController.text.trim().toLowerCase();
    final List<GenreEntity> sorted = List<GenreEntity>.from(_genres)
      ..sort((a, b) {
        if (_selectedSort == 'ID') {
          final int aId = a.id ?? 0;
          final int bId = b.id ?? 0;
          return aId.compareTo(bId);
        } else {
          final String aName = (a.name ?? '').toLowerCase();
          final String bName = (b.name ?? '').toLowerCase();
          return aName.compareTo(bName);
        }
      });

    if (keyword.isEmpty) {
      return sorted;
    }

    return sorted.where((genre) {
      final String name = (genre.name ?? '').toLowerCase();
      return name.contains(keyword);
    }).toList();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openMangaPage() {
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
        final scaffoldBg = isDark
            ? const Color(0xFF1A1D2E)
            : const Color(0xFFDFE3ED);
        final shellBg = isDark ? const Color(0xFF0E1326) : Colors.white;
        final shellBorder = isDark
            ? const Color(0xFF1E2640)
            : const Color(0xFFE2E8F0);

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
                                selectedKey: sidebarKeyGenres,
                                onSelect: (key) {
                                  if (key == sidebarKeyOverview) {
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  } else if (key == sidebarKeyManga) {
                                    _openMangaPage();
                                  } else if (key == sidebarKeyAuthors) {
                                    _openAuthorsPage();
                                  } else if (key == sidebarKeyUsers) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ManageUsers(
                                          mangaController: widget.mangaController,
                                          onLogout: widget.onLogout,
                                        ),
                                      ),
                                    );
                                  } else if (key == sidebarKeyVip) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ManageVipPackages(
                                          mangaController: widget.mangaController,
                                          onLogout: widget.onLogout,
                                        ),
                                      ),
                                    );
                                  } else if (key == sidebarKeyNotifications) {
                                    _openNotificationsPage();
                                  }
                                },
                              ),
                              Expanded(child: _buildMainContent()),
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

  Widget _buildMainContent() {
    final isDark = sl<ThemeController>().isDarkMode;
    return ClipRRect(
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
              hintText: 'Tìm kiếm thể loại...',
              customHeaderWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.category_outlined,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF1F5BFF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Quản lý Thể loại',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1D2638),
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
                      'Quản lý danh sách thể loại truyện trong hệ thống',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF7B879B),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: _isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          )
                        : ManageGenresBody(
                            searchController: _searchController,
                            selectedSort: _selectedSort,
                            onSortChanged: (value) {
                              setState(() {
                                _selectedSort = value;
                              });
                            },
                            visibleGenres: _filterGenres(),
                            onAddGenre: _showGenreForm,
                            onEditGenre: (genre) {
                              _showGenreForm(genre: genre);
                            },
                            onDeleteGenre: _deleteGenre,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
