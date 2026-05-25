import 'package:flutter/foundation.dart';
import 'package:web_admin/data/data_sources/remote/dashboard_api_service.dart';
import 'package:web_admin/data/models/dashboard_dto.dart';

abstract class DashboardState {
  final DashboardModel? stats;
  final String? errorMessage;

  const DashboardState({this.stats, this.errorMessage});
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardDone extends DashboardState {
  const DashboardDone(DashboardModel stats) : super(stats: stats);
}

class DashboardError extends DashboardState {
  const DashboardError(String errorMessage) : super(errorMessage: errorMessage);
}

class LiveActivity {
  final String message;
  final DateTime timestamp;
  final String type; // 'vip', 'register', 'system', 'compress'

  const LiveActivity({
    required this.message,
    required this.timestamp,
    required this.type,
  });
}

class DashboardController extends ChangeNotifier {
  final DashboardApiService _apiService;

  DashboardController(this._apiService) {
    _initSimulatedActivities();
  }

  DashboardState _state = const DashboardLoading();
  DashboardState get state => _state;

  final List<LiveActivity> _liveActivities = [];
  List<LiveActivity> get liveActivities => List.unmodifiable(_liveActivities);

  void _initSimulatedActivities() {
    final now = DateTime.now();
    _liveActivities.addAll([
      LiveActivity(
        message: 'Hệ thống đã nén và chuyển đổi thành công 15 ảnh bộ "One Piece" sang định dạng WebP.',
        timestamp: now.subtract(const Duration(minutes: 2)),
        type: 'compress',
      ),
      LiveActivity(
        message: 'Độc giả Trần Thị B vừa thanh toán gói VIP Premium 30 ngày.',
        timestamp: now.subtract(const Duration(minutes: 5)),
        type: 'vip',
      ),
      LiveActivity(
        message: 'Người dùng Nguyễn Văn A đã đăng ký tài khoản mới thành công.',
        timestamp: now.subtract(const Duration(minutes: 12)),
        type: 'register',
      ),
      LiveActivity(
        message: 'Hệ thống tự động dọn dẹp bộ nhớ đệm cache và tối ưu hóa PostgreSQL.',
        timestamp: now.subtract(const Duration(minutes: 30)),
        type: 'system',
      ),
      LiveActivity(
        message: 'Độc giả Lê Văn C vừa bình luận tại Chương 45 bộ "Naruto".',
        timestamp: now.subtract(const Duration(hours: 1)),
        type: 'register',
      ),
    ]);
  }

  Future<void> loadDashboardStats() async {
    _state = const DashboardLoading();
    notifyListeners();

    try {
      final stats = await _apiService.getDashboardStats();
      _state = DashboardDone(stats);
      notifyListeners();
    } catch (e) {
      _state = DashboardError(e.toString());
      notifyListeners();
    }
  }

  // Adding simulated realtime updates to WOW the user on interval or manual trigger
  void triggerMockActivity(String message, String type) {
    _liveActivities.insert(
      0,
      LiveActivity(
        message: message,
        timestamp: DateTime.now(),
        type: type,
      ),
    );
    if (_liveActivities.length > 20) {
      _liveActivities.removeLast();
    }
    notifyListeners();
  }
}
