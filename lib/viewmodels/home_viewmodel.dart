import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/track.dart';
import '../models/mood.dart';
import '../services/soundcloud_service.dart';
import '../services/audius_service.dart';
import '../services/jamendo_service.dart';
import '../services/local_music_service.dart';

class HomeViewModel extends ChangeNotifier {
  // ÉTAT
  List<Track> _tracks = [];
  Mood? _selectedMood;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOnline = true;
  List<Mood> _availableMoods = [];

  // SERVICES
  final SoundCloudService _soundCloudService = SoundCloudService();
  final AudiusService _audiusService = AudiusService();
  final JamendoService _jamendoService = JamendoService();
  final LocalMusicService _localMusicService = LocalMusicService();

  // GETTERS
  List<Track> get tracks => _tracks;
  Mood? get selectedMood => _selectedMood;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  bool get isOnline => _isOnline;
  List<Mood> get availableMoods => _availableMoods;

  // NOUVELLE MÉTHODE: Obtenir les tracks filtrés selon le mood sélectionné
  List<Track> getFilteredTracks() {
    // Si aucun mood sélectionné, retourner tous les tracks
    if (_selectedMood == null) return _tracks;

    final mood = _selectedMood!;
    final moodKeywords = _getMoodKeywordsForFiltering(mood);

    return _tracks.where((track) {
      // 1. Vérifier par genre (si disponible)
      if (track.genre != null && mood.recommendedGenres.contains(track.genre)) {
        return true;
      }

      // 2. Vérifier par mots-clés dans titre/artiste
      final title = track.title.toLowerCase();
      final artist = track.artist.toLowerCase();

      for (final keyword in moodKeywords) {
        if (title.contains(keyword) || artist.contains(keyword)) {
          return true;
        }
      }

      // 3. Pour les tracks locaux, vérifier le BPM pour certaines humeurs
      if (track.bpm != null) {
        if (mood.id == 'energetic' && track.bpm! > 120) return true;
        if (mood.id == 'chill' && track.bpm! < 100) return true;
      }

      // 4. Pour les tracks locaux de votre JSON, ils sont déjà associés à un mood
      // Le LocalMusicService les a déjà filtrés, donc on les inclut tous
      if (track.isLocal) {
        // On suppose que les tracks locaux retournés par getTracksByMoodObject
        // sont déjà corrects pour le mood
        return true;
      }

      return false;
    }).toList();
  }

  // Helper pour obtenir les mots-clés de filtrage
  List<String> _getMoodKeywordsForFiltering(Mood mood) {
    final Map<String, List<String>> moodKeywords = {
      'happy': [
        'happy', 'joy', 'sun', 'sunny', 'summer', 'smile', 'good', 'love',
        'fun', 'party', 'dance', 'celebration', 'upbeat', 'positive',
        'disco', 'funk', 'reggae', 'pop'
      ],
      'sad': [
        'sad', 'rain', 'blue', 'cry', 'tears', 'alone', 'hurt', 'lonely',
        'broken', 'miss', 'goodbye', 'pain', 'heartbreak',
        'blues', 'jazz', 'soul', 'acoustic'
      ],
      'energetic': [
        'energy', 'power', 'strong', 'fire', 'fast', 'pump', 'workout',
        'run', 'gym', 'intense', 'adrenaline', 'explosive', 'powerful',
        'rock', 'metal', 'edm', 'hip hop', 'electronic'
      ],
      'chill': [
        'chill', 'calm', 'relax', 'peace', 'quiet', 'slow', 'meditation',
        'study', 'focus', 'ambient', 'lo-fi', 'sleep', 'peaceful',
        'ambient', 'chillout', 'jazz'
      ],
      'romantic': [
        'love', 'romantic', 'heart', 'kiss', 'night', 'moon', 'stars',
        'together', 'forever', 'baby', 'darling', 'sweet', 'date',
        'r&b', 'soul', 'classical', 'ballad'
      ],
    };

    return moodKeywords[mood.id] ?? [mood.name.toLowerCase()];
  }

  // Initialiser
  Future<void> initialize() async {
    await _localMusicService.initialize();
    _loadAvailableMoods();
  }

  // Charger les humeurs disponibles depuis les locales
  void _loadAvailableMoods() {
    final moodIds = _localMusicService.getAvailableMoods();

    _availableMoods = moodIds.map((id) {
      final metadata = _localMusicService.getMoodMetadata(id);

      // Utiliser les couleurs hexadécimales de votre JSON
      Color parseColor(String hexColor) {
        hexColor = hexColor.replaceAll('#', '');
        if (hexColor.length == 6) {
          hexColor = 'FF$hexColor'; // Ajouter alpha
        }
        return Color(int.parse(hexColor, radix: 16));
      }

      return Mood(
        id: id,
        name: metadata?['name'] ?? id,
        emoji: metadata?['emoji'] ?? '🎵',
        color: metadata?['color'] != null
            ? parseColor(metadata!['color'])  // metadata['color'] est déjà une Color, pas un String
            : _getDefaultMoodColor(id),
        recommendedGenres: List<String>.from(metadata?['genres'] ?? []),
        createdAt: DateTime.now(),
      );
    }).toList();

    print('🎭 ${_availableMoods.length} humeurs locales chargées');
  }

  // Méthode pour obtenir une couleur par défaut selon l'ID de l'humeur
  Color _getDefaultMoodColor(String moodId) {
    switch (moodId) {
      case 'happy':
        return Colors.yellow;
      case 'sad':
        return Colors.blue;
      case 'energetic':
        return Colors.orange;
      case 'relaxed': // Note: dans votre JSON c'est "relaxed", dans Mood c'est "chill"
      case 'chill':
        return Colors.green;
      case 'romantic':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  // ACTIONS - Recherche qui combine locales + APIs
  Future<void> searchTracks(String query) async {
    if (query.isEmpty) {
      _tracks.clear();
      notifyListeners();
      return;
    }

    _searchQuery = query;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await checkConnectivity();

    // TOUJOURS chercher dans les locales
    List<Track> localTracks = [];
    try {
      localTracks = await _localMusicService.searchTracks(query);
      print('📱 ${localTracks.length} musiques locales trouvées');
    } catch (e) {
      print('⚠️ Erreur recherche locale: $e');
    }

    // Si hors ligne, locales seulement
    if (!_isOnline) {
      _tracks = localTracks;
      _errorMessage = _tracks.isEmpty ? 'Aucune musique trouvée hors ligne' : null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Si en ligne: combiner avec les APIs
    try {
      print('🌐 Recherche sur APIs...');

      final futures = <Future<List<Track>>>[
        _soundCloudService.searchTracks(query),
        _audiusService.searchTracks(query),
        _jamendoService.searchTracks(query),
      ];

      final results = await Future.wait(futures, eagerError: true);

      // Combiner toutes les pistes
      final List<Track> allTracks = [...localTracks];
      for (final result in results) {
        allTracks.addAll(result);
      }

      // Mélanger et marquer les locales
      allTracks.shuffle();
      _tracks = allTracks;
      _errorMessage = null;

      print('✅ Total: ${_tracks.length} pistes (${localTracks.length} locales)');

    } catch (e) {
      print('⚠️ Erreur APIs, fallback local: $e');
      _tracks = localTracks;
      _errorMessage = _tracks.isEmpty
          ? 'Erreur connexion et aucune locale trouvée'
          : 'Connexion limitée - Musiques locales seulement';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sélectionner une humeur (locales + online si disponible)
  Future<void> selectMood(Mood mood) async {
    _selectedMood = mood;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Charger les locales pour cette humeur
      final localTracks = await _localMusicService.getTracksByMoodObject(mood);
      print('📱 ${localTracks.length} locales pour humeur ${mood.name}');

      // 2. Si en ligne, chercher aussi sur APIs avec les genres recommandés
      List<Track> onlineTracks = [];
      if (_isOnline && mood.recommendedGenres.isNotEmpty) {
        try {
          // Prendre le premier genre pour la recherche
          final genre = mood.recommendedGenres.first;
          final futures = <Future<List<Track>>>[
            _soundCloudService.searchTracks(genre),
            _audiusService.searchTracks(genre),
            _jamendoService.searchTracks(genre),
          ];

          final results = await Future.wait(futures, eagerError: true);
          for (final result in results) {
            onlineTracks.addAll(result.take(5)); // Limiter à 5 par API
          }
          print('🌐 ${onlineTracks.length} pistes online pour ${mood.name}');
        } catch (e) {
          print('⚠️ Erreur APIs pour humeur ${mood.name}: $e');
        }
      }

      // 3. Combiner et mélanger
      _tracks = [...localTracks, ...onlineTracks];
      _tracks.shuffle();

      if (_tracks.isEmpty) {
        _errorMessage = 'Aucune musique trouvée pour cette humeur';
      }

    } catch (e) {
      _errorMessage = 'Erreur chargement humeur: $e';
      _tracks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger TOUTES les locales (pour un bouton "Musiques locales")
  Future<void> loadAllLocalTracks() async {
    _selectedMood = null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tracks = await _localMusicService.getAllTracks();
      _tracks.shuffle();

      if (_tracks.isEmpty) {
        _errorMessage = 'Aucune musique locale disponible';
      } else {
        print('📱 ${_tracks.length} musiques locales chargées');
      }
    } catch (e) {
      _errorMessage = 'Erreur chargement musiques locales: $e';
      _tracks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger les humeurs prédéfinies
  void loadPredefinedMoods() {
    _availableMoods = Mood.predefinedMoods;
    print('🎭 ${_availableMoods.length} humeurs prédéfinies chargées');
    notifyListeners();
  }

  // Vérifier la connexion
  Future<void> checkConnectivity() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com'));
      _isOnline = response.statusCode == 200;
      print(_isOnline ? '✅ Connecté à Internet' : '📴 Hors ligne');
    } catch (e) {
      _isOnline = false;
      print('📴 Hors ligne: $e');
    }
    notifyListeners();
  }

  void clearMood() {
    _selectedMood = null;
    _tracks.clear();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _tracks.clear();
    notifyListeners();
  }

  Future<void> refreshConnectivity() async {
    await checkConnectivity();
  }

  // Nouvelle méthode pour sélectionner une humeur par son ID
  Future<void> selectMoodById(String moodId) async {
    final mood = _availableMoods.firstWhere(
          (m) => m.id == moodId,
      orElse: () => Mood.predefinedMoods.firstWhere(
            (m) => m.id == moodId,
        orElse: () => Mood.predefinedMoods.first,
      ),
    );
    await selectMood(mood);
  }

  // Méthode pour obtenir toutes les pistes (utile pour le player)
  List<Track> getAllTracksForPlayer() {
    return List<Track>.from(_tracks);
  }

  // Méthode pour filtrer par source
  List<Track> getTracksBySource(String source) {
    return _tracks.where((track) => track.source == source).toList();
  }

  // Méthode pour obtenir seulement les locales
  List<Track> getLocalTracksOnly() {
    return _tracks.where((track) => track.isLocal).toList();
  }

  // Méthode pour obtenir seulement les online
  List<Track> getOnlineTracksOnly() {
    return _tracks.where((track) => !track.isLocal).toList();
  }

  // Méthode pour obtenir le nombre de tracks par source
  Map<String, int> getTrackCountBySource() {
    final Map<String, int> counts = {};
    for (final track in _tracks) {
      counts[track.source] = (counts[track.source] ?? 0) + 1;
    }
    return counts;
  }

  // Méthode pour obtenir les statistiques
  Map<String, dynamic> getStats() {
    return {
      'total': _tracks.length,
      'local': getLocalTracksOnly().length,
      'online': getOnlineTracksOnly().length,
      'bySource': getTrackCountBySource(),
      'hasMoodSelected': _selectedMood != null,
    };
  }

  // Disposer les ressources
  @override
  void dispose() {
    _tracks.clear();
    _availableMoods.clear();
    super.dispose();
  }
}