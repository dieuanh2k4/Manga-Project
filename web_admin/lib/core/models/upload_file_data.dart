import 'dart:typed_data';

class UploadFileData {
  final String fileName;
  final Uint8List? bytes;
  final String? filePath;

  const UploadFileData({required this.fileName, this.bytes, this.filePath});

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;

  bool get hasPath => filePath != null && filePath!.trim().isNotEmpty;

  bool get isValid => hasBytes || hasPath;
}
