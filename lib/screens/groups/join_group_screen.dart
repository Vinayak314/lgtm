import 'package:flutter/material.dart';

import '../../app/groups_store.dart';
import '../../app/router.dart';
import '../../core/design_tokens.dart';
import '../../core/validators.dart';
import '../../widgets/lgtm_buttons.dart';
import '../../widgets/lgtm_card.dart';
import '../../widgets/lgtm_form_header.dart';
import '../../widgets/lgtm_inline_error.dart';
import '../../widgets/lgtm_logo.dart';
import '../../widgets/lgtm_text_field.dart';
import '../../widgets/lgtm_top_bar.dart';

/// Join a Group: an invite code, then back to the hub with the group on it.
class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _code = TextEditingController();
  final _codeFocus = FocusNode();

  String? _codeError;
  String? _formError;
  bool _submitting = false;

  @override
  void dispose() {
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final codeError = LgtmValidators.inviteCode(_code.text);

    setState(() {
      _codeError = codeError;
      _formError = null;
    });

    if (codeError != null) {
      _codeFocus.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final store = LgtmGroupsScope.read(context);
    final joined = await store.joinWithCode(_code.text);
    if (!mounted) return;

    if (!joined) {
      setState(() {
        _submitting = false;
        _formError = store.error ?? 'We could not join that group.';
      });
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      await navigator.pushNamedAndRemoveUntil(LgtmRoutes.groups, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            center: const LgtmLogo(size: 38, color: LgtmColors.primary),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                LgtmLayout.gutterTight,
                0,
                LgtmLayout.gutterTight,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LgtmFormHeader(
                    title: 'Join a Group',
                    subtitle: 'Have a code? Paste it here to join the session.',
                    topSpacing: 80,
                  ),
                  const SizedBox(height: 32),
                  if (_formError case final message?) ...[
                    LgtmInlineError(message: message),
                    const SizedBox(height: 16),
                  ],
                  LgtmCard(
                    child: LgtmTextField(
                      label: 'Group Code',
                      hint: 'Sample: x7ZA1',
                      controller: _code,
                      focusNode: _codeFocus,
                      errorText: _codeError,
                      enabled: !_submitting,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => _onChanged(),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LgtmPrimaryButton(
                    label: _submitting ? 'Joining...' : 'Join Group',
                    icon: Icons.login,
                    height: 56,
                    shadows: LgtmShadow.primarySoft,
                    onPressed: _submitting ? null : _submit,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context)
                                .pushReplacementNamed(LgtmRoutes.createGroup),
                      child: const Text('No code? Create a group instead'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onChanged() {
    final store = LgtmGroupsScope.read(context);
    if (_codeError == null && _formError == null && store.error == null) return;
    store.clearError();
    setState(() {
      _codeError = null;
      _formError = null;
    });
  }
}
