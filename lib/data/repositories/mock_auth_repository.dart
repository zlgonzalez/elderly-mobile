import '../../domain/entities/user_profile.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  UserProfile? _currentUser;

  static const UserProfile sarahThompson = UserProfile(
    id: 'user_sarah',
    username: 'sarah.thompson',
    fullName: 'Sarah Thompson',
    role: UserRole.familyMember,
    relation: 'Daughter',
    phone: '555-0123',
    linkedResidentId: 'res_margaret',
  );

  static const UserProfile lisaChen = UserProfile(
    id: 'user_lisa',
    username: 'lisa.chen',
    fullName: 'Lisa Chen',
    role: UserRole.familyMember,
    relation: 'Daughter',
    phone: '555-0144',
    linkedResidentId: 'res_robert',
  );

  static const UserProfile jamesWilliams = UserProfile(
    id: 'user_james',
    username: 'james.williams',
    fullName: 'James Williams',
    role: UserRole.familyMember,
    relation: 'Son',
    phone: '555-0188',
    linkedResidentId: 'res_dorothy',
  );

  static const List<UserProfile> demoProfiles = [
    sarahThompson,
    lisaChen,
    jamesWilliams,
  ];

  @override
  // [MICROSERVICE_INTEGRATION_POINT]: AuthService - POST /api/v1/auth/login
  // TODO(microservice): Replace mock data with: final res = await apiClient.post('/api/v1/auth/login', body: {'username': username, 'password': password});
  Future<UserProfile?> loginWithCredentials(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final match = demoProfiles.firstWhere(
      (p) => p.username.toLowerCase() == username.toLowerCase().trim(),
      orElse: () => UserProfile(
        id: 'user_custom',
        username: username,
        fullName: username,
        role: UserRole.familyMember,
        relation: 'Family Member',
        phone: '555-0100',
        linkedResidentId: 'res_margaret',
      ),
    );
    _currentUser = match;
    return _currentUser;
  }

  @override
  // [MICROSERVICE_INTEGRATION_POINT]: AuthService - POST /api/v1/auth/demo-switch
  // TODO(microservice): Replace mock data with: final res = await apiClient.post('/api/v1/auth/demo-switch', body: {'profileId': profileId});
  Future<UserProfile> selectDemoProfile(String profileId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentUser = demoProfiles.firstWhere(
      (p) => p.id == profileId || p.username == profileId,
      orElse: () => sarahThompson,
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<List<DemoAccount>> getDemoAccounts() async {
    return const [
      DemoAccount(
        id: 'user_sarah',
        email: 'sarah.thompson@kubocare.com',
        username: 'sarah.thompson',
        password: 'password123',
        fullName: 'Sarah Thompson',
        role: 'family',
        relation: 'Daughter',
        phone: '555-0123',
        linkedResidentId: '3b471508-d528-4cfb-a9e0-4ac4b06eeec9',
        residentName: 'Margaret Thompson',
        residentAge: 82,
        avatarUrl: '/api/v1/media/avatars/margaret.png',
        tag: 'Primary Demo',
      ),
      DemoAccount(
        id: 'user_lisa',
        email: 'lisa.chen@kubocare.com',
        username: 'lisa.chen',
        password: 'password123',
        fullName: 'Lisa Chen',
        role: 'family',
        relation: 'Daughter',
        phone: '555-0144',
        linkedResidentId: '062510e3-b81a-4421-9576-56c72ff29f18',
        residentName: 'Robert Chen',
        residentAge: 79,
        avatarUrl: '/api/v1/media/avatars/robert.png',
      ),
      DemoAccount(
        id: 'user_james',
        email: 'james.williams@kubocare.com',
        username: 'james.williams',
        password: 'password123',
        fullName: 'James Williams',
        role: 'family',
        relation: 'Son',
        phone: '555-0188',
        linkedResidentId: 'd5eade63-7af6-457e-99ff-befcdd201ac8',
        residentName: 'Dorothy Williams',
        residentAge: 85,
        avatarUrl: '/api/v1/media/avatars/dorothy.png',
      ),
      DemoAccount(
        id: 'user_caregiver',
        email: 'caregiver@kubocare.com',
        username: 'caregiver',
        password: 'password123',
        fullName: 'Nurse Jane',
        role: 'caregiver',
        relation: 'Visiting Nurse',
        phone: '555-0999',
        linkedResidentId: '3b471508-d528-4cfb-a9e0-4ac4b06eeec9',
        residentName: 'Margaret Thompson',
        residentAge: 82,
        avatarUrl: '/api/v1/media/avatars/caregiver.png',
      ),
    ];
  }
}
