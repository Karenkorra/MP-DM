import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/track.dart';

class SoundCloudService {
  // Clé client officielle
  static const String _clientId = 'iZIs9mchVcX5lhVRyQGGAYlNPVldzAoX';

  Future<List<Track>> searchTracks(String query) async {
    if (query.isEmpty) return [];

    print('🎵 SoundCloud recherche: "$query"');

    try {

      final url = Uri.parse(
          'https://api-v2.soundcloud.com/search/tracks'
              '?q=${Uri.encodeQueryComponent(query)}'
              '&client_id=$_clientId'
              '&limit=8'
              '&offset=0'
              '&linked_partitioning=1'
      );

      print('🔗 URL SoundCloud: $url');

      final response = await http.get(url);
      print('📊 Status SoundCloud: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> tracks = data['collection'] ?? [];

        print('📈 Tracks SoundCloud trouvés: ${tracks.length}');

        if (tracks.isEmpty) {
          print('⚠️ Aucun track SoundCloud trouvé pour "$query"');
          return [];
        }

        // Filtrer et mapper les résultats
        final List<Track> result = [];

        for (final item in tracks) {
          try {
            if (item['kind'] != 'track') continue;

            // Vérifier si le track est streamable
            final bool streamable = item['streamable'] ?? false;
            if (!streamable) {
              print('⏭️ Track non streamable: ${item['title']}');
              continue;
            }

            // Récupérer l'artwork (meilleure qualité disponible)
            String? artworkUrl = item['artwork_url'];
            if (artworkUrl == null) {
              artworkUrl = item['user']?['avatar_url'];
            }

            // Améliorer la qualité de l'image si possible
            if (artworkUrl != null) {
              artworkUrl = artworkUrl.replaceFirst('-large', '-t500x500');
            }

            // Construire l'URL de streaming SÉCURISÉE
            final trackId = item['id'];
            String streamUrl = 'https://api.soundcloud.com/tracks/$trackId/stream';

            // Ajouter le client_id pour l'authentification
            streamUrl = '$streamUrl?client_id=$_clientId';

            // Alternative: utiliser media transcodings
            if (item['media']?['transcodings'] != null) {
              final transcodings = List<dynamic>.from(item['media']['transcodings']);
              final hqTranscoding = transcodings.firstWhere(
                    (t) => t['format']?['protocol'] == 'progressive',
                orElse: () => null,
              );

              if (hqTranscoding != null) {
                final streamApiUrl = hqTranscoding['url'];
                if (streamApiUrl != null) {
                  streamUrl = '$streamApiUrl?client_id=$_clientId';
                }
              }
            }

            final track = Track(
              id: trackId.toString(),
              title: item['title']?.toString().trim() ?? 'Titre inconnu',
              artist: item['user']?['username']?.toString().trim() ?? 'Artiste inconnu',
              duration: item['duration'] != null
                  ? Duration(milliseconds: item['duration'])
                  : null,
              thumbnailUrl: artworkUrl,
              audioUrl: streamUrl,
              source: 'soundcloud',
            );

            result.add(track);
            print('✅ Track ajouté: ${track.title} - ${track.artist}');

          } catch (e) {
            print('❌ Erreur parsing track SoundCloud: $e');
            continue;
          }
        }

        print('🎉 Total tracks SoundCloud valides: ${result.length}');
        return result;

      } else {
        print('❌ Erreur HTTP SoundCloud: ${response.statusCode}');
        print('📄 Body: ${response.body.substring(0, min(200, response.body.length))}');
        return [];
      }
    } catch (e) {
      print('❌ Exception SoundCloud: $e');
      return [];
    }
  }
}