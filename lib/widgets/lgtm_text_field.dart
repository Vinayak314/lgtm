import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import 'lgtm_inline_error.dart';

/// The shared form field: a small uppercase label, a pill shaped input and a
/// readable error underneath.
///
/// Password fields get a visibility toggle. Errors are passed in as whole
/// sentences from `LgtmValidators` and render as an alert icon plus the text,
/// so nobody has to guess what went wrong.
class LgtmTextField extends StatefulWidget {
  const LgtmTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.errorText,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.focusNode,
    this.onSubmitted,
    this.onChanged,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;

  /// Masks the text and shows the show/hide toggle.
  final bool obscure;

  /// A full sentence explaining the problem, or null when the field is fine.
  final String? errorText;

  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  @override
  State<LgtmTextField> createState() => _LgtmTextFieldState();
}

class _LgtmTextFieldState extends State<LgtmTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: LgtmSans.label.copyWith(color: LgtmColors.inkMuted),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: widget.obscure && _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          autofillHints: widget.autofillHints,
          onSubmitted: widget.onSubmitted,
          onChanged: widget.onChanged,
          maxLines: widget.maxLines,
          style: LgtmSans.body.copyWith(color: LgtmColors.ink),
          cursorColor: LgtmColors.primary,
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: LgtmColors.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            suffixIcon: widget.obscure
                ? _VisibilityToggle(
                    hidden: _hidden,
                    onToggle: () => setState(() => _hidden = !_hidden),
                  )
                : null,
            error: _error,
          ),
        ),
      ],
    );
  }

  Widget? get _error {
    final message = widget.errorText;
    if (message == null) return null;
    return LgtmInlineError(message: message);
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.hidden, required this.onToggle});

  final bool hidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      icon: Icon(
        hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: LgtmColors.inkSoft,
      ),
      tooltip: hidden ? 'Show password' : 'Hide password',
    );
  }
}
