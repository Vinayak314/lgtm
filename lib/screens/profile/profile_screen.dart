import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/groups_store.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../core/design_tokens.dart';
import '../../core/validators.dart';
import '../../widgets/lgtm_avatar.dart';
import '../../widgets/lgtm_bottom_nav.dart';
import '../../widgets/lgtm_buttons.dart';
import '../../widgets/lgtm_card.dart';
import '../../widgets/lgtm_text_field.dart';
import '../../widgets/lgtm_top_bar.dart';
import '../../widgets/states/lgtm_confirm_dialog.dart';

/// Profile and settings: who is signed in, what they are called, and the way
/// out.
///
/// The display name is the one thing a person can change for themselves, so it
/// is editable here and validated with the same rule Sign Up used. Signing out
/// asks first because it ends the current authenticated session.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _nameFocus = FocusNode();

  String? _nameError;
  bool _saving = false;
  bool _signingOut = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final user = LgtmSessionScope.of(context).user;
    _name.text = user?.displayName ?? '';

    // This screen counts the member's groups, and it can be opened without the
    // hub ever mounting, so it asks for the read itself. The store only ever
    // fetches once, however many screens ask.
    unawaited(LgtmGroupsScope.read(context).load());
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  /// The saved name only changes when it actually differs, so Save never
  /// appears to do nothing for an untouched field.
  bool get _isDirty {
    final user = LgtmSessionScope.read(context).user;
    return user != null && _name.text.trim() != user.displayName;
  }

  Future<void> _save() async {
    final error = LgtmValidators.displayName(_name.text);

    setState(() => _nameError = error);
    if (error != null) {
      _nameFocus.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    await LgtmSessionScope.read(context).updateDisplayName(_name.text);
    if (!mounted) return;

    setState(() => _saving = false);
    _say('Saved. Your group buddies will see the new name.');
  }

  Future<void> _signOut() async {
    final confirmed = await LgtmConfirmDialog.show(
      context,
      title: 'Sign out?',
      message: 'You will need your email and password to get back into LGTM.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _signingOut = true);
    await LgtmSessionScope.read(context).signOut();
    if (!mounted) return;

    // Nothing behind this screen is worth keeping once the session is gone.
    await Navigator.of(context)
        .pushNamedAndRemoveUntil(LgtmRoutes.login, (route) => false);
  }

  void _onTab(LgtmNavTab tab) {
    switch (tab) {
      case LgtmNavTab.groups:
        Navigator.of(context).maybePop();
      case LgtmNavTab.swipe:
        _say('The swipe flow is not built yet.');
      case LgtmNavTab.matches:
        _say('Matches are not built yet.');
      case LgtmNavTab.profile:
        return;
    }
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final session = LgtmSessionScope.of(context);
    final user = session.user;
    final store = LgtmGroupsScope.of(context);
    final groupCount = store.groups.where(store.isMember).length;

    return Scaffold(
      backgroundColor: LgtmColors.bg,
      body: Column(
        children: [
          LgtmTopBar(
            leading: LgtmIconButton(
              icon: Icons.arrow_back,
              tooltip: 'Back to My Groups',
              color: LgtmColors.primary,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            center: Text(
              'Profile',
              style: LgtmSerif.title.copyWith(color: LgtmColors.ink),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                LgtmLayout.gutterTight,
                32,
                LgtmLayout.gutterTight,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (user == null)
                    Text(
                      'You are signed out.',
                      style: LgtmSans.body.copyWith(color: LgtmColors.inkSoft),
                    )
                  else ...[
                    _IdentityCard(
                      displayName: user.displayName,
                      email: user.email,
                      groupCount: groupCount,
                    ),
                    const SizedBox(height: 24),
                    LgtmCard(
                      child: LgtmTextField(
                        label: 'Display Name',
                        hint: user.displayName,
                        controller: _name,
                        focusNode: _nameFocus,
                        errorText: _nameError,
                        enabled: !_saving,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() => _nameError = null),
                        onSubmitted: (_) => _save(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LgtmPrimaryButton(
                      label: _saving ? 'Saving...' : 'Save Changes',
                      height: 56,
                      shadows: LgtmShadow.primarySoft,
                      onPressed: _saving || !_isDirty ? null : _save,
                    ),
                    const SizedBox(height: 32),
                    LgtmSecondaryButton(
                      height: 56,
                      onPressed: _signingOut ? null : _signOut,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            size: 20,
                            color: _signingOut
                                ? LgtmColors.inkMuted
                                : LgtmColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _signingOut ? 'Signing out...' : 'Sign out',
                            style: LgtmSerif.cta.copyWith(
                              color: _signingOut
                                  ? LgtmColors.inkMuted
                                  : LgtmColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: LgtmBottomNav(
        activeTab: LgtmNavTab.profile,
        onSelect: _onTab,
      ),
    );
  }
}

/// Avatar, name, email and the one number worth showing on a profile.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.displayName,
    required this.email,
    required this.groupCount,
  });

  final String displayName;
  final String email;
  final int groupCount;

  @override
  Widget build(BuildContext context) {
    final groups = groupCount == 1 ? '1 group' : '$groupCount groups';

    return LgtmCard(
      child: Column(
        children: [
          LgtmAvatar(
            size: 88,
            fallbackColor: const Color(0xFF4A4A4A),
            ringColor: LgtmColors.card,
            ringWidth: 3,
            label: 'Profile photo of $displayName',
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LgtmSerif.title.copyWith(color: LgtmColors.ink),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LgtmSans.bodySmall.copyWith(color: LgtmColors.inkSoft),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: const BoxDecoration(
              color: LgtmColors.mint,
              borderRadius: LgtmRadius.pill,
            ),
            child: Text(
              groups,
              style: LgtmSans.button.copyWith(
                color: LgtmColors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
