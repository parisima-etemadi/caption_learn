import 'package:flutter/material.dart';
import '../../models/vocabulary_item.dart';

class VocabularyDialog extends StatelessWidget {
  final VocabularyItem selectedWord;
  final TextEditingController definitionController;
  final TextEditingController exampleController;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const VocabularyDialog({
    Key? key,
    required this.selectedWord,
    required this.definitionController,
    required this.exampleController,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add "${selectedWord.word}" to Vocabulary'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: definitionController,
              decoration: const InputDecoration(
                labelText: 'Definition',
                hintText: 'Enter definition',
              ),
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: exampleController,
              decoration: const InputDecoration(
                labelText: 'Example (optional)',
                hintText: 'Enter an example sentence',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: onCancel,
        ),
        TextButton(
          child: const Text('Save'),
          onPressed: onSave,
        ),
      ],
    );
  }
} 