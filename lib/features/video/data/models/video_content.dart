import 'package:caption_learn/features/video/domain/enum/video_source.dart';
import 'package:hive/hive.dart';
import '../../../../services/storage_service.dart';

part 'video_content.g.dart';

@HiveType(typeId: 1)
class Subtitle {
  @HiveField(0)
  final int startTime; // in milliseconds
  
  @HiveField(1)
  final int endTime; // in milliseconds
  
  @HiveField(2)
  final String text;

  const Subtitle({
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
    return {'startTime': startTime, 'endTime': endTime, 'text': text};
  }

  Subtitle copyWith({int? startTime, int? endTime, String? text}) {
    return Subtitle(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      text: text ?? this.text,
    );
  }
}

@HiveType(typeId: 0)
class VideoContent implements Storable {
  @HiveField(0)
  @override
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String sourceUrl;
  
  @HiveField(3)
  final VideoSource source;
  
  @HiveField(4)
  final String? localPath;
  
  @HiveField(5)
  final List<Subtitle> subtitles;
  
  @HiveField(6)
  final DateTime dateAdded;

  const VideoContent({
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
      id: json['id'] as String,
      title: json['title'] as String,
      sourceUrl: json['sourceUrl'] as String,
      source: VideoSource.values.firstWhere(
        (e) => e.toString() == 'VideoSource.${json['source']}',
        orElse: () => VideoSource.local,
      ),
      localPath: json['localPath'] as String?,
      subtitles:
          (json['subtitles'] as List? ?? [])
              .where((subtitle) => subtitle != null)
              .map(
                (subtitle) =>
                    Subtitle.fromJson(subtitle as Map<String, dynamic>),
              )
              .toList(),
      dateAdded:
          DateTime.tryParse(json['dateAdded'] as String) ?? DateTime.now(),
    );
  }

  @override
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

  VideoContent copyWith({
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