import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Single source of truth for the LGTM "Artisanal" design language.
///
/// Every colour, type ramp, radius and shadow used anywhere in the app is
/// declared here. Screens and widgets must reference these tokens instead of
/// hard coding values, so the design can be retuned from one file.
abstract final class LgtmColors {
  // Backgrounds
  static const bg = Color(0xFFFDF9F4);
  static const bgPaper = Color(0xFFECE9E4);

  // Fills
  static const surface = Color(0xFFF0EDE8);
  static const surface2 = Color(0xFFF5F1EC);
  static const card = Color(0xFFFEFBF8);
  static const cardPure = Color(0xFFFFFFFF);
  static const pillFill = Color(0xFFF5F0EB);
  static const mint = Color(0xFFCFE8D6);
  static const tileCircle = Color(0xFFE8E4DE);

  // Brand
  static const primary = Color(0xFFA33A40);
  static const primaryShadow = Color(0xFF7C2A2F);
  static const primarySoft = Color(0xFFFDF4F1);
  static const primarySoftShadow = Color(0xFFEBC9C6);
  static const rose = Color(0xFFC97B7E);
  static const roseSoft = Color(0xFFC0646A);
  static const roseBar = Color(0xFFE8B8B5);

  // Semantic
  static const reject = Color(0xFFB3262E);
  static const rejectFill = Color(0xFFF9EDEA);
  static const rejectBorder = Color(0xFFE3B7B5);
  static const green = Color(0xFF4D6054);
  static const greenDeep = Color(0xFF4A5D51);
  static const greenSoft = Color(0xFFBDC4BC);
  static const mintBorder = Color(0xFFA9CDB5);

  // Ink
  static const ink = Color(0xFF1C1B1A);
  static const inkMuted = Color(0xFF5C4A4A);
  static const inkSoft = Color(0xFF7A6E6E);
  static const inkOnPaper = Color(0xFF4A3F3F);
  static const inkFaint = Color(0xFF8A7F7F);

  // Borders and rules
  static const roseBorder = Color(0xFFE6C5C5);
  static const borderMauve = Color(0xFF8B6B70);
  static const headerBorder = Color(0xFFE8E1DA);
  static const divider = Color(0xFFDDD6CF);
  static const chipBorder = Color(0xFFDDD7D1);
  static const winnerRowBorder = Color(0xFFE8CFCB);
  static const rankedRowBorder = Color(0xFFDDD3CB);
  static const voteBadgeBorder = Color(0xFFE3D8D0);
  static const inputBorder = Color(0xFF5F6B7A);
  static const ringOuter = Color(0xFFF0C8CC);
  static const ringMiddle = Color(0xFFE8DEDA);
  static const dialBorder = Color(0xFFD9AFAF);

  // Accents
  static const star = Color(0xFFF2C14E);
  static const sageDeco = Color(0xFF9AA89C);
  static const barGreyGreen = Color(0xFFA9AFA9);
  static const tagFill = Color(0xFFD7D0CA);
  static const tagInk = Color(0xFF2B2523);
  static const photoFallbackTop = Color(0xFF2A1A14);
  static const photoFallbackBottom = Color(0xFF0D0B0A);
}

/// Layout metrics. The design is authored against a 390pt wide column.
abstract final class LgtmLayout {
  static const designWidth = 390.0;
  static const topBarHeight = 64.0;
  static const bottomNavHeight = 88.0;
  static const gutter = 24.0;
  static const gutterTight = 16.0;

  /// Extra space between the status bar inset and the wordmark on screens
  /// that top align their content (Login), so the wordmark starts 56pt below
  /// the status bar rather than being centred in the viewport.
  static const logoOffset = 56.0;

  /// Floor for the space reserved above the 64pt header content, mirroring
  /// the CSS `env(safe-area-inset-top, 0px)` rule with a 20pt minimum so the
  /// header still clears the status bar when the platform reports no inset.
  static const topBarInset = 20.0;

  /// Space to reserve above header content (or above the content of a screen
  /// without a header): the real safe area inset, or [topBarInset] when the
  /// platform reports less than that.
  static double topInset(BuildContext context) =>
      math.max(MediaQuery.paddingOf(context).top, topBarInset);
}

/// Corner radii used across the app.
abstract final class LgtmRadius {
  static const card = BorderRadius.all(Radius.circular(20));
  static const cardLarge = BorderRadius.all(Radius.circular(24));
  static const cardXL = BorderRadius.all(Radius.circular(40));
  static const pill = BorderRadius.all(Radius.circular(999));
  static const tile = BorderRadius.all(Radius.circular(12));
  static const small = BorderRadius.all(Radius.circular(8));
}

/// Shadows. `hard` variants have no blur and are reserved for the Match
/// screen buttons and card, the Swipe action buttons and the selected chip.
abstract final class LgtmShadow {
  static const primarySoft = [
    BoxShadow(color: Color(0x4DA33A40), blurRadius: 14, offset: Offset(0, 6)),
  ];
  static const primaryHard = [
    BoxShadow(color: LgtmColors.primaryShadow, offset: Offset(0, 6)),
  ];
  static const muveHard = [
    BoxShadow(color: Color(0x668B6B70), offset: Offset(0, 3)),
  ];
  static const inkHard = [
    BoxShadow(color: Color(0xE63A2F2F), offset: Offset(6, 6)),
  ];
  static const rejectHard = [
    BoxShadow(color: LgtmColors.primarySoftShadow, offset: Offset(5, 5)),
  ];
  static const acceptHard = [
    BoxShadow(color: LgtmColors.greenSoft, offset: Offset(5, 5)),
  ];
  static const chipHard = [
    BoxShadow(color: LgtmColors.primarySoftShadow, offset: Offset(3, 3)),
  ];
  static const dialSoft = [
    BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
  ];
  static const buttonTiny = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 2)),
  ];
  static const navSoft = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, -2)),
  ];
}

/// Serif family. Use for the logo, screen titles, card names and the main
/// CTA on setup screens.
abstract final class LgtmSerif {
  static const family = 'Vollkorn';

  static const logo = TextStyle(
    fontFamily: family,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    height: 1.1,
  );
  static const display = TextStyle(
    fontFamily: family,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const title = TextStyle(
    fontFamily: family,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  static const cta = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const body = TextStyle(
    fontFamily: family,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
}

/// Sans family. Use for body copy, labels, chips, nav and status text.
abstract final class LgtmSans {
  static const family = 'PlusJakartaSans';

  static const navActive = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const navInactive = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
  static const label = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    height: 1.2,
  );
  static const title = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const body = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const bodySmall = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const button = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
}
