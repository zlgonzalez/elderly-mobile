import '../../domain/entities/user_profile.dart';

class CaregiverSignUpInitiationResult {
  final String email;
  final String finalizationLink;
  final int expiresInSeconds;
  final String message;

  const CaregiverSignUpInitiationResult({
    required this.email,
    required this.finalizationLink,
    required this.expiresInSeconds,
    required this.message,
  });

  factory CaregiverSignUpInitiationResult.fromJson(Map<String, dynamic> json) {
    return CaregiverSignUpInitiationResult(
      email: json['email']?.toString() ?? '',
      finalizationLink: json['finalization_link']?.toString() ?? '',
      expiresInSeconds: (json['expires_in_seconds'] as num?)?.toInt() ?? 900,
      message: json['message']?.toString() ?? 'Verification email sent',
    );
  }
}

abstract class AuthRepository {
  // [MICROSERVICE_INTEGRATION_POINT]: AuthService - POST /api/v1/auth/login
  Future<UserProfile?> loginWithCredentials(String username, String password);

  // [MICROSERVICE_INTEGRATION_POINT]: AuthService - POST /api/v1/auth/onboarding/initiate
  Future<CaregiverSignUpInitiationResult> initiateCaregiverSignUp(String email);

  // [MICROSERVICE_INTEGRATION_POINT]: AuthService - POST /api/v1/auth/onboarding/resend
  Future<CaregiverSignUpInitiationResult> resendCaregiverSignUpCode(String email);

  // [MICROSERVICE_INTEGRATION_POINT]: AuthService - POST /api/v1/auth/onboarding/finalize
  Future<UserProfile> finalizeCaregiverSignUp({
    required String email,
    required String code,
    required String username,
    required String password,
  });

  // [MICROSERVICE_INTEGRATION_POINT]: AuthService - POST /api/v1/auth/demo-switch
  Future<UserProfile> selectDemoProfile(String profileId);

  // [MICROSERVICE_INTEGRATION_POINT]: AuthService - GET /api/v1/auth/demo-accounts
  Future<List<DemoAccount>> getDemoAccounts();

  // [MICROSERVICE_INTEGRATION_POINT]: AuthService - POST /api/v1/auth/logout
  Future<void> logout();

  Future<UserProfile?> getCurrentUser();
}
