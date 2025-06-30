// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_content.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubtitleAdapter extends TypeAdapter<Subtitle> {
  @override
  final int typeId = 1;

  @override
  Subtitle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subtitle(
      startTime: fields[0] as int,
      endTime: fields[1] as int,
      text: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Subtitle obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.startTime)
      ..writeByte(1)
      ..write(obj.endTime)
      ..writeByte(2)
      ..write(obj.text);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubtitleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VideoContentAdapter extends TypeAdapter<VideoContent> {
  @override
  final int typeId = 0;

  @override
  VideoContent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoContent(
      id: fields[0] as String,
      title: fields[1] as String,
      sourceUrl: fields[2] as String,
      source: fields[3] as VideoSource,
      localPath: fields[4] as String?,
      subtitles: (fields[5] as List).cast<Subtitle>(),
      dateAdded: fields[6] as DateTime,
      subtitleWarning: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VideoContent obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.sourceUrl)
      ..writeByte(3)
      ..write(obj.source)
      ..writeByte(4)
      ..write(obj.localPath)
      ..writeByte(5)
      ..write(obj.subtitles)
      ..writeByte(6)
      ..write(obj.dateAdded)
      ..writeByte(7)
      ..write(obj.subtitleWarning);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoContentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
