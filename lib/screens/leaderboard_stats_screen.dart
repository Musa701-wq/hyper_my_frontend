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
import 'profile_screen.dart';

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
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LeaderboardStatsBody(
            onBack: () => Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const HomeScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                transitionsBuilder: (_, __, ___, child) => child,
              ),
            ),
            showTopBar: true,
          ),
        ),
      ),
    );
  }
}

class LeaderboardStatsBody extends StatefulWidget {
  final VoidCallback? onBack;
  final bool showTopBar;
  const LeaderboardStatsBody({super.key, this.onBack, this.showTopBar = true});

  @override
  State<LeaderboardStatsBody> createState() => _LeaderboardStatsBodyState();
}

class _LeaderboardStatsBodyState extends State<LeaderboardStatsBody>
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
      if (vm.stats != null) {
        _fadeCtrl.forward();
      } else {
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
    return Consumer<LeaderboardViewModel>(
      builder: (context, vm, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showTopBar) _TopBar(vm: vm, onBack: widget.onBack),
            if (widget.showTopBar) const SizedBox(height: 8),
            _PeriodSelector(
              vm: vm,
              onPeriodTap: () => _fadeCtrl.reset(),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildBody(vm, res)),
          ],
        );
      },
    );
  }

  Widget _buildBody(LeaderboardViewModel vm, Responsive res) {
    // ... no changes to _buildBody and other helper methods internally ...
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
    // Period change re-fetch — show shimmer overlay while loading (skip for search)
    if (vm.isLoading && vm.searchQuery.isEmpty) {
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
  final VoidCallback? onBack;
  const _TopBar({required this.vm, this.onBack});

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: AppColors.textPrimary, size: 20),
              onPressed: onBack,
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
        padding: const EdgeInsets.all(3),
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
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              AppColors.brandAccent.withOpacity(0.2),
                              AppColors.brandAccent.withOpacity(0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(7),
                    border: selected
                        ? Border.all(
                            color: AppColors.brandAccent.withOpacity(0.5),
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
// Marquee Headline — top gainers & losers ticker
// ─────────────────────────────────────────────────────────────────────────────
class _HeadlineMarquee extends StatelessWidget {
  const _HeadlineMarquee();

  static String _fmt(double v, {bool isCurrency = false, bool isPct = false}) {
    if (isPct) return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
    final p = isCurrency ? '\$' : '';
    final a = v.abs();
    if (a >= 1e12) return '$p${(v / 1e12).toStringAsFixed(2)}T';
    if (a >= 1e9) return '$p${(v / 1e9).toStringAsFixed(2)}B';
    if (a >= 1e6) return '$p${(v / 1e6).toStringAsFixed(2)}M';
    if (a >= 1e3) return '$p${(v / 1e3).toStringAsFixed(2)}K';
    return '$p${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaderboardViewModel>(
      builder: (context, vm, _) {
        final headline = vm.headline;
        if (headline == null) return const SizedBox.shrink();

        final items = <Widget>[];
        for (final g in headline.gainers) {
          final name = g.displayName.isNotEmpty && g.displayName != 'Anonymous'
              ? g.displayName
              : '${g.ethAddress.substring(0, 6)}...${g.ethAddress.substring(g.ethAddress.length - 4)}';
          items.add(
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_upward, size: 10, color: AppColors.trendGreen),
                  const SizedBox(width: 3),
                  Text(name, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.textPrimary)),
                  const SizedBox(width: 4),
                  Text(_fmt(g.pnl, isCurrency: true),
                    style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.trendGreen)),
                  const SizedBox(width: 4),
                  Text('(${_fmt(g.roi, isPct: true)})',
                    style: GoogleFonts.jetBrainsMono(fontSize: 8, color: AppColors.trendGreen.withOpacity(0.7))),
                ],
              ),
            ),
          );
        }
        for (final l in headline.losers) {
          final name = l.displayName.isNotEmpty && l.displayName != 'Anonymous'
              ? l.displayName
              : '${l.ethAddress.substring(0, 6)}...${l.ethAddress.substring(l.ethAddress.length - 4)}';
          items.add(
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_downward, size: 10, color: AppColors.trendRed),
                  const SizedBox(width: 3),
                  Text(name, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.textPrimary)),
                  const SizedBox(width: 4),
                  Text(_fmt(l.pnl, isCurrency: true),
                    style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.trendRed)),
                  const SizedBox(width: 4),
                  Text('(${_fmt(l.roi, isPct: true)})',
                    style: GoogleFonts.jetBrainsMono(fontSize: 8, color: AppColors.trendRed.withOpacity(0.7))),
                ],
              ),
            ),
          );
        }

        return Container(
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF0D0F13),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceBright.withOpacity(0.3)),
          ),
          clipBehavior: Clip.hardEdge,
          child: _MarqueeScroll(
            items: items,
          ),
        );
      },
    );
  }
}

class _MarqueeScroll extends StatefulWidget {
  final List<Widget> items;
  const _MarqueeScroll({required this.items});

  @override
  State<_MarqueeScroll> createState() => _MarqueeScrollState();
}

class _MarqueeScrollState extends State<_MarqueeScroll>
    with SingleTickerProviderStateMixin {
  late final ScrollController _ctrl;
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(_scroll);
  }

  void _scroll() {
    if (!_ctrl.hasClients) return;
    final maxScroll = _ctrl.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    final target = _animCtrl.value * (maxScroll + _ctrl.position.viewportDimension);
    if (target >= maxScroll + _ctrl.position.viewportDimension) {
      _ctrl.jumpTo(0);
    } else {
      _ctrl.jumpTo(target);
    }
  }

  @override
  void didUpdateWidget(_MarqueeScroll old) {
    super.didUpdateWidget(old);
    if (old.items != widget.items) {
      _ctrl.jumpTo(0);
      _animCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_animCtrl.isAnimating && widget.items.isNotEmpty) {
        _animCtrl.repeat();
      }
    });
    return ListView(
      controller: _ctrl,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      children: [
        ...widget.items,
        ...widget.items,
      ],
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
      // _CardData(
      //   icon: Icons.account_balance_outlined,
      //   label: 'Total Value Locked',
      //   value: _fmt(stats.totalAccountValue, isCurrency: true),
      //   subtitle: 'Across all accounts',
      //   accentColor: const Color(0xFF7C3AED),
      // ),
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
          // ── Marquee Headline ───────────────────────────────────────────
          const _HeadlineMarquee(),
          const SizedBox(height: 12),

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
                    color: AppColors.brandAccent.withOpacity(0.5),
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
            subtitle: 'Market momentum',
          ),
          const SizedBox(height: 10),
          _CardGrid(cards: perfCards),
          const SizedBox(height: 32),

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
                    color: AppColors.brandAccent.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Container(height: 0.5, color: AppColors.surfaceBright)),
              ],
            ),
          ),

          // ── Section 3: Top Traders ─────────────────────────────────────
          /*
          _SectionHeader(
            icon: Icons.workspace_premium_rounded,
            title: 'Top Traders',
            subtitle: 'Leading performers',
          ),
          const SizedBox(height: 10),
          const _TopTradersSection(),
          */
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
            color: AppColors.brandAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.brandAccent.withOpacity(0.25)),
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
          color: AppColors.brandAccent.withOpacity(0.2),
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
                color: d.accentColor.withOpacity(0.25 + (_elevation.value * 0.2)),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: d.accentColor.withOpacity(0.06 + (_elevation.value * 0.08)),
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
                        color: d.accentColor.withOpacity(0.12),
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
                    color: AppColors.textSecondary.withOpacity(0.6),
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

// ─────────────────────────────────────────────────────────────────────────────
// Top Traders Section — full table from leaderboard screen
// ─────────────────────────────────────────────────────────────────────────────
class _TopTradersSection extends StatefulWidget {
  const _TopTradersSection();

  @override
  State<_TopTradersSection> createState() => _TopTradersSectionState();
}

class _TopTradersSectionState extends State<_TopTradersSection> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String _fmt(double v, {bool isCurrency = false, bool isPct = false}) {
    if (isPct) return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
    final p = isCurrency ? '\$' : '';
    final a = v.abs();
    if (a >= 1e12) return '$p${(v / 1e12).toStringAsFixed(2)}T';
    if (a >= 1e9) return '$p${(v / 1e9).toStringAsFixed(2)}B';
    if (a >= 1e6) return '$p${(v / 1e6).toStringAsFixed(2)}M';
    if (a >= 1e3) return '$p${(v / 1e3).toStringAsFixed(2)}K';
    return '$p${v.toStringAsFixed(2)}';
  }

  Widget _buildSearchBar(LeaderboardViewModel vm, {bool compact = false}) {
    final double iconSize = compact ? 14 : 16;
    final double fontSize = compact ? 11 : 13;
    final double vPad = compact ? 6 : 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.surfaceBright),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.textSecondary, size: iconSize),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => vm.setSearchQuery(v),
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textPrimary, fontSize: fontSize),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: fontSize),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: vPad),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            vm.setSearchQuery('');
                          },
                          child: Icon(Icons.close, color: AppColors.textSecondary, size: iconSize - 2),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowsPerPage(LeaderboardViewModel vm, {bool compact = false}) {
    final s = compact ? 9 : 11;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Show:',
            style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary,
                fontSize: s.toDouble())),
        SizedBox(width: compact ? 4 : 6),
        Theme(
          data: Theme.of(context).copyWith(canvasColor: AppColors.background),
          child: Container(
            height: compact ? 26 : 30,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.surfaceBright),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: vm.rowsPerPage,
                dropdownColor: AppColors.background,
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textPrimary,
                    fontSize: compact ? 10 : 12),
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary, size: 14),
                isDense: true,
                onChanged: (v) {
                  if (v != null) vm.setRowsPerPage(v);
                },
                items: [10, 20, 30, 50]
                    .map((v) => DropdownMenuItem(
                          value: v,
                          child: Text('$v rows',
                              style: GoogleFonts.jetBrainsMono(
                                  color: AppColors.textPrimary,
                                  fontSize: compact ? 10 : 12)),
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(Responsive res, LeaderboardViewModel vm) {
    // On tablet/desktop, all columns fit — no horizontal scroll needed
    final bool isTabletPlus = !res.isMobile;

    final double leftW = res.value(mobile: 110, tablet: 180, desktop: 220);
    final double wAcc  = res.value(mobile: 75,  tablet: 110, desktop: 130);
    final double wPnl  = res.value(mobile: 70,  tablet: 110, desktop: 130);
    final double wRoi  = res.value(mobile: 60,  tablet: 90,  desktop: 110);
    final double wVol  = res.value(mobile: 75,  tablet: 110, desktop: 130);
    final double rightW = wAcc + wPnl + wRoi + wVol;

    final traders = vm.topTraders;

    // Tablet/desktop: expand right columns to fill full width
    if (isTabletPlus) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final availableRight = constraints.maxWidth - leftW;
          // Distribute remaining space evenly across 4 columns
          final colW = availableRight / 4;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: leftW,
                child: _StickyTable(
                  header: _leftHeader(res),
                  itemCount: traders.length,
                  itemBuilder: (i) => _leftRow(i, traders[i], vm, res),
                ),
              ),
              Expanded(
                child: _StickyTable(
                  header: _rightHeader(res, vm, colW, colW, colW, colW),
                  itemCount: traders.length,
                  itemBuilder: (i) => _rightRow(traders[i], res, colW, colW, colW, colW),
                ),
              ),
            ],
          );
        },
      );
    }

    // Mobile: sticky left + horizontal scroll for right columns
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: leftW,
          child: _StickyTable(
            header: _leftHeader(res),
            itemCount: traders.length,
            itemBuilder: (i) => _leftRow(i, traders[i], vm, res),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: rightW,
              child: _StickyTable(
                header: _rightHeader(res, vm, wAcc, wPnl, wRoi, wVol),
                itemCount: traders.length,
                itemBuilder: (i) => _rightRow(traders[i], res, wAcc, wPnl, wRoi, wVol),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _leftHeader(Responsive res) {
    final s = res.value(mobile: 8.0, tablet: 10.0, desktop: 11.0);
    final h = res.value(mobile: 34.0, tablet: 40.0, desktop: 44.0);
    return Container(
      height: h,
      color: const Color(0xFF0D0F13),
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text('#',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: s)),
          ),
          Text('Trader',
              style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary,
                  fontSize: s)),
        ],
      ),
    );
  }

  Widget _rightHeader(Responsive res, LeaderboardViewModel vm,
      double wAcc, double wPnl, double wRoi, double wVol) {
    final double s = res.value(mobile: 8.0, tablet: 10.0, desktop: 11.0);
    final double h = res.value(mobile: 34.0, tablet: 40.0, desktop: 44.0);
    return Container(
      height: h,
      color: const Color(0xFF0D0F13),
      child: Row(
        children: [
          _sortableHCell('+ ACC', 'accountValue', wAcc, s, res, vm),
          _sortableHCell('PNL', 'pnl', wPnl, s, res, vm),
          _sortableHCell('ROI', 'roi', wRoi, s, res, vm),
          _sortableHCell('VOL', 'volume', wVol, s, res, vm),
        ],
      ),
    );
  }

  Widget _sortableHCell(String label, String metric, double width,
      double fontSize, Responsive res, LeaderboardViewModel vm) {
    final active = vm.selectedMetric == metric;
    return GestureDetector(
      onTap: () => vm.setMetric(metric),
      child: SizedBox(
        width: width,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (active)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(Icons.arrow_downward_rounded,
                      size: 7, color: AppColors.brandAccent),
                ),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  color: active ? AppColors.brandAccent : AppColors.textSecondary,
                  fontSize: fontSize,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leftRow(int i, Trader t, LeaderboardViewModel vm, Responsive res) {
    final rank = i + 1;
    final addr = t.ethAddress;
    final hasName = t.displayName.isNotEmpty &&
        t.displayName != 'Anonymous' &&
        !t.displayName.startsWith('0x');
    final name = hasName
        ? t.displayName
        : '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';

    final rankColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : AppColors.textSecondary;

    final double rowH     = res.value(mobile: 44.0, tablet: 52.0, desktop: 56.0);
    final double nameSize = res.value(mobile: 9.0,  tablet: 11.0, desktop: 12.0);
    final double addrSize = res.value(mobile: 6.5,  tablet: 8.5,  desktop: 9.0);
    final double rankSize = res.value(mobile: 9.0,  tablet: 11.0, desktop: 12.0);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(walletAddress: addr),
        ),
      ),
      child: Container(
        height: rowH,
        padding: const EdgeInsets.only(left: 4, right: 4),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text('$rank',
                  style: GoogleFonts.jetBrainsMono(
                    color: rankColor,
                    fontSize: rankSize,
                    fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
                  )),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name,
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textPrimary,
                        fontSize: nameSize,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis),
                  Text('${addr.substring(0, 8)}...',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textSecondary,
                        fontSize: addrSize,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rightRow(Trader t, Responsive res,
      double wAcc, double wPnl, double wRoi, double wVol) {
    final double rowH     = res.value(mobile: 44.0, tablet: 52.0, desktop: 56.0);
    final double cellSize = res.value(mobile: 8.0,  tablet: 11.0, desktop: 12.0);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(walletAddress: t.ethAddress),
        ),
      ),
      child: Container(
        height: rowH,
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
        ),
        child: Row(
          children: [
            _dCell(_fmt(t.accountValue, isCurrency: true),
                width: wAcc, fontSize: cellSize, res: res),
            _dCell(_fmt(t.pnl, isCurrency: true),
                width: wPnl, fontSize: cellSize, res: res,
                color: t.pnl >= 0 ? AppColors.trendGreen : AppColors.trendRed),
            _dCell(_fmt(t.roi, isPct: true),
                width: wRoi, fontSize: cellSize, res: res,
                color: t.roi >= 0 ? AppColors.trendGreen : AppColors.trendRed),
            _dCell(_fmt(t.volume, isCurrency: true),
                width: wVol, fontSize: cellSize, res: res),
          ],
        ),
      ),
    );
  }

  Widget _dCell(String text,
      {required double width, required double fontSize, required Responsive res, Color? color}) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              color: color ?? AppColors.textPrimary,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            )),
      ),
    );
  }

  Widget _buildPagination(LeaderboardViewModel vm, Responsive res) {
    if (vm.totalPages <= 1) return const SizedBox.shrink();

    final total = vm.totalPages;
    final cur = vm.currentPage;
    int start = (cur - 1).clamp(1, total);
    int end = (start + 2).clamp(1, total);
    if (end == total && total > 3) start = (end - 2).clamp(1, total);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pgBtn(icon: Icons.chevron_left, enabled: cur > 1, onTap: vm.previousPage),
          const SizedBox(width: 6),
          for (int p = start; p <= end; p++) ...[
            _pgNumBtn(p, cur == p, () => vm.setPage(p)),
            const SizedBox(width: 4),
          ],
          const SizedBox(width: 2),
          _pgBtn(icon: Icons.chevron_right, enabled: cur < total, onTap: vm.nextPage),
        ],
      ),
    );
  }

  Widget _pgNumBtn(int page, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28, height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.brandAccent : AppColors.background,
          border: Border.all(
              color: active ? AppColors.brandAccent : AppColors.surfaceBright),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('$page',
            style: GoogleFonts.jetBrainsMono(
              color: active ? Colors.black : AppColors.textPrimary,
              fontSize: 11,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }

  Widget _pgBtn({required IconData icon, required bool enabled,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28, height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.surfaceBright),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.3,
          child: Icon(icon, size: 14, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    return Consumer<LeaderboardViewModel>(
      builder: (context, vm, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(vm, compact: res.isMobile),
            const SizedBox(height: 6),
            _buildRowsPerPage(vm, compact: res.isMobile),
            const SizedBox(height: 6),
            if (vm.isLoading && vm.topTraders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brandAccent.withOpacity(0.7),
                    ),
                  ),
                ),
              )
            else if (vm.topTraders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No traders found',
                      style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary,
                          fontSize: res.value(mobile: 11.0, tablet: 13.0, desktop: 14.0))),
                ),
              )
            else
              _buildTable(res, vm),
            _buildPagination(vm, res),
          ],
        );
      },
    );
  }
}

// ── Simple table (no slivers — avoids semantics parentDataDirty crash) ─────
class _StickyTable extends StatelessWidget {
  final Widget header;
  final int itemCount;
  final Widget Function(int index) itemBuilder;

  const _StickyTable({
    required this.header,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        Container(height: 0.5, color: AppColors.surfaceBright),
        ...List.generate(itemCount, (i) => itemBuilder(i)),
      ],
    );
  }
}
