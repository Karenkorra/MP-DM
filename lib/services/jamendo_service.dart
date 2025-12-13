import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track.dart';

class JamendoService {
  static const String _clientId = 'e1ce7712';

  Future<List<Track>> searchTracks(String query) async {
    if (query.isEmpty) return [];

    print('🎼 Jamendo recherche: $query');

    try {
      final url = Uri.parse(
          'https://api.jamendo.com/v3.0/tracks/'
              '?client_id=$_clientId'
              '&search=${Uri.encodeQueryComponent(query)}'
              '&format=json'
              '&limit=10'
              '&audioformat=mp31'  // mp31 est plus fiable que mp32
              '&include=musicinfo'
              '&order=popularity_total'
      );

      print('🔗 URL: $url');

      final response = await http.get(url);
      print('📊 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];

        print('📈 Résultats: ${results.length}');

        final result = results.map((item) {
          return Track(
            id: item['id'].toString(),
            title: item['name'] ?? 'Titre inconnu',
            artist: item['artist_name'] ?? 'Artiste inconnu',
            duration: item['duration'] != null
                ? Duration(seconds: item['duration'])
                : null,
            thumbnailUrl: item['album_image']?.replaceFirst('/1.0/100/', '/1.0/300/'),
            audioUrl: item['audio'] ?? '',
            source: 'jamendo',
          );
        }).where((track) => track.audioUrl.isNotEmpty).toList();

        print('✅ Tracks avec audio: ${result.length}');
        return result;
      } else {
        print('❌ Jamendo erreur: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Jamendo exception: $e');
      return [];
    }
  }
}