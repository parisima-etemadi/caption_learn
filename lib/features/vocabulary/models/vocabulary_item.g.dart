// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocabulary_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VocabularyItemAdapter extends TypeAdapter<VocabularyItem> {
  @override
  final int typeId = 3;

  @override
  VocabularyItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VocabularyItem(
      id: fields[0] as String,
      word: fields[1] as String,
      definition: fields[2] as String,
      example: fields[3] as String?,
      sourceVideoId: fields[4] as String,
      dateAdded: fields[5] as DateTime,
      isFavorite: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, VocabularyItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.word)
      ..writeByte(2)
      ..write(obj.definition)
      ..writeByte(3)
      ..write(obj.example)
      ..writeByte(4)
      ..write(obj.sourceVideoId)
      ..writeByte(5)
      ..write(obj.dateAdded)
      ..writeByte(6)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
