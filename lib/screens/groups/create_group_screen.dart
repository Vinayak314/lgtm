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

/// Create a Group: one name field, then straight into the new group so its
/// invite code is the first thing the creator sees.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _name = TextEditingController();
  final _nameFocus = FocusNode();

  String? _nameError;
  String? _formError;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nameError = LgtmValidators.groupName(_name.text);

    setState(() {
      _nameError = nameError;
      _formError = null;
    });

    if (nameError != null) {
      _nameFocus.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final store = LgtmGroupsScope.read(context);
    final group = await store.createGroup(name: _name.text);
    if (!mounted) return;

    if (store.error case final message?) {
      setState(() {
        _submitting = false;
        _formError = message;
      });
      return;
    }

    // Replace this screen so Back from the new group lands on the hub rather
    // than on the form that created it.
    await Navigator.of(context).pushReplacementNamed(
      LgtmRoutes.groupDetail,
      arguments: GroupDetailArgs(groupId: group.id),
    );
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
                    title: 'Create a Group',
                    subtitle:
                        'Start a new decision session or join an existing one.',
                    topSpacing: 80,
                  ),
                  const SizedBox(height: 32),
                  if (_formError case final message?) ...[
                    LgtmInlineError(message: message),
                    const SizedBox(height: 16),
                  ],
                  LgtmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LgtmTextField(
                          label: 'Group Name',
                          hint: 'Roommates',
                          controller: _name,
                          focusNode: _nameFocus,
                          errorText: _nameError,
                          enabled: !_submitting,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => _onChanged(),
                          onSubmitted: (_) => _submit(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  LgtmPrimaryButton(
                    label: _submitting ? 'Creating...' : 'Create Group',
                    icon: Icons.add_circle_outline,
                    height: 56,
                    shadows: LgtmShadow.primarySoft,
                    onPressed: _submitting ? null : _submit,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _submitting
                          ? null
                          : () =>
                                Navigator.of(context)
                                    .pushReplacementNamed(LgtmRoutes.joinGroup),
                      child: const Text('Have a code? Join a group instead'),
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
    if (_nameError == null && _formError == null && store.error == null) return;
    store.clearError();
    setState(() {
      _nameError = null;
      _formError = null;
    });
  }
}
