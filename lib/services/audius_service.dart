import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track.dart';

class AudiusService {
  // Nouveaux hosts (certains peuvent être morts)
  static final List<String> _hosts = [
    'https://discoveryprovider.audius.co',
    'https://discoveryprovider2.audius.co',
    'https://audius-metadata-1.figment.io',
    'https://audius-metadata-2.figment.io',
    'https://audius-discovery-1.cultur3stake.com',
  ];

  Future<List<Track>> searchTracks(String query) async {
    if (query.isEmpty) return [];

    print('🌀 Audius recherche: $query');

    for (final host in _hosts) {
      try {
        final url = Uri.parse('$host/v1/tracks/search?query=${Uri.encodeQueryComponent(query)}');
        print('🔗 Tentative host: $host');

        final response = await http.get(url);
        print('📊 Status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> tracks = data['data'] ?? [];

          print('📈 Tracks trouvés: ${tracks.length}');

          if (tracks.isEmpty) continue;

          final result = tracks.map((item) {
            // Sélectionner la meilleure qualité d'image
            String? artwork;
            if (item['artwork'] != null) {
              artwork = item['artwork']?['150x150'] ??
                  item['artwork']?['480x480'] ??
                  item['artwork']?['1000x1000'];
            }

            // Construire l'URL de streaming
            final trackId = item['id'];
            final streamUrl = '$host/v1/tracks/$trackId/stream';

            return Track(
              id: trackId.toString(),
              title: item['title'] ?? 'Titre inconnu',
              artist: item['user']?['name'] ?? 'Artiste inconnu',
              duration: item['duration'] != null
                  ? Duration(milliseconds: (item['duration'] * 1000).toInt())
                  : null,
              thumbnailUrl: artwork,
              audioUrl: streamUrl,
              source: 'audius',
            );
          }).toList();

          print('✅ Tracks convertis: ${result.length}');
          return result;
        }
      } catch (e) {
        print('❌ Host $host échoué: $e');
        continue;
      }
    }

    print('⚠️ Tous les hosts Audius ont échoué');
    return [];
  }
}