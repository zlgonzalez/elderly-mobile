import 'package:flutter/material.dart';

/// Custom ScrollBehavior that eliminates the Android 12+ stretching overscroll distortion
/// (which causes text to elongate vertically during scroll/fling) and provides clean,
/// non-stretching clamping scroll physics across the entire application.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Returning child directly prevents StretchingOverscrollIndicator from scaling/elongating widgets vertically.
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
