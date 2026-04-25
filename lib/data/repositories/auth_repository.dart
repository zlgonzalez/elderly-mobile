import 'dart:async';
import '../../core/network/api_client.dart';
import '../local/user_entity.dart';

class AuthRepository {
  final ApiClient apiClient;
  
  AuthRepository({required this.apiClient});

  // Mock implementation for Zitadel authentication
  Future<UserEntity> login(String username, String password) async {
    // In a real app, we'd exchange credentials for a token via apiClient
    // final response = await apiClient.post('/oauth/token', body: {...});
    // apiClient.setAuthToken(response['access_token']);
    
    await Future.delayed(const Duration(seconds: 1)); // Simulate network latency

    if (username == 'admin' && password == 'admin') {
      apiClient.setAuthToken('mock_token_123');
      return UserEntity()
        ..remoteId = 'user_1'
        ..firstName = 'Admin'
        ..lastName = 'User'
        ..role = 'admin'
        ..email = 'admin@evergreen.com';
    } else if (username == 'caregiver' && password == 'password') {
      apiClient.setAuthToken('mock_token_456');
      return UserEntity()
        ..remoteId = 'user_2'
        ..firstName = 'Jane'
        ..lastName = 'Doe'
        ..role = 'caregiver'
        ..email = 'jane.doe@evergreen.com';
    } else {
      throw Exception('Invalid credentials');
    }
  }

  void logout() {
    apiClient.clearAuthToken();
  }
}
