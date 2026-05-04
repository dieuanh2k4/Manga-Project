import 'package:flutter/material.dart';
import 'package:web_admin/config/theme/app_themes.dart';
import 'package:web_admin/presentation/controllers/auth_controller.dart';
import 'package:web_admin/presentation/controllers/remote_manga_controller.dart';
import 'package:web_admin/presentation/pages/auth/login_page.dart';
import 'package:web_admin/presentation/pages/home/manage_manga.dart';
import 'package:web_admin/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initilizeDependencies();
  runApp(const WebAdmin());
}

class WebAdmin extends StatelessWidget {
  const WebAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthController _authController;
  RemoteMangaController? _mangaController;

  @override
  void initState() {
    super.initState();
    _authController = sl<AuthController>();
    _authController.addListener(_onAuthChanged);
    // _authController.initialize();
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChanged);
    _mangaController?.dispose();
    _authController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!_authController.isAuthenticated) {
      _disposeMangaController();
    }

    if (mounted) {
      setState(() {});
    }
  }

  RemoteMangaController _ensureMangaController() {
    return _mangaController ??= sl<RemoteMangaController>()..loadManga();
  }

  void _disposeMangaController() {
    _mangaController?.dispose();
    _mangaController = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_authController.status == AuthStatus.initial) {
      return const Scaffold(
        backgroundColor: Color(0xFF2F3034),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_authController.isAuthenticated) {
      return LoginPage(
        authController: _authController,
        onLoginSuccess: () {
          setState(() {});
        },
      );
    }

    return ManageManga(
      mangaController: _ensureMangaController(),
      onLogout: () async {
        await _authController.logout();
      },
    );
  }
}
