class VocabularyItem {
  final String id;
  final String word;
  final String definition;
  final String? example;
  final String sourceVideoId; // Reference to the video where this word was learned
  final DateTime dateAdded;
  final bool isFavorite;
  
  const VocabularyItem({
    required this.id,
    required this.word,
    required this.definition,
    this.example,
    required this.sourceVideoId,
    required this.dateAdded,
    this.isFavorite = false,
  });
  
  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id'] as String,
      word: json['word'] as String,
      definition: json['definition'] as String,
      example: json['example'] as String?,
      sourceVideoId: json['sourceVideoId'] as String,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'definition': definition,
      'example': example,
      'sourceVideoId': sourceVideoId,
      'dateAdded': dateAdded.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }
  
  VocabularyItem copyWith({
    String? id,
    String? word,
    String? definition,
    String? example,
    String? sourceVideoId,
    DateTime? dateAdded,
    bool? isFavorite,
  }) {
    return VocabularyItem(
      id: id ?? this.id,
      word: word ?? this.word,
      definition: definition ?? this.definition,
      example: example ?? this.example,
      sourceVideoId: sourceVideoId ?? this.sourceVideoId,
      dateAdded: dateAdded ?? this.dateAdded,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is VocabularyItem &&
        other.id == id &&
        other.word == word &&
        other.definition == definition &&
        other.example == example &&
        other.sourceVideoId == sourceVideoId &&
        other.dateAdded.isAtSameMomentAs(dateAdded) &&
        other.isFavorite == isFavorite;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        word.hashCode ^
        definition.hashCode ^
        example.hashCode ^
        sourceVideoId.hashCode ^
        dateAdded.hashCode ^
        isFavorite.hashCode;
  }
  
  @override
  String toString() {
    return 'VocabularyItem(id: $id, word: $word, definition: $definition, example: $example, '
        'sourceVideoId: $sourceVideoId, dateAdded: $dateAdded, isFavorite: $isFavorite)';
  }
} 