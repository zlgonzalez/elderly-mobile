import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/resident.dart';
import '../fixtures/resident_fixtures.dart';
import 'mock_resident_repository.dart';
import 'resident_repository.dart';

class HttpResidentRepository implements ResidentRepository {
  final ApiClient _apiClient;
  final MockResidentRepository _fallback = MockResidentRepository();

  HttpResidentRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<Resident?> getResident(String id) async {
    final backendUuid = ResidentFixtures.toBackendUuid(id);
    try {
      final res = await _apiClient.get('/patients/$backendUuid');
      if (res is Map<String, dynamic>) {
        return _mapPatientToResident(res, fallbackId: id);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpResidentRepository] getResident($id) network error: $e, using fallback');
      }
    }
    return _fallback.getResident(id);
  }

  @override
  Future<List<Resident>> listResidents() async {
    try {
      final res = await _apiClient.get('/patients');
      if (res is List && res.isNotEmpty) {
        return res.map((item) {
          final map = item as Map<String, dynamic>;
          final id = map['id']?.toString() ?? '';
          return _mapPatientToResident(map, fallbackId: id);
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpResidentRepository] listResidents() network error: $e, using fallback');
      }
    }
    return _fallback.listResidents();
  }

  @override
  Future<void> updateResident(Resident resident) async {
    final backendUuid = ResidentFixtures.toBackendUuid(resident.id);
    try {
      await _apiClient.patch('/patients/$backendUuid', body: {
        'avatar_url': resident.avatarUrl,
        'biography': resident.biography,
        'quote': resident.quote,
        'education': resident.education,
        'interests': resident.interests,
        'milestones': resident.milestones.map((m) => m.toJson()).toList(),
        'conditions': resident.conditions,
        'allergies': resident.allergies,
        'contacts': resident.contacts.map((c) => c.toJson()).toList(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpResidentRepository] updateResident network error: $e');
      }
    }
    await _fallback.updateResident(resident);
  }

  Resident _mapPatientToResident(Map<String, dynamic> data, {required String fallbackId}) {
    final uuid = data['id']?.toString() ?? fallbackId;
    final fixture = ResidentFixtures.findById(uuid);

    final fullName = data['full_name']?.toString() ??
        '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
    
    int age = fixture.age;
    if (data['date_of_birth'] != null) {
      final dobStr = data['date_of_birth'].toString();
      final dob = DateTime.tryParse(dobStr);
      if (dob != null) {
        final now = DateTime.now();
        age = now.year - dob.year - ((now.month < dob.month || (now.month == dob.month && now.day < dob.day)) ? 1 : 0);
      }
    }

    final rawAvatar = (data['avatar_url'] != null && data['avatar_url'].toString().isNotEmpty)
        ? data['avatar_url'].toString()
        : fixture.avatarUrl;
    final avatarUrl = _apiClient.resolveMediaUrl(rawAvatar);
    final biography = (data['biography'] != null && data['biography'].toString().isNotEmpty)
        ? data['biography'].toString()
        : fixture.biography;
    final quote = (data['quote'] != null && data['quote'].toString().isNotEmpty)
        ? data['quote'].toString()
        : fixture.quote;
    final education = (data['education'] != null && data['education'].toString().isNotEmpty)
        ? data['education'].toString()
        : fixture.education;

    List<String> interests = fixture.interests;
    if (data['interests'] is List && (data['interests'] as List).isNotEmpty) {
      interests = (data['interests'] as List).map((e) => e.toString()).toList();
    }

    List<Milestone> milestones = fixture.milestones;
    if (data['milestones'] is List && (data['milestones'] as List).isNotEmpty) {
      milestones = (data['milestones'] as List)
          .map((m) => Milestone.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    List<String> conditions = fixture.conditions;
    if (data['conditions'] is List && (data['conditions'] as List).isNotEmpty) {
      conditions = (data['conditions'] as List).map((e) => e.toString()).toList();
    }

    List<String> allergies = fixture.allergies;
    if (data['allergies'] is List && (data['allergies'] as List).isNotEmpty) {
      allergies = (data['allergies'] as List).map((e) => e.toString()).toList();
    }

    List<ContactPerson> contacts = fixture.contacts;
    if (data['contacts'] is List && (data['contacts'] as List).isNotEmpty) {
      contacts = (data['contacts'] as List)
          .map((c) => ContactPerson.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    return fixture.copyWith(
      id: fixture.id,
      name: fullName.isNotEmpty ? fullName : fixture.name,
      age: age > 0 ? age : fixture.age,
      avatarUrl: avatarUrl,
      biography: biography,
      quote: quote,
      education: education,
      interests: interests,
      milestones: milestones,
      conditions: conditions,
      allergies: allergies,
      contacts: contacts,
    );
  }
}
