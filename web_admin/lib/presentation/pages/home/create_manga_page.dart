import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:web_admin/core/models/upload_file_data.dart';
import 'package:web_admin/domain/entities/author.dart';
import 'package:web_admin/domain/entities/genre.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/presentation/pages/home/create_manga_submit_result.dart';

class CreateMangaPage extends StatefulWidget {
  final List<AuthorEntity> authors;
  final List<GenreEntity> genres;

  const CreateMangaPage({
    super.key,
    required this.authors,
    required this.genres,
  });

  @override
  State<CreateMangaPage> createState() => _CreateMangaPageState();
}

class _CreateMangaPageState extends State<CreateMangaPage> {
  static const List<String> _statusOptions = <String>[
    'Đang tiến hành',
    'Hoàn thành',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _thumbnailController;
  late final TextEditingController _totalChapterController;
  late final TextEditingController _rateController;

  late DateTime _releaseDate;
  late DateTime _endDate;
  late String _status;
  int? _authorId;
  late final Set<int> _selectedGenreIds;
  UploadFileData? _thumbnailFile;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _thumbnailController = TextEditingController();
    _totalChapterController = TextEditingController(text: '0');
    _rateController = TextEditingController(text: '0');

    final DateTime now = DateTime.now();
    _releaseDate = DateTime(now.year, now.month, now.day);
    _endDate = _releaseDate;
    _status = _statusOptions.first;
    _authorId = _resolveAuthorId();
    _selectedGenreIds = <int>{};
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _thumbnailController.dispose();
    _totalChapterController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  int? _resolveAuthorId() {
    for (final AuthorEntity author in widget.authors) {
      final int? id = author.id;
      if (id != null && id > 0) {
        return id;
      }
    }
    return null;
  }

  String? _requiredTextValidator(String? value, String label) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) {
      return '$label không được để trống';
    }
    return null;
  }

  Future<void> _pickReleaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _releaseDate = DateTime(picked.year, picked.month, picked.day);
      if (_endDate.isBefore(_releaseDate)) {
        _endDate = _releaseDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_releaseDate) ? _releaseDate : _endDate,
      firstDate: _releaseDate,
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _endDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickThumbnailFromDevice() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final PlatformFile picked = result.files.single;
    final UploadFileData file = UploadFileData(
      fileName: picked.name,
      bytes: picked.bytes,
      filePath: picked.path,
    );

    if (!file.isValid) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đọc file ảnh đã chọn')),
      );
      return;
    }

    setState(() {
      _thumbnailFile = file;
    });
  }

  void _clearSelectedThumbnail() {
    setState(() {
      _thumbnailFile = null;
    });
  }

  Widget _buildThumbnailPreview() {
    if (_thumbnailFile != null && _thumbnailFile!.hasBytes) {
      return Image.memory(_thumbnailFile!.bytes!, fit: BoxFit.cover);
    }

    return Container(
      color: const Color(0xFFE5EAF3),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Color(0xFF9AA8BE)),
    );
  }

  void _submit() {
    final bool isFormValid = _formKey.currentState?.validate() ?? false;

    if (!isFormValid) {
      return;
    }

    if (_authorId == null || _authorId! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn tác giả hợp lệ')),
      );
      return;
    }

    if (_selectedGenreIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 thể loại')),
      );
      return;
    }

    final bool hasSelectedThumbnail = _thumbnailFile?.isValid ?? false;

    if (!hasSelectedThumbnail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có ảnh thumbnail, sẽ để trống')),
      );
    }

    final MangaEntity created = MangaEntity(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      thumbnail: _thumbnailController.text.trim(),
      status: _status.trim(),
      totalChapter: 0,
      rate: 0,
      authorId: _authorId,
      genreIds: _selectedGenreIds.toList()..sort(),
      releaseDate: _releaseDate,
      endDate: _endDate,
    );

    Navigator.of(context).pop(
      CreateMangaSubmitResult(manga: created, thumbnailFile: _thumbnailFile),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<int>> authorItems = widget.authors
        .where((author) => (author.id ?? 0) > 0)
        .map((author) {
          final int id = author.id!;
          final String label = (author.fullName ?? '').trim().isEmpty
              ? 'Tác giả #$id'
              : author.fullName!.trim();

          return DropdownMenuItem<int>(value: id, child: Text(label));
        })
        .toList();

    if (authorItems.isEmpty && _authorId != null) {
      authorItems.add(
        DropdownMenuItem<int>(
          value: _authorId,
          child: Text('Tác giả #$_authorId'),
        ),
      );
    }

    final List<GenreEntity> validGenres = widget.genres
        .where((genre) => (genre.id ?? 0) > 0)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Tạo Manga mới'),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE3E7F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin cơ bản',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D2638),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Tên truyện',
                        ),
                        validator: (value) =>
                            _requiredTextValidator(value, 'Tên truyện'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(labelText: 'Mô tả'),
                        validator: (value) =>
                            _requiredTextValidator(value, 'Mô tả'),
                      ),
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Thumbnail',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D2638),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: _buildThumbnailPreview(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _pickThumbnailFromDevice,
                                  icon: const Icon(Icons.upload_file_outlined),
                                  label: const Text('Tải ảnh từ thiết bị'),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _thumbnailFile?.fileName ??
                                      'Chưa có thumbnail',
                                  style: const TextStyle(
                                    color: Color(0xFF607089),
                                    fontSize: 12,
                                  ),
                                ),
                                if (_thumbnailFile != null)
                                  TextButton(
                                    onPressed: _clearSelectedThumbnail,
                                    child: const Text('Bỏ ảnh đã chọn'),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final bool isCompact = constraints.maxWidth < 700;

                          final Widget statusField =
                              DropdownButtonFormField<String>(
                                value: _status,
                                decoration: const InputDecoration(
                                  labelText: 'Trạng thái',
                                ),
                                items: _statusOptions
                                    .map(
                                      (status) => DropdownMenuItem<String>(
                                        value: status,
                                        child: Text(status),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() {
                                    _status = value;
                                  });
                                },
                              );

                          final Widget totalChapterField = TextFormField(
                            controller: _totalChapterController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Số chương',
                            ),
                            readOnly: true,
                          );

                          final Widget rateField = TextFormField(
                            controller: _rateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Đánh giá',
                            ),
                            readOnly: true,
                          );

                          if (isCompact) {
                            return Column(
                              children: [
                                statusField,
                                const SizedBox(height: 12),
                                totalChapterField,
                                const SizedBox(height: 12),
                                rateField,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: statusField),
                              const SizedBox(width: 12),
                              Expanded(child: totalChapterField),
                              const SizedBox(width: 12),
                              Expanded(child: rateField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _authorId,
                        decoration: const InputDecoration(labelText: 'Tác giả'),
                        items: authorItems,
                        onChanged: (value) {
                          setState(() {
                            _authorId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value <= 0) {
                            return 'Vui lòng chọn tác giả';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Thể loại',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D2638),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (validGenres.isEmpty)
                        const Text(
                          'Không có dữ liệu thể loại để chọn.',
                          style: TextStyle(color: Color(0xFF7B879B)),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: validGenres.map((genre) {
                            final int genreId = genre.id!;
                            final String label =
                                (genre.name ?? '').trim().isEmpty
                                ? 'Thể loại #$genreId'
                                : genre.name!.trim();
                            final bool selected = _selectedGenreIds.contains(
                              genreId,
                            );

                            return FilterChip(
                              label: Text(label),
                              selected: selected,
                              onSelected: (value) {
                                setState(() {
                                  if (value) {
                                    _selectedGenreIds.add(genreId);
                                  } else {
                                    _selectedGenreIds.remove(genreId);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickReleaseDate,
                              icon: const Icon(Icons.date_range_outlined),
                              label: Text(
                                'Ngày phát hành: ${_dateFormat.format(_releaseDate)}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickEndDate,
                              icon: const Icon(Icons.event_available_outlined),
                              label: Text(
                                'Ngày kết thúc: ${_dateFormat.format(_endDate)}',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Hủy'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Tạo manga'),
                          ),
                        ],
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
  }
}
