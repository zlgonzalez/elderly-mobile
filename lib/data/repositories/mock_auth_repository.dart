import '../../domain/entities/user_profile.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  UserProfile? _currentUser;
  final Map<String, String> _pendingCodes = {};
  final Map<String, ({UserProfile profile, String password, String email})>
      _registeredCaregivers = {};

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

  static const UserProfile nurseJane = UserProfile(
    id: 'user_caregiver',
    username: 'caregiver',
    fullName: 'Nurse Jane',
    role: UserRole.visitingCaregiver,
    relation: 'Visiting Nurse',
    phone: '555-0999',
    linkedResidentId: 'res_margaret',
  );

  static const List<UserProfile> demoProfiles = [
    sarahThompson,
    lisaChen,
    jamesWilliams,
    nurseJane,
  ];

  @override
  // [MICROSERVICE_INTEGRATION_POINT]: AuthService - POST /api/v1/auth/login
  Future<UserProfile?> loginWithCredentials(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final clean = username.toLowerCase().trim();

    for (final entry in _registeredCaregivers.values) {
      if (entry.profile.username.toLowerCase() == clean ||
          entry.email.toLowerCase() == clean) {
        if (entry.password != password) {
          return null;
        }
        _currentUser = entry.profile;
        return _currentUser;
      }
    }

    final match = demoProfiles.firstWhere(
      (p) =>
          p.username.toLowerCase() == clean ||
          p.id.toLowerCase() == clean ||
          '${p.username.toLowerCase()}@kubocare.com' == clean,
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
  Future<CaregiverSignUpInitiationResult> initiateCaregiverSignUp(String email) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final normalized = email.trim().toLowerCase();
    if (!normalized.contains('@') || !normalized.split('@').last.contains('.')) {
      throw Exception('Please enter a valid email address');
    }
    if (_registeredCaregivers.containsKey(normalized)) {
      throw Exception('An account with this email already exists');
    }
    _pendingCodes[normalized] = '123456';
    final encoded = Uri.encodeQueryComponent(normalized);
    return CaregiverSignUpInitiationResult(
      email: normalized,
      finalizationLink: '/signup/finalize?email=$encoded',
      expiresInSeconds: 900,
      message: 'Verification email sent with 6-digit code',
    );
  }

  @override
  Future<CaregiverSignUpInitiationResult> resendCaregiverSignUpCode(String email) async {
    return initiateCaregiverSignUp(email);
  }

  @override
  Future<UserProfile> finalizeCaregiverSignUp({
    required String email,
    required String code,
    required String username,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final normalized = email.trim().toLowerCase();
    final trimmedUsername = username.trim();
    final expectedCode = _pendingCodes[normalized];
    if (expectedCode == null || code.trim() != expectedCode) {
      throw Exception('Invalid, expired, or locked verification code');
    }
    if (trimmedUsername.length < 3 || trimmedUsername.length > 64) {
      throw Exception('Username must be 3 to 64 characters');
    }
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters');
    }

    final profile = UserProfile(
      id: 'user_cg_${DateTime.now().millisecondsSinceEpoch}',
      username: trimmedUsername,
      fullName: trimmedUsername,
      role: UserRole.visitingCaregiver,
      relation: 'Caregiver',
      phone: '555-0100',
      linkedResidentId: 'res_margaret',
    );
    _pendingCodes.remove(normalized);
    _registeredCaregivers[normalized] = (
      profile: profile,
      password: password,
      email: normalized,
    );
    _currentUser = profile;
    return profile;
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
