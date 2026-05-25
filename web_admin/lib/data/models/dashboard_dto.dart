class DashboardModel {
  final double totalRevenue;
  final int activeReadersCount;
  final int totalViews;
  final double vipConversionRate;
  final List<RevenuePointModel> revenueHistory;
  final List<GenreViewsModel> genreShare;
  final List<MangaRankModel> topManga;

  const DashboardModel({
    required this.totalRevenue,
    required this.activeReadersCount,
    required this.totalViews,
    required this.vipConversionRate,
    required this.revenueHistory,
    required this.genreShare,
    required this.topManga,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> map) {
    return DashboardModel(
      totalRevenue: _toDouble(map['totalRevenue'] ?? map['TotalRevenue']),
      activeReadersCount: _toInt(map['activeReadersCount'] ?? map['ActiveReadersCount']),
      totalViews: _toInt(map['totalViews'] ?? map['TotalViews']),
      vipConversionRate: _toDouble(map['vipConversionRate'] ?? map['VipConversionRate']),
      revenueHistory: _toList(map['revenueHistory'] ?? map['RevenueHistory'])
          .map((item) => RevenuePointModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      genreShare: _toList(map['genreShare'] ?? map['GenreShare'])
          .map((item) => GenreViewsModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      topManga: _toList(map['topManga'] ?? map['TopManga'])
          .map((item) => MangaRankModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static List<dynamic> _toList(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value;
    if (value is Map && value[r'$values'] is List) {
      return value[r'$values'];
    }
    return const [];
  }
}

class RevenuePointModel {
  final String date;
  final double revenue;
  final int vipSignups;

  const RevenuePointModel({
    required this.date,
    required this.revenue,
    required this.vipSignups,
  });

  factory RevenuePointModel.fromJson(Map<String, dynamic> map) {
    return RevenuePointModel(
      date: map['date']?.toString() ?? map['Date']?.toString() ?? '',
      revenue: DashboardModel._toDouble(map['revenue'] ?? map['Revenue']),
      vipSignups: DashboardModel._toInt(map['vipSignups'] ?? map['VipSignups']),
    );
  }
}

class GenreViewsModel {
  final String genreName;
  final int viewsCount;

  const GenreViewsModel({
    required this.genreName,
    required this.viewsCount,
  });

  factory GenreViewsModel.fromJson(Map<String, dynamic> map) {
    return GenreViewsModel(
      genreName: map['genreName']?.toString() ?? map['GenreName']?.toString() ?? '',
      viewsCount: DashboardModel._toInt(map['viewsCount'] ?? map['ViewsCount']),
    );
  }
}

class MangaRankModel {
  final int mangaId;
  final String title;
  final String authorName;
  final String thumbnail;
  final int views;
  final double rating;
  final double score;
  final double estimatedRevenue;

  const MangaRankModel({
    required this.mangaId,
    required this.title,
    required this.authorName,
    required this.thumbnail,
    required this.views,
    required this.rating,
    required this.score,
    required this.estimatedRevenue,
  });

  factory MangaRankModel.fromJson(Map<String, dynamic> map) {
    return MangaRankModel(
      mangaId: DashboardModel._toInt(map['mangaId'] ?? map['MangaId']),
      title: map['title']?.toString() ?? map['Title']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? map['AuthorName']?.toString() ?? '',
      thumbnail: map['thumbnail']?.toString() ?? map['Thumbnail']?.toString() ?? '',
      views: DashboardModel._toInt(map['views'] ?? map['Views']),
      rating: DashboardModel._toDouble(map['rating'] ?? map['Rating']),
      score: DashboardModel._toDouble(map['score'] ?? map['Score']),
      estimatedRevenue: DashboardModel._toDouble(map['estimatedRevenue'] ?? map['EstimatedRevenue']),
    );
  }
}
