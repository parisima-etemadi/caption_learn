import 'package:flutter/material.dart';

class TranscriptDialog extends StatelessWidget {
  const TranscriptDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Transcript'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('You can add a transcript by:'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => const PasteTranscriptDialog(),
              );
            },
            child: const Text('Paste from clipboard'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementation for uploading a subtitle file would go here
            },
            child: const Text('Upload SRT file'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class PasteTranscriptDialog extends StatelessWidget {
  const PasteTranscriptDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    
    return AlertDialog(
      title: const Text('Paste Transcript'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'Paste transcript text here...',
        ),
        maxLines: 10,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Handle transcript parsing and saving
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
} 