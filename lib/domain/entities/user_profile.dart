enum UserRole {
  familyMember,
  visitingCaregiver,
}

class UserProfile {
  final String id;
  final String username;
  final String fullName;
  final UserRole role;
  final String relation;
  final String phone;
  final String linkedResidentId;

  const UserProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.relation,
    required this.phone,
    required this.linkedResidentId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'role': role.name,
    'relation': relation,
    'phone': phone,
    'linkedResidentId': linkedResidentId,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    username: json['username'] as String,
    fullName: json['fullName'] as String,
    role: (json['role'] as String?) == 'visitingCaregiver'
        ? UserRole.visitingCaregiver
        : UserRole.familyMember,
    relation: json['relation'] as String? ?? 'Family Member',
    phone: json['phone'] as String? ?? '',
    linkedResidentId: json['linkedResidentId'] as String? ?? 'res_margaret',
  );
}

class DemoAccount {
  final String id;
  final String email;
  final String username;
  final String password;
  final String fullName;
  final String role;
  final String relation;
  final String phone;
  final String linkedResidentId;
  final String residentName;
  final int residentAge;
  final String? avatarUrl;
  final String? tag;

  const DemoAccount({
    required this.id,
    required this.email,
    required this.username,
    required this.password,
    required this.fullName,
    required this.role,
    required this.relation,
    required this.phone,
    required this.linkedResidentId,
    required this.residentName,
    required this.residentAge,
    this.avatarUrl,
    this.tag,
  });

  factory DemoAccount.fromJson(Map<String, dynamic> json) {
    return DemoAccount(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? 'password123',
      fullName: json['full_name']?.toString() ?? json['fullName']?.toString() ?? '',
      role: json['role']?.toString() ?? 'family',
      relation: json['relation']?.toString() ?? 'Family Member',
      phone: json['phone']?.toString() ?? '',
      linkedResidentId: json['linked_resident_id']?.toString() ?? json['linkedResidentId']?.toString() ?? '',
      residentName: json['resident_name']?.toString() ?? json['residentName']?.toString() ?? '',
      residentAge: (json['resident_age'] as num?)?.toInt() ?? (json['residentAge'] as num?)?.toInt() ?? 80,
      avatarUrl: json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      tag: json['tag']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'password': password,
    'full_name': fullName,
    'role': role,
    'relation': relation,
    'phone': phone,
    'linked_resident_id': linkedResidentId,
    'resident_name': residentName,
    'resident_age': residentAge,
    'avatar_url': avatarUrl,
    'tag': tag,
  };
}
