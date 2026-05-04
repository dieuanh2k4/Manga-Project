import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin/core/constants/constants.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/core/utils/auth_token_storage.dart';
import 'package:web_admin/domain/entities/author.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/domain/usecases/get_authors.dart';
import 'package:web_admin/injection_container.dart';
import 'package:web_admin/presentation/bloc/manga/remote/remote_manga_bloc.dart';
import 'package:web_admin/presentation/bloc/manga/remote/remote_manga_event.dart';
import 'package:web_admin/presentation/bloc/manga/remote/remote_manga_state.dart';
import 'package:web_admin/presentation/helper/manage_manga_service.dart';
import 'package:web_admin/presentation/pages/home/manage_manga.dart';
import 'package:web_admin/presentation/widgets/manage_manga_sidebar.dart';
import 'package:web_admin/presentation/widgets/manage_manga_top_header.dart';

class ManageAuthors extends StatefulWidget {
  const ManageAuthors({super.key});

  @override
  State<ManageAuthors> createState() => _ManageAuthorsState();
}

class _ManageAuthorsState extends State<ManageAuthors> {
  final Dio _dio = sl<Dio>();
  final AuthTokenStorage _tokenStorage = sl<AuthTokenStorage>();
  final GetAuthorsUseCase _getAuthorsUseCase = sl<GetAuthorsUseCase>();
  final ManageMangaService _mangaService = sl<ManageMangaService>();

  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  List<AuthorEntity> _authors = const <AuthorEntity>[];
  String _selectedSort = 'A-Z';
  bool _onlyNoManga = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onFilterChanged);
    _loadAuthors();
    context.read<RemoteMangaBloc>().add(const GetManga());
  }

  @override
  void dispose() {
    _searchController.removeListener(_onFilterChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _loadAuthors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final DataState<List<AuthorEntity>> state = await _getAuthorsUseCase();

    if (!mounted) {
      return;
    }

    if (state is DataSuccess<List<AuthorEntity>> && state.data != null) {
      setState(() {
        _authors = state.data!;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = 'Không thể tải danh sách tác giả';
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

  Future<void> _showAuthorForm({AuthorEntity? author}) async {
    final TextEditingController nameController = TextEditingController(
      text: author?.fullName ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: author?.description ?? '',
    );

    final bool? submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(author == null ? 'Thêm tác giả' : 'Sửa tác giả'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên tác giả'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (submitted != true) {
      return;
    }

    final String fullName = nameController.text.trim();
    if (fullName.isEmpty) {
      _showMessage('Tên tác giả không được để trống');
      return;
    }

    if (author == null) {
      await _createAuthor(fullName, descriptionController.text.trim());
    } else {
      await _updateAuthor(author.id ?? 0, fullName, descriptionController.text);
    }
  }

  Future<void> _createAuthor(String name, String description) async {
    try {
      final Map<String, dynamic> headers = await _buildAuthHeaders();
      final FormData data = FormData.fromMap({
        'FullName': name,
        'Description': description.trim(),
      });

      await _dio.post<dynamic>(
        '${newAPIBaseURL}Author/create-author',
        data: data,
        options: Options(headers: headers),
      );

      await _loadAuthors();
      _showMessage('Tạo tác giả thành công');
    } catch (_) {
      _showMessage('Không thể tạo tác giả');
    }
  }

  Future<void> _updateAuthor(int id, String name, String description) async {
    if (id <= 0) {
      _showMessage('Tác giả không hợp lệ');
      return;
    }

    try {
      final Map<String, dynamic> headers = await _buildAuthHeaders();
      final FormData data = FormData.fromMap({
        'FullName': name,
        'Description': description.trim(),
      });

      await _dio.put<dynamic>(
        '${newAPIBaseURL}Author/update-author/$id',
        data: data,
        options: Options(headers: headers),
      );

      await _loadAuthors();
      _showMessage('Cập nhật tác giả thành công');
    } catch (_) {
      _showMessage('Không thể cập nhật tác giả');
    }
  }

  Future<void> _deleteAuthor(int id, int mangaCount) async {
    if (mangaCount > 0) {
      _showMessage('Bạn phải xóa manga trước');
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tác giả'),
        content: const Text('Bạn có chắc muốn xóa tác giả này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      final Map<String, dynamic> headers = await _buildAuthHeaders();
      await _dio.delete<dynamic>(
        '${newAPIBaseURL}Author/delete-author/$id',
        options: Options(headers: headers),
      );

      await _loadAuthors();
      _showMessage('Đã xóa tác giả');
    } catch (_) {
      _showMessage('Không thể xóa tác giả');
    }
  }

  List<AuthorEntity> _filterAuthors(
    Map<int, List<MangaEntity>> mangaByAuthor,
  ) {
    final String keyword = _searchController.text.trim().toLowerCase();
    final List<AuthorEntity> sorted = List<AuthorEntity>.from(_authors)
      ..sort((a, b) {
        final String aName = (a.fullName ?? '').toLowerCase();
        final String bName = (b.fullName ?? '').toLowerCase();
        return aName.compareTo(bName);
      });

    if (_selectedSort == 'Manga nhiều') {
      sorted.sort((a, b) {
        final int aCount = mangaByAuthor[a.id ?? 0]?.length ?? 0;
        final int bCount = mangaByAuthor[b.id ?? 0]?.length ?? 0;
        return bCount.compareTo(aCount);
      });
    }

    return sorted.where((author) {
      final String name = (author.fullName ?? '').toLowerCase();
      final String description = (author.description ?? '').toLowerCase();
      final int mangaCount = mangaByAuthor[author.id ?? 0]?.length ?? 0;

      final bool matchesKeyword = keyword.isEmpty ||
          name.contains(keyword) ||
          description.contains(keyword);
      final bool matchesNoManga = !_onlyNoManga || mangaCount == 0;

      return matchesKeyword && matchesNoManga;
    }).toList();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showAuthorDetail(
    AuthorEntity author,
    List<MangaEntity> mangaList,
  ) async {
    final int mangaCount = mangaList.length;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(author.fullName ?? 'Tác giả'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (author.description ?? '').trim().isEmpty
                    ? 'Chưa có mô tả'
                    : author.description!.trim(),
                style: const TextStyle(color: Color(0xFF4E5A6F)),
              ),
              const SizedBox(height: 14),
              Text(
                'Tác phẩm (${mangaList.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D2638),
                ),
              ),
              const SizedBox(height: 8),
              if (mangaList.isEmpty)
                const Text('Chưa có manga nào')
              else
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    itemCount: mangaList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final manga = mangaList[index];
                      return ListTile(
                        dense: true,
                        title: Text(manga.title ?? 'Manga'),
                        subtitle: Text(
                          'Chương: ${manga.totalChapter ?? 0}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Xóa manga',
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () async {
                            final int mangaId = manga.id ?? 0;
                            if (mangaId <= 0) {
                              return;
                            }

                            final bool? confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Xóa manga'),
                                content: Text(
                                  'Xóa "${manga.title ?? 'Manga'}" không?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Hủy'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Xóa'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed != true) {
                              return;
                            }

                            final ManageMangaDeleteResult result =
                                await _mangaService.deleteManga(mangaId);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result.message)),
                              );
                              if (result.isSuccess) {
                                context.read<RemoteMangaBloc>().add(
                                  const GetManga(),
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showAuthorForm(author: author);
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Sửa'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await _deleteAuthor(author.id ?? 0, mangaCount);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xóa'),
          ),
        ],
      ),
    );
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
                            selectedKey: sidebarKeyAuthors,
                            onSelect: (key) {
                              if (key == sidebarKeyManga) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ManageManga(),
                                  ),
                                );
                              }
                            },
                          ),
                          Expanded(child: _buildMainContent(context)),
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
    return ClipRRect(
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
              hintText: 'Tìm kiếm tác giả...',
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: _isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : BlocBuilder<RemoteMangaBloc, RemoteMangaState>(
                        builder: (_, state) {
                          final List<MangaEntity> mangaList =
                              state is RemoteMangaDone
                                  ? (state.manga ?? const <MangaEntity>[])
                                  : const <MangaEntity>[];

                          final Map<int, List<MangaEntity>> mangaByAuthor =
                              <int, List<MangaEntity>>{};
                          for (final manga in mangaList) {
                            final int authorId = manga.authorId ?? 0;
                            if (authorId <= 0) {
                              continue;
                            }
                            mangaByAuthor
                                .putIfAbsent(authorId, () => <MangaEntity>[])
                                .add(manga);
                          }

                          final List<AuthorEntity> visibleAuthors =
                              _filterAuthors(mangaByAuthor);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Quản lý tác giả',
                                        style: TextStyle(
                                          color: Color(0xFF1D2638),
                                          fontSize: 32,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Danh sách tác giả và tác phẩm liên quan',
                                        style: TextStyle(
                                          color: Color(0xFF7B879B),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _showAuthorForm,
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
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text(
                                      'Thêm tác giả',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE4E8F2),
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Nhập tên tác giả...',
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
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 11),
                                    filled: true,
                                    fillColor: const Color(0xFFF7F8FC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE4E8F2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 40,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F8FC),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedSort,
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 20,
                                          ),
                                          style: const TextStyle(
                                            color: Color(0xFF4D5B72),
                                            fontSize: 13,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'A-Z',
                                              child: Text('Sắp xếp A-Z'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Manga nhiều',
                                              child: Text('Manga nhiều nhất'),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            if (value == null) {
                                              return;
                                            }
                                            setState(() {
                                              _selectedSort = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Checkbox(
                                      value: _onlyNoManga,
                                      onChanged: (value) {
                                        setState(() {
                                          _onlyNoManga = value ?? false;
                                        });
                                      },
                                    ),
                                    const Text('Chỉ tác giả chưa có truyện'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE4E8F2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          16,
                                          16,
                                          10,
                                        ),
                                        child: Text(
                                          'Danh sách tác giả (${visibleAuthors.length})',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1E2A3C),
                                          ),
                                        ),
                                      ),
                                      const Divider(
                                        height: 1,
                                        color: Color(0xFFEEF1F6),
                                      ),
                                      Expanded(
                                        child: visibleAuthors.isEmpty
                                            ? const Center(
                                                child: Text(
                                                  'Chưa có tác giả nào',
                                                  style: TextStyle(
                                                    color: Color(0xFF8491A7),
                                                  ),
                                                ),
                                              )
                                            : ListView.separated(
                                                itemCount:
                                                    visibleAuthors.length,
                                                separatorBuilder: (_, __) =>
                                                    const Divider(height: 1),
                                                itemBuilder: (context, index) {
                                                  final author =
                                                      visibleAuthors[index];
                                                  final int authorId =
                                                      author.id ?? 0;
                                                  final List<MangaEntity>
                                                      authorManga =
                                                      mangaByAuthor[authorId] ??
                                                          const <MangaEntity>[];

                                                  return ListTile(
                                                    title: Text(
                                                      author.fullName ??
                                                          'Tác giả #$authorId',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                      (author.description ?? '')
                                                              .trim()
                                                              .isEmpty
                                                          ? 'Chưa có mô tả'
                                                          : author.description!
                                                              .trim(),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    trailing: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          '${authorManga.length}',
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                        const Text(
                                                          'manga',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color:
                                                                Color(0xFF7B879B),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    onTap: () =>
                                                        _showAuthorDetail(
                                                      author,
                                                      authorManga,
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
