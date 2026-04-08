import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_buttons.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/fade_route.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/typewriter_text.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 1;
  bool _choicesVisible = false;
  final _nameController = TextEditingController(text: 'Lisa');
  final _nameFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
      _choicesVisible = false;
    });
  }

  void _onTypewriterComplete() {
    setState(() => _choicesVisible = true);
  }

  void _finishOnboarding() {
    final state = context.read<AppState>();
    final name = _nameController.text.trim();
    if (name.isNotEmpty) state.setUserName(name);

    Navigator.of(context).pushAndRemoveUntil(
      fadeRoute(const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Back button
          Positioned(
            top: 12,
            left: 24,
            child: GestureDetector(
              onTap: () {
                if (_currentStep > 1) {
                  _goToStep(_currentStep - 1);
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.creamDeep,
                ),
                child: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                    size: 20, color: AppColors.ink),
              ),
            ),
          ),

          // Stepper dots
          Positioned(
            top: 24,
            right: 24,
            child: Row(
              children: List.generate(2, (i) {
                final step = i + 1;
                final isActive = step == _currentStep;
                final isDone = step < _currentStep;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  width: isActive ? 24 : 7,
                  height: 7,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: (isActive || isDone)
                        ? AppColors.primary
                        : AppColors.creamDeep,
                  ),
                );
              }),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _buildStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 1:
        return _buildPreferencesStep();
      case 2:
        return _buildNameStep();
      default:
        return const SizedBox();
    }
  }

  // ─── Step 1: Preferences (multi-select) ───
  Widget _buildPreferencesStep() {
    return Consumer<AppState>(
      key: const ValueKey('step1'),
      builder: (context, state, _) {
        final prefs = state.selectedPreferences;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TypewriterText(
              key: const ValueKey('tw1'),
              text: 'What kind of games do you enjoy?',
              onComplete: _onTypewriterComplete,
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedOpacity(
              opacity: _choicesVisible ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: Text(
                'Pick as many as you like',
                style: AppText.body.copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppColors.inkTertiary,
                ),
              ),
            ),
            const Spacer(),
            AnimatedOpacity(
              opacity: _choicesVisible ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: AnimatedSlide(
                offset: _choicesVisible ? Offset.zero : const Offset(0, 0.05),
                duration: const Duration(milliseconds: 400),
                child: Column(
                  children: [
                    _prefChoice(
                        'Puzzle games',
                        'Candy Crush, Tetris, Bejeweled',
                        PhosphorIcons.puzzlePiece(),
                        AppColors.taskVideo,
                        'puzzle',
                        prefs),
                    const SizedBox(height: 10),
                    _prefChoice(
                        'Word games',
                        'Wordle, Scrabble GO, Words With Friends',
                        PhosphorIcons.textAa(),
                        AppColors.primary,
                        'word',
                        prefs),
                    const SizedBox(height: 10),
                    _prefChoice(
                        'Card & board games',
                        'Solitaire, Mahjong, Yahtzee',
                        PhosphorIcons.cards(),
                        AppColors.taskGame,
                        'card',
                        prefs),
                    const SizedBox(height: 10),
                    _prefChoice(
                        'Trivia & brain teasers',
                        'Trivia Crack, Jeopardy, Sudoku',
                        PhosphorIcons.lightbulb(),
                        AppColors.taskOffers,
                        'trivia',
                        prefs),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: prefs.isNotEmpty
                    ? () => _goToStep(2)
                    : null, // goes to name step
                style: AppButtonStyles.primary,
                child: Text('Continue', style: AppText.ctaLabel),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _prefChoice(String label, String description, IconData icon,
      Color color, String key, List<String> selected) {
    final isSelected = selected.contains(key);
    return AppCard(
      onTap: () => context.read<AppState>().togglePreference(key),
      selected: isSelected,
      constraints: const BoxConstraints(minHeight: 64),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.listItem,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isSelected
                ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                : PhosphorIcons.circle(),
            size: 24,
            color: isSelected ? AppColors.primary : AppColors.creamDeep,
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Name ───
  Widget _buildNameStep() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TypewriterText(
          key: const ValueKey('tw2'),
          text: 'One last thing —\nwhat should we call you?',
          onComplete: _onTypewriterComplete,
        ),
        const Spacer(),
        Center(
          child: _choicesVisible
              ? TextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: AppText.display,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Your name',
                  ),
                  onSubmitted: (_) => _finishOnboarding(),
                )
              : const SizedBox.shrink(),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _finishOnboarding,
            style: AppButtonStyles.primary,
            child: Text("That's me", style: AppText.ctaLabel),
          ),
        ),
      ],
    );
  }
}
