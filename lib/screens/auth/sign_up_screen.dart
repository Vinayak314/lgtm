import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/session.dart';
import '../../core/design_tokens.dart';
import '../../core/validators.dart';
import '../../widgets/lgtm_buttons.dart';
import '../../widgets/lgtm_inline_error.dart';
import '../../widgets/lgtm_pill.dart';
import '../../widgets/lgtm_top_bar.dart';
import '../../widgets/lgtm_text_field.dart';
import 'auth_social_buttons.dart';

/// Sign Up. Display name, email, password and a confirmation, each with its own
/// readable error. Arriving from an invite link fills the group code in, which
/// [SignUpArgs] carries.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.args = const SignUpArgs()});

  final SignUpArgs args;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _formError;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nameError = LgtmValidators.displayName(_name.text);
    final emailError = LgtmValidators.email(_email.text);
    final passwordError = LgtmValidators.password(_password.text);
    final confirmError = LgtmValidators.passwordConfirmation(
      _confirm.text,
      _password.text,
    );

    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmError = confirmError;
      _formError = null;
    });

    if (nameError != null) {
      _nameFocus.requestFocus();
      return;
    }
    if (emailError != null) {
      _emailFocus.requestFocus();
      return;
    }
    if (passwordError != null) {
      _passwordFocus.requestFocus();
      return;
    }
    if (confirmError != null) {
      _confirmFocus.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final session = LgtmSessionScope.read(context);
    final signedIn = await session.signUp(
      displayName: _name.text,
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;

    if (!signedIn || !session.isSignedIn) {
      setState(() {
        _submitting = false;
        _formError =
            session.error ?? 'We could not create your account. Try again.';
      });
      return;
    }

    await Navigator.of(context)
        .pushNamedAndRemoveUntil(LgtmRoutes.groups, (route) => false);
  }

  void _onChanged() {
    if (_nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmError == null &&
        _formError == null) {
      return;
    }
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
      _formError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final inviteCode = widget.args.inviteCode;

    return Scaffold(
      backgroundColor: LgtmColors.bg,
      body: Column(
        children: [
          LgtmTopBar(
            leading: LgtmIconButton(
              icon: Icons.arrow_back,
              tooltip: 'Back to sign in',
              color: LgtmColors.primary,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                LgtmLayout.gutterTight,
                24,
                LgtmLayout.gutterTight,
                40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create an account',
                    style: LgtmSerif.display.copyWith(color: LgtmColors.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'One account for every group you are in.',
                    style: LgtmSans.body.copyWith(color: LgtmColors.inkMuted),
                  ),
                  if (inviteCode != null) ...[
                    const SizedBox(height: 20),
                    LgtmPill(
                      height: 34,
                      fill: LgtmColors.mint,
                      borderColor: LgtmColors.mintBorder,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.card_giftcard,
                            size: 16,
                            color: LgtmColors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Invite $inviteCode applied',
                            style: LgtmSans.button.copyWith(
                              color: LgtmColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_formError case final message?) ...[
                    LgtmInlineError(message: message),
                    const SizedBox(height: 16),
                  ],
                  LgtmTextField(
                    label: 'Name',
                    hint: 'What should we call you?',
                    controller: _name,
                    focusNode: _nameFocus,
                    errorText: _nameError,
                    enabled: !_submitting,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    onChanged: (_) => _onChanged(),
                    onSubmitted: (_) => _emailFocus.requestFocus(),
                  ),
                  const SizedBox(height: 16),
                  LgtmTextField(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _email,
                    focusNode: _emailFocus,
                    errorText: _emailError,
                    enabled: !_submitting,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    onChanged: (_) => _onChanged(),
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: 16),
                  LgtmTextField(
                    label: 'Password',
                    hint: 'At least 8 characters',
                    controller: _password,
                    focusNode: _passwordFocus,
                    errorText: _passwordError,
                    enabled: !_submitting,
                    obscure: true,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    onChanged: (_) => _onChanged(),
                    onSubmitted: (_) => _confirmFocus.requestFocus(),
                  ),
                  const SizedBox(height: 16),
                  LgtmTextField(
                    label: 'Confirm password',
                    hint: 'Type it once more',
                    controller: _confirm,
                    focusNode: _confirmFocus,
                    errorText: _confirmError,
                    enabled: !_submitting,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => _onChanged(),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),
                  LgtmPrimaryButton(
                    label: _submitting
                        ? 'Creating account...'
                        : 'Create account',
                    height: 56,
                    shadows: LgtmShadow.primarySoft,
                    onPressed: _submitting ? null : _submit,
                  ),
                  const SizedBox(height: 24),
                  const LgtmSocialButtons(),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      child: const Text('Already have an account? Sign in'),
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
}
