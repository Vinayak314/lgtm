import '../models/option_card.dart';

/// Provides local food options for development and demos.
///
/// The deck is deterministic so every participant receives the same cards
/// when the host saves the session to Firebase. The service keeps the same
/// interface as a remote provider, so a live provider can be added later.
class PlacesApiService {
  PlacesApiService({String? apiKey, Object? client});

  Future<List<PlaceCard>> fetchPlacesDeck({
    double latitude = 37.7749,
    double longitude = -122.4194,
    double radiusMiles = 5,
    String? cuisine,
    int limit = 15,
  }) async {
    const places = <PlaceCard>[
      PlaceCard(
        id: 'mock_place_01',
        title: 'Cedar & Stone',
        imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
        subtitle: 'Modern comfort food with seasonal ingredients',
        rating: 4.8,
        priceLevel: r'$$',
        distance: '0.8 MI',
        tags: ['American', 'Comfort food'],
      ),
      PlaceCard(
        id: 'mock_place_02',
        title: 'Mango Leaf Kitchen',
        imageUrl: 'https://images.unsplash.com/photo-1515003197210-e0cd71810b5f',
        subtitle: 'Bright Indian dishes and house-made naan',
        rating: 4.7,
        priceLevel: r'$$',
        distance: '1.2 MI',
        tags: ['Indian', 'Spicy'],
      ),
      PlaceCard(
        id: 'mock_place_03',
        title: 'Harbor Bowl',
        imageUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554',
        subtitle: 'Fresh grain bowls, greens, and grilled specialties',
        rating: 4.6,
        priceLevel: r'$',
        distance: '1.6 MI',
        tags: ['Healthy', 'Bowls'],
      ),
      PlaceCard(
        id: 'mock_place_04',
        title: 'Ember Pizza House',
        imageUrl: 'https://images.unsplash.com/photo-1579751626657-72bc17010498',
        subtitle: 'Wood-fired pizza with classic and creative toppings',
        rating: 4.5,
        priceLevel: r'$$',
        distance: '2.1 MI',
        tags: ['Pizza', 'Italian'],
      ),
      PlaceCard(
        id: 'mock_place_05',
        title: 'Juniper Coffee & Bakes',
        imageUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb',
        subtitle: 'Coffee, pastries, and a relaxed place to catch up',
        rating: 4.4,
        priceLevel: r'$',
        distance: '2.7 MI',
        tags: ['Cafe', 'Bakery'],
      ),
    ];

    return places.take(limit.clamp(0, places.length)).toList();
  }
}
