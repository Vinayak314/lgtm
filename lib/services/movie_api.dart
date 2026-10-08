import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/option_card.dart';

/// Service for fetching and normalizing movie cards from the TMDB API.
///
/// Configurable via `--dart-define=TMDB_KEY=your_key_here`.
/// If no API key is supplied or a network error occurs, returns curated fallback
/// movie cards so the app continues to operate smoothly.
class MovieApiService {
  MovieApiService({
    String? apiKey,
    http.Client? client,
  })  : _apiKey = apiKey ?? const String.fromEnvironment('TMDB_KEY'),
        _client = client ?? http.Client();

  final String _apiKey;
  final http.Client _client;

  static const _baseUrl = 'https://api.themoviedb.org/3';
  static const _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  /// Genre IDs mapping for common TMDB genres.
  static const Map<String, int> genreMap = {
    'action': 28,
    'comedy': 35,
    'drama': 18,
    'horror': 27,
    'scifi': 878,
    'animation': 16,
  };

  /// Fetches up to [limit] normalized [MovieCard]s (default 15).
  Future<List<MovieCard>> fetchMovieDeck({
    String? genre,
    int limit = 15,
  }) async {
    if (_apiKey.isEmpty) {
      return _fallbackMovieDeck(limit: limit);
    }

    try {
      final genreId = genre != null ? genreMap[genre.toLowerCase()] : null;
      final uri = Uri.parse('$_baseUrl/discover/movie').replace(
        queryParameters: {
          'api_key': _apiKey,
          'sort_by': 'popularity.desc',
          'include_adult': 'false',
          'page': '1',
          if (genreId != null) 'with_genres': '$genreId',
        },
      );

      final response = await _client.get(uri);

      if (response.statusCode != 200) {
        return _fallbackMovieDeck(limit: limit);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];

      final cards = <MovieCard>[];
      for (final item in results) {
        if (item is! Map<String, dynamic>) continue;
        final posterPath = item['poster_path'] as String?;
        if (posterPath == null || posterPath.isEmpty) continue;

        final id = 'tmdb_${item['id']}';
        final title = item['title'] as String? ?? 'Untitled Movie';
        final posterUrl = '$_imageBaseUrl$posterPath';
        final overview = item['overview'] as String? ?? '';
        final voteAverage = (item['vote_average'] as num?)?.toDouble() ?? 0.0;
        final releaseDate = item['release_date'] as String? ?? '';
        final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';

        cards.add(
          MovieCard(
            id: id,
            title: title,
            imageUrl: posterUrl,
            subtitle: year.isNotEmpty ? '$year • TMDB $voteAverage' : 'TMDB $voteAverage',
            rating: voteAverage,
            overview: overview,
            releaseYear: year,
          ),
        );

        if (cards.length >= limit) break;
      }

      return cards.isEmpty ? _fallbackMovieDeck(limit: limit) : cards;
    } catch (_) {
      return _fallbackMovieDeck(limit: limit);
    }
  }

  /// Curated fallback cards used when offline or without API key.
  List<MovieCard> _fallbackMovieDeck({int limit = 15}) {
    const list = [
      MovieCard(
        id: 'fallback_m1',
        title: 'Interstellar',
        imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800&q=80',
        subtitle: '2014 • Sci-Fi / Drama',
        rating: 8.7,
        overview: 'A team of explorers travel through a wormhole in space in an attempt to ensure humanity survival.',
        releaseYear: '2014',
      ),
      MovieCard(
        id: 'fallback_m2',
        title: 'Inception',
        imageUrl: 'https://images.unsplash.com/photo-1440404653325-ab127d49abc1?w=800&q=80',
        subtitle: '2010 • Action / Sci-Fi',
        rating: 8.8,
        overview: 'A thief who steals corporate secrets through the use of dream-sharing technology.',
        releaseYear: '2010',
      ),
      MovieCard(
        id: 'fallback_m3',
        title: 'Spirited Away',
        imageUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=800&q=80',
        subtitle: '2001 • Animation / Fantasy',
        rating: 8.6,
        overview: 'During her family move to the suburbs, a 10-year-old girl wanders into a world ruled by gods.',
        releaseYear: '2001',
      ),
      MovieCard(
        id: 'fallback_m4',
        title: 'The Dark Knight',
        imageUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=800&q=80',
        subtitle: '2008 • Action / Crime',
        rating: 9.0,
        overview: 'When the menace known as the Joker wreaks havoc and chaos on Gotham, Batman must accept one of the greatest psychological tests.',
        releaseYear: '2008',
      ),
      MovieCard(
        id: 'fallback_m5',
        title: 'La La Land',
        imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&q=80',
        subtitle: '2016 • Comedy / Drama / Music',
        rating: 8.0,
        overview: 'While navigating their careers in Los Angeles, a pianist and an actress fall in love while attempting to reconcile their aspirations.',
        releaseYear: '2016',
      ),
    ];
    return list.take(limit).toList();
  }
}
