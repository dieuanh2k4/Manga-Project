import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_admin/core/constants/constants.dart';
import 'package:web_admin/core/utils/auth_token_storage.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/injection_container.dart';
import 'package:web_admin/presentation/models/manga_detail_items.dart';
import 'package:web_admin/presentation/controllers/theme_controller.dart';
import 'package:web_admin/presentation/widgets/manga_detail_panels.dart';

class ManageMangaDetailPage extends StatefulWidget {
  final MangaEntity manga;

  const ManageMangaDetailPage({super.key, required this.manga});

  @override
  State<ManageMangaDetailPage> createState() => _ManageMangaDetailPageState();
}

class _ManageMangaDetailPageState extends State<ManageMangaDetailPage>
    with SingleTickerProviderStateMixin {
  final Dio _dio = sl<Dio>();
  final AuthTokenStorage _tokenStorage = sl<AuthTokenStorage>();

  final List<ChapterItem> _chapters = <ChapterItem>[];
  final List<PageItem> _pages = <PageItem>[];
  final Set<int> _selectedPageIds = <int>{};

  bool _loadingChapters = false;
  bool _loadingPages = false;
  String? _errorMessage;
  ChapterItem? _selectedChapter;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChapters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChapters() async {
    final int mangaId = widget.manga.id ?? 0;
    if (mangaId <= 0) {
      setState(() => _errorMessage = 'Manga không hợp lệ');
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
      setState(() => _errorMessage = 'Không thể tải danh sách chapter');
    } finally {
      if (mounted) setState(() => _loadingChapters = false);
    }
  }

  Future<void> _loadPages() async {
    final int mangaId = widget.manga.id ?? 0;
    final int chapterId = _selectedChapter?.id ?? 0;
    if (mangaId <= 0 || chapterId <= 0) return;

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
      setState(() => _pages.clear());
    } finally {
      if (mounted) setState(() => _loadingPages = false);
    }
  }

  Future<Map<String, dynamic>> _buildAuthHeaders() async {
    final String? token = await _tokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) return <String, dynamic>{};
    return <String, dynamic>{
      'Authorization': _tokenStorage.formatBearerValue(token),
    };
  }

  Future<void> _showChapterEditor({ChapterItem? editing}) async {
    final TextEditingController chapterNumberController = TextEditingController(
      text: editing?.chapterNumber ?? '',
    );
    final TextEditingController titleController = TextEditingController(
      text: editing?.title ?? '',
    );
    bool isPremium = editing?.isPremium ?? false;

    final bool? submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        editing == null
                            ? Icons.add_circle_outline
                            : Icons.edit_outlined,
                        color: const Color(0xFF1F5BFF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      editing == null
                          ? 'Thêm Chapter mới'
                          : 'Chỉnh sửa Chapter',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D2638),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: chapterNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Số chapter',
                    hintText: 'VD: 1, 2, 3...',
                    prefixIcon: const Icon(Icons.format_list_numbered),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFF),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Tiêu đề chapter',
                    hintText: 'VD: Khởi đầu mới...',
                    prefixIcon: const Icon(Icons.title_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFF),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: isPremium
                        ? const Color(0xFFFFF7ED)
                        : const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPremium
                          ? const Color(0xFFD97706)
                          : const Color(0xFFE4E8F2),
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    value: isPremium,
                    title: Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: isPremium
                              ? const Color(0xFFD97706)
                              : const Color(0xFF8491A7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chapter Premium',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isPremium
                                ? const Color(0xFFD97706)
                                : const Color(0xFF4E5A6F),
                          ),
                        ),
                      ],
                    ),
                    onChanged: (value) =>
                        setDialogState(() => isPremium = value),
                    activeThumbColor: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: Icon(
                        editing == null ? Icons.add : Icons.save_outlined,
                        size: 16,
                      ),
                      label: Text(editing == null ? 'Thêm' : 'Lưu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F5BFF),
                        foregroundColor: Colors.white,
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
        ),
      ),
    );

    if (submitted != true) return;

    final String chapterNumber = chapterNumberController.text.trim();
    final String title = titleController.text.trim();

    if (chapterNumber.isEmpty || title.isEmpty) {
      if (!mounted) return;
      _showMessage('Vui lòng nhập đủ thông tin chapter', isError: true);
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
    if (mangaId <= 0) return;

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

      _showMessage('Thêm chapter thành công');
      await _loadChapters();
    } catch (_) {
      _showMessage('Không thể tạo chapter', isError: true);
    }
  }

  Future<void> _updateChapter(
    int chapterId,
    String chapterNumber,
    String title,
    bool isPremium,
  ) async {
    final int mangaId = widget.manga.id ?? 0;
    if (mangaId <= 0 || chapterId <= 0) return;

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

      _showMessage('Cập nhật chapter thành công');
      await _loadChapters();
    } catch (_) {
      _showMessage('Không thể cập nhật chapter', isError: true);
    }
  }

  Future<void> _deleteChapter(ChapterItem chapter) async {
    final int mangaId = widget.manga.id ?? 0;
    if (mangaId <= 0 || chapter.id <= 0) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xóa Chapter',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Xóa chapter ${chapter.chapterNumber}: "${chapter.title}"?\nTất cả trang trong chapter này cũng sẽ bị xóa.',
          style: const TextStyle(height: 1.5, color: Color(0xFF4E5A6F)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Xóa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD93025),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final Map<String, dynamic> headers = await _buildAuthHeaders();
      await _dio.put<dynamic>(
        '${newAPIBaseURL}Chapter/delete-chapter/$mangaId',
        queryParameters: <String, dynamic>{'idChapter': chapter.id},
        options: Options(headers: headers),
      );
      _showMessage('Xóa chapter thành công');
      await _loadChapters();
    } catch (_) {
      _showMessage('Không thể xóa chapter', isError: true);
    }
  }

  Future<void> _uploadPages() async {
    final int mangaId = widget.manga.id ?? 0;
    final int chapterId = _selectedChapter?.id ?? 0;
    if (mangaId <= 0 || chapterId <= 0) return;

    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final List<PlatformFile> files = List<PlatformFile>.from(result.files)
      ..sort((a, b) => _compareFileNamesNaturally(a.name, b.name));

    final FormData formData = FormData();
    for (final PlatformFile file in files) {
      if (kIsWeb) {
        if (file.bytes == null) continue;
        final MultipartFile multipartFile = MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        );
        formData.files.add(MapEntry('files', multipartFile));
      } else {
        if (file.bytes == null && file.path == null) continue;
        final MultipartFile multipartFile = file.bytes != null
            ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
            : await MultipartFile.fromFile(file.path!, filename: file.name);
        formData.files.add(MapEntry('files', multipartFile));
      }
    }

    if (formData.files.isEmpty) {
      _showMessage('Không có file ảnh hợp lệ', isError: true);
      return;
    }

    try {
      final Map<String, dynamic> headers = await _buildAuthHeaders();
      await _dio.post<dynamic>(
        '${newAPIBaseURL}Page/add-page/$mangaId/$chapterId',
        data: formData,
        options: Options(headers: headers),
      );
      _showMessage('Upload ${formData.files.length} ảnh thành công');
      await _loadPages();
    } catch (_) {
      _showMessage('Không thể upload page', isError: true);
    }
  }

  Future<void> _deleteSelectedPages() async {
    final int mangaId = widget.manga.id ?? 0;
    final int chapterId = _selectedChapter?.id ?? 0;
    if (mangaId <= 0 || chapterId <= 0 || _selectedPageIds.isEmpty) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xóa trang',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Xóa ${_selectedPageIds.length} trang đã chọn?',
          style: const TextStyle(color: Color(0xFF4E5A6F)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Xóa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD93025),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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
      _showMessage('Xóa trang thành công');
      await _loadPages();
    } catch (_) {
      _showMessage('Không thể xóa page', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFD93025)
            : const Color(0xFF1A7C40),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  int _compareFileNamesNaturally(String left, String right) {
    final List<String> leftParts = _fileNameSortParts(left);
    final List<String> rightParts = _fileNameSortParts(right);
    final int maxLength = leftParts.length > rightParts.length
        ? leftParts.length
        : rightParts.length;

    for (int index = 0; index < maxLength; index++) {
      if (index >= leftParts.length) {
        return -1;
      }
      if (index >= rightParts.length) {
        return 1;
      }

      final String leftPart = leftParts[index];
      final String rightPart = rightParts[index];
      final int? leftNumber = int.tryParse(leftPart);
      final int? rightNumber = int.tryParse(rightPart);

      if (leftNumber != null && rightNumber != null) {
        final int numberCompare = leftNumber.compareTo(rightNumber);
        if (numberCompare != 0) {
          return numberCompare;
        }
      } else {
        final int textCompare = leftPart.compareTo(rightPart);
        if (textCompare != 0) {
          return textCompare;
        }
      }
    }

    return left.toLowerCase().compareTo(right.toLowerCase());
  }

  List<String> _fileNameSortParts(String fileName) {
    final String normalized = fileName.toLowerCase();
    return RegExp(
      r'\d+|\D+',
    ).allMatches(normalized).map((match) => match.group(0)!).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = sl<ThemeController>();
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final isDark = themeController.isDarkMode;
        final String title = widget.manga.title ?? 'Manga';
        final String? thumbnail = widget.manga.thumbnail;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFDFE3ED),
          appBar: _buildAppBar(title, thumbnail),
          body: _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Color(0xFFD93025),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFF8491A7)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadChapters,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
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
                          SizedBox(width: 360, child: _buildChapterPanel()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildPagePanel()),
                        ],
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(String title, String? thumbnail) {
    final isDark = sl<ThemeController>().isDarkMode;
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF0E1326) : Colors.white,
      foregroundColor: isDark ? Colors.white : const Color(0xFF1D2638),
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: isDark ? Colors.white70 : const Color(0xFF1D2638),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          if (thumbnail != null && thumbnail.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                thumbnail,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, _, _) => SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: isDark ? Colors.white54 : const Color(0xFF8491A7),
                    size: 20,
                  ),
                ),
              ),
            )
          else
            Icon(
              Icons.menu_book_rounded,
              color: isDark ? Colors.white54 : const Color(0xFF8491A7),
              size: 22,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1D2638),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_chapters.length} chapter · ${_pages.length} trang',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF9BB2D4) : const Color(0xFF7B879B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh_rounded,
            color: isDark ? Colors.white70 : const Color(0xFF1D2638),
          ),
          tooltip: 'Tải lại',
          onPressed: _loadChapters,
        ),
        const SizedBox(width: 8),
      ],
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
        setState(() => _selectedChapter = chapter);
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
