import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/services/shared_prefs_storage_service.dart';
import 'core/services/storage_repository.dart';
import 'core/utils/logger.dart';
import 'features/video_management/screens/home_screen.dart';
import 'common/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure logger
  Logger.logLevel = LogLevel.debug; // Set to error in production
  final logger = Logger('Main');
  
  // Set preferred orientations
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    logger.i('Set preferred orientations');
  } catch (e) {
    logger.e('Failed to set preferred orientations', e);
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Register your repositories here for dependency injection
        Provider<VideoStorageRepository>(create: (_) => VideoStorage()),
        Provider<VocabularyStorageRepository>(create: (_) => VocabularyStorage()),
      ],
      child: const CaptionLearnApp(),
    ),
  );
  
  logger.i('Application started');
}

class CaptionLearnApp extends StatelessWidget {
  const CaptionLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false, // Remove debug banner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: const HomeScreen(),
    );
  }
}
