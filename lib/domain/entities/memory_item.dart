enum MemoryFormat {
  photo,
  story,
  letter,
  video;

  String get displayName {
    switch (this) {
      case MemoryFormat.photo:
        return 'Photo';
      case MemoryFormat.story:
        return 'Story';
      case MemoryFormat.letter:
        return 'Letter';
      case MemoryFormat.video:
        return 'Video';
    }
  }

  static MemoryFormat fromString(String value) {
    switch (value.toLowerCase()) {
      case 'story':
        return MemoryFormat.story;
      case 'letter':
        return MemoryFormat.letter;
      case 'video':
        return MemoryFormat.video;
      case 'photo':
      default:
        return MemoryFormat.photo;
    }
  }
}

class MemoryItem {
  final String id;
  final String residentId;
  final MemoryFormat format;
  final String title;
  final String? content;
  final String? mediaUrl;
  final DateTime date;
  final String sharedBy;
  final List<String> tags;

  const MemoryItem({
    required this.id,
    required this.residentId,
    required this.format,
    required this.title,
    this.content,
    this.mediaUrl,
    required this.date,
    required this.sharedBy,
    this.tags = const [],
  });

  MemoryItem copyWith({
    String? id,
    String? residentId,
    MemoryFormat? format,
    String? title,
    String? content,
    String? mediaUrl,
    DateTime? date,
    String? sharedBy,
    List<String>? tags,
  }) {
    return MemoryItem(
      id: id ?? this.id,
      residentId: residentId ?? this.residentId,
      format: format ?? this.format,
      title: title ?? this.title,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      date: date ?? this.date,
      sharedBy: sharedBy ?? this.sharedBy,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'residentId': residentId,
      'format': format.name,
      'title': title,
      'content': content,
      'mediaUrl': mediaUrl,
      'date': date.toIso8601String(),
      'sharedBy': sharedBy,
      'tags': tags,
    };
  }

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    return MemoryItem(
      id: json['id'] as String,
      residentId: json['residentId'] as String? ?? 'res_margaret',
      format: MemoryFormat.fromString(json['format'] as String? ?? 'photo'),
      title: json['title'] as String,
      content: json['content'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      sharedBy: json['sharedBy'] as String? ?? 'Family Member',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
