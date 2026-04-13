class JsonListParser {
  const JsonListParser._();

  static List<dynamic> extractList(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is List) {
        return data['data'];
      }

      if (data['data'] is Map<String, dynamic> &&
          data['data'][r'$values'] is List) {
        return data['data'][r'$values'];
      }

      if (data[r'$values'] is List) {
        return data[r'$values'];
      }
    }

    if (data is List) {
      return data;
    }

    return const [];
  }
}
