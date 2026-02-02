import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/track.dart';
import '../models/mood.dart';
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

  // FILTRAGE AMÉLIORÉ AVEC SCORING
  List<Track> getFilteredTracks() {
    if (_selectedMood == null) return _tracks;

    final mood = _selectedMood!;
    final filteredTracks = _tracks.where((track) {
      return _calculateMoodScore(track, mood) >= 1; // Seuil minimal
    }).toList();

    // Trier par score décroissant
    filteredTracks.sort((a, b) =>
        _calculateMoodScore(b, mood).compareTo(_calculateMoodScore(a, mood)));

    return filteredTracks;
  }

  // CALCUL DE SCORE POUR CHAQUE TRACK
  int _calculateMoodScore(Track track, Mood mood) {
    int score = 0;

    // 1. Score par genre (3 points pour correspondance exacte, 1 pour partielle)
    if (track.genre != null) {
      final trackGenre = track.genre!.toLowerCase();
      for (final moodGenre in mood.recommendedGenres) {
        final lowerMoodGenre = moodGenre.toLowerCase();
        if (trackGenre == lowerMoodGenre) {
          score += 3;
          break;
        } else if (trackGenre.contains(lowerMoodGenre) ||
            lowerMoodGenre.contains(trackGenre)) {
          score += 1;
          break;
        }
      }
    }

    // 2. Score par BPM selon l'humeur
    if (track.bpm != null) {
      switch (mood.id) {
        case 'energetic':
          if (track.bpm! >= 120) score += 2;
          else if (track.bpm! >= 100) score += 1;
          break;
        case 'chill':
          if (track.bpm! <= 100) score += 2;
          else if (track.bpm! <= 120) score += 1;
          break;
        case 'happy':
          if (track.bpm! >= 100 && track.bpm! <= 140) score += 2;
          break;
        case 'sad':
          if (track.bpm! <= 100) score += 2;
          break;
        case 'romantic':
          if (track.bpm! >= 60 && track.bpm! <= 100) score += 2;
          break;
      }
    }

    // 3. Score par mots-clés dans le titre/artiste
    final lowerTitle = track.title.toLowerCase();
    final lowerArtist = track.artist.toLowerCase();
    final keywords = _getMoodKeywordsForFiltering(mood);

    for (final keyword in keywords) {
      if (lowerTitle.contains(keyword)) {
        score += 2;
      }
      if (lowerArtist.contains(keyword)) {
        score += 1;
      }
    }

    // 4. Bonus pour les tracks locaux (on leur fait confiance)
    if (track.isLocal) {
      score += 1;
    }

    return score;
  }

  // Helper pour obtenir les mots-clés de filtrage
  List<String> _getMoodKeywordsForFiltering(Mood mood) {
    final Map<String, List<String>> moodKeywords = {
      'happy': [
        'happy', 'joy', 'sun', 'sunny', 'summer', 'smile', 'good', 'love',
        'fun', 'party', 'dance', 'celebration', 'upbeat', 'positive',
        'disco', 'funk', 'reggae', 'pop', 'feel good', 'positive'
      ],
      'sad': [
        'sad', 'rain', 'blue', 'cry', 'tears', 'alone', 'hurt', 'lonely',
        'broken', 'miss', 'goodbye', 'pain', 'heartbreak', 'emotional',
        'blues', 'jazz', 'soul', 'acoustic', 'melancholy', 'breakup'
      ],
      'energetic': [
        'energy', 'power', 'strong', 'fire', 'fast', 'pump', 'workout',
        'run', 'gym', 'intense', 'adrenaline', 'explosive', 'powerful',
        'rock', 'metal', 'edm', 'hip hop', 'electronic', 'motivational'
      ],
      'chill': [
        'chill', 'calm', 'relax', 'peace', 'quiet', 'slow', 'meditation',
        'study', 'focus', 'ambient', 'lo-fi', 'sleep', 'peaceful',
        'ambient', 'chillout', 'jazz', 'relaxing', 'study', 'background'
      ],
      'romantic': [
        'love', 'romantic', 'heart', 'kiss', 'night', 'moon', 'stars',
        'together', 'forever', 'baby', 'darling', 'sweet', 'date',
        'r&b', 'soul', 'classical', 'ballad', 'intimate', 'slow dance'
      ],
    };

    return moodKeywords[mood.id] ?? [mood.name.toLowerCase()];
  }

  // Mots-clés étendus pour la recherche en ligne
  List<String> _getSearchKeywordsForMood(Mood mood) {
    final Map<String, List<String>> moodSearchKeywords = {
      'happy': [
        'happy music', 'joyful songs', 'upbeat pop', 'summer vibes',
        'dance music', 'feel good hits', 'positive vibes', 'celebration',
        'party music', 'disco hits', 'funk groove', 'reggae sunshine'
      ],
      'sad': [
        'sad songs', 'emotional music', 'heartbreak ballads', 'melancholy',
        'blues music', 'acoustic sad', 'rainy day music', 'lonely nights',
        'piano ballads', 'breakup songs', 'emotional indie', 'soulful blues'
      ],
      'energetic': [
        'workout music', 'energy boost', 'high intensity', 'powerful rock',
        'motivational songs', 'gym workout', 'running music', 'epic rock',
        'action music', 'rock workout', 'electronic dance', 'metal power'
      ],
      'chill': [
        'chill beats', 'relaxing music', 'study focus', 'calm ambient',
        'meditation music', 'peaceful sounds', 'background music',
        'lo-fi hip hop', 'smooth jazz', 'ambient study', 'calming piano'
      ],
      'romantic': [
        'love songs', 'romantic music', 'slow dance', 'intimate ballads',
        'date night music', 'wedding songs', 'soft love', 'smooth r&b',
        'romantic jazz', 'love ballads', 'sentimental', 'romantic piano'
      ],
    };

    return moodSearchKeywords[mood.id] ?? [mood.name];
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

      // couleurs hexadécimales
      Color parseColor(String hexColor) {
        hexColor = hexColor.replaceAll('#', '');
        if (hexColor.length == 6) {
          hexColor = 'FF$hexColor';
        }
        return Color(int.parse(hexColor, radix: 16));
      }

      return Mood(
        id: id,
        name: metadata?['name'] ?? id,
        emoji: metadata?['emoji'] ?? '🎵',
        color: metadata?['color'] != null
            ? parseColor(metadata!['color'])
            : _getDefaultMoodColor(id),
        recommendedGenres: _getExtendedGenresForMood(id, metadata?['genres']),
        createdAt: DateTime.now(),
      );
    }).toList();

    print('🎭 ${_availableMoods.length} humeurs locales chargées');
  }

  // Générer des genres étendus pour chaque humeur
  List<String> _getExtendedGenresForMood(String moodId, List<dynamic>? baseGenres) {
    final Map<String, List<String>> extendedGenres = {
      'happy': [
        'Pop', 'Disco', 'Funk', 'Reggae', 'Ska', 'Dance',
        'Electropop', 'Indie Pop', 'Synthpop', 'Tropical House',
        'Bubblegum Pop', 'Dancehall', 'Afrobeat', 'Latin Pop'
      ],
      'sad': [
        'Blues', 'Jazz', 'Soul', 'Acoustic', 'Folk', 'Indie Folk',
        'Singer-Songwriter', 'Piano', 'Ambient', 'Slowcore',
        'Post-rock', 'Dream Pop', 'Alternative R&B', 'Emo'
      ],
      'energetic': [
        'Rock', 'Metal', 'EDM', 'Hip Hop', 'Electronic', 'Punk',
        'Hard Rock', 'Techno', 'House', 'Trap', 'Dubstep',
        'Hardstyle', 'Rockabilly', 'Power Metal', 'Rap'
      ],
      'chill': [
        'Lo-fi', 'Ambient', 'Chillout', 'Jazz', 'Downtempo',
        'Trip Hop', 'Acid Jazz', 'Smooth Jazz', 'Chillwave',
        'Vaporwave', 'Synthwave', 'New Age', 'Acoustic'
      ],
      'romantic': [
        'R&B', 'Soul', 'Classical', 'Pop Ballad', 'Smooth Jazz',
        'Neo Soul', 'Contemporary R&B', 'Piano Ballads',
        'Orchestral', 'Cinematic', 'Romantic Classical', 'Soft Rock'
      ],
    };

    // Utiliser les genres étendus ou les baseGenres s'ils existent
    if (baseGenres != null && baseGenres.isNotEmpty) {
      return List<String>.from(baseGenres);
    }

    return extendedGenres[moodId] ?? [moodId];
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
      case 'relaxed':
      case 'chill':
        return Colors.green;
      case 'romantic':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  // RECHERCHE COMBINÉE AMÉLIORÉE
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

    // Chercher dans toutes les sources
    List<Track> localTracks = [];
    List<Track> deviceTracks = [];
    try {
      // 1. Musiques locales (assets)
      localTracks = await _localMusicService.searchTracks(query);
      print('📱 ${localTracks.length} musiques locales trouvées');
    } catch (e) {
      print('⚠️ Erreur recherche locale: $e');
    }

    // Si hors ligne, locales seulement + device
    if (!_isOnline) {
      _tracks = [...localTracks, ...deviceTracks];
      _errorMessage = _tracks.isEmpty ? 'Aucune musique trouvée hors ligne' : null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Si en ligne: combiner avec les APIs
    try {
      print('🌐 Recherche sur APIs...');

      final futures = <Future<List<Track>>>[
        _audiusService.searchTracks(query),
        _jamendoService.searchTracks(query),
      ];

      final results = await Future.wait(futures, eagerError: true);

      // Combiner toutes les pistes
      final List<Track> allTracks =  [...localTracks, ...deviceTracks];
      for (final result in results) {
        allTracks.addAll(result);
      }

      // Supprimer les doublons et mélanger
      _tracks = _removeDuplicates(allTracks);
      _tracks.shuffle();
      _errorMessage = null;

      print('✅ Total: ${_tracks.length} pistes (${localTracks.length} locales, ${deviceTracks.length} device)');

    } catch (e) {
      print('⚠️ Erreur APIs, fallback local: $e');
      _tracks = [...localTracks, ...deviceTracks];
      _errorMessage = _tracks.isEmpty
          ? 'Erreur connexion et aucune locale trouvée'
          : 'Connexion limitée - Musiques locales seulement';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // SUPPRIMER LES DOUBLONS
  List<Track> _removeDuplicates(List<Track> tracks) {
    final Map<String, Track> uniqueTracks = {};

    for (final track in tracks) {
      // Créer une clé unique basée sur le titre et l'artiste
      final key = '${track.title.toLowerCase()}_${track.artist.toLowerCase()}';
      if (!uniqueTracks.containsKey(key)) {
        uniqueTracks[key] = track;
      }
    }

    return uniqueTracks.values.toList();
  }


  // SÉLECTION D'HUMEUR AMÉLIORÉE
  Future<void> selectMood(Mood mood) async {
    _selectedMood = mood;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Charger les locales pour cette humeur
      final localTracks = await _localMusicService.getTracksByMoodObject(mood);
      print('📱 ${localTracks.length} locales pour humeur ${mood.name}');

      // 2. Si en ligne, chercher sur les APIs avec MULTIPLES genres
      List<Track> onlineTracks = [];
      if (_isOnline) {
        try {
          onlineTracks = await _searchMultipleGenresOnline(mood);
          print('🌐 ${onlineTracks.length} pistes online pour ${mood.name}');
        } catch (e) {
          print('⚠️ Erreur APIs pour humeur ${mood.name}: $e');
        }
      }

      // 3. Ajouter des mots-clés liés à l'humeur
      List<Track> keywordTracks = [];
      if (_isOnline) {
        try {
          keywordTracks = await _searchByMoodKeywords(mood);
          print('🔍 ${keywordTracks.length} pistes par mots-clés pour ${mood.name}');
        } catch (e) {
          print('⚠️ Erreur recherche mots-clés: $e');
        }
      }

      // 4. Combiner toutes les pistes
      _tracks = [...localTracks, ...onlineTracks, ...keywordTracks];

      // Supprimer les doublons et mélanger
      _tracks = _removeDuplicates(_tracks);
      _tracks.shuffle();

      if (_tracks.isEmpty) {
        _errorMessage = 'Aucune musique trouvée pour cette humeur';
      } else {
        print('✅ Total ${_tracks.length} pistes pour humeur ${mood.name}');
        print('   - Locales: ${localTracks.length}');
        print('   - Online (genres): ${onlineTracks.length}');
        print('   - Online (mots-clés): ${keywordTracks.length}');
      }

    } catch (e) {
      _errorMessage = 'Erreur chargement humeur: $e';
      _tracks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // NOUVELLE MÉTHODE: Rechercher avec plusieurs genres
  Future<List<Track>> _searchMultipleGenresOnline(Mood mood) async {
    List<Track> allTracks = [];

    // Utiliser les genres étendus (jusqu'à 8)
    final genresToSearch = _getExtendedGenresForMood(mood.id, mood.recommendedGenres);
    final selectedGenres = genresToSearch.take(min(8, genresToSearch.length)).toList();

    print('🔍 Recherche avec ${selectedGenres.length} genres pour ${mood.name}');

    for (final genre in selectedGenres) {
      try {
        final futures = <Future<List<Track>>>[
          _audiusService.searchTracks(genre),
          _jamendoService.searchTracks(genre),
        ];

        final results = await Future.wait(futures, eagerError: false);

        for (final result in results) {
          // Prendre 2-4 pistes par genre pour éviter la surcharge
          final random = Random();
          final count = random.nextInt(3) + 2; // Entre 2 et 4
          allTracks.addAll(result.take(count));
        }

        print('   Genre "$genre": ${results.fold(0, (sum, list) => sum + list.length)} pistes trouvées');

        // Petite pause entre les requêtes pour éviter le rate limiting
        await Future.delayed(Duration(milliseconds: 100));

      } catch (e) {
        print('⚠️ Erreur avec genre "$genre": $e');
        continue;
      }
    }

    return allTracks;
  }

  // NOUVELLE MÉTHODE: Rechercher par mots-clés d'humeur
  Future<List<Track>> _searchByMoodKeywords(Mood mood) async {
    List<Track> allTracks = [];

    // Récupérer les mots-clés associés à l'humeur
    final keywords = _getSearchKeywordsForMood(mood);

    // Utiliser les 4 premiers mots-clés
    for (final keyword in keywords.take(4)) {
      try {
        final futures = <Future<List<Track>>>[
          _audiusService.searchTracks(keyword),
          _jamendoService.searchTracks(keyword),
        ];

        final results = await Future.wait(futures, eagerError: false);

        for (final result in results) {
          // Prendre 1-2 pistes par mot-clé
          final random = Random();
          final count = random.nextInt(2) + 1; // Entre 1 et 2
          allTracks.addAll(result.take(count));
        }

        // Petite pause entre les requêtes
        await Future.delayed(Duration(milliseconds: 100));

      } catch (e) {
        print('⚠️ Erreur avec mot-clé "$keyword": $e');
        continue;
      }
    }

    return allTracks;
  }

  // Ajouter un getter pour les musiques du téléphone
  List<Track> getDeviceTracksOnly() {
    return _tracks.where((track) => track.source == 'device').toList();
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
    _availableMoods = Mood.predefinedMoods.map((mood) {
      return Mood(
        id: mood.id,
        name: mood.name,
        emoji: mood.emoji,
        color: mood.color,
        recommendedGenres: _getExtendedGenresForMood(mood.id, mood.recommendedGenres),
        createdAt: mood.createdAt,
      );
    }).toList();

    print('🎭 ${_availableMoods.length} humeurs prédéfinies chargées (genres étendus)');
    notifyListeners();
  }

  // Vérifier la connexion
  Future<void> checkConnectivity() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(Duration(seconds: 5));
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

  // Méthode pour sélectionner une humeur par son ID
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
    final moodStats = _selectedMood != null ? {
      'moodName': _selectedMood!.name,
      'moodScoreAverage': _tracks.isEmpty ? 0 :
      _tracks.map((t) => _calculateMoodScore(t, _selectedMood!))
          .fold(0, (a, b) => a + b) / _tracks.length,
      'genreDistribution': _getGenreDistribution(),
    } : null;

    return {
      'total': _tracks.length,
      'local': getLocalTracksOnly().length,
      'online': getOnlineTracksOnly().length,
      'bySource': getTrackCountBySource(),
      'hasMoodSelected': _selectedMood != null,
      'moodStats': moodStats,
    };
  }

  // Distribution des genres pour l'humeur sélectionnée
  Map<String, int> _getGenreDistribution() {
    final Map<String, int> distribution = {};

    if (_selectedMood == null) return distribution;

    for (final track in _tracks) {
      if (track.genre != null) {
        final genre = track.genre!;
        distribution[genre] = (distribution[genre] ?? 0) + 1;
      }
    }

    return distribution;
  }

  // NOUVELLE MÉTHODE: Obtenir les tracks triés par score
  List<Track> getTracksSortedByMoodScore() {
    if (_selectedMood == null) return _tracks;

    final sorted = List<Track>.from(_tracks);
    sorted.sort((a, b) =>
        _calculateMoodScore(b, _selectedMood!).compareTo(_calculateMoodScore(a, _selectedMood!)));

    return sorted;
  }

  // NOUVELLE MÉTHODE: Obtenir les meilleures tracks pour l'humeur (top 10)
  List<Track> getTopMoodTracks({int limit = 10}) {
    if (_selectedMood == null) return _tracks.take(limit).toList();

    final sorted = getTracksSortedByMoodScore();
    return sorted.take(min(limit, sorted.length)).toList();
  }

  // NOUVELLE MÉTHODE: Recherche enrichie par humeur (pour le futur)
  Future<void> enhancedMoodSearch(Mood mood, {List<String>? additionalKeywords}) async {
    _selectedMood = mood;
    _isLoading = true;
    notifyListeners();

    try {
      // Combinaison de toutes les stratégies
      final List<Track> combinedTracks = [];

      // 1. Tracks locales
      combinedTracks.addAll(await _localMusicService.getTracksByMoodObject(mood));

      // 2. Tracks par genres
      if (_isOnline) {
        combinedTracks.addAll(await _searchMultipleGenresOnline(mood));
      }

      // 3. Tracks par mots-clés
      if (_isOnline) {
        combinedTracks.addAll(await _searchByMoodKeywords(mood));

        // Recherche par mots-clés supplémentaires
        if (additionalKeywords != null) {
          for (final keyword in additionalKeywords) {
            try {
              final results = await Future.wait([
                _audiusService.searchTracks(keyword),
              ]);

              for (final result in results) {
                combinedTracks.addAll(result.take(2));
              }
            } catch (e) {
              print('⚠️ Erreur recherche mot-clé "$keyword": $e');
            }
          }
        }
      }

      // Traitement final
      _tracks = _removeDuplicates(combinedTracks);

      // Trier par score de pertinence
      _tracks.sort((a, b) =>
          _calculateMoodScore(b, mood).compareTo(_calculateMoodScore(a, mood)));

      print('🎯 Recherche enrichie: ${_tracks.length} pistes pour ${mood.name}');

    } catch (e) {
      _errorMessage = 'Erreur recherche enrichie: $e';
      _tracks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Disposer les ressources
  @override
  void dispose() {
    _tracks.clear();
    _availableMoods.clear();
    super.dispose();
  }
}