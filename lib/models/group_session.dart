import 'package:flutter/material.dart';

import 'json.dart';

/// A session the group already finished: what they were deciding, what they
/// agreed on, and when.
///
/// This is the shape the hub's past winners list reads. The live session
/// itself belongs to the session engine, so this record only keeps what
/// survives after a session ends. [winnerIcon] is a glyph rather than an image
/// until real card images arrive; it is derived from [activity] on the way out
/// of the database because an `IconData` cannot be stored.
class LgtmGroupSession {
  const LgtmGroupSession({
    required this.id,
    required this.activity,
    required this.winnerName,
    required this.winnerIcon,
    required this.date,
  });

  final String id;

  /// What the group was deciding, e.g. "Dinner".
  final String activity;

  /// The option everyone settled on.
  final String winnerName;
  final IconData winnerIcon;

  /// Already formatted for display, e.g. "12 Mar".
  final String date;

  factory LgtmGroupSession.fromJson(String id, Map<String, Object?> json) {
    final activity = jsonAsString(json['activity'], fallback: 'Session');
    return LgtmGroupSession(
      id: id,
      activity: activity,
      winnerName: jsonAsString(json['winnerName'], fallback: 'No winner'),
      winnerIcon: sessionIconFor(activity),
      date: jsonAsString(json['date']),
    );
  }

  Map<String, Object?> toJson() => {
    'activity': activity,
    'winnerName': winnerName,
    'date': date,
  };

  /// Reads a `sessions/{sid}` style collection.
  static List<LgtmGroupSession> listFromJson(Map<String, Object?> json) => [
    for (final entry in json.entries)
      if (entry.value is Map)
        LgtmGroupSession.fromJson(entry.key, jsonAsMap(entry.value)),
  ];
}

/// The placeholder glyph for a finished activity.
///
/// Only here so the same category always looks the same on every card; it
/// disappears once options carry real images.
IconData sessionIconFor(String activity) {
  final words = activity.toLowerCase();
  if (words.contains('drink') || words.contains('coffee')) {
    return Icons.local_cafe_outlined;
  }
  if (words.contains('lunch')) return Icons.ramen_dining;
  if (words.contains('dinner') || words.contains('food')) {
    return Icons.lunch_dining;
  }
  if (words.contains('movie') || words.contains('watch')) {
    return Icons.movie_outlined;
  }
  if (words.contains('trip') || words.contains('travel')) {
    return Icons.flight_outlined;
  }
  return Icons.fastfood;
}
