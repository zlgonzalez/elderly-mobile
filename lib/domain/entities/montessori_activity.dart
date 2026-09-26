enum MontessoriCategory {
  practicalLife('Practical Life', '🤲'),
  cognitive('Cognitive', '🧩'),
  creative('Creative', '🎨'),
  sensory('Sensory', '🌿'),
  social('Social', '☕');

  final String label;
  final String icon;

  const MontessoriCategory(this.label, this.icon);

  static MontessoriCategory fromString(String val) {
    switch (val.toLowerCase().replaceAll(' ', '')) {
      case 'practicallife':
        return MontessoriCategory.practicalLife;
      case 'cognitive':
        return MontessoriCategory.cognitive;
      case 'creative':
        return MontessoriCategory.creative;
      case 'sensory':
        return MontessoriCategory.sensory;
      case 'social':
        return MontessoriCategory.social;
      default:
        return MontessoriCategory.practicalLife;
    }
  }
}

class MontessoriActivity {
  final String id;
  final String title;
  final MontessoriCategory category;
  final String summary;
  final int durationMinutes;
  final List<String> materials;
  final String whyItMatters;
  final List<String> steps;
  final String? dignityTip;

  const MontessoriActivity({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.durationMinutes,
    required this.materials,
    required this.whyItMatters,
    required this.steps,
    this.dignityTip,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'summary': summary,
      'durationMinutes': durationMinutes,
      'materials': materials,
      'whyItMatters': whyItMatters,
      'steps': steps,
      'dignityTip': dignityTip,
    };
  }

  factory MontessoriActivity.fromJson(Map<String, dynamic> json) {
    return MontessoriActivity(
      id: json['id'] as String,
      title: json['title'] as String,
      category: MontessoriCategory.fromString(json['category'] as String? ?? 'practicalLife'),
      summary: json['summary'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? 15,
      materials: (json['materials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      whyItMatters: json['whyItMatters'] as String? ?? '',
      steps: (json['steps'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      dignityTip: json['dignityTip'] as String?,
    );
  }
}
