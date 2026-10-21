import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/option_card.dart';

class LgtmApiException implements Exception {
  const LgtmApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fetches movie options from TMDB. Returns only provider results.
class MovieApiService {
  MovieApiService({String? apiKey, http.Client? client})
    : _apiKey = apiKey ?? const String.fromEnvironment('TMDB_KEY'),
      _client = client ?? http.Client();

  final String _apiKey;
  final http.Client _client;

  static const _baseUrl = 'https://api.themoviedb.org/3';
  static const _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  static const Map<String, int> genreMap = {
    'action': 28,
    'comedy': 35,
    'drama': 18,
    'horror': 27,
    'scifi': 878,
    'animation': 16,
  };

  Future<List<MovieCard>> fetchMovieDeck({String? genre, int limit = 15}) async {
    if (_apiKey.isEmpty) {
      throw const LgtmApiException(
        'TMDB is not configured. Add TMDB_KEY to the debug build.',
      );
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
        throw LgtmApiException(
          'TMDB could not load movies (HTTP ${response.statusCode}).',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      final cards = <MovieCard>[];
      for (final item in results) {
        if (item is! Map<String, dynamic>) continue;
        final posterPath = item['poster_path'] as String?;
        if (posterPath == null || posterPath.isEmpty) continue;

        final title = item['title'] as String? ?? '';
        final overview = item['overview'] as String? ?? '';
        final rating = (item['vote_average'] as num?)?.toDouble() ?? 0;
        final releaseDate = item['release_date'] as String? ?? '';
        final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
        cards.add(MovieCard(
          id: 'tmdb_${item['id']}',
          title: title,
          imageUrl: '$_imageBaseUrl$posterPath',
          subtitle: year.isNotEmpty ? '$year • TMDB $rating' : 'TMDB $rating',
          rating: rating,
          overview: overview,
          releaseYear: year,
        ));
        if (cards.length >= limit) break;
      }
      if (cards.length < 3) {
        throw const LgtmApiException(
          'TMDB returned too few movies. Try again later.',
        );
      }
      return cards;
    } on LgtmApiException {
      rethrow;
    } catch (error) {
      throw LgtmApiException('Could not load movies: $error');
    }
  }
}
