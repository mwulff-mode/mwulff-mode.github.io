import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/earnwise_theme.dart';

/// Standard bottom-sheet shell used across the app:
/// raised-surface background, rounded top, grab handle, safe-area bottom inset.
///
/// Prefer calling [showAppBottomSheet] over `showModalBottomSheet` directly so
/// every sheet picks up this shell automatically.
class BottomSheetShell extends StatelessWidget {
  final Widget child;
  const BottomSheetShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppLayout.gutter,
        AppSpacing.sm,
        AppLayout.gutter,
        MediaQuery.of(context).padding.bottom + AppLayout.gutter,
      ),
      decoration: BoxDecoration(
        color: t.palette.surfaceRaised,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(t.radii.modal),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: t.palette.surfaceSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// Shows a modal bottom sheet wrapped in [BottomSheetShell]. Use this instead
/// of `showModalBottomSheet` directly.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => BottomSheetShell(child: builder(ctx)),
  );
}
