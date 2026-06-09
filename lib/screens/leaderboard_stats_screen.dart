import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/app_colors.dart';
import '../utils/common_widgets.dart';
import '../utils/responsive.dart';
import '../viewmodels/leaderboard_viewmodel.dart';
import '../models/leaderboard_model.dart';
import 'home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
class LeaderboardStatsScreen extends StatefulWidget {
  const LeaderboardStatsScreen({super.key});

  @override
  State<LeaderboardStatsScreen> createState() => _LeaderboardStatsScreenState();
}

class _LeaderboardStatsScreenState extends State<LeaderboardStatsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<LeaderboardViewModel>(context, listen: false);
      // If data already cached, fade in immediately
      if (vm.stats != null) {
        _fadeCtrl.forward();
      } else {
        // Fetch then fade in
        vm.fetchAllData().then((_) {
          if (mounted) _fadeCtrl.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Consumer<LeaderboardViewModel>(
            builder: (context, vm, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(vm: vm),
                  const SizedBox(height: 8),
                  _PeriodSelector(
                    vm: vm,
                    onPeriodTap: () => _fadeCtrl.reset(),
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _buildBody(vm, res)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(LeaderboardViewModel vm, Responsive res) {
    // First load — show shimmer
    if (vm.isLoading && vm.stats == null) {
      return _buildShimmer();
    }
    if (vm.error != null && vm.stats == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.trendRed, size: 48),
            const SizedBox(height: 12),
            Text('Failed to load stats',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                _fadeCtrl.reset();
                vm.fetchAllData().then((_) {
                  if (mounted) _fadeCtrl.forward();
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.brandAccent),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Retry',
                    style: GoogleFonts.jetBrainsMono(
                        color: AppColors.brandAccent, fontSize: 13)),
              ),
            ),
          ],
        ),
      );
    }
    if (vm.stats == null) return _buildShimmer();

    // Period change re-fetch — show shimmer overlay while loading
    if (vm.isLoading) {
      return _buildShimmer();
    }

    // Data ready — trigger fade if not already playing
    if (_fadeCtrl.status == AnimationStatus.dismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fadeCtrl.forward();
      });
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: _StatsContent(stats: vm.stats!, res: res),
    );  }

  // ── Shimmer skeleton ──────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E222D),
      highlightColor: const Color(0xFF2A2F3A),
      period: const Duration(milliseconds: 1400),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header skeleton
            Row(children: [
              _sBox(30, 30, radius: 8),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sBox(110, 12, radius: 4),
                const SizedBox(height: 5),
                _sBox(80, 9, radius: 4),
              ]),
            ]),
            const SizedBox(height: 14),
            // 2-col card grid x2
            for (int r = 0; r < 2; r++) ...[
              Row(children: [
                Expanded(child: _shimmerCard()),
                const SizedBox(width: 10),
                Expanded(child: _shimmerCard()),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _shimmerCard()),
                const SizedBox(width: 10),
                Expanded(child: _shimmerCard()),
              ]),
              if (r == 0) ...[
                const SizedBox(height: 28),
                Row(children: [
                  _sBox(30, 30, radius: 8),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _sBox(130, 12, radius: 4),
                    const SizedBox(height: 5),
                    _sBox(100, 9, radius: 4),
                  ]),
                ]),
                const SizedBox(height: 14),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _shimmerCard() {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _sBox(30, 30, radius: 8),
            const SizedBox(width: 8),
            _sBox(70, 9, radius: 4),
          ]),
          const SizedBox(height: 14),
          _sBox(90, 20, radius: 4),
          const SizedBox(height: 10),
          _sBox(32, 2, radius: 2),
          const SizedBox(height: 8),
          _sBox(60, 9, radius: 4),
        ],
      ),
    );
  }

  Widget _sBox(double w, double h, {double radius = 4}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final LeaderboardViewModel vm;
  const _TopBar({required this.vm});

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const HomeScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                transitionsBuilder: (_, __, ___, child) => child,
              ),
            ),
            padding: EdgeInsets.zero,
          ),
          Text(
            'Market Stats',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textPrimary,
              fontSize: res.fontSize(18),
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (vm.isLoading)
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.brandAccent),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh,
                  color: AppColors.textSecondary, size: 18),
              onPressed: () => vm.fetchAllData(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Period selector
// ─────────────────────────────────────────────────────────────────────────────
class _PeriodSelector extends StatelessWidget {
  final LeaderboardViewModel vm;
  final VoidCallback onPeriodTap;
  const _PeriodSelector({required this.vm, required this.onPeriodTap});

  static const _periods = [
    ('allTime', 'All Time'),
    ('day', '24H'),
    ('week', '7D'),
    ('month', '30D'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D21),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceBright),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: _periods.map((p) {
            final selected = vm.selectedPeriod == p.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  onPeriodTap();
                  vm.setPeriod(p.$1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              AppColors.brandAccent.withValues(alpha: 0.2),
                              AppColors.brandAccent.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(7),
                    border: selected
                        ? Border.all(
                            color: AppColors.brandAccent.withValues(alpha: 0.5),
                            width: 1)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    p.$2,
                    style: GoogleFonts.jetBrainsMono(
                      color: selected
                          ? AppColors.brandAccent
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main content — two sections
// ─────────────────────────────────────────────────────────────────────────────
class _StatsContent extends StatelessWidget {
  final LeaderboardStats stats;
  final Responsive res;
  const _StatsContent({required this.stats, required this.res});

  static String _fmt(double v,
      {bool isCurrency = false, bool isPct = false, bool isCount = false}) {
    if (isPct) return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
    final a = v.abs();
    final prefix = isCurrency ? '\$' : '';
    if (isCount) {
      if (a >= 1e6) return '${(v / 1e6).toStringAsFixed(3)}M';
      if (a >= 1e3) return '${(v / 1e3).toStringAsFixed(3)}K';
      return v.toStringAsFixed(0);
    }
    if (a >= 1e12) return '$prefix${(v / 1e12).toStringAsFixed(3)}T';
    if (a >= 1e9)  return '$prefix${(v / 1e9).toStringAsFixed(3)}B';
    if (a >= 1e6)  return '$prefix${(v / 1e6).toStringAsFixed(3)}M';
    if (a >= 1e3)  return '$prefix${(v / 1e3).toStringAsFixed(3)}K';
    return '$prefix${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    // ── Section 1: Market Overview ────────────────────────────────────────
    final overviewCards = <_CardData>[
      _CardData(
        icon: Icons.people_alt_outlined,
        label: 'Total Traders',
        value: _fmt(stats.totalTraders.toDouble(), isCount: true),
        subtitle: 'Active accounts',
        accentColor: const Color(0xFF00C2FF),
      ),
      _CardData(
        icon: Icons.emoji_events_outlined,
        label: 'Profitable',
        value: _fmt(stats.profitableTraders.toDouble(), isCount: true),
        subtitle: '${stats.profitablePercentage.toStringAsFixed(1)}% in profit',
        accentColor: AppColors.trendGreen,
        valueColor: AppColors.trendGreen,
      ),
      _CardData(
        icon: Icons.account_balance_outlined,
        label: 'Total Value Locked',
        value: _fmt(stats.totalAccountValue, isCurrency: true),
        subtitle: 'Across all accounts',
        accentColor: const Color(0xFF7C3AED),
      ),
      _CardData(
        icon: Icons.swap_horiz_rounded,
        label: 'Total Volume',
        value: _fmt(stats.totalVolume, isCurrency: true),
        subtitle: 'Cumulative traded',
        accentColor: const Color(0xFF2563EB),
      ),
    ];

    // ── Section 2: Performance Pulse ──────────────────────────────────────
    final perfCards = <_CardData>[
      _CardData(
        icon: Icons.show_chart_rounded,
        label: 'Total PnL',
        value: _fmt(stats.totalPnl, isCurrency: true),
        subtitle: 'Net profit & loss',
        accentColor: stats.totalPnl >= 0 ? AppColors.trendGreen : AppColors.trendRed,
        valueColor: stats.totalPnl >= 0 ? AppColors.trendGreen : AppColors.trendRed,
      ),
      _CardData(
        icon: Icons.percent_rounded,
        label: 'Average ROI',
        value: _fmt(stats.averageRoi, isPct: true),
        subtitle: 'Mean return',
        accentColor: stats.averageRoi >= 0 ? const Color(0xFF34D399) : AppColors.trendRed,
        valueColor: stats.averageRoi >= 0 ? const Color(0xFF34D399) : AppColors.trendRed,
      ),
      _CardData(
        icon: Icons.attach_money_rounded,
        label: 'Avg PnL / Trader',
        value: _fmt(stats.averagePnl, isCurrency: true),
        subtitle: 'Per account avg',
        accentColor: stats.averagePnl >= 0 ? AppColors.trendGreen : AppColors.trendRed,
        valueColor: stats.averagePnl >= 0 ? AppColors.trendGreen : AppColors.trendRed,
      ),
      _CardData(
        icon: Icons.bar_chart_rounded,
        label: 'Avg Vol / Trader',
        value: _fmt(stats.averageVolume, isCurrency: true),
        subtitle: 'Per account traded',
        accentColor: const Color(0xFF0891B2),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section 1 ──────────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.public_rounded,
            title: 'Market Overview',
            subtitle: 'Liquidity & participation',
          ),
          const SizedBox(height: 6),
          _CardGrid(cards: overviewCards),

          // ── Divider ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(height: 0.5, width: 24, color: AppColors.surfaceBright),
                const SizedBox(width: 8),
                Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.brandAccent.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Container(height: 0.5, color: AppColors.surfaceBright)),
              ],
            ),
          ),

          // ── Section 2 ──────────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.bolt_rounded,
            title: 'Performance Pulse',
            subtitle: 'Returns & efficiency',
          ),
          const SizedBox(height: 6),
          _CardGrid(cards: perfCards),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.brandAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.brandAccent.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, size: 15, color: AppColors.brandAccent),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          height: 0.5,
          width: 60,
          color: AppColors.brandAccent.withValues(alpha: 0.2),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2-column card grid — fills available height equally
// ─────────────────────────────────────────────────────────────────────────────
class _CardGrid extends StatelessWidget {
  final List<_CardData> cards;
  const _CardGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < cards.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _AnimatedStatCard(data: cards[i])),
              const SizedBox(width: 8),
              if (i + 1 < cards.length)
                Expanded(child: _AnimatedStatCard(data: cards[i + 1]))
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
      if (i + 2 < cards.length) rows.add(const SizedBox(height: 8));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: rows,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated card with press lift effect
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedStatCard extends StatefulWidget {
  final _CardData data;
  const _AnimatedStatCard({required this.data});

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _elevation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _elevation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: d.accentColor.withValues(alpha: 0.25 + (_elevation.value * 0.2)),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: d.accentColor.withValues(alpha: 0.06 + (_elevation.value * 0.08)),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon + label row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: d.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(d.icon, size: 11, color: d.accentColor),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        d.label.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary,
                          fontSize: 7.5,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Value
                Text(
                  d.value,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                    color: d.valueColor ?? AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                // Subtitle
                Text(
                  d.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 7.5,
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

// ─────────────────────────────────────────────────────────────────────────────
// Card data model
// ─────────────────────────────────────────────────────────────────────────────
class _CardData {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color accentColor;
  final Color? valueColor;

  const _CardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    this.valueColor,
  });
}
