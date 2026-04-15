import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../services/haptics.dart';
import '../widgets/press_scale.dart';
import '../widgets/primary_button.dart';
import '../widgets/bottom_sheet_shell.dart';

/// First payout threshold in stars. Completing all onboarding tasks
/// (250 + 375 + 750 = 1375 task stars + 125 welcome gift) lands exactly here.
const int _kPayoutThresholdStars = 1500;

/// Dollar equivalent of the payout threshold.
const String _kPayoutDollars = '\$2.00';

/// PayPal brand blue, used for the icon badge.
const Color _kPaypalBlue = Color(0xFF0070BA);

// ──────────────────────────────────────────────────────────────
// Wallet Screen
// ──────────────────────────────────────────────────────────────

class WalletScreen extends StatefulWidget {
  final VoidCallback onNavigateHome;

  const WalletScreen({super.key, required this.onNavigateHome});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  void _showConfirmSheet(AppState state) {
    showAppBottomSheet<bool>(
      context: context,
      builder: (_) => _ConfirmRedeemContent(
        balanceStars: state.stars,
        redeemStars: _kPayoutThresholdStars,
      ),
    ).then((confirmed) {
      if (confirmed != true || !mounted) return;
      _handleRedeem();
    });
  }

  void _handleRedeem() async {
    final state = context.read<AppState>();
    state.redeemPayout();

    if (!mounted) return;
    await _showPayoutCelebration(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final balanceDollars = AppState.starsToDollars(state.stars);
        final thresholdDollars =
            AppState.starsToDollars(_kPayoutThresholdStars);
        final progress = (balanceDollars / thresholdDollars).clamp(0.0, 1.0);
        final isUnlocked =
            state.stars >= _kPayoutThresholdStars && !state.hasRedeemed;
        final isRedeemed = state.hasRedeemed;

        return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppLayout.gutter),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 38),
                        Text('Wallet', style: AppText.sectionTitle),
                        const SizedBox(height: AppSpacing.lg),
                        _buildBalanceSection(state, progress, isUnlocked),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Available Rewards',
                          style: AppText.listItem
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 14),
                        _buildRewardCard(isUnlocked, isRedeemed, state),
                        const SizedBox(height: AppSpacing.lg),
                        if (!isUnlocked && !isRedeemed) _buildLockedFooter(),
                        if (isRedeemed) _buildRedeemedFooter(),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
      },
    );
  }

  // ── Balance Section ─────────────────────────────────────────

  Widget _buildBalanceSection(
      AppState state, double progress, bool isUnlocked) {
    final balanceStr = state.formatBalance();
    final remaining = _kPayoutThresholdStars - state.stars;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$balanceStr / $_kPayoutDollars',
          style: AppText.prompt.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: AppDurations.hero,
            curve: AppCurves.warmOut,
            builder: (context, value, _) {
              return SizedBox(
                height: 22,
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.creamDeep,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primary),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        if (isUnlocked)
          Row(
            children: [
              Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                "You're ready to redeem!",
                style: AppText.caption.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          )
        else
          Text(
            remaining > 0
                ? 'Cashouts start at \$2. Earn \$${AppState.starsToDollars(remaining).toStringAsFixed(2)} more to get there.'
                : 'Reward redeemed',
            style: AppText.caption.copyWith(
                color: AppColors.inkTertiary, fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  // ── Reward Card ─────────────────────────────────────────────

  Widget _buildRewardCard(
      bool isUnlocked, bool isRedeemed, AppState state) {
    return PressScale(
      onTap: isUnlocked ? () => _showConfirmSheet(state) : null,
      enabled: isUnlocked,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnlocked ? AppColors.primary : AppColors.creamDeep,
            width: isUnlocked ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isUnlocked ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // PayPal icon badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _kPaypalBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/logos/svg/PayPal.svg',
                      width: 28,
                      height: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _kPayoutDollars,
                        style: AppText.prompt
                            .copyWith(fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                      Text('PayPal Gift Card',
                          style:
                              AppText.body.copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                if (isUnlocked || isRedeemed)
                  Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                      size: 32, color: AppColors.primary)
                else
                  Icon(PhosphorIcons.lockSimple(PhosphorIconsStyle.regular),
                      size: 32, color: AppColors.inkTertiary),
              ],
            ),
            if (isUnlocked || isRedeemed) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isRedeemed ? AppColors.primaryPale : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isRedeemed ? 'Redeemed' : 'Tap to redeem',
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(
                    color: isRedeemed ? AppColors.primary : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Locked Footer ───────────────────────────────────────────

  Widget _buildLockedFooter() {
    return Column(
      children: [
        Text(
          'Finish your starter tasks to cash out \$2.00',
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(
              color: AppColors.inkTertiary, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: 'Finish onboarding tasks',
          onTap: widget.onNavigateHome,
        ),
      ],
    );
  }

  // ── Redeemed Footer ─────────────────────────────────────────

  Widget _buildRedeemedFooter() {
    return Center(
      child: Text(
        'Your reward is being delivered to your PayPal',
        textAlign: TextAlign.center,
        style: AppText.body.copyWith(color: AppColors.primary),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Confirm Redeem Bottom Sheet
// ──────────────────────────────────────────────────────────────

class _ConfirmRedeemContent extends StatelessWidget {
  final int balanceStars;
  final int redeemStars;

  const _ConfirmRedeemContent({
    required this.balanceStars,
    required this.redeemStars,
  });

  String _dollars(int stars) =>
      '\$${AppState.starsToDollars(stars).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final afterStars = (balanceStars - redeemStars).clamp(0, balanceStars);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/logos/svg/PayPal.svg',
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 8),
            Text('$_kPayoutDollars PayPal Gift Card',
                style: AppText.listItem),
          ],
        ),
        const SizedBox(height: 20),
        Text('Confirm your withdrawal', style: AppText.sectionTitle),
        const SizedBox(height: 20),

        // Balance breakdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.creamDeep.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _detailRow('Current balance', _dollars(balanceStars)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: AppColors.creamDeep, height: 1),
              ),
              _detailRow('After redemption', _dollars(afterStars)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Confirm CTA
        PressScale(
          onTap: () => Navigator.of(context).pop(true),
          haptic: HapticIntensity.confirm,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Yes, Redeem Now', style: AppText.ctaLabel),
                const SizedBox(width: 6),
                Icon(PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                    size: 20, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Later
        PressScale(
          onTap: () => Navigator.of(context).pop(false),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.creamDeep,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Later',
              textAlign: TextAlign.center,
              style:
                  AppText.bodyStrong.copyWith(color: AppColors.inkSecondary),
            ),
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Reward delivered to your PayPal within 24 hours',
          style: AppText.caption.copyWith(
              fontWeight: FontWeight.w400, color: AppColors.inkTertiary),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppText.body.copyWith(fontWeight: FontWeight.w500)),
        Text(value, style: AppText.bodyStrong),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Payout Celebration Modal
// ──────────────────────────────────────────────────────────────

Future<void> _showPayoutCelebration(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => const _PayoutCelebrationModal(),
  );
}

class _PayoutCelebrationModal extends StatefulWidget {
  const _PayoutCelebrationModal();

  @override
  State<_PayoutCelebrationModal> createState() =>
      _PayoutCelebrationModalState();
}

class _PayoutCelebrationModalState extends State<_PayoutCelebrationModal>
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

    Haptics.celebrate(CelebrateMoments.payoutConfirmed);
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
            // Close X
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: _dismiss,
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
                PhosphorIcons.check(PhosphorIconsStyle.bold),
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Amount
            Text(
              _kPayoutDollars,
              style: AppText.prompt.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              'PAYOUT CONFIRMED',
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
              'Your reward is on its way to PayPal. It usually arrives within a few minutes.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
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
                  'Back to earning',
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
