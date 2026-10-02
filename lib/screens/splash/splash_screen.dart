import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../core/design_tokens.dart';
import '../../widgets/design_canvas.dart';
import '../../widgets/lgtm_logo.dart';

/// The first screen: the wordmark on cream for a beat, then straight to the
/// auth gate. Nothing here decides where the app goes, that is the gate's job.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.hold = const Duration(milliseconds: 1400),
    this.nextRoute = LgtmRoutes.authGate,
  });

  /// How long the wordmark stays up before the app moves on.
  final Duration hold;

  final String nextRoute;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.hold, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(widget.nextRoute);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LgtmColors.bg,
      body: LgtmStatusBarInset(
        child: Center(
          child: Semantics(
            header: true,
            label: 'LGTM',
            child: const LgtmLogo(size: 46, color: LgtmColors.green),
          ),
        ),
      ),
    );
  }
}
