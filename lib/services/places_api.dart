import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/option_card.dart';

/// Service for fetching and normalizing food & place cards from public place APIs
/// (Overpass OSM / Yelp / Foursquare).
///
/// Configurable via `--dart-define=PLACES_KEY=your_key_here`.
/// If no API key is supplied or a network error occurs, returns curated fallback
/// place cards so the app continues to operate smoothly.
class PlacesApiService {
  PlacesApiService({
    String? apiKey,
    http.Client? client,
  })  : _apiKey = apiKey ?? const String.fromEnvironment('PLACES_KEY'),
        _client = client ?? http.Client();

  final String _apiKey;
  final http.Client _client;

  /// Fetches up to [limit] normalized [PlaceCard]s (default 15).
  Future<List<PlaceCard>> fetchPlacesDeck({
    double latitude = 37.7749,
    double longitude = -122.4194,
    double radiusMiles = 5.0,
    String? cuisine,
    int limit = 15,
  }) async {
    if (_apiKey.isEmpty) {
      return _fallbackPlacesDeck(limit: limit);
    }

    try {
      final uri = Uri.parse('https://api.yelp.com/v3/businesses/search').replace(
        queryParameters: {
          'latitude': '$latitude',
          'longitude': '$longitude',
          'radius': '${(radiusMiles * 1609.34).round()}',
          'categories': cuisine != null && cuisine.isNotEmpty ? cuisine.toLowerCase() : 'restaurants,food',
          'limit': '$limit',
          'sort_by': 'rating',
        },
      );

      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode != 200) {
        return _fallbackPlacesDeck(limit: limit);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final businesses = data['businesses'] as List<dynamic>? ?? [];

      final cards = <PlaceCard>[];
      for (final item in businesses) {
        if (item is! Map<String, dynamic>) continue;
        final imageUrl = item['image_url'] as String?;
        if (imageUrl == null || imageUrl.isEmpty) continue;

        final id = 'yelp_${item['id']}';
        final name = item['name'] as String? ?? 'Restaurant';
        final rating = (item['rating'] as num?)?.toDouble() ?? 4.0;
        final price = item['price'] as String? ?? '\$\$';
        final distanceMeters = (item['distance'] as num?)?.toDouble() ?? 0.0;
        final distanceMiles = (distanceMeters / 1609.34).toStringAsFixed(1);
        final location = item['location'] as Map<String, dynamic>?;
        final address = (location?['display_address'] as List<dynamic>?)?.join(', ') ?? '';
        final categories = (item['categories'] as List<dynamic>?)
                ?.map((c) => (c as Map<String, dynamic>)['title'] as String? ?? '')
                .where((c) => c.isNotEmpty)
                .toList() ??
            [];

        cards.add(
          PlaceCard(
            id: id,
            title: name,
            imageUrl: imageUrl,
            subtitle: '$price • $distanceMiles MI',
            rating: rating,
            priceLevel: price,
            tags: categories,
            distance: '$distanceMiles MI',
            mapsUrl: 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$name $address')}',
          ),
        );

        if (cards.length >= limit) break;
      }

      return cards.isEmpty ? _fallbackPlacesDeck(limit: limit) : cards;
    } catch (_) {
      return _fallbackPlacesDeck(limit: limit);
    }
  }

  /// Curated fallback food/places cards used when offline or without API key.
  List<PlaceCard> _fallbackPlacesDeck({int limit = 15}) {
    const list = [
      PlaceCard(
        id: 'fallback_p1',
        title: 'Spicy Basil Thai',
        imageUrl: 'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800&q=80',
        subtitle: '\$\$ • 0.8 MI',
        rating: 4.8,
        priceLevel: '\$\$',
        tags: ['Thai', 'Noodles', 'Spicy'],
        distance: '0.8 MI',
        mapsUrl: 'https://maps.google.com/?q=Spicy+Basil+Thai',
      ),
      PlaceCard(
        id: 'fallback_p2',
        title: 'Taco Heaven',
        imageUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800&q=80',
        subtitle: '\$ • 1.2 MI',
        rating: 4.6,
        priceLevel: '\$',
        tags: ['Mexican', 'Tacos', 'Casual'],
        distance: '1.2 MI',
        mapsUrl: 'https://maps.google.com/?q=Taco+Heaven',
      ),
      PlaceCard(
        id: 'fallback_p3',
        title: 'Artisan Pizza Lab',
        imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80',
        subtitle: '\$\$\$ • 1.5 MI',
        rating: 4.7,
        priceLevel: '\$\$\$',
        tags: ['Pizza', 'Italian', 'Wood-fired'],
        distance: '1.5 MI',
        mapsUrl: 'https://maps.google.com/?q=Artisan+Pizza+Lab',
      ),
      PlaceCard(
        id: 'fallback_p4',
        title: 'Ramen Ichiraku',
        imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=800&q=80',
        subtitle: '\$\$ • 2.0 MI',
        rating: 4.9,
        priceLevel: '\$\$',
        tags: ['Japanese', 'Ramen', 'Comfort Food'],
        distance: '2.0 MI',
        mapsUrl: 'https://maps.google.com/?q=Ramen+Ichiraku',
      ),
      PlaceCard(
        id: 'fallback_p5',
        title: 'The Green Bistro',
        imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&q=80',
        subtitle: '\$\$ • 2.4 MI',
        rating: 4.5,
        priceLevel: '\$\$',
        tags: ['Vegan', 'Healthy', 'Salads'],
        distance: '2.4 MI',
        mapsUrl: 'https://maps.google.com/?q=The+Green+Bistro',
      ),
    ];
    return list.take(limit).toList();
  }
}
