import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// Shows a transient toast at the top of the screen using an [OverlayEntry].
///
/// Unlike a stateful in-screen toast (`_showStreakToast` + `setState`), this
/// helper can be called from any screen and survives rebuilds. The toast
/// fades in, holds for [showFor], then fades out and removes itself.
void showAppToast(
  BuildContext context, {
  required String title,
  String? subtitle,
  required IconData icon,
  Color iconColor = AppColors.ink,
  Color iconBackground = AppColors.creamDeep,
  Duration showFor = const Duration(milliseconds: 3500),
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AppToast(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      iconBackground: iconBackground,
      showFor: showFor,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _AppToast extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Duration showFor;
  final VoidCallback onDone;

  const _AppToast({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.showFor,
    required this.onDone,
  });

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast> {
  static const _fadeDuration = AppDurations.long;
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1);
    });
    Future.delayed(widget.showFor, () {
      if (!mounted) return;
      setState(() => _opacity = 0);
      Future.delayed(_fadeDuration, widget.onDone);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Positioned(
      top: mq.padding.top + 12,
      left: 20,
      right: 20,
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: _fadeDuration,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.iconBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, size: 22, color: widget.iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppText.bodyStrong,
                      ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: AppText.body.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
