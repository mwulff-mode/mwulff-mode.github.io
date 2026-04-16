import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/earnwise_theme.dart';
import '../theme/theme_catalog.dart';
import '../widgets/press_scale.dart';
import '../widgets/screen_scaffold.dart';

/// Theme picker. Reachable from the gear icon on `ProfileScreen`. Lists
/// every theme in `kEarnWiseThemes`; tapping a row calls
/// `AppState.setTheme` which rebuilds the whole app through the
/// `Consumer<AppState>` in `main.dart`.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Row labels in the same order as `kEarnWiseThemes`. A parallel list
  /// of named records keeps the name + subtitle together without needing
  /// a `name` field on `EarnWiseTheme` itself.
  static const List<({String name, String subtitle})> _rowLabels = [
    (name: 'Cream', subtitle: 'Warm and soft. The original.'),
    (name: 'Plum', subtitle: 'Bold violet, white surface.'),
    (name: 'Bumble', subtitle: 'Honey yellow with black accents.'),
    (name: 'Clue', subtitle: 'Calm gray with deep teal.'),
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      child: Consumer<AppState>(
        builder: (context, state, _) {
          final t = context.theme;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.pageTop),
                _Header(onBack: () => Navigator.of(context).maybePop()),
                const SizedBox(height: AppSpacing.sectionGap),
                Text(
                  'Theme',
                  style: AppText.title.copyWith(color: t.palette.ink),
                ),
                const SizedBox(height: AppSpacing.tight),
                Text(
                  "Pick how EarnWise looks. The change happens instantly.",
                  style: AppText.body.copyWith(color: t.palette.inkSecondary),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                for (var i = 0; i < kEarnWiseThemes.length; i++) ...[
                  _ThemeRow(
                    name: _rowLabels[i].name,
                    subtitle: _rowLabels[i].subtitle,
                    theme: kEarnWiseThemes[i],
                    selected: state.currentTheme == kEarnWiseThemes[i],
                  ),
                  if (i < kEarnWiseThemes.length - 1)
                    const SizedBox(height: AppSpacing.rowGap),
                ],
                const SizedBox(height: AppSpacing.blockGap),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    return Row(
      children: [
        PressScale(
          onTap: onBack,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.palette.surfaceRaised,
              shape: BoxShape.circle,
              border: Border.all(color: t.palette.hairline),
            ),
            child: Icon(
              PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
              size: 18,
              color: t.palette.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final EarnWiseTheme theme;
  final bool selected;

  const _ThemeRow({
    required this.name,
    required this.subtitle,
    required this.theme,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    final fill =
        selected ? t.palette.surfaceSelected : t.palette.surfaceRaised;
    final borderColor =
        selected ? t.palette.brand : t.palette.hairline;

    return PressScale(
      haptic: HapticIntensity.confirm,
      onTap: () => context.read<AppState>().setTheme(theme),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPad),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(t.radii.card),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: t.elevation.card,
        ),
        child: Row(
          children: [
            _CornerSplitSwatch(
              topLeft: theme.palette.surface,
              bottomRight: theme.palette.brand,
            ),
            const SizedBox(width: AppSpacing.cardPad),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppText.listItem.copyWith(color: t.palette.ink),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  Text(
                    subtitle,
                    style: AppText.body
                        .copyWith(color: t.palette.inkSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _CornerSplitSwatch extends StatelessWidget {
  final Color topLeft;
  final Color bottomRight;

  const _CornerSplitSwatch({
    required this.topLeft,
    required this.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: CustomPaint(
          painter: _SplitPainter(topLeft: topLeft, bottomRight: bottomRight),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _SplitPainter extends CustomPainter {
  final Color topLeft;
  final Color bottomRight;

  _SplitPainter({required this.topLeft, required this.bottomRight});

  @override
  void paint(Canvas canvas, Size size) {
    final tlPaint = Paint()..color = topLeft;
    final brPaint = Paint()..color = bottomRight;
    canvas.drawRect(Offset.zero & size, tlPaint);
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, brPaint);
  }

  @override
  bool shouldRepaint(covariant _SplitPainter oldDelegate) =>
      oldDelegate.topLeft != topLeft || oldDelegate.bottomRight != bottomRight;
}

class _RadioDot extends StatelessWidget {
  final bool selected;

  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? t.palette.brand : Colors.transparent,
        border: Border.all(
          color: selected ? t.palette.brand : t.palette.inkTertiary,
          width: 1.5,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }
}
