/// Small null safe readers for Realtime Database payloads.
///
/// Anything off the wire is `Object?`: a key can be missing, null, or hold a
/// type we did not expect (a group written by hand, or a schema from a later
/// version of the app). Reading it must never throw, because a single odd
/// record should not take down a whole group list.
library;

/// Treats [value] as a JSON object, or as an empty one when it is anything
/// else. Keys become strings so lookups cannot fail on an int key.
Map<String, Object?> jsonAsMap(Object? value) {
  if (value is Map) {
    return <String, Object?>{
      for (final entry in value.entries) '${entry.key}': entry.value,
    };
  }
  return const <String, Object?>{};
}

/// [value] as a string, or [fallback] when it is missing or not a string.
String jsonAsString(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;

/// [value] as an int, or [fallback] when it is missing or not a number.
/// Accepts the numeric strings the database sometimes hands back.
int jsonAsInt(Object? value, {int fallback = 0}) => switch (value) {
  int i => i,
  num n => n.toInt(),
  String s => int.tryParse(s) ?? fallback,
  _ => fallback,
};

/// [value] as a bool, or [fallback] when it is missing or not a bool.
bool jsonAsBool(Object? value, {bool fallback = false}) =>
    value is bool ? value : fallback;

/// [value] as a list of JSON objects, skipping anything that is not one.
List<Map<String, Object?>> jsonAsMapList(Object? value) => switch (value) {
  List list => list.map(jsonAsMap).toList(),
  _ => const <Map<String, Object?>>[],
};
