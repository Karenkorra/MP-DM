import 'package:dj_mood_front/services/audio_player_service.dart';
import 'package:dj_mood_front/services/local_music_service.dart';
import 'package:dj_mood_front/viewmodels/home_viewmodel.dart';
import 'package:dj_mood_front/viewmodels/mood_viewmodel.dart';
import 'package:dj_mood_front/viewmodels/player_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'views/home_view.dart';
import 'views/mood_view.dart';
import 'views/player_view.dart';

Future<void> checkAssets() async {
  try {
    final manifest = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifest);

    final musicAssets = manifestMap.keys
        .where((key) => key.startsWith('assets/music/') && key.endsWith('.mp3'))
        .toList();

    print('🎵 ${musicAssets.length} fichiers MP3 trouvés dans les assets:');
    for (final asset in musicAssets.take(10)) {
      print('   - $asset');
    }
    if (musicAssets.length > 10) {
      print('   ... et ${musicAssets.length - 10} autres');
    }

    final folders = ['happy', 'sad', 'energetic', 'relaxed', 'romantic'];
    for (final folder in folders) {
      final folderAssets = manifestMap.keys
          .where((key) => key.contains('assets/music/$folder/'))
          .toList();
      print('   $folder/: ${folderAssets.length} fichiers');
    }

  } catch (e) {
    print('❌ Erreur vérification assets: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Démarrer avec le splash screen
  runApp(const SplashApp());
}

// Application temporaire pour le splash screen
class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

// Splash Screen avec le GIF
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _initializationComplete = false;
  bool _minDurationPassed = false;
  final int _minSplashDuration = 5000; // 2 secondes minimum
  final int _maxSplashDuration = 6000; // 5 secondes maximum (sécurité)

  @override
  void initState() {
    super.initState();

    // Démarrer le timer pour la durée minimum
    Timer(Duration(milliseconds: _minSplashDuration), () {
      if (mounted) {
        setState(() {
          _minDurationPassed = true;
        });
        _checkAndNavigate();
      }
    });

    // Timer de sécurité pour éviter que le splash reste trop longtemps
    Timer(Duration(milliseconds: _maxSplashDuration), () {
      if (mounted && _initializationComplete) {
        _navigateToMainApp();
      }
    });

    // Initialiser l'application en arrière-plan
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('🔍 Vérification des assets...');
      await checkAssets();

      // Initialiser les services
      final audioService = AudioPlayerService();
      final localService = LocalMusicService();
      await localService.initialize();

      // Marquer l'initialisation comme terminée
      if (mounted) {
        setState(() {
          _initializationComplete = true;
        });
        _checkAndNavigate();
      }
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation: $e');
      // Même en cas d'erreur, on navigue vers l'app principale
      if (mounted) {
        setState(() {
          _initializationComplete = true;
        });
        _checkAndNavigate();
      }
    }
  }

  void _checkAndNavigate() {
    // Naviguer seulement si la durée minimum est passée ET l'initialisation est terminée
    if (_minDurationPassed && _initializationComplete) {
      _navigateToMainApp();
    }
  }

  void _navigateToMainApp() {
    // Initialiser les services pour l'app principale
    final audioService = AudioPlayerService();
    final localService = LocalMusicService();

    // Naviguer vers l'app principale
    Future.delayed(Duration.zero, () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MultiProvider(
              providers: [
                Provider<AudioPlayerService>.value(value: audioService),
                Provider<LocalMusicService>.value(value: localService),

                ChangeNotifierProxyProvider<LocalMusicService, HomeViewModel>(
                  create: (context) => HomeViewModel(),
                  update: (context, localService, homeViewModel) {
                    homeViewModel ??= HomeViewModel();
                    homeViewModel.initialize();
                    return homeViewModel;
                  },
                ),

                ChangeNotifierProvider(
                  create: (context) => PlayerViewModel(
                    context.read<AudioPlayerService>(),
                  ),
                ),

                ChangeNotifierProvider(
                  create: (context) => MoodViewModel(),
                ),
              ],
              child: const MyApp(),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // GIF de fond
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Image.asset(
              'assets/gifs/splash.gif',
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                // Fallback si le GIF ne charge pas
                return Container(
                  color: Colors.black,
                  child: const Center(
                    child: Text(
                      'DJ MOOD',
                      style: TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Indicateur de chargement en bas
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (!_initializationComplete)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                const SizedBox(height: 20),
                Text(
                  _initializationComplete ? 'Prêt !' : 'Chargement...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Application principale
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DJ Mood',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeView(),
        '/mood': (context) => const MoodView(),
        '/player': (context) => const PlayerView(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}