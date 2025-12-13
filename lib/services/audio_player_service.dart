import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _currentState = PlayerState.stopped;
  bool _isInitialized = false;
  String? _currentUrl;

  AudioPlayerService() {
    _setupPlayer();
  }

  void _setupPlayer() {
    if (_isInitialized) return;

    // Configuration optimale
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);

    // Gestion des changements d'état
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _currentState = state;
      print('🎵 État audio changé: $state');
    });

    // Gestion de la complétion
    _audioPlayer.onPlayerComplete.listen((_) {
      print('🎵 Lecture audio terminée');
      _currentState = PlayerState.completed;
    });

    _isInitialized = true;
    print('🎵 AudioPlayer configuré');
  }

  // GETTERS pour les streams
  Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;
  Stream<Duration> get onDurationChanged => _audioPlayer.onDurationChanged;
  Stream<PlayerState> get onStateChanged => _audioPlayer.onPlayerStateChanged;

  Future<void> play(String url) async {
    try {
      print('🎵 Tentative de lecture: $url');
      _currentUrl = url;

      // Arrêter et libérer la lecture en cours si nécessaire
      if (_currentState == PlayerState.playing) {
        print('🔄 Arrêt de la lecture en cours...');
        await _stopAndRelease();
        await Future.delayed(Duration(milliseconds: 100));
      }

      _currentState = PlayerState.playing;

      if (url.startsWith('asset://')) {
        // Lecture depuis assets avec retry
        await _playFromAssetsWithRetry(url);
      } else if (url.startsWith('file://')) {
        // Lecture depuis fichier local
        await _audioPlayer.play(DeviceFileSource(url.replaceFirst('file://', '')));
      } else {
        // Lecture depuis URL réseau
        await _audioPlayer.play(UrlSource(url));
      }

      print('✅ Lecture démarrée: $url');

    } catch (e) {
      _currentState = PlayerState.stopped;
      _currentUrl = null;
      print('❌ Erreur lecture audio: $e');

      // Détails supplémentaires pour le debug
      if (e.toString().contains('Unable to load asset')) {
        print('💡 Vérifiez que le fichier existe dans assets/');
        print('💡 Vérifiez votre pubspec.yaml');
        await _debugAssetIssue(url);
      }

      rethrow;
    }
  }

  Future<void> _playFromAssetsWithRetry(String assetUrl) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final path = assetUrl.replaceFirst('asset://', '');
        print('🎵 Tentative ${retryCount + 1}/$maxRetries: $path');

        // Vérifier si l'asset existe avant de tenter de le lire
        final exists = await _checkAssetExists(path);
        if (!exists) {
          throw Exception('Asset non trouvé: assets/$path');
        }

        await _audioPlayer.play(AssetSource(path));
        print('✅ Lecture réussie: $path');
        return;

      } catch (e) {
        retryCount++;
        print('⚠️ Échec tentative $retryCount: ${e.toString()}');

        if (retryCount >= maxRetries) {
          print('❌ Échec final après $maxRetries tentatives pour: $assetUrl');
          await _debugAssetIssue(assetUrl);
          rethrow;
        }

        // Attente exponentielle avant de réessayer
        final delay = Duration(milliseconds: 300 * retryCount);
        print('⏳ Attente de ${delay.inMilliseconds}ms avant réessai...');
        await Future.delayed(delay);
      }
    }
  }

  // Vérifier si un asset existe
  Future<bool> _checkAssetExists(String path) async {
    try {
      final assetPath = 'assets/$path';
      await rootBundle.load(assetPath);
      print('✅ Asset vérifié: $assetPath');
      return true;
    } catch (e) {
      print('❌ Asset non trouvé: assets/$path');
      return false;
    }
  }

  // Debug détaillé pour les problèmes d'assets
  Future<void> _debugAssetIssue(String assetUrl) async {
    try {
      print('🔍 Début debug pour: $assetUrl');

      final path = assetUrl.replaceFirst('asset://', 'assets/');
      print('📁 Chemin recherché: $path');

      // Essayer de charger le manifest
      try {
        final manifest = await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifestMap = json.decode(manifest);

        print('📋 Assets disponibles contenant "music":');

        final musicAssets = manifestMap.keys
            .where((key) => key.contains('music'))
            .toList();

        if (musicAssets.isEmpty) {
          print('   ❌ Aucun asset "music" trouvé dans le manifest!');
          print('   💡 Vérifiez votre pubspec.yaml');
        } else {
          print('   ✅ ${musicAssets.length} assets music trouvés');

          // Afficher les 15 premiers pour référence
          for (final key in musicAssets.take(15)) {
            print('   - $key');
          }
          if (musicAssets.length > 15) {
            print('   ... et ${musicAssets.length - 15} autres');
          }

          // Chercher le fichier spécifique
          final searchFileName = assetUrl.split('/').last;
          final exactMatches = musicAssets.where((key) =>
              key.endsWith('/$searchFileName')).toList();

          if (exactMatches.isNotEmpty) {
            print('🔍 Fichier trouvé avec ces chemins:');
            for (final match in exactMatches) {
              print('   ✅ $match');
            }
          } else {
            print('🔍 Aucune correspondance exacte pour: $searchFileName');

            // Chercher des fichiers similaires
            final similarFiles = musicAssets.where((key) =>
                key.contains(searchFileName.split('.')[0])).toList();

            if (similarFiles.isNotEmpty) {
              print('🔍 Fichiers similaires trouvés:');
              for (final similar in similarFiles) {
                print('   ≈ $similar');
              }
            }
          }
        }
      } catch (e) {
        print('⚠️ Impossible de lire le manifest: $e');

        // Essayer de charger directement un fichier test
        print('🧪 Test avec un fichier connu...');
        const testFiles = [
          'assets/music/happy/bee_gees_stayin_alive.mp3',
          'assets/metadata/local_playlists.json',
        ];

        for (final testFile in testFiles) {
          try {
            await rootBundle.load(testFile);
            print('   ✅ $testFile chargé avec succès');
          } catch (e) {
            print('   ❌ $testFile échoué: $e');
          }
        }
      }

    } catch (e) {
      print('⚠️ Erreur lors du debug: $e');
    }
  }

  Future<void> pause() async {
    if (_currentState == PlayerState.playing) {
      await _audioPlayer.pause();
      _currentState = PlayerState.paused;
      print('⏸️ Lecture mise en pause');
    }
  }

  Future<void> resume() async {
    if (_currentState == PlayerState.paused && _currentUrl != null) {
      await _audioPlayer.resume();
      _currentState = PlayerState.playing;
      print('▶️ Lecture reprise');
    }
  }

  // Méthode pour arrêter et libérer les ressources
  Future<void> _stopAndRelease() async {
    try {
      await _audioPlayer.stop();
      // Note: Dans audioplayers, release() n'est pas disponible
      // On utilise simplement stop() et dispose() quand nécessaire
      _currentState = PlayerState.stopped;
      _currentUrl = null;
      print('⏹️ Lecture arrêtée et ressources libérées');
    } catch (e) {
      print('⚠️ Erreur lors de l\'arrêt: $e');
    }
  }

  Future<void> stop() async {
    await _stopAndRelease();
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      print('⏩ Seek à: $position');
    } catch (e) {
      print('⚠️ Erreur seek: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
      print('🔊 Volume réglé à: ${volume.toStringAsFixed(2)}');
    } catch (e) {
      print('⚠️ Erreur réglage volume: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _stopAndRelease();
      await _audioPlayer.dispose();
      _currentState = PlayerState.stopped;
      _currentUrl = null;
      _isInitialized = false;
      print('🗑️ AudioPlayerService désactivé');
    } catch (e) {
      print('⚠️ Erreur disposal: $e');
    }
  }

  // Méthodes supplémentaires utiles
  Future<Duration?> getDuration() async {
    try {
      return await _audioPlayer.getDuration();
    } catch (e) {
      print('⚠️ Erreur getDuration: $e');
      return null;
    }
  }

  Future<Duration?> getCurrentPosition() async {
    try {
      return await _audioPlayer.getCurrentPosition();
    } catch (e) {
      print('⚠️ Erreur getCurrentPosition: $e');
      return null;
    }
  }

  Future<void> setPlaybackRate(double rate) async {
    try {
      await _audioPlayer.setPlaybackRate(rate);
      print('⚡ Vitesse réglée à: ${rate.toStringAsFixed(1)}x');
    } catch (e) {
      print('⚠️ Erreur réglage vitesse: $e');
    }
  }

  Future<void> setReleaseMode(ReleaseMode releaseMode) async {
    try {
      await _audioPlayer.setReleaseMode(releaseMode);
      print('🔄 Mode release réglé: $releaseMode');
    } catch (e) {
      print('⚠️ Erreur réglage release mode: $e');
    }
  }

  // Getters pour l'état actuel
  PlayerState get currentState => _currentState;
  String? get currentUrl => _currentUrl;
  bool get isPlaying => _currentState == PlayerState.playing;
  bool get isPaused => _currentState == PlayerState.paused;
  bool get isStopped => _currentState == PlayerState.stopped;

  // Réinitialiser le player
  Future<void> reset() async {
    await _stopAndRelease();
    _setupPlayer();
    print('🔄 AudioPlayer réinitialisé');
  }

  // Vérifier si une URL asset existe
  Future<bool> checkAssetExists(String assetUrl) async {
    try {
      final path = assetUrl.replaceFirst('asset://', 'assets/');
      await rootBundle.load(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtenir des informations de debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'currentState': _currentState.toString(),
      'currentUrl': _currentUrl,
      'isInitialized': _isInitialized,
      'isPlaying': isPlaying,
      'isPaused': isPaused,
      'isStopped': isStopped,
    };
  }

  // Tester la lecture d'un fichier spécifique
  Future<bool> testPlayAsset(String assetPath) async {
    try {
      print('🧪 Test de lecture: $assetPath');
      await _audioPlayer.play(AssetSource(assetPath));
      await Future.delayed(Duration(seconds: 2));
      await _stopAndRelease();
      print('✅ Test réussi: $assetPath');
      return true;
    } catch (e) {
      print('❌ Test échoué: $assetPath - $e');
      return false;
    }
  }

  // Nettoyer complètement le player (pour les gros problèmes)
  Future<void> clean() async {
    try {
      print('🧹 Nettoyage complet du player audio...');
      await dispose();
      _setupPlayer();
      print('✅ Player audio nettoyé et réinitialisé');
    } catch (e) {
      print('❌ Erreur lors du nettoyage: $e');
    }
  }
}