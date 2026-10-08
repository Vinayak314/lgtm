import 'json.dart';

/// The category a session is deciding between.
///
/// Stored on the session so every participant and the result screen can show
/// the right icons and labels without re-reading what the host chose.
enum SessionCategory {
  food('food'),
  movie('movie');

  const SessionCategory(this.wire);

  /// The value written to the database.
  final String wire;

  static SessionCategory fromWire(Object? value) => values.firstWhere(
    (category) => category.wire == value,
    orElse: () => SessionCategory.food,
  );
}

/// Base class for swipeable option cards.
///
/// The swipe UI and consensus engine work with [OptionCard] so they are
/// category-agnostic: a [MovieCard] and a [PlaceCard] both carry the same
/// data the deck and the voter need.
///
/// Maps to `sessions/{sid}/cards/[index]` in the Realtime Database, where
/// each entry is a flat JSON object.
abstract class OptionCard {
  const OptionCard({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.subtitle = '',
    this.rating = 0.0,
    this.mapsUrl,
  });

  /// Stable identifier (TMDB id, Yelp id, etc.), used as the key under
  /// `votes/{cardId}`.
  final String id;

  /// Primary name shown on the card.
  final String title;

  /// Full URL to a photo. An empty string means "no image available".
  final String imageUrl;

  /// Secondary line: genre, cuisine type, price range, etc.
  final String subtitle;

  /// 0–5 stars. Used for tie-breaking in the Closest Match fallback.
  final double rating;

  /// Deep link to Google Maps / Apple Maps / TMDB page.
  final String? mapsUrl;

  /// Which category this card belongs to.
  SessionCategory get category;

  /// Whether a real image was returned by the API.
  bool get hasImage => imageUrl.isNotEmpty;

  /// Serialises the card for writing to `sessions/{sid}/cards/[index]`.
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'imageUrl': imageUrl,
    'subtitle': subtitle,
    'rating': rating,
    if (mapsUrl != null) 'mapsUrl': mapsUrl,
    'category': category.wire,
  };

  /// Reads a card from JSON, routing to the right subclass.
  static OptionCard fromJson(Map<String, Object?> json) {
    final cat = SessionCategory.fromWire(json['category']);
    return switch (cat) {
      SessionCategory.movie => MovieCard.fromJson(json),
      SessionCategory.food => PlaceCard.fromJson(json),
    };
  }

  /// Reads a list of cards from the `cards` array on a session.
  static List<OptionCard> listFromJson(Object? value) => switch (value) {
    List list => [
      for (final item in list)
        if (item is Map) OptionCard.fromJson(jsonAsMap(item)),
    ],
    _ => const <OptionCard>[],
  };
}

/// A movie fetched from TMDB.
class MovieCard extends OptionCard {
  const MovieCard({
    required super.id,
    required super.title,
    required super.imageUrl,
    super.subtitle,
    super.rating,
    super.mapsUrl,
    this.releaseYear = '',
    this.overview = '',
  });

  /// Four-digit year, e.g. "2024".
  final String releaseYear;

  /// Short plot summary from TMDB.
  final String overview;

  @override
  SessionCategory get category => SessionCategory.movie;

  factory MovieCard.fromJson(Map<String, Object?> json) => MovieCard(
    id: jsonAsString(json['id']),
    title: jsonAsString(json['title'], fallback: 'Movie'),
    imageUrl: jsonAsString(json['imageUrl']),
    subtitle: jsonAsString(json['subtitle']),
    rating: _jsonAsDouble(json['rating']),
    mapsUrl: switch (jsonAsString(json['mapsUrl'])) {
      '' => null,
      final url => url,
    },
    releaseYear: jsonAsString(json['releaseYear']),
    overview: jsonAsString(json['overview']),
  );

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'releaseYear': releaseYear,
    'overview': overview,
  };
}

/// A restaurant or place fetched from Yelp / Foursquare / Overpass.
class PlaceCard extends OptionCard {
  const PlaceCard({
    required super.id,
    required super.title,
    required super.imageUrl,
    super.subtitle,
    super.rating,
    super.mapsUrl,
    this.distance = '',
    this.priceLevel = '',
    this.tags = const [],
    this.latitude,
    this.longitude,
  });

  /// Human-readable distance, e.g. "1.2 miles away".
  final String distance;

  /// Price range indicator, e.g. "$$".
  final String priceLevel;

  /// Category tags, e.g. ["Thai", "Spicy"].
  final List<String> tags;

  /// Coordinates for the Directions button.
  final double? latitude;
  final double? longitude;

  @override
  SessionCategory get category => SessionCategory.food;

  factory PlaceCard.fromJson(Map<String, Object?> json) => PlaceCard(
    id: jsonAsString(json['id']),
    title: jsonAsString(json['title'], fallback: 'Place'),
    imageUrl: jsonAsString(json['imageUrl']),
    subtitle: jsonAsString(json['subtitle']),
    rating: _jsonAsDouble(json['rating']),
    mapsUrl: switch (jsonAsString(json['mapsUrl'])) {
      '' => null,
      final url => url,
    },
    distance: jsonAsString(json['distance']),
    priceLevel: jsonAsString(json['priceLevel']),
    tags: _jsonAsStringList(json['tags']),
    latitude: _jsonAsNullableDouble(json['latitude']),
    longitude: _jsonAsNullableDouble(json['longitude']),
  );

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'distance': distance,
    'priceLevel': priceLevel,
    'tags': tags,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };
}

// ---------------------------------------------------------------------------
// Tiny JSON helpers specific to option cards.
// ---------------------------------------------------------------------------

double _jsonAsDouble(Object? value, {double fallback = 0.0}) => switch (value) {
  num n => n.toDouble(),
  String s => double.tryParse(s) ?? fallback,
  _ => fallback,
};

double? _jsonAsNullableDouble(Object? value) => switch (value) {
  num n => n.toDouble(),
  String s => double.tryParse(s),
  _ => null,
};

List<String> _jsonAsStringList(Object? value) => switch (value) {
  List list => [for (final item in list) '$item'],
  _ => const <String>[],
};
