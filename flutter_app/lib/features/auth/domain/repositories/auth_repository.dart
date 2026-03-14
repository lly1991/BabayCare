import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> login(String username, String password);
  Future<AppUser> register(String username, String password);
  Future<AppUser?> getById(int userId);
}
