import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

class ScreenSecurityService with WidgetsBindingObserver {
  ScreenSecurityService._();

  static final ScreenSecurityService instance = ScreenSecurityService._();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    await _applySecureFlag();
  }

  Future<void> _applySecureFlag() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {
      // Keep app resilient even if secure flag cannot be applied.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applySecureFlag();
    }
  }
}
