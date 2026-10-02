import 'package:flutter/material.dart';

import '../core/design_tokens.dart';

/// Material 3 theme for the LGTM app.
///
/// Screen specific flourishes (logo colour, card radius, top bar) stay in the
/// widgets themselves; this theme only carries the shared, app wide defaults.
abstract final class LgtmTheme {
  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: LgtmColors.primary,
      onPrimary: Colors.white,
      secondary: LgtmColors.green,
      onSecondary: Colors.white,
      error: LgtmColors.reject,
      onError: Colors.white,
      surface: LgtmColors.bg,
      onSurface: LgtmColors.ink,
      surfaceContainerHighest: LgtmColors.surface,
      onSurfaceVariant: LgtmColors.inkMuted,
      outline: LgtmColors.headerBorder,
      outlineVariant: LgtmColors.divider,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: LgtmColors.bg,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: LgtmSans.family,
        bodyColor: LgtmColors.ink,
        displayColor: LgtmColors.ink,
      ),
      dividerTheme: const DividerThemeData(
        color: LgtmColors.divider,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: LgtmColors.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: LgtmColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      iconTheme: const IconThemeData(color: LgtmColors.ink, size: 24),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: LgtmColors.primary,
        selectionColor: LgtmColors.roseBorder,
        selectionHandleColor: LgtmColors.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: LgtmColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: LgtmSans.family,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: LgtmColors.bg,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: LgtmRadius.card),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: LgtmColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        titleTextStyle: LgtmSerif.title,
        contentTextStyle: LgtmSans.body,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: LgtmColors.bg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LgtmColors.primary,
          textStyle: LgtmSans.button.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: const RoundedRectangleBorder(borderRadius: LgtmRadius.pill),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LgtmColors.ink,
          backgroundColor: LgtmColors.surface,
          side: const BorderSide(color: LgtmColors.borderMauve, width: 2),
          textStyle: LgtmSans.button,
          minimumSize: const Size.fromHeight(56),
          shape: const RoundedRectangleBorder(borderRadius: LgtmRadius.small),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(LgtmColors.primary),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          elevation: const WidgetStatePropertyAll(0),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(54)),
          textStyle: WidgetStatePropertyAll(LgtmSerif.cta),
          shape: WidgetStatePropertyAll(
            const RoundedRectangleBorder(borderRadius: LgtmRadius.pill),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LgtmColors.card,
        hintStyle: LgtmSans.body.copyWith(color: LgtmColors.inkSoft),
        labelStyle: LgtmSans.caption.copyWith(color: LgtmColors.inkMuted),
        errorStyle: LgtmSans.caption.copyWith(color: LgtmColors.reject),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: LgtmRadius.pill,
          borderSide: const BorderSide(color: LgtmColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: LgtmRadius.pill,
          borderSide: const BorderSide(color: LgtmColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: LgtmRadius.pill,
          borderSide: const BorderSide(color: LgtmColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: LgtmRadius.pill,
          borderSide: const BorderSide(color: LgtmColors.reject),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: LgtmRadius.pill,
          borderSide: const BorderSide(color: LgtmColors.reject, width: 2),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: LgtmColors.primary,
        linearTrackColor: LgtmColors.surface,
        circularTrackColor: LgtmColors.surface,
      ),
    );
  }
}
