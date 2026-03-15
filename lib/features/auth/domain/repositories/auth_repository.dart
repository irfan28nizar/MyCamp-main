import 'package:mycamp_app/features/auth/domain/models/user.dart';

abstract class AuthRepository {
  Future<User?> login(String email, String password);

  Future<User?> getCurrentUser();

  Future<void> logout();

  Future<User?> signUp(String email, String password, {String role = 'student'});

  Future<void> deleteUser(String userId);

  Future<List<User>> listUsers();
}
