import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/user_profile.dart';
import 'auth_repository.dart';
import 'mock_auth_repository.dart';

class HttpAuthRepository implements AuthRepository {
  final ApiClient _apiClient;
  final MockAuthRepository _mockFallback = MockAuthRepository();
  UserProfile? _currentUser;
  List<DemoAccount>? _cachedDemoAccounts;

  HttpAuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<DemoAccount>> getDemoAccounts() async {
    try {
      final res = await _apiClient.get('/auth/demo-accounts');
      if (res is List && res.isNotEmpty) {
        final accounts = res
            .map((item) {
              final acc = DemoAccount.fromJson(item as Map<String, dynamic>);
              return DemoAccount(
                id: acc.id,
                email: acc.email,
                username: acc.username,
                password: acc.password,
                fullName: acc.fullName,
                role: acc.role,
                relation: acc.relation,
                phone: acc.phone,
                linkedResidentId: acc.linkedResidentId,
                residentName: acc.residentName,
                residentAge: acc.residentAge,
                avatarUrl: _apiClient.resolveMediaUrl(acc.avatarUrl),
                tag: acc.tag,
              );
            })
            .toList();
        _cachedDemoAccounts = accounts;
        return accounts;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpAuthRepository] getDemoAccounts network error: $e, using fallback');
      }
    }

    final fallbackAccounts = await _mockFallback.getDemoAccounts();
    _cachedDemoAccounts = fallbackAccounts;
    return fallbackAccounts;
  }

  @override
  Future<UserProfile?> loginWithCredentials(String username, String password) async {
    final cleanUsername = username.trim();
    String email = cleanUsername;
    if (!email.contains('@')) {
      email = '$cleanUsername@kubocare.com';
    }

    try {
      final res = await _apiClient.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      if (res is Map<String, dynamic> && res['token'] != null) {
        final token = res['token'] as String;
        _apiClient.setAuthToken(token);

        final userData = res['user'] as Map<String, dynamic>? ?? {};
        final roleStr = userData['role'] as String? ?? 'family';
        final userRole = roleStr.toLowerCase() == 'caregiver'
            ? UserRole.visitingCaregiver
            : roleStr.toLowerCase() == 'admin'
                ? UserRole.visitingCaregiver
                : UserRole.familyMember;

        String linkedResidentId = '3b471508-d528-4cfb-a9e0-4ac4b06eeec9';
        final accounts = _cachedDemoAccounts ?? await getDemoAccounts();
        for (final acc in accounts) {
          if (acc.email.toLowerCase() == email.toLowerCase() ||
              acc.username.toLowerCase() == cleanUsername.toLowerCase()) {
            linkedResidentId = acc.linkedResidentId;
            break;
          }
        }

        _currentUser = UserProfile(
          id: userData['id']?.toString() ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
          username: cleanUsername,
          fullName: userData['name']?.toString() ?? cleanUsername,
          role: userRole,
          relation: userRole == UserRole.visitingCaregiver ? 'Caregiver' : 'Family Member',
          phone: userData['phone_number']?.toString() ?? '555-0100',
          linkedResidentId: linkedResidentId,
        );
        return _currentUser;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpAuthRepository] Remote login failed ($e), attempting fallback');
      }
    }

    // Fallback to local mock if backend is temporarily disconnected
    final fallbackUser = await _mockFallback.loginWithCredentials(username, password);
    _currentUser = fallbackUser;
    return _currentUser;
  }

  @override
  Future<UserProfile> selectDemoProfile(String profileId) async {
    final accounts = _cachedDemoAccounts ?? await getDemoAccounts();
    final acc = accounts.firstWhere(
      (a) => a.id == profileId || a.username == profileId,
      orElse: () => accounts.first,
    );

    final email = acc.email;
    final password = acc.password;

    try {
      final res = await _apiClient.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      if (res is Map<String, dynamic> && res['token'] != null) {
        final token = res['token'] as String;
        _apiClient.setAuthToken(token);

        final userData = res['user'] as Map<String, dynamic>? ?? {};
        final roleStr = userData['role'] as String? ?? acc.role;
        final userRole = roleStr.toLowerCase() == 'caregiver' || acc.relation == 'Visiting Nurse'
            ? UserRole.visitingCaregiver
            : UserRole.familyMember;

        _currentUser = UserProfile(
          id: userData['id']?.toString() ?? acc.id,
          username: acc.username,
          fullName: userData['name']?.toString() ?? acc.fullName,
          role: userRole,
          relation: acc.relation,
          phone: userData['phone_number']?.toString() ?? acc.phone,
          linkedResidentId: acc.linkedResidentId,
        );
        return _currentUser!;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpAuthRepository] selectDemoProfile network call failed ($e), using local fallback');
      }
    }

    _currentUser = await _mockFallback.selectDemoProfile(profileId);
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _apiClient.clearAuthToken();
    _currentUser = null;
    await _mockFallback.logout();
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    return _currentUser;
  }
}
