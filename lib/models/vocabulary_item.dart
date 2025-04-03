class VocabularyItem {
  final String id;
  final String word;
  final String definition;
  final String? example;
  final String sourceVideoId; // Reference to the video where this word was learned
  final DateTime dateAdded;
  final bool isFavorite;
  
  VocabularyItem({
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
      id: json['id'],
      word: json['word'],
      definition: json['definition'],
      example: json['example'],
      sourceVideoId: json['sourceVideoId'],
      dateAdded: DateTime.parse(json['dateAdded']),
      isFavorite: json['isFavorite'] ?? false,
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
} 