import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

/// Shared [AuthService] instance. Override in main if needed.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Stream of auth state: [User] when signed in, null when signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
