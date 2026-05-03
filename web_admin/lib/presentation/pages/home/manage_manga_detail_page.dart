import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:web_admin/core/constants/constants.dart';
import 'package:web_admin/core/utils/auth_token_storage.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/injection_container.dart';

class ManageMangaDetailPage extends StatefulWidget {
  final MangaEntity manga;

  const ManageMangaDetailPage({super.key, required this.manga});

  @override
  State<ManageMangaDetailPage> createState() => _ManageMangaDetailPageState();
}

class _ManageMangaDetailPageState extends State<ManageMangaDetailPage> {
  final Dio _dio = sl<Dio>();
  final AuthTokenStorage _tokenStorage = sl<AuthTokenStorage>();

  final List<_ChapterItem> _chapters = <_ChapterItem>[];
  final List<_PageItem> _pages = <_PageItem>[];
  final Set<int> _selectedPageIds = <int>{};

  bool _loadingChapters = false;
  bool _loadingPages = false;
  String? _errorMessage;
  _ChapterItem? _selectedChapter;

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

      final List<dynamic> rawList = _extractList(response.data);
      final List<_ChapterItem> chapters = rawList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_ChapterItem.fromJson)
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
    } catch (e) {
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

      final List<dynamic> rawList = _extractList(response.data);
      final List<_PageItem> pages = rawList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_PageItem.fromJson)
          .toList();

      setState(() {
        _pages
          ..clear()
          ..addAll(pages);
      });
    } catch (e) {
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

  Future<void> _showChapterEditor({_ChapterItem? editing}) async {
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tạo chapter')),
      );
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể cập nhật chapter')),
      );
    }
  }

  Future<void> _deleteChapter(_ChapterItem chapter) async {
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa chapter')),
      );
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có file ảnh hợp lệ')),
      );
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể upload page')),
      );
    }
  }

  Future<void> _deleteSelectedPages() async {
    final int mangaId = widget.manga.id ?? 0;
    final int chapterId = _selectedChapter?.id ?? 0;

    if (mangaId <= 0 || chapterId <= 0) {
      return;
    }

    if (_selectedPageIds.isEmpty) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa page'),
        content: Text(
          'Xóa ${_selectedPageIds.length} trang đã chọn?',
        ),
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa page')),
      );
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      final dynamic values = data[r'$values'];
      if (values is List) {
        return values;
      }

      final dynamic directData = data['data'];
      if (directData is List) {
        return directData;
      }

      if (directData is Map) {
        final dynamic nestedValues = directData[r'$values'];
        if (nestedValues is List) {
          return nestedValues;
        }
      }

      final dynamic items = data['items'] ?? data['result'];
      if (items is List) {
        return items;
      }

      if (items is Map) {
        final dynamic nestedValues = items[r'$values'];
        if (nestedValues is List) {
          return nestedValues;
        }
      }
    }

    return const <dynamic>[];
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.manga.title ?? 'Manga';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: Text('Quản lý Chapter: $title'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final bool isNarrow = constraints.maxWidth < 980;
                  final List<Widget> sections = [
                    Expanded(child: _buildChapterPanel()),
                    const SizedBox(width: 16, height: 16),
                    Expanded(child: _buildPagePanel()),
                  ];

                  if (isNarrow) {
                    return Column(
                      children: [
                        Expanded(child: _buildChapterPanel()),
                        const SizedBox(height: 16),
                        Expanded(child: _buildPagePanel()),
                      ],
                    );
                  }

                  return Row(children: sections);
                },
              ),
      ),
    );
  }

  Widget _buildChapterPanel() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE3E7F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Danh sách Chapter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D2638),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _loadingChapters ? null : _showChapterEditor,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loadingChapters
                ? const Center(child: CircularProgressIndicator())
                : _chapters.isEmpty
                ? const Center(child: Text('Chưa có chapter'))
                : ListView.builder(
                    itemCount: _chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = _chapters[index];
                      final bool selected = chapter.id == _selectedChapter?.id;

                      return ListTile(
                        selected: selected,
                        title: Text(
                          'Chapter ${chapter.chapterNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(chapter.title),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (chapter.isPremium)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.lock,
                                  size: 16,
                                  color: Color(0xFFEF8354),
                                ),
                              ),
                            IconButton(
                              tooltip: 'Sửa',
                              onPressed: () => _showChapterEditor(editing: chapter),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                            ),
                            IconButton(
                              tooltip: 'Xóa',
                              onPressed: () => _deleteChapter(chapter),
                              icon: const Icon(Icons.delete_outline, size: 18),
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _selectedChapter = chapter;
                          });
                          _loadPages();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagePanel() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE3E7F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedChapter == null
                      ? 'Trang truyện'
                      : 'Trang truyện - Chapter ${_selectedChapter!.chapterNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D2638),
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _selectedChapter == null
                          ? null
                          : _uploadPages,
                      icon: const Icon(Icons.upload_file_outlined, size: 16),
                      label: const Text('Upload'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _selectedPageIds.isEmpty
                          ? null
                          : _deleteSelectedPages,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text('Xóa (${_selectedPageIds.length})'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loadingPages
                ? const Center(child: CircularProgressIndicator())
                : _selectedChapter == null
                ? const Center(child: Text('Chọn chapter để xem trang'))
                : _pages.isEmpty
                ? const Center(child: Text('Chưa có trang nào'))
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      final bool selected = _selectedPageIds.contains(page.id);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedPageIds.remove(page.id);
                            } else {
                              _selectedPageIds.add(page.id);
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF1F5BFF)
                                  : const Color(0xFFE3E7F0),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    page.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) {
                                      return Container(
                                        color: const Color(0xFFE5EAF3),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.broken_image_outlined,
                                          color: Color(0xFF9AA8BE),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFF1F5BFF)
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF1F5BFF)
                                          : const Color(0xFFB8C2D6),
                                    ),
                                  ),
                                  child: selected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#${page.id}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChapterItem {
  final int id;
  final String chapterNumber;
  final String title;
  final bool isPremium;

  const _ChapterItem({
    required this.id,
    required this.chapterNumber,
    required this.title,
    required this.isPremium,
  });

  factory _ChapterItem.fromJson(Map<String, dynamic> map) {
    return _ChapterItem(
      id: _toInt(map['id']) ?? 0,
      chapterNumber: _toString(map['chapterNumber'] ?? map['ChapterNumber']),
      title: _toString(map['title'] ?? map['Title']),
      isPremium: _toBool(map['isPremium'] ?? map['IsPremium']),
    );
  }
}

class _PageItem {
  final int id;
  final String imageUrl;

  const _PageItem({required this.id, required this.imageUrl});

  factory _PageItem.fromJson(Map<String, dynamic> map) {
    return _PageItem(
      id: _toInt(map['id']) ?? 0,
      imageUrl: _toString(map['imageUrl'] ?? map['ImageUrl']),
    );
  }
}

String _toString(dynamic value) {
  return value?.toString() ?? '';
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  if (value is int) {
    return value != 0;
  }
  return false;
}
