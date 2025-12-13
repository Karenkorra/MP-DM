import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/track.dart';
import '../services/audio_player_service.dart';

class PlayerViewModel extends ChangeNotifier {
  final AudioPlayerService _audioService;

  // ÉTAT
  Track? _currentTrack;
  List<Track> _playlist = [];
  PlayerState _audioState = PlayerState.stopped;
  double _volume = 1.0;
  bool _isShuffled = false;
  bool _isRepeating = false;

  // Variables pour éviter les conflits
  bool _isLoading = false;
  bool _isPlaying = false;
  static const int MAX_PLAYLIST_SIZE = 50;

  // NOUVELLES PROPRIÉTÉS POUR LA PROGRESSION
  Duration? _currentPosition;
  Duration? _currentDuration;

  // STREAMS du service audio
  Stream<Duration> get onPositionChanged => _audioService.onPositionChanged;
  Stream<Duration> get onDurationChanged => _audioService.onDurationChanged;
  Stream<PlayerState> get onStateChanged => _audioService.onStateChanged;

  // GETTERS
  Track? get currentTrack => _currentTrack;
  List<Track> get playlist => _playlist;
  PlayerState get state => _audioState;
  double get volume => _volume;
  bool get isShuffled => _isShuffled;
  bool get isRepeating => _isRepeating;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isPaused => _audioState == PlayerState.paused;
  bool get isStopped => _audioState == PlayerState.stopped;

  // NOUVEAUX GETTERS POUR LA PROGRESSION
  Duration? get currentPosition => _currentPosition;
  Duration? get currentDuration => _currentDuration;

  // Navigation dans la playlist
  bool get hasNext => _playlist.isNotEmpty && _currentTrack != null
      && _playlist.indexOf(_currentTrack!) < _playlist.length - 1;

  bool get hasPrevious => _playlist.isNotEmpty && _currentTrack != null
      && _playlist.indexOf(_currentTrack!) > 0;

  PlayerViewModel(this._audioService) {
    // Configuration des listeners audio
    _setupAudioListeners();

    // Écouter les changements du service audio
    _audioService.onStateChanged.listen((state) {
      _audioState = state;
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    // Écouter la fin d'une piste pour passer à la suivante
    _audioService.onStateChanged.listen((state) {
      if (state == PlayerState.completed && _currentTrack != null) {
        _handleTrackCompletion();
      }
    });
  }

  // NOUVELLE MÉTHODE : Configuration des listeners pour la progression
  void _setupAudioListeners() {
    // Écouter les changements de position
    _audioService.onPositionChanged.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    // Écouter les changements de durée
    _audioService.onDurationChanged.listen((duration) {
      _currentDuration = duration;
      notifyListeners();
    });
  }

  // Gestion de la fin de piste
  void _handleTrackCompletion() {
    if (_isRepeating) {
      // Rejouer la même piste
      if (_currentTrack != null) {
        _playTrackInternal(_currentTrack!);
      }
    } else if (hasNext) {
      // Passer à la piste suivante
      next();
    } else {
      // Arrêter si fin de playlist
      stop();
    }
  }

  // Méthode interne pour jouer une track avec gestion d'erreurs
  Future<void> _playTrackInternal(Track track) async {
    if (_isLoading) {
      print('⚠️ Lecture déjà en cours, ignorer');
      return;
    }

    _isLoading = true;
    _currentTrack = track;
    // Réinitialiser la position
    _currentPosition = Duration.zero;
    notifyListeners();

    try {
      await _audioService.play(track.audioUrl);
      _isPlaying = true;
      print('✅ Lecture démarrée: ${track.title}');
    } catch (e) {
      print('❌ Erreur lecture: $e');
      _currentTrack = null;
      _currentPosition = null;
      _currentDuration = null;
      _isPlaying = false;

      if (e.toString().contains('Unable to load asset') && hasNext) {
        print('🔄 Tentative lecture suivante...');
        await Future.delayed(Duration(milliseconds: 500));
        await next();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ACTIONS
  Future<void> playTrack(Track track) async {
    await _playTrackInternal(track);

    // Ajouter à l'historique si pas déjà dans la playlist
    if (!_playlist.contains(track)) {
      _playlist.insert(0, track);

      // Limiter la taille de la playlist
      if (_playlist.length > MAX_PLAYLIST_SIZE) {
        _playlist.removeRange(MAX_PLAYLIST_SIZE, _playlist.length);
      }
    }
  }

  Future<void> playPlaylist(List<Track> tracks, {int startIndex = 0}) async {
    _playlist = List.from(tracks); // Copie pour éviter les modifications externes
    _isShuffled = false;

    if (tracks.isNotEmpty && startIndex < tracks.length) {
      await _playTrackInternal(tracks[startIndex]);
    }

    notifyListeners();
  }

  Future<void> pause() async {
    if (_isPlaying) {
      await _audioService.pause();
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> resume() async {
    if (!_isPlaying && _currentTrack != null) {
      await _audioService.resume();
      _isPlaying = true;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _audioService.stop();
    _currentTrack = null;
    _currentPosition = null;
    _currentDuration = null;
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> next() async {
    if (_playlist.isEmpty || _currentTrack == null) return;

    final currentIndex = _playlist.indexOf(_currentTrack!);

    if (currentIndex < _playlist.length - 1) {
      await _playTrackInternal(_playlist[currentIndex + 1]);
    } else if (_isRepeating) {
      // Revenir au début si répétition activée
      await _playTrackInternal(_playlist[0]);
    } else {
      // Arrêter si fin de playlist
      await stop();
    }
  }

  Future<void> previous() async {
    if (_playlist.isEmpty || _currentTrack == null) return;

    final currentIndex = _playlist.indexOf(_currentTrack!);

    if (currentIndex > 0) {
      await _playTrackInternal(_playlist[currentIndex - 1]);
    } else if (_isRepeating) {
      // Aller à la fin si répétition activée
      await _playTrackInternal(_playlist[_playlist.length - 1]);
    }
  }

  // MÉTHODE SEEK MIS À JOUR
  Future<void> seek(Duration position) async {
    if (_currentTrack != null) {
      await _audioService.seek(position);
      _currentPosition = position;
      notifyListeners();
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0); // S'assurer que le volume est entre 0 et 1
    await _audioService.setVolume(_volume);
    notifyListeners();
  }

  Future<void> shuffle() async {
    if (_playlist.isEmpty) return;

    final currentTrack = _currentTrack;
    final tempPlaylist = List<Track>.from(_playlist);

    // Garder la piste courante en première position si elle existe
    if (currentTrack != null) {
      tempPlaylist.remove(currentTrack);
      tempPlaylist.shuffle();
      tempPlaylist.insert(0, currentTrack);
    } else {
      tempPlaylist.shuffle();
    }

    _playlist = tempPlaylist;
    _isShuffled = true;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeating = !_isRepeating;
    notifyListeners();
  }

  void clearPlaylist() {
    _playlist.clear();
    _currentTrack = null;
    _currentPosition = null;
    _currentDuration = null;
    _isShuffled = false;
    _isRepeating = false;
    _isPlaying = false;
    notifyListeners();
  }

  void addToPlaylist(Track track) {
    if (!_playlist.contains(track)) {
      _playlist.add(track);

      // Limiter la taille
      if (_playlist.length > MAX_PLAYLIST_SIZE) {
        // Supprimer le premier élément (le plus ancien)
        _playlist.removeAt(0);
      }

      notifyListeners();
    }
  }

  void removeFromPlaylist(Track track) {
    if (_playlist.remove(track)) {
      if (_currentTrack == track) {
        _currentTrack = _playlist.isNotEmpty ? _playlist.first : null;
        _currentPosition = null;
        _currentDuration = null;
      }
      notifyListeners();
    }
  }

  // Vérifier si une track peut être lue
  Future<bool> canPlayTrack(Track track) async {
    if (track.isLocal) {
      try {
        final path = track.audioUrl.replaceFirst('asset://', 'assets/');
        await rootBundle.load(path);
        return true;
      } catch (e) {
        print('⚠️ Track non lisible: ${track.title} - $e');
        return false;
      }
    }
    return true; // Pour les tracks en ligne
  }

  // Obtenir l'index de la track courante
  int get currentTrackIndex {
    if (_currentTrack == null || _playlist.isEmpty) return -1;
    return _playlist.indexOf(_currentTrack!);
  }

  // Obtenir le nombre de tracks dans la playlist
  int get playlistLength => _playlist.length;

  // Vérifier si la playlist est vide
  bool get isPlaylistEmpty => _playlist.isEmpty;

  // Obtenir le prochain track (sans le jouer)
  Track? get nextTrack {
    if (!hasNext) return null;
    final currentIndex = currentTrackIndex;
    return _playlist[currentIndex + 1];
  }

  // Obtenir le track précédent (sans le jouer)
  Track? get previousTrack {
    if (!hasPrevious) return null;
    final currentIndex = currentTrackIndex;
    return _playlist[currentIndex - 1];
  }

  //MÉTHODE : Réinitialiser la progression
  void resetProgress() {
    _currentPosition = Duration.zero;
    _currentDuration = null;
    notifyListeners();
  }

  // MÉTHODE : Obtenir le pourcentage de progression
  double get progressPercentage {
    if (_currentDuration == null || _currentDuration!.inMilliseconds == 0) {
      return 0.0;
    }

    if (_currentPosition == null) {
      return 0.0;
    }

    return _currentPosition!.inMilliseconds / _currentDuration!.inMilliseconds;
  }

  // MÉTHODE : Obtenir le temps restant
  Duration? get remainingTime {
    if (_currentDuration == null || _currentPosition == null) {
      return null;
    }

    final remaining = _currentDuration! - _currentPosition!;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  Future<void> dispose() async {
    await _audioService.dispose();
    _playlist.clear();
    _currentTrack = null;
    _currentPosition = null;
    _currentDuration = null;
    _isPlaying = false;
    _isLoading = false;
    super.dispose();
  }
}