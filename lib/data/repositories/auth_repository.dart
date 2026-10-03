import '../../domain/entities/user_profile.dart';

abstract class AuthRepository {
  // [MICROSERVICE_INTEGRATION_POINT]: AuthService - POST /api/v1/auth/login
  Future<UserProfile?> loginWithCredentials(String username, String password);

  // [MICROSERVICE_INTEGRATION_POINT]: AuthService - POST /api/v1/auth/demo-switch
  Future<UserProfile> selectDemoProfile(String profileId);

  // [MICROSERVICE_INTEGRATION_POINT]: AuthService - GET /api/v1/auth/demo-accounts
  Future<List<DemoAccount>> getDemoAccounts();

  // [MICROSERVICE_INTEGRATION_POINT]: AuthService - POST /api/v1/auth/logout
  Future<void> logout();

  Future<UserProfile?> getCurrentUser();
}
