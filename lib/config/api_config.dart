class ApiConfig {
  // YOUTUBE DATA API v3
  static const String youtubeApiKey = 'AIzaSyBcbmFeLFxZjN40sawegmoIC6n3WxM59CM';

  // Quotas (par défaut gratuit)
  static const int maxDailyQuota = 10000; // unités/jour
  static const int searchCost = 100;      // unités par recherche
  static const int videoCost = 1;         // unités par détail vidéo

  // Limites de cache
  static const int maxCachedTracks = 10;
  static const Duration cacheDuration = Duration(hours: 1);
}

