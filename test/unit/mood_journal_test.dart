import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/domain/entities/mood_entry.dart';
import 'package:elderly_mobile/data/repositories/mock_mood_repository.dart';

void main() {
  group('Mood Journal Unit Tests', () {
    late MockMoodRepository repository;

    setUp(() {
      repository = MockMoodRepository();
    });

    test('Loads default moods for Margaret Thompson', () async {
      final moods = await repository.getMoods('res_margaret');
      expect(moods.length, 3);
      expect(moods.first.mood, MoodType.happy);
      expect(moods[1].mood, MoodType.content);
      expect(moods[2].mood, MoodType.anxious);
    });

    test('Empty mood list for Robert Chen (empty state test)', () async {
      final moods = await repository.getMoods('res_robert');
      expect(moods, isEmpty);
    });

    test('Log new mood prepends to resident entries', () async {
      final newEntry = MoodEntry(
        id: 'test_mood_123',
        residentId: 'res_robert',
        mood: MoodType.content,
        timestamp: DateTime.now(),
        recordedBy: 'Michael Chen',
        notes: 'Peaceful afternoon listening to radio',
      );

      final logged = await repository.logMood('res_robert', newEntry);
      expect(logged.id, 'test_mood_123');
      expect(logged.mood, MoodType.content);

      final updatedMoods = await repository.getMoods('res_robert');
      expect(updatedMoods.length, 1);
      expect(updatedMoods.first.recordedBy, 'Michael Chen');
      expect(updatedMoods.first.notes, 'Peaceful afternoon listening to radio');
    });

    test('MoodType fromString parses correctly', () {
      expect(MoodType.fromString('happy'), MoodType.happy);
      expect(MoodType.fromString('content'), MoodType.content);
      expect(MoodType.fromString('neutral'), MoodType.neutral);
      expect(MoodType.fromString('sad'), MoodType.sad);
      expect(MoodType.fromString('anxious'), MoodType.anxious);
      expect(MoodType.fromString('upset'), MoodType.upset);
      expect(MoodType.fromString('unknown_value'), MoodType.happy);
    });

    test('MoodEntry JSON serialization and deserialization', () {
      final now = DateTime.now();
      final entry = MoodEntry(
        id: 'json_test_1',
        residentId: 'res_margaret',
        mood: MoodType.sad,
        timestamp: now,
        recordedBy: 'Nurse Jane',
        notes: 'Missing family',
      );

      final json = entry.toJson();
      expect(json['id'], 'json_test_1');
      expect(json['mood'], 'sad');

      final deserialized = MoodEntry.fromJson(json);
      expect(deserialized.id, entry.id);
      expect(deserialized.mood, MoodType.sad);
      expect(deserialized.recordedBy, 'Nurse Jane');
      expect(deserialized.notes, 'Missing family');
    });
  });
}
