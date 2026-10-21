import 'json.dart';
import 'option_card.dart';

export 'option_card.dart' show SessionCategory;

/// The lifecycle of a live session.
enum SessionStatus {
  /// Host is waiting for members to join.
  lobby('lobby'),

  /// Swiping is in progress.
  active('active'),

  /// A winner has been declared.
  finished('finished');

  const SessionStatus(this.wire);

  final String wire;

  static SessionStatus fromWire(Object? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => SessionStatus.lobby,
  );
}

/// The type of consensus that ended the session.
enum WinnerType {
  unanimous('unanimous'),
  closest('closest');

  const WinnerType(this.wire);

  final String wire;

  static WinnerType fromWire(Object? value) => values.firstWhere(
    (type) => type.wire == value,
    orElse: () => WinnerType.closest,
  );
}

/// Who won and how.
class SessionWinner {
  const SessionWinner({required this.cardId, required this.type});

  final String cardId;
  final WinnerType type;

  factory SessionWinner.fromJson(Map<String, Object?> json) => SessionWinner(
    cardId: jsonAsString(json['cardId']),
    type: WinnerType.fromWire(json['type']),
  );

  Map<String, Object?> toJson() => {'cardId': cardId, 'type': type.wire};
}

/// A live or completed session, stored at `sessions/{sid}`.
///
/// ```text
/// sessions/{sid}: {
///   groupId, hostId, category, radius, createdAt,
///   status: "lobby" | "active" | "finished",
///   cards: [ { id, title, image, ... } x 15 ],
///   participants: { uid: true },
///   votes: { cardId: { uid: true|false } },
///   finished: { uid: true },
///   winner: { cardId, type }
/// }
/// ```
class LgtmSession {
  const LgtmSession({
    required this.id,
    required this.groupId,
    required this.hostId,
    required this.category,
    this.radius = 5.0,
    this.genre = '',
    this.status = SessionStatus.lobby,
    this.createdAt,
    this.cards = const [],
    this.participantIds = const {},
    this.votes = const {},
    this.finishedIds = const {},
    this.winner,
  });

  final String id;
  final String groupId;
  final String hostId;
  final SessionCategory category;

  /// Search radius in miles (food/places), or 0 when not applicable (movies).
  final double radius;

  /// Genre filter for movies, empty when not set.
  final String genre;

  final SessionStatus status;

  /// Server timestamp, milliseconds since the epoch.
  final int? createdAt;

  /// The deck of up to 15 option cards, in the order the host fetched them.
  final List<OptionCard> cards;

  /// UIDs of members who joined the lobby. Frozen when the host taps Begin.
  final Set<String> participantIds;

  /// `votes/{cardId}/{uid} = true|false`. Outer key is the card id, inner key
  /// is the voter uid, inner value is whether they swiped Yes.
  final Map<String, Map<String, bool>> votes;

  /// UIDs of members who have finished swiping all cards.
  final Set<String> finishedIds;

  /// Set when a winner is declared (unanimous or closest).
  final SessionWinner? winner;

  // ---- Derived getters ----------------------------------------------------

  /// How many Yes votes are needed for a unanimous win.
  int get threshold => participantIds.length;

  /// Whether swiping is live.
  bool get isActive => status == SessionStatus.active;

  /// Whether the session is over.
  bool get isFinished => status == SessionStatus.finished;

  /// Whether a winner has been declared.
  bool get hasWinner => winner != null;

  /// Whether [uid] is in the lobby.
  bool isParticipant(String uid) => participantIds.contains(uid);

  /// Whether [uid] is the host.
  bool isHost(String uid) => hostId == uid;

  /// Whether [uid] has finished swiping.
  bool hasFinished(String uid) => finishedIds.contains(uid);

  /// Number of participants who are done swiping.
  int get finishedCount => finishedIds.length;

  /// The winning card, if any.
  OptionCard? get winnerCard {
    if (winner == null) return null;
    for (final card in cards) {
      if (card.id == winner!.cardId) return card;
    }
    return null;
  }

  // ---- JSON ---------------------------------------------------------------

  factory LgtmSession.fromJson(String id, Map<String, Object?> json) {
    final votesRaw = jsonAsMap(json['votes']);
    final votes = <String, Map<String, bool>>{};
    for (final entry in votesRaw.entries) {
      final inner = jsonAsMap(entry.value);
      votes[entry.key] = {
        for (final voter in inner.entries) voter.key: voter.value == true,
      };
    }

    final participantsRaw = jsonAsMap(json['participants']);
    final finishedRaw = jsonAsMap(json['finished']);

    final winnerRaw = json['winner'];
    final winner = winnerRaw is Map
        ? SessionWinner.fromJson(jsonAsMap(winnerRaw))
        : null;

    return LgtmSession(
      id: id,
      groupId: jsonAsString(json['groupId']),
      hostId: jsonAsString(json['hostId']),
      category: SessionCategory.fromWire(json['category']),
      radius: _asDouble(json['radius'], fallback: 5.0),
      genre: jsonAsString(json['genre']),
      status: SessionStatus.fromWire(json['status']),
      createdAt: json['createdAt'] is num
          ? (json['createdAt'] as num).toInt()
          : null,
      cards: OptionCard.listFromJson(json['cards']),
      participantIds: {for (final key in participantsRaw.keys) key},
      votes: votes,
      finishedIds: {for (final key in finishedRaw.keys) key},
      winner: winner,
    );
  }

  Map<String, Object?> toJson() => {
    'groupId': groupId,
    'hostId': hostId,
    'category': category.wire,
    'radius': radius,
    'genre': genre,
    'status': status.wire,
    if (createdAt != null) 'createdAt': createdAt,
    'cards': [for (final card in cards) card.toJson()],
    'participants': {for (final uid in participantIds) uid: true},
    'votes': {for (final entry in votes.entries) entry.key: entry.value},
    'finished': {for (final uid in finishedIds) uid: true},
    if (winner != null) 'winner': winner!.toJson(),
  };

  LgtmSession copyWith({
    String? groupId,
    String? hostId,
    SessionCategory? category,
    double? radius,
    String? genre,
    SessionStatus? status,
    int? createdAt,
    List<OptionCard>? cards,
    Set<String>? participantIds,
    Map<String, Map<String, bool>>? votes,
    Set<String>? finishedIds,
    SessionWinner? winner,
  }) => LgtmSession(
    id: id,
    groupId: groupId ?? this.groupId,
    hostId: hostId ?? this.hostId,
    category: category ?? this.category,
    radius: radius ?? this.radius,
    genre: genre ?? this.genre,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    cards: cards ?? this.cards,
    participantIds: participantIds ?? this.participantIds,
    votes: votes ?? this.votes,
    finishedIds: finishedIds ?? this.finishedIds,
    winner: winner ?? this.winner,
  );

  bool get allParticipantsFinished =>
      participantIds.isNotEmpty && finishedIds.containsAll(participantIds);

  String? findUnanimousCard() =>
      findUnanimousCardHelper(votes, participantIds.length);

  OptionCard? closestMatchCard() =>
      cards.isEmpty ? null : closestMatch(cards, votes);

  /// The winner the votes have already settled on, or null while swiping
  /// should go on. A card every participant said Yes to wins straight away;
  /// otherwise the closest match wins once everyone has finished the deck.
  SessionWinner? get decidedWinner {
    if (participantIds.isEmpty) return null;
    final unanimous = findUnanimousCard();
    if (unanimous != null) {
      return SessionWinner(cardId: unanimous, type: WinnerType.unanimous);
    }
    if (!allParticipantsFinished) return null;
    final closest = closestMatchCard();
    return closest == null
        ? null
        : SessionWinner(cardId: closest.id, type: WinnerType.closest);
  }

  /// Index of the first card [uid] has not voted on, or -1 once they have
  /// voted on the whole deck. Deriving progress from the stored votes keeps
  /// every device, and every rejoin, on the same card.
  int nextCardIndexFor(String uid) =>
      cards.indexWhere((card) => !(votes[card.id]?.containsKey(uid) ?? false));

  /// Every card with its live tally, best first, for the leaderboard members
  /// see while they wait. Once the votes have decided a winner, that card is
  /// always the top row, so the leaderboard shows what the host will confirm.
  List<OptionStanding> get standings {
    final ranked = [
      for (final (index, card) in cards.indexed)
        OptionStanding(
          card: card,
          deckIndex: index,
          yesCount: votes[card.id]?.values.where((v) => v).length ?? 0,
          votedCount: votes[card.id]?.length ?? 0,
        ),
    ];
    // Once the votes have decided, rank as the host will and pin the winner to
    // the top. With several unanimous cards (piled up while the host was
    // away) the pick can differ from the rating tie-break.
    final decided = decidedWinner;
    ranked.sort(decided != null ? compareFinalStandings : compareLiveStandings);
    if (decided != null) {
      final at = ranked.indexWhere((s) => s.card.id == decided.cardId);
      if (at > 0) ranked.insert(0, ranked.removeAt(at));
    }
    return ranked;
  }
}

// ---------------------------------------------------------------------------
// Consensus detection helpers (pure functions, no side effects).
// ---------------------------------------------------------------------------

/// Returns the card id that every participant voted Yes on, or null if there
/// is no unanimous winner yet.
///
/// Corresponds to section 7.2 of the development plan.
String? findUnanimousCardHelper(
  Map<String, Map<String, bool>> votes,
  int threshold,
) {
  for (final entry in votes.entries) {
    final yesCount = entry.value.values.where((v) => v).length;
    if (yesCount >= threshold) return entry.key;
  }
  return null;
}

/// Picks the option with the most Yes votes. Ties broken by rating then by
/// deck order (earlier index wins).
///
/// Corresponds to section 7.3 of the development plan.
OptionCard closestMatch(
  List<OptionCard> cards,
  Map<String, Map<String, bool>> votes,
) {
  int yesCount(OptionCard c) => votes[c.id]?.values.where((v) => v).length ?? 0;

  return cards.reduce((a, b) {
    final diff = yesCount(a) - yesCount(b);
    if (diff != 0) return diff > 0 ? a : b;
    // Tie-break by rating, then by deck order (a appeared first).
    return a.rating >= b.rating ? a : b;
  });
}

/// One option's live tally on the waiting screen's leaderboard.
class OptionStanding {
  const OptionStanding({
    required this.card,
    required this.deckIndex,
    required this.yesCount,
    required this.votedCount,
  });

  final OptionCard card;

  /// Position in the deck, the last tie-break.
  final int deckIndex;

  /// Participants who swiped Yes.
  final int yesCount;

  /// Participants who have voted on this card at all, Yes or No.
  final int votedCount;
}

/// Leaderboard order once everyone has finished: most Yes votes, then the
/// higher rating, then the earlier card. This matches [closestMatch], so the
/// top standing is always the card the host declares.
int compareFinalStandings(OptionStanding a, OptionStanding b) {
  final byYes = b.yesCount.compareTo(a.yesCount);
  if (byYes != 0) return byYes;
  final byRating = b.card.rating.compareTo(a.card.rating);
  if (byRating != 0) return byRating;
  return a.deckIndex.compareTo(b.deckIndex);
}

/// Leaderboard order while the votes have not decided a winner yet. Once they
/// have, [LgtmSession.standings] switches to [compareFinalStandings].
///
/// TODO: pick the in-progress ranking. Raw Yes counts (the default, same as
/// the final order) favour cards early in the deck, because slower swipers
/// have not reached the later ones yet. The share of Yes among those who
/// have voted on a card ([OptionStanding.votedCount]) is fairer mid-swipe,
/// but the order shuffles more as the last votes come in.
int compareLiveStandings(OptionStanding a, OptionStanding b) =>
    compareFinalStandings(a, b);

// ---------------------------------------------------------------------------
// Tiny helpers
// ---------------------------------------------------------------------------

double _asDouble(Object? value, {double fallback = 0.0}) => switch (value) {
  num n => n.toDouble(),
  String s => double.tryParse(s) ?? fallback,
  _ => fallback,
};
