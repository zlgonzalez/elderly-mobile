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
      case 'functional':
        return MontessoriCategory.practicalLife;
      case 'cognitive':
      case 'language':
      case 'math':
        return MontessoriCategory.cognitive;
      case 'creative':
        return MontessoriCategory.creative;
      case 'sensory':
      case 'sensorial':
      case 'physical':
        return MontessoriCategory.sensory;
      case 'social':
      case 'cultural':
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
  final String? historicalConnection;
  final String? safetyComfort;
  final String? scriptPrompt;
  final String? materialsTraySetup;
  final bool isPersonalized;

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
    this.historicalConnection,
    this.safetyComfort,
    this.scriptPrompt,
    this.materialsTraySetup,
    this.isPersonalized = false,
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
      'historicalConnection': historicalConnection,
      'safetyComfort': safetyComfort,
      'scriptPrompt': scriptPrompt,
      'materialsTraySetup': materialsTraySetup,
      'isPersonalized': isPersonalized,
    };
  }

  factory MontessoriActivity.fromJson(Map<String, dynamic> json) {
    return MontessoriActivity(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: MontessoriCategory.fromString(json['category'] as String? ?? 'practicalLife'),
      summary: json['summary'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ??
          (json['duration_minutes'] as num?)?.toInt() ??
          15,
      materials: (json['materials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      whyItMatters: json['whyItMatters'] as String? ?? json['why_it_matters'] as String? ?? '',
      steps: (json['steps'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      dignityTip: json['dignityTip'] as String? ?? json['dignity_tip'] as String?,
      historicalConnection: json['historicalConnection'] as String? ??
          json['historical_connection'] as String?,
      safetyComfort:
          json['safetyComfort'] as String? ?? json['safety_comfort'] as String?,
      scriptPrompt:
          json['scriptPrompt'] as String? ?? json['script_prompt'] as String?,
      materialsTraySetup: json['materialsTraySetup'] as String? ??
          json['materials_tray_setup'] as String?,
      isPersonalized: json['isPersonalized'] as bool? ?? false,
    );
  }
}
