import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  static const _youtubeScope = 'https://www.googleapis.com/auth/youtube.readonly';

  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', _youtubeScope],
  );

  GoogleSignInAccount? _user;

  bool get isSignedIn => _user != null;
  GoogleSignInAccount? get user => _user;

  AuthService() {
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _user = account;
      notifyListeners();
    });
    // Attempt silent sign-in on startup
    _googleSignIn.signInSilently();
  }

  Future<void> signIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (e) {
      debugPrint('Sign-in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Returns HTTP Authorization headers for YouTube API calls.
  Future<Map<String, String>?> getAuthHeaders() async {
    if (_user == null) return null;
    try {
      return await _user!.authHeaders;
    } catch (e) {
      debugPrint('Auth headers error: $e');
      return null;
    }
  }
}
