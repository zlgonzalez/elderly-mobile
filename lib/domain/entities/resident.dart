class Milestone {
  final int year;
  final String title;
  final String description;

  const Milestone({
    required this.year,
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'year': year,
    'title': title,
    'description': description,
  };

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
    year: json['year'] as int,
    title: json['title'] as String,
    description: json['description'] as String,
  );
}

class ContactPerson {
  final String name;
  final String relation;
  final String phone;

  const ContactPerson({
    required this.name,
    required this.relation,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'relation': relation,
    'phone': phone,
  };

  factory ContactPerson.fromJson(Map<String, dynamic> json) => ContactPerson(
    name: json['name'] as String,
    relation: json['relation'] as String,
    phone: json['phone'] as String,
  );
}

class Resident {
  final String id;
  final String name;
  final int age;
  final String avatarUrl;
  final String biography;
  final String quote;
  final String education;
  final List<String> interests;
  final List<Milestone> milestones;
  final List<String> conditions;
  final List<String> allergies;
  final List<ContactPerson> contacts;

  const Resident({
    required this.id,
    required this.name,
    required this.age,
    required this.avatarUrl,
    required this.biography,
    required this.quote,
    required this.education,
    required this.interests,
    required this.milestones,
    required this.conditions,
    required this.allergies,
    required this.contacts,
  });

  String get fullName => name;

  Resident copyWith({
    String? id,
    String? name,
    int? age,
    String? avatarUrl,
    String? biography,
    String? quote,
    String? education,
    List<String>? interests,
    List<Milestone>? milestones,
    List<String>? conditions,
    List<String>? allergies,
    List<ContactPerson>? contacts,
  }) {
    return Resident(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      biography: biography ?? this.biography,
      quote: quote ?? this.quote,
      education: education ?? this.education,
      interests: interests ?? this.interests,
      milestones: milestones ?? this.milestones,
      conditions: conditions ?? this.conditions,
      allergies: allergies ?? this.allergies,
      contacts: contacts ?? this.contacts,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'avatarUrl': avatarUrl,
    'biography': biography,
    'quote': quote,
    'education': education,
    'interests': interests,
    'milestones': milestones.map((m) => m.toJson()).toList(),
    'conditions': conditions,
    'allergies': allergies,
    'contacts': contacts.map((c) => c.toJson()).toList(),
  };

  factory Resident.fromJson(Map<String, dynamic> json) => Resident(
    id: json['id'] as String,
    name: json['name'] as String,
    age: json['age'] as int,
    avatarUrl: json['avatarUrl'] as String? ?? '',
    biography: json['biography'] as String? ?? '',
    quote: json['quote'] as String? ?? '',
    education: json['education'] as String? ?? '',
    interests: (json['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    milestones: (json['milestones'] as List<dynamic>?)
            ?.map((m) => Milestone.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [],
    conditions: (json['conditions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    allergies: (json['allergies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    contacts: (json['contacts'] as List<dynamic>?)
            ?.map((c) => ContactPerson.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [],
  );
}
