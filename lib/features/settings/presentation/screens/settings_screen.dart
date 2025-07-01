import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/settings/presentation/providers/theme_provider.dart';
import '../../../video/presentation/widgets/youtube_auth_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildThemeSettings(context),
          _buildYouTubeSettings(context),
        ],
      ),
    );
  }

  Widget _buildThemeSettings(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            RadioListTile<ThemeMode>(
              title: const Text('Light Theme'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setLightMode();
                }
              },
            ),
            
            RadioListTile<ThemeMode>(
              title: const Text('Dark Theme'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setDarkMode();
                }
              },
            ),
            
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setSystemMode();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYouTubeSettings(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: YouTubeAuthWidget(
        onAuthSuccess: () {
          // Optionally show a success message or refresh video list
        },
        onAuthFailed: () {
          // Handle auth failure if needed
        },
      ),
    );
  }
} 