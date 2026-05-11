class ChapterItem {
  final int id;
  final String chapterNumber;
  final String title;
  final bool isPremium;

  const ChapterItem({
    required this.id,
    required this.chapterNumber,
    required this.title,
    required this.isPremium,
  });

  factory ChapterItem.fromJson(Map<String, dynamic> map) {
    return ChapterItem(
      id: _toInt(map['id']) ?? 0,
      chapterNumber: _toString(map['chapterNumber'] ?? map['ChapterNumber']),
      title: _toString(map['title'] ?? map['Title']),
      isPremium: _toBool(map['isPremium'] ?? map['IsPremium']),
    );
  }
}

class PageItem {
  final int id;
  final String imageUrl;

  const PageItem({required this.id, required this.imageUrl});

  factory PageItem.fromJson(Map<String, dynamic> map) {
    return PageItem(
      id: _toInt(map['id']) ?? 0,
      imageUrl: _toString(map['imageUrl'] ?? map['ImageUrl']),
    );
  }
}

List<dynamic> extractApiList(dynamic data) {
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
