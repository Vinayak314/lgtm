import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/option_card.dart';

/// Fetches place options from Yelp. Returns an empty list when no live results
/// are available; it never inserts locally defined sample places.
class PlacesApiService {
  PlacesApiService({String? apiKey, http.Client? client})
    : _apiKey = apiKey ?? const String.fromEnvironment('PLACES_KEY'),
      _client = client ?? http.Client();

  final String _apiKey;
  final http.Client _client;

  Future<List<PlaceCard>> fetchPlacesDeck({
    double latitude = 37.7749,
    double longitude = -122.4194,
    double radiusMiles = 5,
    String? cuisine,
    int limit = 15,
  }) async {
    if (_apiKey.isEmpty) return [];

    try {
      final uri = Uri.parse('https://api.yelp.com/v3/businesses/search').replace(
        queryParameters: {
          'latitude': '$latitude',
          'longitude': '$longitude',
          'radius': '${(radiusMiles * 1609.34).round()}',
          'categories': cuisine != null && cuisine.isNotEmpty
              ? cuisine.toLowerCase()
              : 'restaurants,food',
          'limit': '$limit',
          'sort_by': 'rating',
        },
      );
      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer $_apiKey'},
      );
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final businesses = data['businesses'] as List<dynamic>? ?? [];
      final cards = <PlaceCard>[];
      for (final item in businesses) {
        if (item is! Map<String, dynamic>) continue;
        final imageUrl = item['image_url'] as String?;
        if (imageUrl == null || imageUrl.isEmpty) continue;

        final name = item['name'] as String? ?? '';
        final rating = (item['rating'] as num?)?.toDouble() ?? 0;
        final price = item['price'] as String? ?? '';
        final meters = (item['distance'] as num?)?.toDouble() ?? 0;
        final miles = (meters / 1609.34).toStringAsFixed(1);
        final location = item['location'] as Map<String, dynamic>?;
        final address =
            (location?['display_address'] as List<dynamic>?)?.join(', ') ?? '';
        final categories = (item['categories'] as List<dynamic>?)
                ?.map((category) =>
                    (category as Map<String, dynamic>)['title'] as String? ?? '')
                .where((category) => category.isNotEmpty)
                .toList() ??
            [];

        cards.add(PlaceCard(
          id: 'yelp_${item['id']}',
          title: name,
          imageUrl: imageUrl,
          subtitle: '$price • $miles MI',
          rating: rating,
          priceLevel: price,
          tags: categories,
          distance: '$miles MI',
          mapsUrl:
              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$name $address')}',
        ));
        if (cards.length >= limit) break;
      }
      return cards;
    } catch (_) {
      return [];
    }
  }
}
