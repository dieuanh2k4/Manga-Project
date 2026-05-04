import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:web_admin/core/constants/constants.dart';
import 'package:web_admin/core/utils/auth_token_storage.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/injection_container.dart';
import 'package:web_admin/presentation/models/manga_detail_items.dart';
import 'package:web_admin/presentation/widgets/manga_detail_panels.dart';

class ManageMangaDetailPage extends StatefulWidget {
  final MangaEntity manga;

  const ManageMangaDetailPage({super.key, required this.manga});

  @override
  State<ManageMangaDetailPage> createState() => _ManageMangaDetailPageState();
}

class _ManageMangaDetailPageState extends State<ManageMangaDetailPage> {
  final Dio _dio = sl<Dio>();
  final AuthTokenStorage _tokenStorage = sl<AuthTokenStorage>();

  final List<ChapterItem> _chapters = <ChapterItem>[];
  final List<PageItem> _pages = <PageItem>[];
  final Set<int> _selectedPageIds = <int>{};

  bool _loadingChapters = false;
  bool _loadingPages = false;
  String? _errorMessage;
  ChapterItem? _selectedChapter;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    final int mangaId = widget.manga.id ?? 0;
    if (mangaId <= 0) {
      setState(() {
        _errorMessage = 'Manga không hợp lệ';
      });
      return;
    }

    setState(() {
      _loadingChapters = true;
      _errorMessage = null;
    });

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '${newAPIBaseURL}Chapter/get-all-chapter/$mangaId',
      );

      final List<ChapterItem> chapters = extractApiList(response.data)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(ChapterItem.fromJson)
          .toList();

      setState(() {
        _chapters
          ..clear()
          ..addAll(chapters);
        _selectedChapter = chapters.isNotEmpty ? chapters.first : null;
      });

      if (_selectedChapter != null) {
        await _loadPages();
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Không thể tải danh sách chapter';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingChapters = false;
        });
      }
    }
  }

  Future<void> _loadPages() async {
    final int mangaId = widget.manga.id ?? 0;
    final int chapterId = _selectedChapter?.id ?? 0;

    if (mangaId <= 0 || chapterId <= 0) {
      return;
    }

    setState(() {
      _loadingPages = true;
      _selectedPageIds.clear();
    });

    try {
      final Map<String, dynamic> headers = await _buildAuthHeaders();
      final Response<dynamic> response = await _dio.get<dynamic>(
        '${newAPIBaseURL}Page/get-all-page/$mangaId/$chapterId',
        options: Options(headers: headers),
      );

      final List<PageItem> pages = extractApiList(response.data)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(PageItem.fromJson)
          .toList();

      setState(() {
        _pages
          ..clear()
          ..addAll(pages);
      });
    } catch (_) {
      setState(() {
        _pages.clear();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingPages = false;
        });
      }
    }
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

  Future<void> _showChapterEditor({ChapterItem? editing}) async {
    final TextEditingController chapterNumberController =
        TextEditingController(text: editing?.chapterNumber ?? '');
    final TextEditingController titleController =
        TextEditingController(text: editing?.title ?? '');
    bool isPremium = editing?.isPremium ?? false;

    final bool? submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(editing == null ? 'Thêm Chapter' : 'Sửa Chapter'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: chapterNumberController,
                  decoration: const InputDecoration(labelText: 'Số chapter'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Tiêu đề'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isPremium,
                  title: const Text('Chapter premium'),
                  onChanged: (value) {
                    setDialogState(() {
                      isPremium = value;
                    });
                  },
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
      ),
    );

    if (submitted != true) {
      return;
    }

    final String chapterNumber = chapterNumberController.text.trim();
    final String title = titleController.text.trim();

    if (chapterNumber.isEmpty || title.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ thông tin chapter')),
      );
      return;
    }

    if (editing == null) {
      await _createChapter(chapterNumber, title, isPremium);
    } else {
      await _updateChapter(editing.id, chapterNumber, title, isPremium);
    }
  }

  Future<void> _createChapter(
    String chapterNumber,
    String title,
    bool isPremium,
  ) async {
    final int mangaId = widget.manga.id ?? 0;
    if (mangaId <= 0) {
      return;
    }

    try {
      final Map<String, dynamic> headers = await _buildAuthHeaders();
      final FormData data = FormData.fromMap({
        'ChapterNumber': chapterNumber,
        'Title': title,
        'IsPremium': isPremium,
        'MangaId': mangaId,
      });

      await _dio.post<dynamic>(
        '${newAPIBaseURL}Chapter/create-chapter/$mangaId',
        data: data,
        options: Options(headers: headers),
      );

      await _loadChapters();
    } catch (_) {
      _showMessage('Không thể tạo chapter');
    }
  }

  Future<void> _updateChapter(
    int chapterId,
    String chapterNumber,
    String title,
    bool isPremium,
  ) async {
    final int mangaId = widget.manga.id ?? 0;
    if (mangaId <= 0 || chapterId <= 0) {
      return;
    }

    try {
      final Map<String, dynamic> headers = await _buildAuthHeaders();
      final FormData data = FormData.fromMap({
        'ChapterNumber': chapterNumber,
        'Title': title,
        'IsPremium': isPremium,
        'MangaId': mangaId,
      });

      await _dio.put<dynamic>(
        '${newAPIBaseURL}Chapter/update-chapter/$chapterId',
        data: data,
        options: Options(headers: headers),
      );

      await _loadChapters();
    } catch (_) {
      _showMessage('Không thể cập nhật chapter');
    }
  }

  Future<void> _deleteChapter(ChapterItem chapter) async {
    final int mangaId = widget.manga.id ?? 0;
    if (mangaId <= 0 || chapter.id <= 0) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Chapter'),
        content: Text('Xóa chapter ${chapter.chapterNumber} không?'),
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
      await _dio.put<dynamic>(
        '${newAPIBaseURL}Chapter/delete-chapter/$mangaId',
        queryParameters: <String, dynamic>{'idChapter': chapter.id},
        options: Options(headers: headers),
      );

      await _loadChapters();
    } catch (_) {
      _showMessage('Không thể xóa chapter');
    }
  }

  Future<void> _uploadPages() async {
    final int mangaId = widget.manga.id ?? 0;
    final int chapterId = _selectedChapter?.id ?? 0;

    if (mangaId <= 0 || chapterId <= 0) {
      return;
    }

    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final List<PlatformFile> files = List<PlatformFile>.from(result.files)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final FormData formData = FormData();
    for (final PlatformFile file in files) {
      if (file.bytes == null && file.path == null) {
        continue;
      }

      final MultipartFile multipartFile = file.bytes != null
          ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
          : await MultipartFile.fromFile(file.path!, filename: file.name);

      formData.files.add(MapEntry('files', multipartFile));
    }

    if (formData.files.isEmpty) {
      _showMessage('Không có file ảnh hợp lệ');
      return;
    }

    try {
      final Map<String, dynamic> headers = await _buildAuthHeaders();
      await _dio.post<dynamic>(
        '${newAPIBaseURL}Page/add-page/$mangaId/$chapterId',
        data: formData,
        options: Options(headers: headers),
      );

      await _loadPages();
    } catch (_) {
      _showMessage('Không thể upload page');
    }
  }

  Future<void> _deleteSelectedPages() async {
    final int mangaId = widget.manga.id ?? 0;
    final int chapterId = _selectedChapter?.id ?? 0;

    if (mangaId <= 0 || chapterId <= 0 || _selectedPageIds.isEmpty) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa page'),
        content: Text('Xóa ${_selectedPageIds.length} trang đã chọn?'),
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
      final FormData formData = FormData();

      for (final int id in _selectedPageIds) {
        formData.fields.add(MapEntry('pageIds', '$id'));
      }

      await _dio.post<dynamic>(
        '${newAPIBaseURL}Page/delete-page/$mangaId/$chapterId',
        data: formData,
        options: Options(headers: headers),
      );

      await _loadPages();
    } catch (_) {
      _showMessage('Không thể xóa page');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.manga.title ?? 'Manga';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(title: Text('Quản lý Chapter: $title')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final bool isNarrow = constraints.maxWidth < 980;

                  if (isNarrow) {
                    return Column(
                      children: [
                        Expanded(child: _buildChapterPanel()),
                        const SizedBox(height: 16),
                        Expanded(child: _buildPagePanel()),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: _buildChapterPanel()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPagePanel()),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildChapterPanel() {
    return MangaChapterPanel(
      chapters: _chapters,
      selectedChapter: _selectedChapter,
      loading: _loadingChapters,
      onAdd: _showChapterEditor,
      onEdit: (chapter) => _showChapterEditor(editing: chapter),
      onDelete: _deleteChapter,
      onSelect: (chapter) {
        setState(() {
          _selectedChapter = chapter;
        });
        _loadPages();
      },
    );
  }

  Widget _buildPagePanel() {
    return MangaPagePanel(
      selectedChapter: _selectedChapter,
      pages: _pages,
      selectedPageIds: _selectedPageIds,
      loading: _loadingPages,
      onUpload: _uploadPages,
      onDeleteSelected: _deleteSelectedPages,
      onTogglePage: (page) {
        setState(() {
          if (_selectedPageIds.contains(page.id)) {
            _selectedPageIds.remove(page.id);
          } else {
            _selectedPageIds.add(page.id);
          }
        });
      },
    );
  }
}
