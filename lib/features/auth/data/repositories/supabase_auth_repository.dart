import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mycamp_app/features/auth/domain/models/user.dart' as app;
import 'package:mycamp_app/features/auth/domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// A separate client using the service_role key for admin API calls.
  static SupabaseClient? _adminClient;
  SupabaseClient get _admin {
    _adminClient ??= SupabaseClient(
      dotenv.env['SUPABASE_URL']!,
      dotenv.env['SUPABASE_SERVICE_ROLE_KEY']!,
    );
    return _adminClient!;
  }

  @override
  Future<app.User?> login(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final supabaseUser = response.user;
      if (supabaseUser == null) return null;

      return _toAppUser(supabaseUser);
    } on AuthException catch (e) {
      debugPrint('Login failed: ${e.message}');
      return null;
    }
  }

  @override
  Future<app.User?> getCurrentUser() async {
    final supabaseUser = _client.auth.currentUser;
    if (supabaseUser == null) return null;
    return _toAppUser(supabaseUser);
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  /// Login with Google using Supabase OAuth.
  Future<app.User?> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google sign in cancelled by user.');
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        debugPrint('Failed to obtain Google tokens.');
        return null;
      }

      debugPrint('Attempting Supabase Google sign-in...');
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final supabaseUser = response.user;
      if (supabaseUser == null) {
        debugPrint('Supabase returned no user');
        return null;
      }

      debugPrint('Google login successful: ${supabaseUser.email}');
      return _toAppUser(supabaseUser);
    } on AuthException catch (e) {
      debugPrint('Google login failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Google login error: $e');
      return null;
    }
  }

  @override
  Future<app.User?> signUp(
    String email,
    String password, {
    String role = 'student',
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'role': role, 'must_change_password': true},
      );

      final supabaseUser = response.user;
      if (supabaseUser == null) return null;

      return _toAppUser(supabaseUser);
    } on AuthException catch (e) {
      debugPrint('Sign up failed: ${e.message}');
      return null;
    }
  }

  /// Creates a user via the admin API with a temporary password.
  /// The user will be forced to change their password on first login.
  Future<app.User?> createUser(
    String email,
    String password, {
    String role = 'student',
    String? name,
    String? phone,
    String? year,
    String? branch,
  }) async {
    try {
      final metadata = <String, dynamic>{
        'role': role,
        'must_change_password': true,
      };
      if (name != null && name.isNotEmpty) metadata['name'] = name;
      if (phone != null && phone.isNotEmpty) metadata['phone'] = phone;
      if (year != null && year.isNotEmpty) metadata['year'] = year;
      if (branch != null && branch.isNotEmpty) metadata['branch'] = branch;

      final response = await _admin.auth.admin.createUser(
        AdminUserAttributes(
          email: email.trim(),
          password: password,
          emailConfirm: true,
          userMetadata: metadata,
        ),
      );

      final user = response.user;
      if (user == null) return null;

      return _toAppUser(user);
    } on AuthException catch (e) {
      debugPrint('Create user failed: ${e.message}');
      return null;
    }
  }

  /// Whether the current user must change their password (first login).
  bool get mustChangePassword {
    final metadata = _client.auth.currentUser?.userMetadata;
    return metadata?['must_change_password'] == true;
  }

  /// Updates the current user's password and clears the must_change_password flag.
  Future<bool> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(
          password: newPassword,
          data: {'must_change_password': false},
        ),
      );
      return true;
    } on AuthException catch (e) {
      debugPrint('Password update failed: ${e.message}');
      return false;
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    // Requires admin/service_role privileges via Supabase Edge Function or
    // direct admin API. For now we call the admin endpoint.
    await _admin.auth.admin.deleteUser(userId);
  }

  @override
  Future<List<app.User>> listUsers() async {
    try {
      final response = await _admin.auth.admin.listUsers();
      return response
          .map((u) => _toAppUser(u))
          .toList();
    } catch (e) {
      debugPrint('List users failed: $e');
      return [];
    }
  }

  /// Sends a password reset email to the specified email address.
  /// Returns true if the email was sent successfully.
  Future<bool> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'io.supabase.flutter://reset-callback/',
      );
      return true;
    } on AuthException catch (e) {
      debugPrint('Password reset failed: ${e.message}');
      return false;
    }
  }

  /// Maps a Supabase [User] to the app's domain [app.User].
  app.User _toAppUser(User supabaseUser) {
    final metadata = supabaseUser.userMetadata ?? {};
    final role = (metadata['role'] as String?) ?? 'student';

    return app.User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      role: role,
      name: metadata['name'] as String?,
      phone: metadata['phone'] as String?,
      year: metadata['year'] as String?,
      branch: metadata['branch'] as String?,
    );
  }
}
