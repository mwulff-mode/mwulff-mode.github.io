import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/app_card.dart';
import '../widgets/app_toast.dart';
import '../services/haptics.dart';
import '../widgets/press_scale.dart';
import '../widgets/bottom_sheet_shell.dart';
import '../widgets/reward_glow.dart';
import '../widgets/fade_route.dart';
import '../widgets/screen_scaffold.dart';
import 'journey_screen.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _showGift = true;
  bool _giftFading = false;
  bool _homeRevealed = false;
  int _navIndex = 0;
  String? _selectedGame;

  late AnimationController _giftAmountController;
  late AnimationController _giftLabelController;
  final RewardGlowController _giftGlow = RewardGlowController();
  final RewardGlowController _ringGlow = RewardGlowController();
  double _lastGoalProgress = 0;

  @override
  void initState() {
    super.initState();
    _giftAmountController = AnimationController(
        vsync: this, duration: AppDurations.hero);
    _giftLabelController = AnimationController(
        vsync: this, duration: AppDurations.long);
    _playGiftAnimation();
  }

  void _playGiftAnimation() async {
    final state = context.read<AppState>();
    if (state.screen5Played) {
      setState(() {
        _showGift = false;
        _homeRevealed = true;
      });
      return;
    }
    state.screen5Played = true;

    await Future.delayed(const Duration(milliseconds: 200));
    _giftGlow.play();
    Haptics.celebrate(CelebrateMoments.welcomeGift);
    await Future.delayed(const Duration(milliseconds: 300));
    _giftAmountController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _giftLabelController.forward();

    await Future.delayed(const Duration(milliseconds: 1700));
    setState(() => _giftFading = true);
    await Future.delayed(AppDurations.long);
    setState(() {
      _showGift = false;
      _homeRevealed = true;
    });

    // Add journey entries
    state.addJourneyEntry(
      '125 Stars to get you started',
      'Welcome gift',
      PhosphorIcons.star(PhosphorIconsStyle.duotone),
      AppColors.accent,
      AppColors.accentLight,
    );
    await Future.delayed(const Duration(milliseconds: 2500));
    state.addJourneyEntry(
      'Hey ${state.userName}, let\'s start earning',
      'You joined EarnWise',
      PhosphorIcons.handWaving(PhosphorIconsStyle.duotone),
      AppColors.primary,
      AppColors.primaryPale,
    );
  }

  void _completeTask(String task) {
    final state = context.read<AppState>();
    if (state.completedTasks.contains(task)) return;

    Haptics.reward();
    final goalCompleted = state.completeTask(task);

    final taskNames = {
      'profile': 'Profile completed',
      'survey': 'Survey completed',
      'game': _selectedGame ?? 'Game played'
    };
    final taskStarValues = {'profile': 250, 'survey': 375, 'game': 750};
    final taskIcons = {
      'profile': PhosphorIcons.userCircle(PhosphorIconsStyle.duotone),
      'survey': PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
      'game': PhosphorIcons.gameController(PhosphorIconsStyle.duotone),
    };
    final taskColors = {
      'profile': AppColors.primary,
      'survey': AppColors.taskSurvey,
      'game': AppColors.taskGame
    };
    final taskBgs = {
      'profile': AppColors.primaryPale,
      'survey': AppColors.taskSurveyBg,
      'game': AppColors.taskGameBg
    };

    state.addJourneyEntry(
      'Earned ${taskStarValues[task]} Stars — ${taskNames[task]}',
      'Task completed',
      taskIcons[task]!,
      taskColors[task]!,
      taskBgs[task]!,
    );

    if (state.tasksCompleted == 1) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        state.streakCount = 1;
        state.addJourneyEntry(
          '1-day streak — nice start!',
          'Come back tomorrow to keep it going',
          PhosphorIcons.flame(PhosphorIconsStyle.fill),
          const Color(0xFFFF6B35),
          const Color(0xFFFFF4ED),
        );
        showAppToast(
          context,
          title: '1-day streak — nice start',
          subtitle: 'Come back tomorrow to keep it going',
          icon: PhosphorIcons.flame(PhosphorIconsStyle.fill),
          iconColor: const Color(0xFFFF6B35),
          iconBackground: const Color(0xFFFFF0E8),
        );
      });
    }

    // Goal completed — hold the solid fill, then advance
    if (goalCompleted) {
      Haptics.milestone();
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        final s = context.read<AppState>();
        s.advanceGoal();
        if (s.isLegend) {
          Haptics.celebrate(CelebrateMoments.legendReached);
        }
        s.addJourneyEntry(
          'Goal ${s.goalIndex} complete!',
          s.isLegend
              ? "You've earned it all."
              : 'Next goal: ${AppState.formatNumber(s.currentGoal.goalStars)} Stars',
          PhosphorIcons.trophy(PhosphorIconsStyle.fill),
          s.ringColor,
          s.ringColor.withValues(alpha: 0.1),
        );
      });
    }

    if (state.allTasksCompleted) {
      Haptics.milestone();
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        state.addJourneyEntry(
          'All starter tasks done — Earn More unlocked!',
          'Offers, Receipts & Games are now available',
          PhosphorIcons.lockSimpleOpen(PhosphorIconsStyle.duotone),
          AppColors.primary,
          AppColors.primaryPale,
        );
      });
    }
  }

  void _showGamePicker(AppState state) {
    if (state.completedTasks.contains('game')) return;
    showAppBottomSheet(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose your game',
              style: AppText.sheetTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You\'ll earn 750 Stars once you reach 1 hour of play time. Pick the one you\'ll enjoy most — you can\'t switch later.',
              textAlign: TextAlign.center,
              style: AppText.body
                  .copyWith(fontWeight: FontWeight.w400, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.taskGameBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.clock(PhosphorIconsStyle.bold),
                      size: 16, color: AppColors.taskGame),
                  const SizedBox(width: 6),
                  Text(
                    'About 1 hour total · play at your own pace',
                    style: AppText.caption.copyWith(color: AppColors.taskGame),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _gameOption(
                ctx,
                'Candy Crush',
                'Match-3 puzzle — swap & match colorful candies',
                PhosphorIcons.diamondsFour(PhosphorIconsStyle.duotone),
                const Color(0xFFE8913A),
                state),
            const SizedBox(height: 10),
            _gameOption(
                ctx,
                'Solitaire',
                'Classic card game — sort cards into suits',
                PhosphorIcons.cards(PhosphorIconsStyle.duotone),
                AppColors.primary,
                state),
            const SizedBox(height: 10),
            _gameOption(
                ctx,
                'Word Search',
                'Find hidden words in a letter grid',
                PhosphorIcons.textAa(PhosphorIconsStyle.duotone),
                AppColors.taskVideo,
                state),
          ],
        );
      },
    );
  }

  Widget _gameOption(BuildContext ctx, String name, String description,
      IconData icon, Color color, AppState state) {
    return AppCard(
      onTap: () {
        Navigator.of(ctx).pop();
        _selectedGame = name;
        _completeTask('game');
      },
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 26, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.listItem),
                const SizedBox(height: 2),
                Text(description,
                    style: AppText.body.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.inkTertiary)),
              ],
            ),
          ),
          Icon(PhosphorIcons.play(PhosphorIconsStyle.fill),
              size: 28, color: color),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _giftAmountController.dispose();
    _giftLabelController.dispose();
    _giftGlow.dispose();
    _ringGlow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      safeArea: false,
      padding: EdgeInsets.zero,
      animatedGradient: true,
      child: Stack(
        children: [
          // Home content
          if (_homeRevealed) _buildHomeContent(),

          // Gift overlay
          if (_showGift) _buildGiftOverlay(),

          // Currency toggle
          if (_homeRevealed && !_showGift)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 80,
              right: 16,
              child: Consumer<AppState>(
                builder: (context, state, _) {
                  return PressScale(
                    onTap: () => state.toggleCurrency(),
                    haptic: HapticIntensity.tick,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.black.withValues(alpha: 0.08)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            state.showDollars
                                ? PhosphorIcons.currencyDollar(
                                    PhosphorIconsStyle.bold)
                                : PhosphorIcons.star(PhosphorIconsStyle.fill),
                            size: 16,
                            color: state.showDollars
                                ? AppColors.progress
                                : AppColors.accent,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            state.showDollars ? '\$' : '★',
                            style: AppText.caption
                                .copyWith(color: AppColors.inkSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGiftOverlay() {
    final state = context.read<AppState>();
    return AnimatedOpacity(
      opacity: _giftFading ? 0 : 1,
      duration: AppDurations.long,
      child: Container(
        color: AppColors.cream,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RewardGlow(
                controller: _giftGlow,
                glowColor: AppColors.primary,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, Color(0xFF2BA08E)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                      size: 48, color: Colors.white),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ScaleTransition(
                scale: CurvedAnimation(
                    parent: _giftAmountController, curve: AppCurves.warmOut),
                child: Text(
                  '125',
                  style: GoogleFonts.outfit(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -3,
                  ),
                ),
              ),
              ScaleTransition(
                scale: CurvedAnimation(
                    parent: _giftAmountController, curve: AppCurves.warmOut),
                child: Text(
                  'Stars',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary.withValues(alpha: 0.6),
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _giftLabelController,
                child: Text(
                  'A little head start, ${state.userName}',
                  style: AppText.sectionTitle.copyWith(letterSpacing: -0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 24,
                  right: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Conversational card
                    _buildConvCard(state),
                    const SizedBox(height: 28),

                    // Balance + Ring row
                    _buildBalanceRow(state),
                    const SizedBox(height: AppSpacing.lg),

                    // Starter tasks
                    _buildStarterTasks(state),
                    const SizedBox(height: AppSpacing.lg),

                    // Earn more section
                    _buildEarnMore(state),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Bottom nav
            _buildBottomNav(),
          ],
        );
      },
    );
  }

  Widget _buildConvCard(AppState state) {
    return PressScale(
      onTap: () {
        Navigator.of(context).push(fadeRoute(const JourneyScreen()));
      },
      haptic: HapticIntensity.tick,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: state.convCardIconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(state.convCardIcon,
                  size: 20, color: state.convCardIconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.convCardMsg.isEmpty
                    ? 'Hey ${state.userName}, let\'s start earning'
                    : state.convCardMsg,
                style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceRow(AppState state) {
    final isSolidFill = state.goalProgress >= 100 || state.isLegend;
    final ringColor = state.ringColor;
    final centerTextColor = isSolidFill ? Colors.white : AppColors.ink;
    final centerSubColor = isSolidFill
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.inkTertiary;

    // Rising-edge detector: trigger ring glow when goalProgress crosses 100.
    final currentProgress = state.goalProgress;
    if (_lastGoalProgress < 100 && currentProgress >= 100) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ringGlow.play();
      });
    }
    _lastGoalProgress = currentProgress;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your balance',
                style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    state.formatBalance(),
                    style: GoogleFonts.outfit(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -2.5,
                      height: 1,
                    ),
                  ),
                  if (!state.showDollars) ...[
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                          size: 24, color: AppColors.accent),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.progressLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.arrowUp(PhosphorIconsStyle.bold),
                        size: 14, color: AppColors.progress),
                    const SizedBox(width: 6),
                    Text(
                      state.formatToday(),
                      style: AppText.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.progress),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Goal ring
        RewardGlow(
          controller: _ringGlow,
          glowColor: ringColor,
          child: AnimatedContainer(
            duration: AppDurations.long,
            curve: AppCurves.warmOut,
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isSolidFill
                  ? [
                      BoxShadow(
                          color: ringColor.withValues(
                              alpha: state.isLegend ? 0.4 : 0.3),
                          blurRadius: state.isLegend ? 40 : 30,
                          spreadRadius: state.isLegend ? 8 : 4)
                    ]
                  : [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: state.goalProgress),
                  duration: AppDurations.hero,
                  curve: AppCurves.warmOut,
                  builder: (context, value, _) {
                    return CustomPaint(
                      size: const Size(170, 170),
                      painter: _GoalRingPainter(
                        percentage: value,
                        trackColor: state.trackColor,
                        fillColor: ringColor,
                        solidFill: isSolidFill,
                      ),
                    );
                  },
                ),
                // Center content
                if (state.isLegend)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.crown(PhosphorIconsStyle.fill),
                          size: 28, color: Colors.white),
                      const SizedBox(height: 6),
                      Text("You've earned",
                          style: AppText.caption.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.85))),
                      Text('it all.',
                          style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ],
                  )
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${state.goalProgress.round()}%',
                        style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: centerTextColor,
                            letterSpacing: -1),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.formatRingProgress(),
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: centerSubColor),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStarterTasks(AppState state) {
    if (state.goalIndex == 0) {
      return _buildOnboardingTasks(state);
    }
    return _buildDailyTasks(state);
  }

  Widget _buildOnboardingTasks(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete all 3 to cash out \$2',
          style: AppText.listItem.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Finish these tasks and withdraw to PayPal right away',
          style: AppText.caption.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 14),
        _taskCard(
          'Complete your profile',
          '~2 min',
          PhosphorIcons.userCircle(PhosphorIconsStyle.duotone),
          AppColors.primary,
          'profile',
          state,
        ),
        const SizedBox(height: 10),
        _taskCard(
          'Complete a survey',
          '~5 min',
          PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
          AppColors.taskSurvey,
          'survey',
          state,
        ),
        const SizedBox(height: 10),
        _taskCard(
          'Play a game',
          '~1 hour total',
          PhosphorIcons.gameController(PhosphorIconsStyle.duotone),
          AppColors.taskGame,
          'game',
          state,
          onTap: () => _showGamePicker(state),
        ),
      ],
    );
  }

  Widget _buildDailyTasks(AppState state) {
    final done = state.dailyTasksCompleted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Today's tasks",
              style: AppText.listItem.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              '$done/3 done',
              style: AppText.body.copyWith(
                  fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Complete daily tasks to keep earning',
          style: AppText.caption.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 14),
        _taskCard(
          'Complete a daily survey',
          '~5 min · 500 Stars',
          PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
          AppColors.taskSurvey,
          'daily_survey',
          state,
        ),
        const SizedBox(height: 10),
        _taskCard(
          'Play for 15 minutes',
          '~15 min · 650 Stars',
          PhosphorIcons.gameController(PhosphorIconsStyle.duotone),
          AppColors.taskGame,
          'daily_play',
          state,
        ),
        const SizedBox(height: 10),
        _taskCard(
          'Check out an offer',
          '~3 min · 350 Stars',
          PhosphorIcons.tag(PhosphorIconsStyle.duotone),
          AppColors.taskOffers,
          'daily_offer',
          state,
        ),
      ],
    );
  }

  Widget _taskCard(String title, String meta, IconData icon, Color color,
      String taskKey, AppState state,
      {VoidCallback? onTap}) {
    final completed = state.completedTasks.contains(taskKey);
    return PressScale(
      onTap: completed ? null : (onTap ?? () => _completeTask(taskKey)),
      haptic: HapticIntensity.tick,
      enabled: !completed,
      child: AnimatedOpacity(
        opacity: completed ? 0.55 : 1,
        duration: AppDurations.medium,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: completed ? AppColors.white : AppColors.primary,
            borderRadius: BorderRadius.circular(18),
            border: completed
                ? Border.all(color: Colors.black.withValues(alpha: 0.06))
                : null,
            boxShadow: [
              BoxShadow(
                color: completed
                    ? Colors.black.withValues(alpha: 0.05)
                    : AppColors.primary.withValues(alpha: 0.25),
                blurRadius: completed ? 4 : 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: completed ? color.withValues(alpha: 0.12) : color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    size: 24, color: completed ? color : Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppText.bodyStrong.copyWith(
                            color: completed ? AppColors.ink : Colors.white)),
                    const SizedBox(height: 2),
                    Text(meta,
                        style: AppText.body.copyWith(
                            fontWeight: FontWeight.w400,
                            color: completed
                                ? AppColors.inkSecondary
                                : Colors.white.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              Icon(
                completed
                    ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                    : PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                size: completed ? 40 : 24,
                color: completed
                    ? AppColors.progress
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarnMore(AppState state) {
    final unlocked = state.allTasksCompleted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (!unlocked) ...[
              Icon(PhosphorIcons.lockSimple(), size: 14, color: AppColors.ink),
              const SizedBox(width: 6),
            ],
            Text(
              'Earn more',
              style: AppText.bodyStrong,
            ),
          ],
        ),
        if (!unlocked) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Finish your first 3 tasks to unlock these',
            style: AppText.caption.copyWith(
                fontWeight: FontWeight.w500, color: AppColors.inkTertiary),
          ),
        ],
        const SizedBox(height: 12),
        AnimatedOpacity(
          opacity: unlocked ? 1 : 0.4,
          duration: AppDurations.long,
          child: Row(
            children: [
              _earnTile(
                  'Offers',
                  'Save & earn',
                  PhosphorIcons.tag(PhosphorIconsStyle.duotone),
                  AppColors.taskOffers,
                  AppColors.taskOffersBg),
              const SizedBox(width: 12),
              _earnTile(
                  'Receipts',
                  'Earn cashback',
                  PhosphorIcons.receipt(PhosphorIconsStyle.duotone),
                  AppColors.taskReceipts,
                  AppColors.taskReceiptsBg),
              const SizedBox(width: 12),
              _earnTile(
                  'Games',
                  'Play & earn',
                  PhosphorIcons.gameController(PhosphorIconsStyle.duotone),
                  AppColors.taskGame,
                  AppColors.taskGameBg),
            ],
          ),
        ),
      ],
    );
  }

  Widget _earnTile(
      String title, String sub, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: AppText.bodyStrong),
            const SizedBox(height: 2),
            Text(sub,
                style: AppText.caption.copyWith(fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cream.withValues(alpha: 0), AppColors.cream],
          stops: const [0, 0.35],
        ),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 12, top: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _navItem(0, PhosphorIcons.house(PhosphorIconsStyle.fill), 'Home'),
              _navItem(1, PhosphorIcons.wallet(), null),
              _navItem(2, PhosphorIcons.user(), null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String? label) {
    final isActive = _navIndex == index;
    return PressScale(
      onTap: () => setState(() => _navIndex = index),
      haptic: HapticIntensity.tick,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        curve: AppCurves.warmOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 24 : 24,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.ink : AppColors.inkTertiary,
            ),
            if (isActive && label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.caption.copyWith(color: AppColors.ink),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoalRingPainter extends CustomPainter {
  final double percentage;
  final Color trackColor;
  final Color fillColor;
  final bool solidFill;

  _GoalRingPainter({
    required this.percentage,
    required this.trackColor,
    required this.fillColor,
    required this.solidFill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 28) / 2;
    final pct = (percentage / 100).clamp(0.0, 1.0);

    if (solidFill) {
      final solidPaint = Paint()..color = fillColor;
      canvas.drawCircle(center, radius + 11, solidPaint);
    } else {
      // Subtle inner fill
      final centerFill = Paint()..color = fillColor.withValues(alpha: 0.06);
      canvas.drawCircle(center, radius - 12, centerFill);

      // Track
      final trackPaint = Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius, trackPaint);

      // Progress arc
      final arcPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * pi * pct;
      if (sweepAngle > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -pi / 2,
          sweepAngle,
          false,
          arcPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GoalRingPainter old) =>
      old.percentage != percentage ||
      old.solidFill != solidFill ||
      old.fillColor != fillColor;
}
