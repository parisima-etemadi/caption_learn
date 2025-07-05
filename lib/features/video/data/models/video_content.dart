import 'package:caption_learn/features/video/domain/enum/video_source.dart';
import 'package:hive/hive.dart';

part 'video_content.g.dart';

class TimedWord {
  final String text;
  final int startTime;
  final int endTime;

  TimedWord({
    required this.text,
    required this.startTime,
    required this.endTime,
  });
}

@HiveType(typeId: 1)
class Subtitle {
  @HiveField(0)
  final int startTime; // in milliseconds
  
  @HiveField(1)
  final int endTime; // in milliseconds
  
  @HiveField(2)
  final String text;

  @HiveField(3)
  final String? translation; // Add translation field

  const Subtitle({
    required this.startTime,
    required this.endTime,
    required this.text,
    this.translation, // Add to constructor
  });

  List<TimedWord> get words {
    final wordList = <TimedWord>[];
    // Split by space, but also handle multiple spaces and leading/trailing spaces.
    final textWords =
        text.trim().split(' ').where((word) => word.isNotEmpty).toList();

    if (textWords.isEmpty) {
      return wordList;
    }

    final totalDuration = endTime - startTime;
    final totalLength = text.replaceAll(' ', '').length;

    if (totalLength == 0) {
      return textWords
          .map((word) =>
              TimedWord(text: word, startTime: startTime, endTime: endTime))
          .toList();
    }

    final timePerChar = totalDuration / totalLength;
    int currentWordStartTime = startTime;

    for (int i = 0; i < textWords.length; i++) {
      final word = textWords[i];
      final isLastWord = i == textWords.length - 1;

      final wordDuration = (word.length * timePerChar).round();
      final wordEndTime =
          isLastWord ? endTime : currentWordStartTime + wordDuration;

      wordList.add(
        TimedWord(
          text: word,
          startTime: currentWordStartTime,
          endTime: wordEndTime,
        ),
      );
      currentWordStartTime = wordEndTime;
    }
    return wordList;
  }

  factory Subtitle.fromJson(Map<String, dynamic> json) {
    return Subtitle(
      startTime: json['startTime'],
      endTime: json['endTime'],
      text: json['text'],
      translation: json['translation'], // Add to fromJson
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'text': text,
      'translation': translation, // Add to toJson
    };
  }

  Subtitle copyWith({
    int? startTime,
    int? endTime,
    String? text,
    String? translation, // Add to copyWith
  }) {
    return Subtitle(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      text: text ?? this.text,
      translation: translation ?? this.translation, // Add to copyWith
    );
  }
}

@HiveType(typeId: 0)
class VideoContent {
  @HiveField(0)
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

  @HiveField(7)
  final String? subtitleWarning; // Add this to show in the UI

  const VideoContent({
    required this.id,
    required this.title,
    required this.sourceUrl,
    required this.source,
    this.localPath,
    required this.subtitles,
    required this.dateAdded,
    this.subtitleWarning,
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
      subtitleWarning: json['subtitleWarning'] as String?,
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
      'subtitleWarning': subtitleWarning,
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
    String? subtitleWarning,
  }) {
    return VideoContent(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      source: source ?? this.source,
      localPath: localPath ?? this.localPath,
      subtitles: subtitles ?? this.subtitles,
      dateAdded: dateAdded ?? this.dateAdded,
      subtitleWarning: subtitleWarning ?? this.subtitleWarning,
    );
  }
}