import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/data/repositories/mock_health_vitals_repository.dart';
import 'package:elderly_mobile/domain/entities/vital_sign.dart';

void main() {
  group('VitalSign Entity & Validation Tests', () {
    test('normal vitals evaluate isAbnormal to false', () {
      final normal = VitalSign(
        id: '1',
        residentId: 'res_margaret',
        timestamp: DateTime.now(),
        bloodPressure: '120/80',
        heartRate: 72,
        temperature: 98.6,
        painLevel: 2,
        recordedBy: 'Nurse Jane',
      );
      expect(normal.isAbnormal, isFalse);
    });

    test('high blood pressure evaluates isAbnormal to true', () {
      final highBP = VitalSign(
        id: '2',
        residentId: 'res_margaret',
        timestamp: DateTime.now(),
        bloodPressure: '145/95',
        heartRate: 72,
        temperature: 98.6,
        painLevel: 1,
        recordedBy: 'Nurse Jane',
      );
      expect(highBP.isAbnormal, isTrue);
    });

    test('tachycardia heart rate evaluates isAbnormal to true', () {
      final tachycardia = VitalSign(
        id: '3',
        residentId: 'res_margaret',
        timestamp: DateTime.now(),
        bloodPressure: '120/80',
        heartRate: 110,
        temperature: 98.6,
        painLevel: 1,
        recordedBy: 'Nurse Jane',
      );
      expect(tachycardia.isAbnormal, isTrue);
    });

    test('fever temperature evaluates isAbnormal to true', () {
      final fever = VitalSign(
        id: '4',
        residentId: 'res_margaret',
        timestamp: DateTime.now(),
        bloodPressure: '120/80',
        heartRate: 72,
        temperature: 101.2,
        painLevel: 1,
        recordedBy: 'Nurse Jane',
      );
      expect(fever.isAbnormal, isTrue);
    });

    test('high pain level (>= 7) evaluates isAbnormal to true', () {
      final severePain = VitalSign(
        id: '5',
        residentId: 'res_margaret',
        timestamp: DateTime.now(),
        bloodPressure: '120/80',
        heartRate: 72,
        temperature: 98.6,
        painLevel: 8,
        recordedBy: 'Nurse Jane',
      );
      expect(severePain.isAbnormal, isTrue);
    });
  });

  group('MockHealthVitalsRepository Tests', () {
    late MockHealthVitalsRepository repository;

    setUp(() {
      repository = MockHealthVitalsRepository();
    });

    test('getVitals returns pre-loaded vitals for Margaret', () async {
      final vitals = await repository.getVitals('res_margaret');
      expect(vitals.length, greaterThanOrEqualTo(2));
      expect(vitals.first.bloodPressure, '120/80');
      expect(vitals.first.recordedBy, 'Nurse Jane');
    });

    test('recordVitals appends new vital entry to repository store', () async {
      final newVital = VitalSign(
        id: 'vit_test',
        residentId: 'res_margaret',
        timestamp: DateTime.now(),
        bloodPressure: '118/78',
        heartRate: 70,
        temperature: 98.5,
        weight: 137.5,
        mobilityLevel: 'Independent',
        painLevel: 0,
        recordedBy: 'Sarah Thompson',
        clinicalNotes: 'Good appetite and high energy',
      );

      final recorded = await repository.recordVitals('res_margaret', newVital);
      expect(recorded.bloodPressure, '118/78');

      final list = await repository.getVitals('res_margaret');
      expect(list.first.bloodPressure, '118/78');
      expect(list.first.clinicalNotes, 'Good appetite and high energy');
    });
  });
}
