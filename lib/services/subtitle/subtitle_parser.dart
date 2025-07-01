import '../../features/video/data/models/video_content.dart';

/// Simple subtitle parser - handles common formats
class SubtitleParser {
  static List<Subtitle> parse(String content) {
    if (content.contains('<transcript>')) return _parseXml(content);
    if (content.contains('WEBVTT') || content.contains('-->')) return _parseVtt(content);
    return _parseSrt(content);
  }
  
  // Public methods for specific formats
  static List<Subtitle> parseVtt(String content) => _parseVtt(content);
  static List<Subtitle> parseSrv3(String content) => _parseXml(content);
  
  static List<Subtitle> _parseXml(String content) {
    final regex = RegExp(r'<text.*?start="([^"]*)".*?dur="([^"]*)".*?>(.*?)</text>');
    return regex.allMatches(content).map((m) {
      final start = double.tryParse(m.group(1)!) ?? 0;
      final dur = double.tryParse(m.group(2)!) ?? 0;
      final text = m.group(3)!.replaceAll(RegExp(r'&\w+;'), '').trim();
      return Subtitle(
        startTime: (start * 1000).toInt(),
        endTime: ((start + dur) * 1000).toInt(),
        text: text,
      );
    }).where((s) => s.text.isNotEmpty).toList();
  }
  
  static List<Subtitle> _parseVtt(String content) {
    final lines = content.split('\n');
    final subtitles = <Subtitle>[];
    
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('-->')) {
        final times = lines[i].split('-->');
        if (times.length == 2) {
          final start = _parseTime(times[0].trim());
          final end = _parseTime(times[1].trim());
          final text = lines.skip(i + 1).takeWhile((l) => l.trim().isNotEmpty).join(' ').trim();
          if (text.isNotEmpty) {
            subtitles.add(Subtitle(startTime: start, endTime: end, text: text));
          }
        }
      }
    }
    return subtitles;
  }
  
  static List<Subtitle> _parseSrt(String content) {
    return content.split('\n\n').map((block) {
      final lines = block.trim().split('\n');
      if (lines.length >= 3 && lines[1].contains('-->')) {
        final times = lines[1].split('-->');
        final start = _parseTime(times[0].trim());
        final end = _parseTime(times[1].trim());
        final text = lines.skip(2).join(' ').trim();
        return Subtitle(startTime: start, endTime: end, text: text);
      }
      return null;
    }).where((s) => s != null).cast<Subtitle>().toList();
  }
  
  static int _parseTime(String time) {
    final parts = time.replaceAll(',', '.').split(':');
    if (parts.length == 3) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = double.tryParse(parts[2]) ?? 0;
      return ((h * 3600 + m * 60 + s) * 1000).toInt();
    }
    return 0;
  }
}