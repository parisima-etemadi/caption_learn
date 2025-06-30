import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/logger.dart';
import 'core/widgets/app_error_boundary.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/settings/presentation/providers/theme_provider.dart';
import 'services/hive_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup error handling
  AppErrorHandler.setup();
  
  // Configure logger
  Logger.logLevel = LogLevel.debug; // Set to error in production
  final logger = Logger('Main');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
    );
    logger.i('Firebase initialized successfully');
    
    // Initialize Hive first - this must succeed
    await HiveService.initialize();
    logger.i('Hive initialized successfully');
    
    // Initialize StorageService (which opens the boxes) - this must succeed
    await StorageService().initialize();
    logger.i('StorageService initialized successfully');
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    logger.i('Set preferred orientations');
    
  } catch (e, stackTrace) {
    logger.e('Failed to initialize app', e, stackTrace);
    // Continue with app launch even if some initialization fails
  }
  
  
  runApp(
    AppErrorBoundary(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc()..add(AuthCheckRequested()),
          ),
        ],
        child: ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: const CaptionLearnApp(),
        ),
      ),
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
      debugShowCheckedModeBanner: false,
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
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state.isAuthenticated) {
            return const HomeScreen();
          }
          return const HomeScreen();
        },
      ),
    );
  }
}