enum VideoSource { youtube, instagram, local }

class Subtitle {
  final int startTime; // in milliseconds
  final int endTime; // in milliseconds
  final String text;
  
  Subtitle({
    required this.startTime,
    required this.endTime,
    required this.text,
  });
  
  factory Subtitle.fromJson(Map<String, dynamic> json) {
    return Subtitle(
      startTime: json['startTime'] ?? 0,
      endTime: json['endTime'] ?? 0,
      text: json['text'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'text': text,
    };
  }
}

class VideoContent {
  final String id;
  final String title;
  final String sourceUrl;
  final VideoSource source;
  final String? localPath;
  final List<Subtitle> subtitles;
  final DateTime dateAdded;
  
  VideoContent({
    required this.id,
    required this.title,
    required this.sourceUrl,
    required this.source,
    this.localPath,
    required this.subtitles,
    required this.dateAdded,
  });
  
  factory VideoContent.fromJson(Map<String, dynamic> json) {
    return VideoContent(
      id: json['id'],
      title: json['title'],
      sourceUrl: json['sourceUrl'],
      source: VideoSource.values.firstWhere(
        (e) => e.toString() == 'VideoSource.${json['source']}',
        orElse: () => VideoSource.local,
      ),
      localPath: json['localPath'],
      subtitles: (json['subtitles'] as List? ?? [])
          .where((subtitle) => subtitle != null)
          .map((subtitle) => Subtitle.fromJson(subtitle))
          .toList(),
      dateAdded: DateTime.tryParse(json['dateAdded']) ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'sourceUrl': sourceUrl,
      'source': source.toString().split('.').last,
      'localPath': localPath,
      'subtitles': subtitles.map((subtitle) => subtitle.toJson()).toList(),
      'dateAdded': dateAdded.toIso8601String(),
    };
  }
  
  copyWith({
    String? id,
    String? title,
    String? sourceUrl,
    VideoSource? source,
    String? localPath,
    List<Subtitle>? subtitles,
    DateTime? dateAdded,
  }) {
    return VideoContent(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      source: source ?? this.source,
      localPath: localPath ?? this.localPath,
      subtitles: subtitles ?? this.subtitles,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }
} 