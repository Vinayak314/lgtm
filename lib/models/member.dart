import 'package:flutter/material.dart';

import 'json.dart';
import 'user.dart';

/// One person in a group.
///
/// [avatarColor] is not stored. The database knows a uid and a display name,
/// nothing else, so the colour is derived from the id: everyone keeps the same
/// avatar on every device without writing styling data.
class LgtmMember {
  const LgtmMember({
    required this.id,
    required this.displayName,
    required this.avatarColor,
  });

  final String id;
  final String displayName;
  final Color avatarColor;

  /// Builds a member from a `users/{uid}` record.
  factory LgtmMember.fromUser(LgtmUser user) => LgtmMember(
    id: user.uid,
    displayName: user.displayName,
    avatarColor: avatarColorFor(user.uid),
  );

  /// Builds a member from a denormalised `{id, name}` object, which is what a
  /// group looks like if member names are copied into it later.
  factory LgtmMember.fromJson(Map<String, Object?> json) => LgtmMember(
    id: jsonAsString(json['id']),
    displayName: jsonAsString(json['name'], fallback: 'Member'),
    avatarColor: avatarColorFor(jsonAsString(json['id'])),
  );

  Map<String, Object?> toJson() => {'id': id, 'name': displayName};

  LgtmMember copyWith({String? displayName}) => LgtmMember(
    id: id,
    displayName: displayName ?? this.displayName,
    avatarColor: avatarColor,
  );
}

/// Picks an avatar colour from [id].
///
/// Deliberately a hand rolled FNV-1a hash and not `String.hashCode`, whose
/// value Dart does not promise to keep stable between runs. A member's avatar
/// has to look the same on every launch and on every teammate's phone, so the
/// hash cannot move under us.
Color avatarColorFor(String id) {
  var hash = 0x811c9dc5;
  for (final unit in id.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return _avatarPalette[hash % _avatarPalette.length];
}

/// Muted colours used for derived avatars.
const List<Color> _avatarPalette = [
  Color(0xFF4A4A4A),
  Color(0xFF2F5D5B),
  Color(0xFF4B3F63),
  Color(0xFF5B4A3A),
  Color(0xFF3F5A46),
  Color(0xFF6B4A4A),
];
