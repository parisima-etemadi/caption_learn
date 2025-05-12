import 'package:hive/hive.dart';

enum VideoSource { youtube, local }

class VideoSourceAdapter extends TypeAdapter<VideoSource> {
  @override
  final int typeId = 2;

  @override
  VideoSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return VideoSource.youtube;
      case 1:
        return VideoSource.local;
      default:
        return VideoSource.youtube;
    }
  }

  @override
  void write(BinaryWriter writer, VideoSource obj) {
    switch (obj) {
      case VideoSource.youtube:
        writer.writeByte(0);
        break;
      case VideoSource.local:
        writer.writeByte(1);
        break;
    }
  }
}