import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/session.dart';
import '../../core/design_tokens.dart';
import '../../core/validators.dart';
import '../../widgets/design_canvas.dart';
import '../../widgets/lgtm_buttons.dart';
import '../../widgets/lgtm_inline_error.dart';
import '../../widgets/lgtm_logo.dart';
import '../../widgets/lgtm_text_field.dart';
import 'auth_social_buttons.dart';

/// Login. Email and password with readable errors under each field, a password
/// visibility toggle, and the two social buttons from the design.
///
/// The submission goes through [LgtmSession], which is a mock until the
/// Firebase items in TODO.md are done.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _emailError;
  String? _passwordError;
  String? _formError;
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailError = LgtmValidators.email(_email.text);
    final passwordError = LgtmValidators.password(_password.text);

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _formError = null;
    });

    if (emailError != null) {
      _emailFocus.requestFocus();
      return;
    }
    if (passwordError != null) {
      _passwordFocus.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final session = LgtmSessionScope.read(context);
    final signedIn = await session.signIn(
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;

    if (!signedIn || !session.isSignedIn) {
      setState(() {
        _submitting = false;
        _formError =
            session.error ?? 'We could not sign you in. Please try again.';
      });
      return;
    }

    await Navigator.of(context)
        .pushNamedAndRemoveUntil(LgtmRoutes.groups, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LgtmColors.bg,
      body: LgtmStatusBarInset(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    LgtmLayout.gutterTight,
                    LgtmLayout.logoOffset,
                    LgtmLayout.gutterTight,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LgtmLogo(size: 46, color: LgtmColors.green),
                      const SizedBox(height: 20),
                      // Narrow column so the headline breaks over three lines.
                      SizedBox(
                        width: 180,
                        child: Text(
                          'Group Decisions, Sorted.',
                          style: LgtmSerif.display.copyWith(
                            color: LgtmColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (_formError case final message?) ...[
                        LgtmInlineError(message: message),
                        const SizedBox(height: 16),
                      ],
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
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onChanged: (_) => _onChanged(),
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),
                      LgtmPrimaryButton(
                        label: _submitting ? 'Signing in...' : 'Sign in',
                        height: 56,
                        shadows: LgtmShadow.primarySoft,
                        onPressed: _submitting ? null : _submit,
                      ),
                      const SizedBox(height: 24),
                      const LgtmSocialButtons(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LgtmLayout.gutterTight,
                8,
                LgtmLayout.gutterTight,
                24,
              ),
              child: Center(
                child: TextButton(
                  onPressed: _submitting
                      ? null
                      : () =>
                            Navigator.of(context).pushNamed(LgtmRoutes.signUp),
                  child: const Text('New here? Create an account'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Errors clear as soon as somebody starts fixing them, so a stale red line
  /// never sits under a field that is now correct.
  void _onChanged() {
    if (_emailError == null && _passwordError == null && _formError == null) {
      return;
    }
    setState(() {
      _emailError = null;
      _passwordError = null;
      _formError = null;
    });
  }
}
