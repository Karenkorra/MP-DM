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
    );
  }

  // Méthodes statiques pour retourner la couleur selon la source.
  static Color _getDefaultColor(String source) {
    switch (source.toLowerCase()) {
      case 'soundcloud':
        return const Color(0xFFFF5500); // Orange SoundCloud
      case 'audius':
        return const Color(0xFF1E88E5); // Bleu Audius
      case 'jamendo':
        return const Color(0xFF9C27B0); // Violet Jamendo
      case 'local':
        return const Color(0xFF4CAF50); // Vert pour local
      case 'spotify':
        return const Color(0xFF1DB954); // Vert Spotify
      case 'youtube':
        return const Color(0xFFFF0000); // Rouge YouTube
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
    );
  }

  // Pour le debug
  @override
  String toString() {
    return 'Track{id: $id, title: $title, artist: $artist, source: $source, isLocal: $isLocal}';
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