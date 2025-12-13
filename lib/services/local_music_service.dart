import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/track.dart';
import '../models/mood.dart';

class LocalMusicService {
  static final LocalMusicService _instance = LocalMusicService._internal();
  factory LocalMusicService() => _instance;
  LocalMusicService._internal();

  List<Track> _allLocalTracks = [];
  Map<String, List<Track>> _tracksByMood = {};
  Map<String, Map<String, dynamic>> _moodMetadata = {};
  bool _isInitialized = false;

  // Initialiser depuis local_playlists.json
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('📂 Chargement des playlists locales...');

      final metadata = await rootBundle.loadString('assets/metadata/local_playlists.json');
      final Map<String, dynamic> data = json.decode(metadata);

      final List<dynamic> moodPlaylists = data['mood_playlists'] ?? [];

      int totalTracksLoaded = 0;
      int totalTracksSkipped = 0;

      // Traiter chaque playlist d'humeur
      for (final playlist in moodPlaylists) {
        final moodId = playlist['id'];
        final moodName = playlist['name'];
        final moodEmoji = playlist['emoji'];
        final moodColor = _parseColor(playlist['color']);

        // Stocker les métadonnées de l'humeur
        _moodMetadata[moodId] = {
          'name': moodName,
          'emoji': moodEmoji,
          'color': moodColor,
          'genres': List<String>.from(playlist['genres'] ?? []),
          'description': playlist['description'] ?? '',
        };

        // Traiter les tracks de cette humeur
        final List<dynamic> tracksData = playlist['tracks'] ?? [];
        final List<Track> moodTracks = [];

        for (final trackData in tracksData) {
          final filename = trackData['filename'];
          final moodFolder = trackData['id'].split('_')[0];
          final assetPath = 'assets/music/$moodFolder/$filename';

          // Vérifier si le fichier existe
          bool fileExists = false;
          try {
            await rootBundle.load(assetPath);
            fileExists = true;
            print('✅ $filename existe');
          } catch (e) {
            print('❌ $filename manquant: $e');
            totalTracksSkipped++;
            continue; // Passer au fichier suivant
          }

          if (fileExists) {
            // Créer le track seulement si le fichier existe
            final track = Track.local(
              id: trackData['id'],
              title: trackData['title'],
              artist: trackData['artist'],
              duration: Duration(seconds: trackData['duration']),
              thumbnailAsset: trackData['thumbnail']?.isNotEmpty == true
                  ? trackData['thumbnail']
                  : null,
              color: moodColor,
              sourceName: 'Local - $moodName',
              bpm: trackData['bpm'],
              year: trackData['year'],
              genre: trackData['genre'],
              filename: filename,
            );

            moodTracks.add(track);
            _allLocalTracks.add(track);
            totalTracksLoaded++;
          }
        }

        _tracksByMood[moodId] = moodTracks;

        print('🎵 ${moodTracks.length} tracks chargés pour $moodName');
      }

      // Supprimer les doublons (si une track apparaît dans plusieurs humeurs)
      _allLocalTracks = _allLocalTracks.fold<List<Track>>([], (unique, track) {
        if (!unique.any((t) => t.id == track.id)) {
          unique.add(track);
        }
        return unique;
      });

      print('\n📊 Résumé du chargement:');
      print('   ✅ Tracks chargés: $totalTracksLoaded');
      print('   ❌ Tracks ignorés: $totalTracksSkipped');
      print('   🎯 Tracks uniques: ${_allLocalTracks.length}');
      print('   🎭 Humeurs: ${moodPlaylists.length}');

      if (totalTracksSkipped > 0) {
        print('\n⚠️ Attention: $totalTracksSkipped fichiers MP3 manquants!');
        print('   Vérifiez que tous les fichiers listés dans local_playlists.json');
        print('   existent dans les dossiers assets/music/');
      }

      _isInitialized = true;

    } catch (e) {
      print('❌ Erreur chargement local_playlists.json: $e');
      print('🔄 Création de tracks de fallback...');
      _createFallbackTracks();
      _isInitialized = true;
    }
  }

  // Parser une couleur hex en Color
  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor'; // Ajouter alpha
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      print('⚠️ Erreur parsing couleur $hexColor: $e');
      return Colors.grey;
    }
  }

  // Rechercher dans TOUTES les musiques locales
  Future<List<Track>> searchTracks(String query) async {
    if (!_isInitialized) await initialize();

    if (query.isEmpty) return List<Track>.from(_allLocalTracks);

    final lowerQuery = query.toLowerCase();

    return _allLocalTracks.where((track) {
      return track.title.toLowerCase().contains(lowerQuery) ||
          track.artist.toLowerCase().contains(lowerQuery) ||
          (track.genre != null && track.genre!.toLowerCase().contains(lowerQuery)) ||
          track.sourceName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Obtenir des tracks par humeur (ID)
  Future<List<Track>> getTracksByMood(String moodId) async {
    if (!_isInitialized) await initialize();

    return List<Track>.from(_tracksByMood[moodId] ?? []);
  }

  // Obtenir des tracks par humeur (objet Mood)
  Future<List<Track>> getTracksByMoodObject(Mood mood) async {
    return await getTracksByMood(mood.id);
  }

  // Obtenir TOUTES les musiques locales
  Future<List<Track>> getAllTracks() async {
    if (!_isInitialized) await initialize();
    return List<Track>.from(_allLocalTracks);
  }

  // Obtenir les métadonnées d'une humeur
  Map<String, dynamic>? getMoodMetadata(String moodId) {
    return _moodMetadata[moodId];
  }

  // Obtenir toutes les humeurs disponibles localement
  List<String> getAvailableMoods() {
    return _tracksByMood.keys.toList();
  }

  // Obtenir une track par son ID
  Track? getTrackById(String id) {
    try {
      return _allLocalTracks.firstWhere((track) => track.id == id);
    } catch (e) {
      return null;
    }
  }

  // Vérifier si un fichier MP3 existe
  Future<bool> checkFileExists(String filename, String moodId) async {
    try {
      final assetPath = 'assets/music/$moodId/$filename';
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtenir la liste des fichiers manquants
  Future<List<String>> getMissingFiles() async {
    if (!_isInitialized) await initialize();

    final List<String> missingFiles = [];

    for (final moodId in _tracksByMood.keys) {
      final metadata = await rootBundle.loadString('assets/metadata/local_playlists.json');
      final Map<String, dynamic> data = json.decode(metadata);
      final moodPlaylists = data['mood_playlists'] ?? [];

      for (final playlist in moodPlaylists) {
        if (playlist['id'] == moodId) {
          final tracksData = playlist['tracks'] ?? [];
          for (final trackData in tracksData) {
            final filename = trackData['filename'];
            final exists = await checkFileExists(filename, moodId);
            if (!exists) {
              missingFiles.add('$moodId/$filename');
            }
          }
        }
      }
    }

    return missingFiles;
  }

  // Créer des tracks de fallback si le JSON échoue
  void _createFallbackTracks() {
    print('⚠️ Création de tracks de fallback...');

    _allLocalTracks = [
      Track.local(
        id: 'fallback_1',
        title: 'Chill Study Beats',
        artist: 'Lo-fi Radio',
        duration: Duration(minutes: 3, seconds: 30),
        color: Colors.green,
        sourceName: 'Local - Détendu',
        filename: 'fallback_1.mp3',
        bpm: 85,
        year: 2023,
        genre: 'Lo-fi',
      ),
      Track.local(
        id: 'fallback_2',
        title: 'Workout Energy',
        artist: 'Fitness Mix',
        duration: Duration(minutes: 4, seconds: 15),
        color: Colors.orange,
        sourceName: 'Local - Énergique',
        filename: 'fallback_2.mp3',
        bpm: 130,
        year: 2023,
        genre: 'Workout',
      ),
    ];

    _tracksByMood = {
      'happy': [_allLocalTracks[1]],
      'chill': [_allLocalTracks[0]],
      'energetic': [_allLocalTracks[1]],
      'relaxed': [_allLocalTracks[0]],
      'romantic': [_allLocalTracks[0]],
    };

    _moodMetadata = {
      'happy': {
        'name': 'Heureux',
        'emoji': '😊',
        'color': Colors.yellow,
        'genres': ['Pop', 'Disco'],
        'description': 'Musique joyeuse',
      },
      'chill': {
        'name': 'Détendu',
        'emoji': '😌',
        'color': Colors.green,
        'genres': ['Lo-fi', 'Ambient'],
        'description': 'Musique relaxante',
      },
    };

    print('✅ ${_allLocalTracks.length} tracks de fallback créées');
  }

  // Réinitialiser le service
  Future<void> reset() async {
    _allLocalTracks.clear();
    _tracksByMood.clear();
    _moodMetadata.clear();
    _isInitialized = false;
    print('🔄 LocalMusicService réinitialisé');
  }

  // Obtenir des statistiques
  Map<String, dynamic> getStats() {
    return {
      'totalTracks': _allLocalTracks.length,
      'moods': _tracksByMood.length,
      'isInitialized': _isInitialized,
      'tracksByMood': _tracksByMood.map((key, value) =>
          MapEntry(key, value.length)),
    };
  }
}