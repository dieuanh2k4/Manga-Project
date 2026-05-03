import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:screen_protector/screen_protector.dart';

class ScreenSecurityService with WidgetsBindingObserver {
  ScreenSecurityService._();

  static final ScreenSecurityService instance = ScreenSecurityService._();

  bool _isInitialized = false;

  Future<void> _applySecureFlag() async {
    if (kIsWeb) {
      return;
    } // nếu app chạy trên web thì bỏ qua

    try {
      switch (defaultTargetPlatform) {
        // nếu trên androi
        case TargetPlatform.android:
          await ScreenProtector.protectDataLeakageOn();
          // bật FLAG_SECURE cho window, khi bật flag này, Android sẽ chặn screenshot,
          // screen recording, thường cả preview app trong recent apps.
          break;
        // nếu trên ios
        case TargetPlatform.iOS:
          await ScreenProtector.preventScreenshotOn();
          // bật cơ chế chống/che nội dung khi người dùng chụp màn hình hoặc khi app bị đưa vào trạng thái có nguy cơ lộ nội dung
          break;
        default:
          return;
      }
    } catch (_) {
      // Đảm bảo ứng dụng hoạt động ổn định ngay cả khi không thể áp dụng cờ bảo mật.
    }
  }

  // Nó đảm bảo service chỉ khởi tạo một lần
  // sau đó đăng ký observer để nghe vòng đời app, rồi bật bảo vệ màn hình lần đầu.
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    await _applySecureFlag();
  }

  // Khi app quay lại foreground (resumed), code bật lại cơ chế bảo vệ
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applySecureFlag();
    }
  }
}
