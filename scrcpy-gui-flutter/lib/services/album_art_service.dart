import 'dart:convert';
import 'package:http/http.dart' as http;

class AlbumArtService {
  static const String _baseUrl = 'https://itunes.apple.com/search';

  Future<String?> fetchArtwork(String title, String artist) async {
    if (title.isEmpty || artist.isEmpty) return null;

    final term = Uri.encodeComponent('$title $artist');
    final url = Uri.parse('$_baseUrl?term=$term&entity=song&limit=1');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;

        if (results.isNotEmpty) {
          final track = results.first;
          // Get high res artwork by replacing 100x100 with 600x600
          String artworkUrl = track['artworkUrl100'] ?? '';
          if (artworkUrl.isNotEmpty) {
            return artworkUrl.replaceAll('100x100', '600x600');
          }
        }
      }
    } catch (e) {
      // Fail silently
      print('Error fetching artwork: $e');
    }
    return null;
  }
}
