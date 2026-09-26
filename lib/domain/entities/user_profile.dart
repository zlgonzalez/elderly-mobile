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
