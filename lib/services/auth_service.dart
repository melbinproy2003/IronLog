import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Handles Firebase Authentication. All auth logic lives here; UI only calls these methods.
class AuthService {
  AuthService()
      : _auth = FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Current user if signed in, null otherwise.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes (sign in / sign out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signUp(String email, String password) async {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in with email and password.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signIn(String email, String password) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out. No-op if not signed in.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Sign in with Google.
  /// Returns null if user cancels the sign-in flow.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null;
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }
}
