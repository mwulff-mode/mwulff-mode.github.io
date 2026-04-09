import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../data/games.dart';
import '../state/app_state.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/app_card.dart';
import '../widgets/app_toast.dart';
import '../services/haptics.dart';
import '../widgets/press_scale.dart';
import '../widgets/bottom_sheet_shell.dart';
import '../widgets/animated_counter.dart';
import '../widgets/reward_glow.dart';
import '../widgets/fade_route.dart';
import '../widgets/screen_scaffold.dart';
import 'journey_screen.dart';
import 'conv_card_content.dart';
import 'game_detail_screen.dart';
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
    _giftAmountController =
        AnimationController(vsync: this, duration: AppDurations.hero);
    _giftLabelController =
        AnimationController(vsync: this, duration: AppDurations.long);
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
      '\$0.17 to get you started',
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
      'game': _selectedGame ?? 'Game played',
      'daily_survey': 'Daily survey completed',
      'daily_play': 'Daily play completed',
      'daily_offer': 'Daily offer completed',
    };
    final taskIcons = {
      'profile': PhosphorIcons.userCircle(PhosphorIconsStyle.duotone),
      'survey': PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
      'game': PhosphorIcons.gameController(PhosphorIconsStyle.duotone),
      'daily_survey': PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
      'daily_play': PhosphorIcons.gameController(PhosphorIconsStyle.duotone),
      'daily_offer': PhosphorIcons.tag(PhosphorIconsStyle.duotone),
    };
    final taskColors = {
      'profile': AppColors.primary,
      'survey': AppColors.taskSurvey,
      'game': AppColors.taskGame,
      'daily_survey': AppColors.taskSurvey,
      'daily_play': AppColors.taskGame,
      'daily_offer': AppColors.taskOffers,
    };
    final taskBgs = {
      'profile': AppColors.primaryPale,
      'survey': AppColors.taskSurveyBg,
      'game': AppColors.taskGameBg,
      'daily_survey': AppColors.taskSurveyBg,
      'daily_play': AppColors.taskGameBg,
      'daily_offer': AppColors.taskOffersBg,
    };

    final stars = AppState.taskStars[task] ?? 0;
    final dollars = (stars / AppState.starsPerDollar).toStringAsFixed(2);
    state.addJourneyEntry(
      'Earned \$$dollars — ${taskNames[task] ?? 'Task completed'}',
      'Task completed',
      taskIcons[task] ?? PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone),
      taskColors[task] ?? AppColors.primary,
      taskBgs[task] ?? AppColors.primaryPale,
    );

    if (state.tasksCompleted == 1) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        state.streakCount = 1;
        state.addJourneyEntry(
          '1-day streak — keep it rolling',
          'Every task adds to your balance',
          PhosphorIcons.flame(PhosphorIconsStyle.fill),
          const Color(0xFFFF6B35),
          const Color(0xFFFFF4ED),
        );
        showAppToast(
          context,
          title: '1-day streak — keep it rolling',
          subtitle: 'Every task adds to your balance',
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
              : 'Next goal: \$${(s.currentGoal.goalStars / AppState.starsPerDollar).toStringAsFixed(2)}',
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
    // Returns the picked game name via Navigator.pop(name); the .then below
    // runs AFTER the sheet's dismiss animation completes, so the conv-card
    // rebuild from _completeTask doesn't visually fight the fading scrim.
    showAppBottomSheet<String>(
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
              'Tap a game to see the details. You can come back and pick a different one anytime.',
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
    ).then((picked) {
      if (picked == null || !mounted) return;
      final game = gamesByName[picked];
      if (game == null) return;
      _selectedGame = picked;
      Navigator.of(context).push(
        fadeRoute(GameDetailScreen(
          game: game,
          onInstall: () => _completeTask('game'),
        )),
      );
    });
  }

  Widget _gameOption(BuildContext ctx, String name, String description,
      IconData icon, Color color, AppState state) {
    return AppCard(
      onTap: () => Navigator.of(ctx).pop(name),
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
              size: 32, color: AppColors.primary),
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

          // Floating glass nav bar with a cream-to-transparent gradient fade
          // above it so scrolling content eases into the nav instead of
          // abruptly cutting behind the glass pill.
          if (_homeRevealed && !_showGift)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: false,
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    top: 40,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.cream.withValues(alpha: 0),
                        AppColors.cream.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                  child: Center(child: _buildBottomNav()),
                ),
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
                  '\$0.17',
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
                  'Welcome gift',
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
                    const SizedBox(height: 16),

                    // Balance + Ring row
                    _buildBalanceRow(state),
                    const SizedBox(height: AppSpacing.md),

                    // Starter tasks
                    _buildStarterTasks(state),
                    const SizedBox(height: AppSpacing.lg),

                    // Earn more section
                    _buildEarnMore(state),
                    // Extra bottom space so content clears the floating glass nav
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Conversational card content — see [conv_card_content.dart] to edit messages.
  ConvCard _convCardContent(AppState state) => resolveConvCard(state);

  Widget _buildConvCard(AppState state) {
    final content = _convCardContent(state);
    return PressScale(
      onTap: () {
        Navigator.of(context).push(fadeRoute(const JourneyScreen()));
      },
      haptic: null,
      pressedScale: 0.99, // large surface: subtler shrink
      child: Container(
        // Fixed height so the card never reflows the page when the message
        // grows from one line to two. 80px = 16+16 padding + room for two
        // lines of bodyStrong (16px @ ~1.25 line height).
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: content.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(content.icon, size: 20, color: content.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                content.message,
                style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBubble(
      IconData icon, int rawValue, String label, AppState state) {
    final numberStyle = GoogleFonts.outfit(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: AppColors.ink,
      letterSpacing: -0.5,
    );

    String format(int v) =>
        '\$${(v / AppState.starsPerDollar).toStringAsFixed(2)}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: AppColors.creamDeep,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: AppColors.inkSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedCounter(
              value: rawValue,
              format: format,
              style: numberStyle,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppText.caption.copyWith(fontWeight: FontWeight.w400),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBalanceRow(AppState state) {
    final isSolidFill = state.goalProgress >= 100 || state.isLegend;
    final ringColor = state.ringColor;

    // Rising-edge detector: trigger ring glow when goalProgress crosses 100.
    final currentProgress = state.goalProgress;
    if (_lastGoalProgress < 100 && currentProgress >= 100) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ringGlow.play();
      });
    }
    _lastGoalProgress = currentProgress;

    return LayoutBuilder(builder: (context, constraints) {
      // Ring takes 52% of content width; each stat takes the remaining 24%.
      // Stat icon is 50px so the column is narrow enough to give the ring
      // plenty of space even on small phones.
      final ringSize = (constraints.maxWidth * 0.52).clamp(140.0, 220.0);

      final ring = RewardGlow(
        controller: _ringGlow,
        glowColor: ringColor,
        child: AnimatedContainer(
          duration: AppDurations.long,
          curve: AppCurves.warmOut,
          width: ringSize,
          height: ringSize,
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
            clipBehavior: Clip.none,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: state.goalProgress),
                duration: AppDurations.hero,
                curve: AppCurves.warmOut,
                builder: (context, value, _) {
                  return CustomPaint(
                    size: Size(ringSize, ringSize),
                    painter: _GoalRingPainter(
                      percentage: value,
                      fillColor: ringColor,
                    ),
                  );
                },
              ),
              if (state.isLegend)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.crown(PhosphorIconsStyle.fill),
                        size: 28, color: Colors.white),
                    const SizedBox(height: 4),
                    Text("You've\nearned it all.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.formatGoal(),
                      style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Daily Goal',
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left stat — takes remaining space beside the ring
          Expanded(
            child: _buildStatBubble(
              PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
              state.stars,
              'Balance',
              state,
            ),
          ),

          // Center ring — fixed proportional size
          ring,

          // Right stat
          Expanded(
            child: _buildStatBubble(
              PhosphorIcons.lightning(PhosphorIconsStyle.duotone),
              state.earnedToday,
              'Today',
              state,
            ),
          ),
        ],
      );
    }); // LayoutBuilder
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
          '~5 min · \$0.67',
          PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
          AppColors.taskSurvey,
          'daily_survey',
          state,
        ),
        const SizedBox(height: 10),
        _taskCard(
          'Play for 15 minutes',
          '~15 min · \$0.87',
          PhosphorIcons.gameController(PhosphorIconsStyle.duotone),
          AppColors.taskGame,
          'daily_play',
          state,
        ),
        const SizedBox(height: 10),
        _taskCard(
          'Check out an offer',
          '~3 min · \$0.47',
          PhosphorIcons.tag(PhosphorIconsStyle.duotone),
          AppColors.taskOffers,
          'daily_offer',
          state,
        ),
      ],
    );
  }

  /// Indigo "pills" style task card — icon pill + play circle action.
  Widget _taskCard(String title, String meta, IconData icon, Color color,
      String taskKey, AppState state,
      {VoidCallback? onTap}) {
    final completed = state.completedTasks.contains(taskKey);
    final bg = color.withValues(alpha: 0.10);
    return PressScale(
      onTap: completed ? null : (onTap ?? () => _completeTask(taskKey)),
      haptic: null,
      enabled: !completed,
      child: AnimatedOpacity(
        opacity: completed ? 0.55 : 1,
        duration: AppDurations.medium,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon pill
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppText.bodyStrong
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                completed
                    ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                    : PhosphorIcons.playCircle(PhosphorIconsStyle.fill),
                size: 48,
                color: completed ? AppColors.progress : AppColors.primary,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _navItem(0, PhosphorIcons.house(PhosphorIconsStyle.fill), 'Home'),
              _navItem(
                  1, PhosphorIcons.wallet(PhosphorIconsStyle.fill), 'Wallet'),
              _navItem(
                  2, PhosphorIcons.user(PhosphorIconsStyle.fill), 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _navIndex == index;
    return PressScale(
      onTap: () => setState(() => _navIndex = index),
      haptic: null,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        curve: AppCurves.warmOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isActive ? Colors.white : AppColors.inkSecondary,
            ),
            AnimatedSize(
              duration: AppDurations.medium,
              curve: AppCurves.warmOut,
              child: isActive
                  ? Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: AppText.bodyStrong.copyWith(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalRingPainter extends CustomPainter {
  final double percentage;
  final Color fillColor;

  _GoalRingPainter({
    required this.percentage,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const stroke = 24.0;
    final totalRadius = size.width / 2;

    // Arc centred at the disc's perimeter — half bleeds inside the disc,
    // half extends outside it — matching the reference design.
    final discRadius = totalRadius - stroke; // disc fills ~77% of widget
    final arcCenterRadius = discRadius; // arc centre == disc edge
    final pct = (percentage / 100).clamp(0.0, 1.0);

    // Filled disc
    canvas.drawCircle(center, discRadius, Paint()..color = fillColor);

    // Progress arc around the disc in a lighter shade
    final arcColor = Color.lerp(fillColor, Colors.white, 0.40)!;
    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * pct;
    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcCenterRadius),
        -pi / 2,
        sweepAngle,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GoalRingPainter old) =>
      old.percentage != percentage || old.fillColor != fillColor;
}
