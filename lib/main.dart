import 'package:dj_mood_front/services/audio_player_service.dart';
import 'package:dj_mood_front/services/local_music_service.dart';
import 'package:dj_mood_front/services/mood_analyzer.dart';
import 'package:dj_mood_front/viewmodels/home_viewmodel.dart';
import 'package:dj_mood_front/viewmodels/mood_viewmodel.dart';
import 'package:dj_mood_front/viewmodels/player_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'views/home_view.dart';
import 'views/player_view.dart';
import 'package:dj_mood_front/viewmodels/text_analysis_viewmodel.dart';

Future<void> checkAssets() async {
  print('🔍 Vérification des assets...');
  try {
    final manifest = await rootBundle.loadString('local_playlists.json');
    final Map<String, dynamic> manifestMap = json.decode(manifest);

    final musicAssets = manifestMap.keys
        .where((key) => key.contains('music/'))
        .toList();

    print('📁 ${musicAssets.length} assets music trouvés');

    if (musicAssets.isEmpty) {
      print('Aucun asset music trouvé!');
    } else {
      print('Assets vérifiés avec succès');
    }
  } catch (e) {
    print(' Erreur vérification assets: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SplashApp());
}


class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _initializationComplete = false;
  bool _minDurationPassed = false;
  final int _minSplashDuration = 3000;
  final int _maxSplashDuration = 5000;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animation de pulsation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Timer(Duration(milliseconds: _minSplashDuration), () {
      if (mounted) {
        setState(() {
          _minDurationPassed = true;
        });
        _checkAndNavigate();
      }
    });

    Timer(Duration(milliseconds: _maxSplashDuration), () {
      if (mounted && !_initializationComplete) {
        _navigateToMainApp();
      }
    });

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('Initialisation de l\'application...');
      await checkAssets();

      if (mounted) {
        setState(() {
          _initializationComplete = true;
        });
        _checkAndNavigate();
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
      if (mounted) {
        setState(() {
          _initializationComplete = true;
        });
        _checkAndNavigate();
      }
    }
  }

  void _checkAndNavigate() {
    if (_minDurationPassed && _initializationComplete) {
      _navigateToMainApp();
    }
  }

  void _navigateToMainApp() {
    Future.delayed(Duration.zero, () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => MultiProvider(
              providers: [
                Provider<AudioPlayerService>(
                  create: (_) => AudioPlayerService(),
                ),
                Provider<LocalMusicService>(
                  create: (_) => LocalMusicService(),
                ),
                Provider<MoodAnalyzer>(
                  create: (_) => MoodAnalyzer(),
                ),
                ChangeNotifierProvider<HomeViewModel>(
                  create: (context) {
                    final homeViewModel = HomeViewModel();
                    homeViewModel.initialize();
                    return homeViewModel;
                  },
                ),
                ChangeNotifierProvider<PlayerViewModel>(
                  create: (context) => PlayerViewModel(
                    context.read<AudioPlayerService>(),
                  ),
                ),
                ChangeNotifierProvider<MoodViewModel>(
                  create: (context) => MoodViewModel(),
                ),
                ChangeNotifierProvider<TextAnalysisViewModel>(
                  create: (context) => TextAnalysisViewModel(),
                ),
              ],
              child: const MyApp(),
            ),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.black,
              Colors.deepPurple.shade800,
            ],
          ),
        ),
        child: Stack(
          children: [
            // GIF de fond (si disponible)
            Positioned.fill(
              child: Image.asset(
                'assets/gifs/splash.gif',
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  return Container(); // Fond transparent si pas de GIF
                },
              ),
            ),

            // Overlay gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),

            // Indicateur de chargement
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  if (!_initializationComplete)
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.deepPurple.shade300,
                      ),
                      strokeWidth: 3,
                    ),
                  const SizedBox(height: 20),
                  Text(
                    _initializationComplete ? 'Prêt !' : 'Chargement...',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DJ Mood',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black26,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple.shade600,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.deepPurple,
      ),
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeView(),
        '/player': (context) => const PlayerView(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}