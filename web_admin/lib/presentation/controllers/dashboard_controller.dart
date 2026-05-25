import 'dart:async';
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

class DashboardController extends ChangeNotifier {
  final DashboardApiService _apiService;

  DashboardController(this._apiService);

  DashboardState _state = const DashboardLoading();
  DashboardState get state => _state;

  // Real activities from backend
  final List<RecentActivityModel> _recentActivities = [];
  List<RecentActivityModel> get recentActivities =>
      List.unmodifiable(_recentActivities);

  bool _activitiesLoading = false;
  bool get activitiesLoading => _activitiesLoading;

  Timer? _activityPollingTimer;

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

  /// Load recent activities from real backend data.
  /// Combines VIP purchases + new registrations, sorted by timestamp.
  Future<void> loadRecentActivities() async {
    _activitiesLoading = true;
    notifyListeners();

    try {
      final activities = await _apiService.getRecentActivities(limit: 20);
      _recentActivities
        ..clear()
        ..addAll(activities);
    } catch (_) {
      // Silently fail - keep previous activities if any
    } finally {
      _activitiesLoading = false;
      notifyListeners();
    }
  }

  /// Start auto-polling every [intervalSeconds] seconds.
  void startActivityPolling({int intervalSeconds = 60}) {
    _activityPollingTimer?.cancel();
    _activityPollingTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => loadRecentActivities(),
    );
  }

  void stopActivityPolling() {
    _activityPollingTimer?.cancel();
    _activityPollingTimer = null;
  }

  @override
  void dispose() {
    stopActivityPolling();
    super.dispose();
  }
}
