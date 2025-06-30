import '../../../features/video/data/models/video_content.dart';

/// Abstract base class for subtitle parsers
abstract class SubtitleParser {
  Future<List<Subtitle>> parse(String content);
}

/// Parser for XML subtitle format
class XmlSubtitleParser extends SubtitleParser {
  @override
  Future<List<Subtitle>> parse(String content) async {
    final subtitles = <Subtitle>[];
    
    // Parse XML subtitle content
    final transcriptMatch = RegExp(r'<transcript>(.*?)</transcript>', dotAll: true).firstMatch(content);
    if (transcriptMatch == null) return subtitles;
    
    final textElements = RegExp(r'<text.*?start="([^"]*)".*?dur="([^"]*)".*?>(.*?)</text>').allMatches(transcriptMatch.group(1)!);
    
    for (final match in textElements) {
      try {
        final startTime = double.tryParse(match.group(1)!) ?? 0.0;
        final duration = double.tryParse(match.group(2)!) ?? 0.0;
        final text = match.group(3)!
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'")
            .trim();
        
        if (text.isNotEmpty) {
          subtitles.add(Subtitle(
            startTime: startTime.toInt(),
            endTime: (startTime + duration).toInt(),
            text: text,
          ));
        }
      } catch (e) {
        continue; // Skip malformed entries
      }
    }
    
    return subtitles;
  }
}

/// Parser for WebVTT subtitle format
class WebVttSubtitleParser extends SubtitleParser {
  @override
  Future<List<Subtitle>> parse(String content) async {
    final subtitles = <Subtitle>[];
    final lines = content.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Look for timestamp lines (format: "00:00:00.000 --> 00:00:05.000")
      if (line.contains('-->')) {
        try {
          final parts = line.split('-->');
          if (parts.length == 2) {
            final startTime = _parseTimeToSeconds(parts[0].trim());
            final endTime = _parseTimeToSeconds(parts[1].trim());
            
            // Get the subtitle text (next non-empty line)
            String text = '';
            for (int j = i + 1; j < lines.length; j++) {
              final textLine = lines[j].trim();
              if (textLine.isEmpty) break;
              if (textLine.contains('-->')) break;
              
              if (text.isNotEmpty) text += ' ';
              text += textLine;
            }
            
            if (text.isNotEmpty) {
              subtitles.add(Subtitle(
                startTime: startTime.toInt(),
                endTime: endTime.toInt(),
                text: text,
              ));
            }
          }
        } catch (e) {
          continue; // Skip malformed entries
        }
      }
    }
    
    return subtitles;
  }
  
  double _parseTimeToSeconds(String timeString) {
    final parts = timeString.split(':');
    if (parts.length == 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final secondsParts = parts[2].split('.');
      final seconds = int.tryParse(secondsParts[0]) ?? 0;
      final milliseconds = secondsParts.length > 1 ? int.tryParse(secondsParts[1]) ?? 0 : 0;
      
      return hours * 3600 + minutes * 60 + seconds + milliseconds / 1000;
    }
    return 0.0;
  }
}

/// Parser for SRT subtitle format
class SrtSubtitleParser extends SubtitleParser {
  @override
  Future<List<Subtitle>> parse(String content) async {
    final subtitles = <Subtitle>[];
    final blocks = content.split('\n\n');
    
    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length >= 3) {
        try {
          // Skip sequence number (first line)
          final timecodeLine = lines[1];
          
          if (timecodeLine.contains('-->')) {
            final timeParts = timecodeLine.split('-->');
            final startTime = _parseTimeToSeconds(timeParts[0].trim());
            final endTime = _parseTimeToSeconds(timeParts[1].trim());
            
            // Combine all text lines
            final text = lines.sublist(2).join(' ').trim();
            
            if (text.isNotEmpty) {
              subtitles.add(Subtitle(
                startTime: startTime.toInt(),
                endTime: endTime.toInt(),
                text: text,
              ));
            }
          }
        } catch (e) {
          continue; // Skip malformed entries
        }
      }
    }
    
    return subtitles;
  }
  
  double _parseTimeToSeconds(String timeString) {
    final parts = timeString.replaceAll(',', '.').split(':');
    if (parts.length == 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final secondsParts = parts[2].split('.');
      final seconds = int.tryParse(secondsParts[0]) ?? 0;
      final milliseconds = secondsParts.length > 1 ? int.tryParse(secondsParts[1]) ?? 0 : 0;
      
      return hours * 3600 + minutes * 60 + seconds + milliseconds / 1000;
    }
    return 0.0;
  }
}

/// Factory for creating subtitle parsers
class SubtitleParserFactory {
  static SubtitleParser createParser(String content) {
    if (content.contains('<transcript>')) {
      return XmlSubtitleParser();
    } else if (content.contains('WEBVTT') || content.contains('-->') && content.contains(':')) {
      return WebVttSubtitleParser();
    } else {
      return SrtSubtitleParser();
    }
  }
}