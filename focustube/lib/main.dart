import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'services/auth_service.dart';
import 'services/youtube_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FocusTubeApp());
}

class FocusTubeApp extends StatelessWidget {
  const FocusTubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      builder: (context, _) => ProxyProvider<AuthService, YouTubeService>(
        update: (_, auth, __) => YouTubeService(auth),
        child: MaterialApp(
          title: 'FocusTube',
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          home: const _RootPage(),
        ),
      ),
    );
  }
}

/// Watches auth state and shows either the login screen or the home screen.
class _RootPage extends StatelessWidget {
  const _RootPage();

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.watch<AuthService>().isSignedIn;
    return isSignedIn ? const HomeScreen() : const LoginScreen();
  }
}
