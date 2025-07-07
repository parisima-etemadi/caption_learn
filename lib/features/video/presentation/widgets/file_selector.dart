import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FileSelector extends StatelessWidget {
  final String label;
  final File? file;
  final Function(File) onSelected;
  final List<String> extensions;

  const FileSelector({
    super.key,
    required this.label,
    required this.file,
    required this.onSelected,
    required this.extensions,
  });

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    
    if (result != null) {
      onSelected(File(result.files.single.path!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (file == null)
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('Select File'),
          )
        else
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(file!.path.split('/').last),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => onSelected(File('')), // Clear
            ),
            tileColor: Colors.green.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }
}