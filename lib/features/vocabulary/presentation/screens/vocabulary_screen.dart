import 'package:caption_learn/features/vocabulary/models/vocabulary_item.dart';
import 'package:caption_learn/services/storage_service.dart';
import 'package:flutter/material.dart';


class VocabularyScreen extends StatefulWidget {
  final String? videoId; // If provided, shows vocabulary for specific video, otherwise all

  const VocabularyScreen({super.key, this.videoId});

  @override
  _VocabularyScreenState createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final StorageService _storageService = StorageService();
  List<VocabularyItem> _vocabularyItems = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  Future<void> _loadVocabulary() async {
    setState(() {
      _isLoading = true;
    });

    final items = widget.videoId != null
        ? await _storageService.getVocabularyByVideoId(widget.videoId!)
        : await _storageService.getVocabularyItems();

    items.sort((a, b) => b.dateAdded.compareTo(a.dateAdded)); // Sort by newest first

    setState(() {
      _vocabularyItems = items;
      _isLoading = false;
    });
  }

  Future<void> _deleteVocabularyItem(String id) async {
    await _storageService.deleteVocabularyItem(id);
    _loadVocabulary();
  }

  Future<void> _toggleFavorite(VocabularyItem item) async {
    final updatedItem = item.copyWith(isFavorite: !item.isFavorite);
    await _storageService.saveVocabularyItem(updatedItem);
    _loadVocabulary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.videoId != null ? 'Video Vocabulary' : 'All Vocabulary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVocabulary,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vocabularyItems.isEmpty
              ? _buildEmptyState()
              : _buildVocabularyList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.menu_book,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No vocabulary items yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.videoId != null
                ? 'Click on words in the subtitles to add them'
                : 'Add vocabulary items while watching videos',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyList() {
    return ListView.builder(
      itemCount: _vocabularyItems.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final item = _vocabularyItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.word,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        item.isFavorite
                            ? Icons.star
                            : Icons.star_border,
                        color: item.isFavorite
                            ? Colors.amber
                            : Colors.grey,
                      ),
                      onPressed: () => _toggleFavorite(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _showDeleteConfirmation(item),
                    ),
                  ],
                ),
                const Divider(),
                Text(
                  item.definition,
                  style: const TextStyle(fontSize: 16),
                ),
                if (item.example != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Example: "${item.example}"',
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Added: ${_formatDate(item.dateAdded)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showDeleteConfirmation(VocabularyItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vocabulary Item'),
        content: Text('Are you sure you want to delete "${item.word}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteVocabularyItem(item.id);
    }
  }
}