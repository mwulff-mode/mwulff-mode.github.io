import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final VoidCallback? onComplete;
  final Duration charDelay;

  const TypewriterText({
    super.key,
    required this.text,
    this.onComplete,
    this.charDelay = const Duration(milliseconds: 28),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  Timer? _timer;
  int _charIndex = 0;
  bool _cursorVisible = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _startTyping();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    });
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.charDelay, (_) {
      if (_charIndex < widget.text.length) {
        setState(() {
          _displayedText = widget.text.substring(0, _charIndex + 1);
          _charIndex++;
        });
      } else {
        _timer?.cancel();
        _cursorTimer?.cancel();
        if (mounted) setState(() => _cursorVisible = false);
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppText.prompt,
        children: [
          TextSpan(text: _displayedText),
          if (_cursorVisible)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                width: 2,
                height: 24,
                margin: const EdgeInsets.only(left: 2),
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}
