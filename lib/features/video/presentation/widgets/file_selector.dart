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

  Future<void> _pickFile(BuildContext context) async {
    // Use FileType.any on iOS to allow all files, then filter manually
    final result = await FilePicker.platform.pickFiles(
      type: Platform.isIOS ? FileType.any : FileType.custom,
      allowedExtensions: Platform.isIOS ? null : extensions,
    );
    
    if (result != null) {
      final file = File(result.files.single.path!);
      
      // Manual extension validation for iOS
      if (Platform.isIOS) {
        final fileName = file.path.toLowerCase();
        final hasValidExtension = extensions.any((ext) => fileName.endsWith('.$ext'));
        
        if (!hasValidExtension) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please select a file with one of these extensions: ${extensions.join(', ')}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
      onSelected(file);
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
            onPressed: () => _pickFile(context), // Pass context here
            icon: const Icon(Icons.folder_open),
            label: Text(Platform.isIOS 
                ? 'Select File (${extensions.join(', ')})'
                : 'Select File'),
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