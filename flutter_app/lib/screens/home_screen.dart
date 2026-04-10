import 'dart:async';
import 'package:flutter/material.dart';
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
import '../widgets/breathing.dart';
import '../widgets/reward_glow.dart';
import '../widgets/fade_route.dart';
import 'game_detail_screen.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToWallet;

  const HomeScreen({super.key, this.onNavigateToWallet});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _showGift = false;
  bool _giftFading = false;
  bool _homeRevealed = true;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (!state.welcomeModalShown) {
        state.welcomeModalShown = true;
        _showWelcomeModal(context);
      }
    });
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
      'game_install': '${_selectedGame ?? 'Game'} installed',
      'game_milestone': 'First milestone reached',
      'daily_survey': 'Daily survey completed',
      'daily_play': 'Daily play completed',
      'daily_offer': 'Daily offer completed',
    };
    final taskIcons = {
      'profile': PhosphorIcons.userCircle(PhosphorIconsStyle.duotone),
      'survey': PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
      'game_install': PhosphorIcons.gameController(PhosphorIconsStyle.duotone),
      'game_milestone': PhosphorIcons.trophy(PhosphorIconsStyle.duotone),
      'daily_survey': PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
      'daily_play': PhosphorIcons.gameController(PhosphorIconsStyle.duotone),
      'daily_offer': PhosphorIcons.tag(PhosphorIconsStyle.duotone),
    };
    final taskColors = {
      'profile': AppColors.primary,
      'survey': AppColors.taskSurvey,
      'game_install': AppColors.taskGame,
      'game_milestone': AppColors.taskGame,
      'daily_survey': AppColors.taskSurvey,
      'daily_play': AppColors.taskGame,
      'daily_offer': AppColors.taskOffers,
    };
    final taskBgs = {
      'profile': AppColors.primaryPale,
      'survey': AppColors.taskSurveyBg,
      'game_install': AppColors.taskGameBg,
      'game_milestone': AppColors.taskGameBg,
      'daily_survey': AppColors.taskSurveyBg,
      'daily_play': AppColors.taskGameBg,
      'daily_offer': AppColors.taskOffersBg,
    };

    final stars = AppState.taskStars[task] ?? 0;
    final dollars = (stars / AppState.starsPerDollar).toStringAsFixed(2);
    state.addJourneyEntry(
      'Earned \$$dollars: ${taskNames[task] ?? 'Task completed'}',
      'Task completed',
      taskIcons[task] ?? PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone),
      taskColors[task] ?? AppColors.primary,
      taskBgs[task] ?? AppColors.primaryPale,
    );

    if (state.streakCount == 0) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        state.streakCount = 1;
        state.addJourneyEntry(
          'Look at that, your first streak!',
          'One task each day to keep it rolling',
          PhosphorIcons.flame(PhosphorIconsStyle.fill),
          AppColors.flame,
          AppColors.flameBg,
        );
        showAppToast(
          context,
          title: 'Look at that, your first streak!',
          subtitle: 'One task each day to keep it rolling',
          icon: PhosphorIcons.flame(PhosphorIconsStyle.fill),
          iconColor: AppColors.flame,
          iconBackground: const Color(0xFFFFF0E8),
        );
      });
    }

    // Goal completed: hold the solid fill so the user sees it, then celebrate
    if (goalCompleted) {
      Haptics.milestone();
      // First onboarding goal: show celebration modal
      if (state.goalIndex == 0) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          _showGoalCelebration(context).then((cashOut) {
            if (!mounted) return;
            final s = context.read<AppState>();
            // Shared dismiss logic: advance goal + journal entry
            s.advanceGoal();
            s.addJourneyEntry(
              'Goal complete! Your first \$2 payout is ready.',
              'Earn More is now unlocked',
              PhosphorIcons.trophy(PhosphorIconsStyle.fill),
              s.ringColor,
              s.ringColor.withValues(alpha: 0.1),
            );
            // Branch on path
            if (cashOut) {
              widget.onNavigateToWallet?.call();
            } else {
              showAppToast(
                context,
                title: 'Earn More is unlocked!',
                subtitle: 'Offers, Receipts and Games are now available',
                icon: PhosphorIcons.lockSimpleOpen(PhosphorIconsStyle.duotone),
                iconColor: AppColors.primary,
                iconBackground: AppColors.primaryPale,
              );
            }
          });
        });
      } else {
        // Later goals: keep the existing silent advance behavior
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
                'Match-3 puzzle: swap & match colorful candies',
                'assets/app_icons/Candy_Crush_Saga.png',
                state),
            const SizedBox(height: 10),
            _gameOption(
                ctx,
                'Solitaire',
                'Classic card game: sort cards into suits',
                'assets/app_icons/Solitaire_Classic.png',
                state),
            const SizedBox(height: 10),
            _gameOption(
                ctx,
                'Word Search',
                'Find hidden words in a letter grid',
                'assets/app_icons/Word_Search.png',
                state),
          ],
        );
      },
    ).then((picked) {
      if (picked == null || !mounted) return;
      final game = gamesByName[picked];
      if (game == null) return;
      _selectedGame = picked;
      // Task completes when the user taps Install on the detail screen,
      // not here. The picker just opens the detail page.
      Navigator.of(context).push(
        slideUpRoute(GameDetailScreen(
          game: game,
          onInstall: () => _completeTask('game_install'),
        )),
      );
    });
  }

  Widget _gameOption(BuildContext ctx, String name, String description,
      String iconPath, AppState state) {
    return AppCard(
      onTap: () => Navigator.of(ctx).pop(name),
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              iconPath,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
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
          Icon(PhosphorIcons.playCircle(PhosphorIconsStyle.fill),
              size: 48, color: AppColors.primary),
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
    return Stack(
        children: [
          // Home content
          if (_homeRevealed) _buildHomeContent(),

          // Gift overlay
          if (_showGift) _buildGiftOverlay(),
        ],
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
                      colors: [AppColors.primary, AppColors.tealSecondary],
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
                  style: AppText.heroAmount,
                ),
              ),
              ScaleTransition(
                scale: CurvedAnimation(
                    parent: _giftAmountController, curve: AppCurves.warmOut),
                child: Text(
                  'Welcome gift',
                  style: AppText.prompt.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary.withValues(alpha: 0.6),
                    letterSpacing: 1,
                    height: null,
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
                  top: MediaQuery.of(context).padding.top + 32,
                  left: 24,
                  right: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingRow(state),
                    const SizedBox(height: AppSpacing.xl),

                    // Balance + Ring row
                    _buildBalanceRow(state),
                    const SizedBox(height: AppSpacing.xl),

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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildGreetingRow(AppState state) {
    final greeting = state.userName.isNotEmpty
        ? '${_greeting()}, ${state.userName}'
        : _greeting();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            greeting,
            style: AppText.sectionTitle,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.flame(PhosphorIconsStyle.fill),
                size: 22,
                color: state.streakCount > 0
                    ? AppColors.flame
                    : AppColors.inkTertiary,
              ),
              const SizedBox(width: 5),
              Text(
                '${state.streakCount}',
                style: AppText.bodyStrong.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: state.streakCount > 0
                      ? AppColors.flame
                      : AppColors.inkTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBubble(
      IconData icon, int rawValue, String label, AppState state) {
    String format(int v) =>
        '\$${(v / AppState.starsPerDollar).toStringAsFixed(2)}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.creamDeep,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 26, color: AppColors.inkSecondary),
        ),
        const SizedBox(height: 10),
        AnimatedCounter(
          value: rawValue,
          format: format,
          style: AppText.statNumber.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppText.caption.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.inkSecondary,
          ),
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
      final ringSize = (constraints.maxWidth * 0.50).clamp(140.0, 200.0);

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
                    trackColor: state.trackColor,
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
                        style: AppText.bodyStrong.copyWith(
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
                      style: AppText.ringGoal,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Daily Goal',
                      style: AppText.caption.copyWith(
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: _buildStatBubble(
                PhosphorIcons.wallet(PhosphorIconsStyle.fill),
                state.stars,
                'Balance',
                state,
              ),
            ),
          ),
          Breathing(amplitude: 0.03, child: ring),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: _buildStatBubble(
                PhosphorIcons.money(PhosphorIconsStyle.fill),
                state.earnedToday,
                'Today',
                state,
              ),
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
    final profileDone = state.completedTasks.contains('profile');
    final installDone = state.completedTasks.contains('game_install');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Starter Tasks',
          style: AppText.listItem.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          'Complete all 4 to cash out \$2',
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
          locked: !profileDone,
        ),
        const SizedBox(height: 10),
        _taskCard(
          'Install a game',
          '~1 min',
          PhosphorIcons.gameController(PhosphorIconsStyle.duotone),
          AppColors.taskGame,
          'game_install',
          state,
          onTap: () => _showGamePicker(state),
        ),
        const SizedBox(height: 10),
        _taskCard(
          'Reach first milestone',
          '~10 min',
          PhosphorIcons.trophy(PhosphorIconsStyle.duotone),
          AppColors.taskGame,
          'game_milestone',
          state,
          locked: !installDone,
        ),
      ],
    );
  }

  Widget _taskCard(String title, String meta, IconData icon, Color color,
      String taskKey, AppState state,
      {VoidCallback? onTap, bool locked = false}) {
    final completed = state.completedTasks.contains(taskKey);
    final disabled = completed || locked;
    final bg = color.withValues(alpha: 0.10);
    return PressScale(
      onTap: disabled ? null : (onTap ?? () => _completeTask(taskKey)),
      haptic: null,
      enabled: !disabled,
      child: AnimatedOpacity(
        opacity: disabled ? 0.45 : 1,
        duration: AppDurations.medium,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppText.bodyStrong
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: AppText.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                completed
                    ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                    : locked
                        ? PhosphorIcons.lockSimple(PhosphorIconsStyle.regular)
                        : PhosphorIcons.playCircle(PhosphorIconsStyle.fill),
                size: completed ? 48 : locked ? 24 : 48,
                color: completed
                    ? AppColors.primary
                    : locked
                        ? AppColors.inkTertiary
                        : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
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
              "Today's Tasks",
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
        const SizedBox(height: 2),
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
              'Earn More',
              style: AppText.listItem.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        if (!unlocked) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Finish your starter tasks to unlock all modes',
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
                  'Cashback',
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
}

/// Shows the goal celebration modal as a general dialog overlay.
/// Returns `true` if the user tapped "Cash out now", `false` if dismissed
/// via close X or "Keep earning".
Future<bool> _showGoalCelebration(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => const _GoalCelebrationModal(),
  ).then((v) => v ?? false);
}

class _GoalCelebrationModal extends StatefulWidget {
  const _GoalCelebrationModal();

  @override
  State<_GoalCelebrationModal> createState() => _GoalCelebrationModalState();
}

class _GoalCelebrationModalState extends State<_GoalCelebrationModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _barrierOpacity;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _barrierOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
      ),
    );
    _cardScale = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppCurves.warmOut),
    );
    _cardOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    Haptics.celebrate(CelebrateMoments.goalReached);
    _ctrl.forward();
  }

  Future<void> _dismiss(bool cashOut) async {
    await _ctrl.reverse();
    if (mounted) Navigator.of(context).pop(cashOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Stack(
          children: [
            // Barrier scrim
            Positioned.fill(
              child: Opacity(
                opacity: _barrierOpacity.value,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
            // Card
            Center(
              child: Opacity(
                opacity: _cardOpacity.value,
                child: Transform.scale(
                  scale: _cardScale.value,
                  child: _buildCard(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard() {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close X - top right
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => _dismiss(false),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.creamDeep,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.x(PhosphorIconsStyle.bold),
                    size: 14,
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.tealSecondary],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                PhosphorIcons.star(PhosphorIconsStyle.fill),
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Amount
            Text(
              '\$2.00',
              style: AppText.prompt.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              'GOAL REACHED',
              style: AppText.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            // Body
            Text(
              'You did it! Your first payout is ready to cash out.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            // Primary CTA
            PressScale(
              onTap: () => _dismiss(true),
              haptic: HapticIntensity.confirm,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Cash out now',
                  textAlign: TextAlign.center,
                  style: AppText.bodyStrong.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Secondary
            PressScale(
              onTap: () => _dismiss(false),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Keep earning',
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkTertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Welcome Modal ───────────────────────────────────────────────

Future<void> _showWelcomeModal(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => const _WelcomeModal(),
  );
}

class _WelcomeModal extends StatefulWidget {
  const _WelcomeModal();

  @override
  State<_WelcomeModal> createState() => _WelcomeModalState();
}

class _WelcomeModalState extends State<_WelcomeModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _barrierOpacity;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _barrierOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
      ),
    );
    _cardScale = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppCurves.warmOut),
    );
    _cardOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _ctrl.forward();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: _barrierOpacity.value,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
            Center(
              child: Opacity(
                opacity: _cardOpacity.value,
                child: Transform.scale(
                  scale: _cardScale.value,
                  child: _buildCard(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard() {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.tealSecondary],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                PhosphorIcons.handWaving(PhosphorIconsStyle.fill),
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'Welcome to EarnWise',
              style: AppText.prompt.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            // Subtitle
            Text(
              'Because actions speak louder than words',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: 48),
            // Bullet points
            UnconstrainedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WelcomeBullet(
                    icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                    color: AppColors.primary,
                    text: 'Finish a few starter tasks',
                  ),
                  const SizedBox(height: 12),
                  _WelcomeBullet(
                    icon: PhosphorIcons.currencyDollar(PhosphorIconsStyle.fill),
                    color: const Color(0xFFE89A2E),
                    text: 'Cash out \$2.00 to your PayPal',
                  ),
                  const SizedBox(height: 12),
                  _WelcomeBullet(
                    icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
                    color: const Color(0xFF6366F1),
                    text: 'No catches, no waiting',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // CTA
            PressScale(
              onTap: _dismiss,
              haptic: HapticIntensity.confirm,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Show me',
                  textAlign: TextAlign.center,
                  style: AppText.bodyStrong.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeBullet extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _WelcomeBullet({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 12),
        Text(
          text,
          style: AppText.bodyStrong.copyWith(fontSize: 16),
        ),
      ],
    );
  }
}

class _GoalRingPainter extends CustomPainter {
  final double percentage;
  final Color fillColor;
  final Color trackColor;

  _GoalRingPainter({
    required this.percentage,
    required this.fillColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const stroke = 22.0;
    final totalRadius = size.width / 2;

    final arcRadius = totalRadius - stroke / 2;
    final discRadius = arcRadius;
    final pct = (percentage / 100).clamp(0.0, 1.0);

    // Filled disc
    canvas.drawCircle(center, discRadius, Paint()..color = fillColor);

    // Progress arc - thick, on top of everything
    final arcPaint = Paint()
      ..color = AppColors.tealRing
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * pct;
    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        -pi / 2,
        sweepAngle,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GoalRingPainter old) =>
      old.percentage != percentage ||
      old.fillColor != fillColor ||
      old.trackColor != trackColor;
}

