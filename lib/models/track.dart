import 'package:flutter/cupertino.dart';

class Track {
  final String id;
  final String title;
  final String artist;
  final Duration? duration;
  final String? thumbnailUrl;
  final String audioUrl;
  final String source;
  final bool isLocal;
  final Color color;
  final String sourceName;
  final int? bpm;
  final int? year;
  final String? genre;
  final String? youtubeVideoId;

  // Crée un Track et applique les valeurs par défaut si nécessaire.
  Track({
    required this.id,
    required this.title,
    required this.artist,
    this.duration,
    this.thumbnailUrl,
    required this.audioUrl,
    required this.source,
    this.isLocal = false,
    Color? color,
    String? sourceName,
    this.bpm,
    this.year,
    this.genre,
    this.youtubeVideoId,
  })  : color = color ?? _getDefaultColor(source),
        sourceName = sourceName ?? _getDefaultSourceName(source);

  // Factory pour créer un track local avec toutes les infos
  factory Track.local({
    required String id,
    required String title,
    required String artist,
    Duration? duration,
    String? thumbnailAsset,
    Color? color,
    String? sourceName,
    int? bpm,
    int? year,
    String? genre,
    required String filename,
  }) {
    // Déduire le dossier mood depuis l'ID (ex: "happy_1" -> "happy")
    final moodFolder = id.split('_')[0];

    return Track(
      id: id,
      title: title,
      artist: artist,
      duration: duration,
      thumbnailUrl: thumbnailAsset,
      audioUrl: 'asset://music/$moodFolder/$filename',
      source: 'local',
      isLocal: true,
      color: color ?? const Color(0xFF4CAF50),
      sourceName: sourceName ?? 'Local',
      bpm: bpm,
      year: year,
      genre: genre,
    );
  }

  // Factory pour créer un track depuis une source externe
  factory Track.fromSource({
    required String id,
    required String title,
    required String artist,
    Duration? duration,
    String? thumbnailUrl,
    required String audioUrl,
    required String source,
    Color? color,
    String? sourceName,
    int? bpm,
    int? year,
    String? genre,
    String? youtubeVideoId,
  }) {
    return Track(
      id: id,
      title: title,
      artist: artist,
      duration: duration,
      thumbnailUrl: thumbnailUrl,
      audioUrl: audioUrl,
      source: source,
      isLocal: false,
      color: color,
      sourceName: sourceName,
      bpm: bpm,
      year: year,
      genre: genre,
      youtubeVideoId: youtubeVideoId,
    );
  }

  //MÉTHODE POUR YOUTUBE
  factory Track.youtube({
    required String videoId,
    required String title,
    required String artist,
    Duration? duration,
    String? thumbnailUrl,
    int? bpm,
    int? year,
    String? genre,
  }) {
    return Track(
      id: 'youtube_$videoId',
      title: title,
      artist: artist,
      duration: duration,
      thumbnailUrl: thumbnailUrl,
      audioUrl: 'https://www.youtube.com/watch?v=$videoId',
      source: 'youtube',
      isLocal: false,
      color: const Color(0xFFFF0000),
      sourceName: 'YouTube',
      bpm: bpm,
      year: year,
      genre: genre,
      youtubeVideoId: videoId,
    );
  }

  // Méthodes statiques pour retourner la couleur selon la source.
  static Color _getDefaultColor(String source) {
    switch (source.toLowerCase()) {
      case 'soundcloud':
        return const Color(0xFFFF5500); //SoundCloud
      case 'audius':
        return const Color(0xFF1E88E5); //Audius
      case 'jamendo':
        return const Color(0xFF9C27B0); //Jamendo
      case 'local':
        return const Color(0xFF9C27B0); //local
      case 'spotify':
        return const Color(0xFF1DB954); //Spotify
      case 'youtube':
        return const Color(0xFFFF0000); //YouTube
      default:
        return const Color(0xFF607D8B); // Gris par défaut
    }
  }

  // Retourne le nom lisible de la source.
  static String _getDefaultSourceName(String source) {
    switch (source.toLowerCase()) {
      case 'soundcloud':
        return 'SoundCloud';
      case 'audius':
        return 'Audius';
      case 'jamendo':
        return 'Jamendo';
      case 'local':
        return 'Local';
      case 'spotify':
        return 'Spotify';
      case 'youtube':
        return 'YouTube';
      default:
        return source;
    }
  }

  //Vérifier si c'est une track YouTube
  bool get isYouTube => source.toLowerCase() == 'youtube';

  //Obtenir l'ID vidéo YouTube
  String? get youtubeId {
    if (isYouTube) {
      // Essayer d'extraire de l'URL ou utiliser youtubeVideoId
      if (youtubeVideoId != null) return youtubeVideoId;

      final regExp = RegExp(
        r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      );
      final match = regExp.firstMatch(audioUrl);
      return match?.group(1);
    }
    return null;
  }

  // Méthode pour vérifier si c'est un asset local
  bool get isAsset => audioUrl.startsWith('asset://');

  // Méthode pour obtenir le vrai chemin de l'asset
  String get assetPath {
    if (isAsset) {
      return audioUrl.replaceFirst('asset://', '');
    }
    return audioUrl;
  }

  // Méthode pour convertir en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'duration': duration?.inSeconds,
      'thumbnailUrl': thumbnailUrl,
      'audioUrl': audioUrl,
      'source': source,
      'isLocal': isLocal,
      'bpm': bpm,
      'year': year,
      'genre': genre,
      'youtubeVideoId': youtubeVideoId,
    };
  }

  // Crée un Track depuis une Map.
  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      duration: map['duration'] != null
          ? Duration(seconds: map['duration'] as int)
          : null,
      thumbnailUrl: map['thumbnailUrl'],
      audioUrl: map['audioUrl'] ?? '',
      source: map['source'] ?? 'unknown',
      isLocal: map['isLocal'] ?? false,
      bpm: map['bpm'],
      year: map['year'],
      genre: map['genre'],
      youtubeVideoId: map['youtubeVideoId'],
    );
  }

  // Copie le Track avec des valeurs modifiées.
  Track copyWith({
    String? id,
    String? title,
    String? artist,
    Duration? duration,
    String? thumbnailUrl,
    String? audioUrl,
    String? source,
    bool? isLocal,
    Color? color,
    String? sourceName,
    int? bpm,
    int? year,
    String? genre,
    String? youtubeVideoId,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      source: source ?? this.source,
      isLocal: isLocal ?? this.isLocal,
      color: color ?? this.color,
      sourceName: sourceName ?? this.sourceName,
      bpm: bpm ?? this.bpm,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
    );
  }

  // Pour le debug
  @override
  String toString() {
    return 'Track{id: $id, title: $title, artist: $artist, source: $source, isYouTube: $isYouTube}';
  }

  // Pour comparer deux tracks
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Track && other.id == id && other.source == source;
  }

  // Génère le hash du Track.
  @override
  int get hashCode => id.hashCode ^ source.hashCode;
}