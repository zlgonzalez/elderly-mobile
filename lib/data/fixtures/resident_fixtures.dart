import '../../domain/entities/resident.dart';

class ResidentFixtures {
  ResidentFixtures._();

  static const Resident margaretThompson = Resident(
    id: 'res_margaret',
    name: 'Margaret Thompson',
    age: 82,
    avatarUrl: '/api/v1/media/avatars/margaret.png',
    biography: 'Elementary School Teacher (35 years)\nBurlington, Vermont',
    quote: 'Every child is a garden waiting to bloom. You just have to believe in what you cannot yet see.',
    education: 'B.Ed., University of Vermont, 1965',
    interests: [
      'Gardening',
      'Reading',
      'Watercolour painting',
      'Birdwatching',
      'Tea preparation',
    ],
    milestones: [
      Milestone(
        year: 1965,
        title: 'Wedding Day 1965',
        description: 'Married Harold Thompson at First Congregational Church, Burlington. A bright June afternoon surrounded by family, wildflowers, and handwritten promises.',
      ),
      Milestone(
        year: 1998,
        title: 'Vermont Educator of the Year',
        description: 'Received the statewide award for lifelong dedication to early literacy and compassionate classroom leadership.',
      ),
      Milestone(
        year: 2000,
        title: 'Retired after 35 years',
        description: 'Her final graduating class planted a sugar maple tree in her honour on the school grounds.',
      ),
      Milestone(
        year: 2018,
        title: 'Lost Harold',
        description: 'After 53 years of loving marriage, companionship, and shared garden seasons.',
      ),
    ],
    conditions: [
      'Mild Dementia',
      'Arthritis',
      'Hypertension',
    ],
    allergies: [
      '⚠ Penicillin',
    ],
    contacts: [
      ContactPerson(
        name: 'Sarah Thompson',
        relation: 'Daughter',
        phone: '555-0123',
      ),
      ContactPerson(
        name: 'Nurse Jane',
        relation: 'Visiting Nurse',
        phone: '555-0199',
      ),
    ],
  );

  static const Resident robertChen = Resident(
    id: 'res_robert',
    name: 'Robert Chen',
    age: 79,
    avatarUrl: '/api/v1/media/avatars/robert.png',
    biography: 'Civil Engineer (40 years)\nSan Francisco, California',
    quote: 'Good foundations make bridges that outlast generations.',
    education: 'B.S. Civil Engineering, UC Berkeley, 1968',
    interests: [
      'Chess',
      'Classical music',
      'Walking',
      'Woodworking',
    ],
    milestones: [
      Milestone(
        year: 1970,
        title: 'Bay Area Infrastructure Project',
        description: 'Led engineering design for regional transit corridors.',
      ),
      Milestone(
        year: 2008,
        title: 'Retirement & Community Mentorship',
        description: 'Mentored young engineering students across local colleges.',
      ),
    ],
    conditions: [
      'Mild Cognitive Impairment',
      'Type 2 Diabetes',
    ],
    allergies: [
      '⚠ Sulfa drugs',
    ],
    contacts: [
      ContactPerson(
        name: 'Lisa Chen',
        relation: 'Daughter',
        phone: '555-0144',
      ),
    ],
  );

  static const Resident dorothyWilliams = Resident(
    id: 'res_dorothy',
    name: 'Dorothy Williams',
    age: 85,
    avatarUrl: '/api/v1/media/avatars/dorothy.png',
    biography: 'Librarian & Pianist\nChicago, Illinois',
    quote: 'Stories are where we keep what we cannot afford to lose.',
    education: 'M.L.I.S., University of Illinois, 1963',
    interests: [
      'Piano',
      'Historical fiction',
      'Crossword puzzles',
      'Baking',
    ],
    milestones: [
      Milestone(
        year: 1963,
        title: 'Chief Children’s Librarian',
        description: 'Founded the Saturday Story Hour program serving thousands of children.',
      ),
      Milestone(
        year: 1995,
        title: 'Community Music Award',
        description: 'Recognized for 30 years of volunteering as choir accompanist.',
      ),
    ],
    conditions: [
      'Mild Dementia',
      'Osteoporosis',
    ],
    allergies: [
      '⚠ Codeine',
    ],
    contacts: [
      ContactPerson(
        name: 'James Williams',
        relation: 'Son',
        phone: '555-0188',
      ),
    ],
  );

  static const Map<String, String> residentIdToBackendUuid = {
    'res_margaret': '3b471508-d528-4cfb-a9e0-4ac4b06eeec9',
    'res_robert': '062510e3-b81a-4421-9576-56c72ff29f18',
    'res_dorothy': 'd5eade63-7af6-457e-99ff-befcdd201ac8',
  };

  static const Map<String, String> backendUuidToResidentId = {
    '3b471508-d528-4cfb-a9e0-4ac4b06eeec9': 'res_margaret',
    '062510e3-b81a-4421-9576-56c72ff29f18': 'res_robert',
    'd5eade63-7af6-457e-99ff-befcdd201ac8': 'res_dorothy',
  };

  static String toBackendUuid(String id) {
    return residentIdToBackendUuid[id] ?? id;
  }

  static String toFixtureId(String uuid) {
    return backendUuidToResidentId[uuid] ?? uuid;
  }

  static List<Resident> get allResidents => [
    margaretThompson,
    robertChen,
    dorothyWilliams,
  ];

  static Resident findById(String id) {
    final fixtureId = backendUuidToResidentId[id] ?? id;
    return allResidents.firstWhere(
      (r) => r.id == fixtureId || r.id == id,
      orElse: () => margaretThompson,
    );
  }
}
