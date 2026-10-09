import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/groups_repository.dart';

export '../data/groups_repository.dart';

/// The groups the signed in person belongs to, held for the life of the app.
///
/// This is the state Provider watches, and the only thing screens talk to for
/// groups: they read it through [LgtmGroupsScope]. It owns the view state
/// (loading, busy, the last failure) and asks an [LgtmGroupsRepository] for
/// the data, so the Realtime Database implementation can slot in without a
/// screen changing.
///
class LgtmGroupsStore extends ChangeNotifier {
  /// Builds a store backed by the configured groups repository.
  LgtmGroupsStore({
    this.timeout = firstLoadTimeout,
    LgtmMember? currentMember,
    required LgtmGroupsRepository repository,
  }) : _currentMember = currentMember,
       _repository = repository;

  /// How long the first load may take before it is called a failure. A spinner
  /// with no ceiling is the same as a spinner that never ends.
  static const firstLoadTimeout = Duration(seconds: 10);

  /// The ceiling on one load, [firstLoadTimeout] unless a test wants it faster.
  final Duration timeout;

  LgtmMember? _currentMember;
  StreamSubscription<List<LgtmGroup>>? _groupsSubscription;

  /// The signed in member. The member lists mark this row as you, and every
  /// read is scoped to this member's uid.
  LgtmMember? get currentMember => _currentMember;

  final LgtmGroupsRepository _repository;
  List<LgtmGroup> _groups = [];
  bool _ready = false;
  bool _loading = false;
  bool _busy = false;
  String? _error;

  /// False until [load] has finished, so the hub can show a loading state.
  bool get isReady => _ready;

  /// True while a create or a join is in flight.
  bool get isBusy => _busy;

  /// The last failure as a whole sentence a form can show as is.
  String? get error => _error;

  /// Newest first.
  List<LgtmGroup> get groups => List.unmodifiable(_groups);

  /// True when this member is already in the group.
  bool isMember(LgtmGroup group) =>
      group.members.any((member) => member.id == currentMember?.id);

  LgtmGroup? groupById(String id) {
    for (final group in _groups) {
      if (group.id == id) return group;
    }
    return null;
  }

  /// Loads the groups and starts watching for Firebase updates. The app shell
  /// shares this store so every screen sees the same live group data.
  ///
  /// A read that fails still ends the loading state, otherwise the hub would
  /// sit on its spinner forever. The reason lands in [error].
  ///
  /// Three things end it, in every case: the read, the [timeout], or any error
  /// at all. Nothing is allowed to leave this method without setting [isReady].
  Future<void> load() async {
    if (_ready || _loading) return;
    _loading = true;

    try {
      final member = _currentMember;
      if (member == null) {
        _error = 'Sign in to load your groups.';
        return;
      }
      _groups = await _repository
          .loadGroups(member: member)
          .timeout(timeout);
      await _groupsSubscription?.cancel();
      _groupsSubscription = _repository.watchGroups(member: member).listen(
        (groups) {
          _groups = groups;
          _error = null;
          _ready = true;
          notifyListeners();
        },
        onError: (Object failure) {
          _error = failure is LgtmGroupsException
              ? failure.message
              : 'Something went wrong loading your groups.';
          _ready = true;
          notifyListeners();
        },
      );
    } on TimeoutException {
      _error = 'LGTM did not answer in time.';
    } on LgtmGroupsException catch (failure) {
      _error = failure.message;
    } catch (_) {
      // The safety net: an error type the repository did not name still ends the
      // loading state and still says why.
      _error = 'Something went wrong loading your groups.';
    } finally {
      _loading = false;
      _ready = true;
      notifyListeners();
    }
  }

  /// Throws the last failure away and reads again, which is what the hub's
  /// Retry does.
  Future<void> retry() async {
    _error = null;
    _ready = false;
    notifyListeners();
    await load();
  }

  /// Creates a group owned by [currentMember] and puts it at the top of the
  /// hub, then returns it so the caller can open it.
  Future<LgtmGroup> createGroup({required String name}) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final group = await _repository.createGroup(
        name: name,
        member: _requireCurrentMember(),
      );
      _groups = [group, ..._groups];
      return group;
    } on LgtmGroupsException catch (failure) {
      _error = failure.message;
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Joins with an invite code. Returns true when the group is in the hub
  /// afterwards, whether it was joined now or the member was in it already.
  Future<bool> joinWithCode(String code) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final joined = await _repository.joinWithCode(
        code: code,
        member: _requireCurrentMember(),
      );
      _applyJoined(joined);
      return true;
    } on LgtmGroupsException catch (failure) {
      _error = failure.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Puts [joined] where the member would expect to find it: at the top when
  /// they just joined, back where it was when they were already in it.
  ///
  /// Always builds a new list: what [load] took from the repository is the
  /// repository's read only copy, and nothing here may edit it.
  void _applyJoined(LgtmGroup joined) {
    final index = _groups.indexWhere((group) => group.id == joined.id);
    if (index < 0) {
      _groups = [joined, ..._groups];
      return;
    }

    final wasAlreadyIn = isMember(_groups[index]);
    final reordered = [..._groups]..removeAt(index);
    _groups = [...reordered]..insert(wasAlreadyIn ? index : 0, joined);
  }

  /// Points the store at whoever is signed in now.
  ///
  /// Anything already read was read for the old member, so it is dropped and
  /// the next screen that needs data reads it again for the new one. Called
  /// when the session changes, which is why nothing here has to know about
  /// auth.
  void setCurrentMember(LgtmMember member) {
    if (member.id == _currentMember?.id) return;

    unawaited(_groupsSubscription?.cancel());
    _groupsSubscription = null;
    _currentMember = member;
    _groups = [];
    _ready = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_groupsSubscription?.cancel());
    super.dispose();
  }

  LgtmMember _requireCurrentMember() {
    final member = _currentMember;
    if (member == null) throw const LgtmGroupsException('Sign in to continue.');
    return member;
  }

  /// Clears the last failure message once the form has been edited.
  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}

/// Makes the one [LgtmGroupsStore] available to every route through Provider.
///
/// A thin adapter over `ChangeNotifierProvider`, so screens keep calling
/// [LgtmGroupsScope.of] and Provider stays the source of truth: whichever scope
/// is nearest wins, and nothing else has to be threaded through the tree.
class LgtmGroupsScope extends StatelessWidget {
  const LgtmGroupsScope({super.key, required this.store, required this.child});

  final LgtmGroupsStore store;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<LgtmGroupsStore>.value(value: store, child: child);

  /// Read the store and rebuild when it changes.
  static LgtmGroupsStore of(BuildContext context) =>
      Provider.of<LgtmGroupsStore>(context);

  /// Read the store without subscribing, for one off calls such as a
  /// submission.
  static LgtmGroupsStore read(BuildContext context) =>
      context.read<LgtmGroupsStore>();
}
