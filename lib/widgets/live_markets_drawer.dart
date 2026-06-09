import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/ticker_model.dart';
import '../utils/app_colors.dart';
import '../viewmodels/home_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Drawer nav item → navigates to LiveMarketsScreen
// ─────────────────────────────────────────────────────────────────────────────
class LiveMarketsDrawerItem extends StatelessWidget {
  final VoidCallback onTap;
  const LiveMarketsDrawerItem({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.surfaceBright.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            // accent bar placeholder
            Container(width: 3, height: 60, color: Colors.transparent),
            const SizedBox(width: 12),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceBright.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  size: 17, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Live Markets',
                      style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textPrimary, fontSize: 13)),
                  Text('Gainers • Losers • Active',
                      style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary.withValues(alpha: 0.55),
                          fontSize: 9.5)),
                ],
              ),
            ),
            _PulseDot(color: AppColors.trendGreen),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.surfaceBright),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Markets full screen
// Layout:
//   Row 1 → [Top Gainers (Expanded)] [Top Losers (Expanded)]
//   Row 2 → Most Active (full width)
// ─────────────────────────────────────────────────────────────────────────────
class LiveMarketsScreen extends StatelessWidget {
  const LiveMarketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── AppBar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: AppColors.textPrimary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Text('Live Markets',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(width: 8),
                  _PulseDot(color: AppColors.trendGreen),
                  const Spacer(),
                  Text('Real-time',
                      style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // thin accent line
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.brandAccent.withValues(alpha: 0.0),
                  AppColors.brandAccent.withValues(alpha: 0.5),
                  AppColors.brandAccent.withValues(alpha: 0.0),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: Consumer<HomeViewModel>(
                builder: (context, vm, _) {
                  final all = vm.tickers.where((t) => !t.isDelisted).toList();

                  if (vm.isLoading && all.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.brandAccent),
                    );
                  }
                  if (all.isEmpty) {
                    return Center(
                      child: Text('No market data',
                          style: GoogleFonts.jetBrainsMono(
                              color: AppColors.textSecondary, fontSize: 13)),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Top Gainers ───────────────────────────────
                        _GainersCard(tickers: all),
                        const SizedBox(height: 12),

                        // ── Top Losers ────────────────────────────────
                        _LosersCard(tickers: all),
                        const SizedBox(height: 12),

                        // ── Most Active ───────────────────────────────
                        _MostActiveCard(tickers: all),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Gainers card
// ─────────────────────────────────────────────────────────────────────────────
class _GainersCard extends StatelessWidget {
  final List<TickerModel> tickers;
  const _GainersCard({required this.tickers});

  @override
  Widget build(BuildContext context) {
    final list = tickers.where((t) => t.change24hPct > 0).toList()
      ..sort((a, b) => b.change24hPct.compareTo(a.change24hPct));
    final top = list.take(3).toList();

    return _MarketCard(
      headerIcon: Icons.trending_up_rounded,
      headerLabel: 'Top Gainers',
      headerTag: '24h',
      accentColor: AppColors.trendGreen,
      child: _MarketRows(items: top, isGainer: true),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Losers card
// ─────────────────────────────────────────────────────────────────────────────
class _LosersCard extends StatelessWidget {
  final List<TickerModel> tickers;
  const _LosersCard({required this.tickers});

  @override
  Widget build(BuildContext context) {
    final list = tickers.where((t) => t.change24hPct < 0).toList()
      ..sort((a, b) => a.change24hPct.compareTo(b.change24hPct));
    final top = list.take(3).toList();

    return _MarketCard(
      headerIcon: Icons.trending_down_rounded,
      headerLabel: 'Top Losers',
      headerTag: '24h',
      accentColor: AppColors.trendRed,
      child: _MarketRows(items: top, isGainer: false),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card shell
// ─────────────────────────────────────────────────────────────────────────────
class _MarketCard extends StatelessWidget {
  final IconData headerIcon;
  final String headerLabel;
  final String headerTag;
  final Color accentColor;
  final Widget child;

  const _MarketCard({
    required this.headerIcon,
    required this.headerLabel,
    required this.headerTag,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161A1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.18),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(headerIcon, size: 12, color: accentColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(headerLabel,
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              Text(headerTag,
                  style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary, fontSize: 9)),
            ],
          ),
          // divider
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 0.5,
            color: AppColors.surfaceBright.withValues(alpha: 0.4),
          ),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3 market rows inside gainers/losers card
// ─────────────────────────────────────────────────────────────────────────────
class _MarketRows extends StatelessWidget {
  final List<TickerModel> items;
  final bool isGainer;
  const _MarketRows({required this.items, required this.isGainer});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text('No data',
          style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary, fontSize: 9));
    }
    final color = isGainer ? AppColors.trendGreen : AppColors.trendRed;

    return Column(
      children: List.generate(items.length, (i) {
        final t = items[i];
        final pct =
            '${t.change24hPct >= 0 ? '+' : ''}${t.change24hPct.toStringAsFixed(2)}%';

        return Padding(
          padding: EdgeInsets.only(bottom: i < items.length - 1 ? 10 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rank
              SizedBox(
                width: 12,
                child: Text('${i + 1}',
                    style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textSecondary
                            .withValues(alpha: 0.5),
                        fontSize: 9)),
              ),
              const SizedBox(width: 6),
              // Avatar
              _Avatar(ticker: t, size: 28),
              const SizedBox(width: 8),
              // Symbol + price — takes remaining space
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.symbol,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        )),
                    Text(_price(t.lastPrice),
                        style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textSecondary,
                            fontSize: 9.5)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
                ),
                child: Text(pct,
                    style: GoogleFonts.jetBrainsMono(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _price(double v) {
    if (v == 0) return '\$0';
    if (v < 0.000001) return '\$${v.toStringAsFixed(8)}';
    if (v < 0.0001) return '\$${v.toStringAsFixed(6)}';
    if (v < 0.01) return '\$${v.toStringAsFixed(5)}';
    if (v < 1) return '\$${v.toStringAsFixed(4)}';
    if (v < 10000) return '\$${v.toStringAsFixed(2)}';
    return '\$${(v / 1000).toStringAsFixed(1)}K';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Most Active card — full width, Vol/OI toggle
// ─────────────────────────────────────────────────────────────────────────────
class _MostActiveCard extends StatefulWidget {
  final List<TickerModel> tickers;
  const _MostActiveCard({required this.tickers});

  @override
  State<_MostActiveCard> createState() => _MostActiveCardState();
}

class _MostActiveCardState extends State<_MostActiveCard> {
  bool _byVol = true;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7C3AED);
    const amber = Color(0xFFF59E0B);

    final barColor = _byVol ? purple : amber;

    final sorted = [...widget.tickers]
      ..sort((a, b) => _byVol
          ? b.volume24hUSD.compareTo(a.volume24hUSD)
          : b.openInterestUSD.compareTo(a.openInterestUSD));
    final top5 = sorted.take(5).toList();
    final maxVal = top5.isEmpty
        ? 1.0
        : top5
            .map((t) => _byVol ? t.volume24hUSD : t.openInterestUSD)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161A1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: barColor.withValues(alpha: 0.18),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: barColor.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.bar_chart_rounded,
                    size: 12, color: barColor),
              ),
              const SizedBox(width: 6),
              Text('Most Active',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  )),
              const Spacer(),
              // Toggle
              Container(
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBright.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                      color: AppColors.surfaceBright.withValues(alpha: 0.3),
                      width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Toggle(
                        label: 'Vol',
                        active: _byVol,
                        color: purple,
                        onTap: () => setState(() => _byVol = true)),
                    _Toggle(
                        label: 'OI',
                        active: !_byVol,
                        color: amber,
                        onTap: () => setState(() => _byVol = false)),
                  ],
                ),
              ),
            ],
          ),
          // divider
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 0.5,
            color: AppColors.surfaceBright.withValues(alpha: 0.4),
          ),
          // Rows
          ...List.generate(top5.length, (i) {
            final t = top5[i];
            final val = _byVol ? t.volume24hUSD : t.openInterestUSD;
            final pct = val / maxVal;
            final chColor = t.change24hPct >= 0
                ? AppColors.trendGreen
                : AppColors.trendRed;

            return Padding(
              padding:
                  EdgeInsets.only(bottom: i < top5.length - 1 ? 12 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // rank
                      SizedBox(
                        width: 14,
                        child: Text('${i + 1}',
                            style: GoogleFonts.jetBrainsMono(
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.5),
                                fontSize: 9)),
                      ),
                      const SizedBox(width: 6),
                      _Avatar(ticker: t, size: 26),
                      const SizedBox(width: 8),
                      // symbol
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(t.symbol,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${t.change24hPct >= 0 ? '+' : ''}${t.change24hPct.toStringAsFixed(2)}%',
                              style: GoogleFonts.jetBrainsMono(
                                  color: chColor, fontSize: 9.5),
                            ),
                          ],
                        ),
                      ),
                      // value
                      Text(_compact(val),
                          style: GoogleFonts.jetBrainsMono(
                              color: AppColors.textSecondary, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // progress bar
                  Row(
                    children: [
                      const SizedBox(width: 20),
                      Expanded(
                        child: Stack(
                          children: [
                            // bg track
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: barColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // fill
                            FractionallySizedBox(
                              widthFactor: pct.clamp(0.0, 1.0),
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    barColor.withValues(alpha: 0.5),
                                    barColor,
                                  ]),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _compact(double v) {
    if (v >= 1e12) return '\$${(v / 1e12).toStringAsFixed(1)}T';
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(0)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(0)}K';
    return '\$${v.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toggle button
// ─────────────────────────────────────────────────────────────────────────────
class _Toggle extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _Toggle(
      {required this.label,
      required this.active,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:
              active ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: GoogleFonts.jetBrainsMono(
              color: active ? color : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coin avatar with colored fallback
// ─────────────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final TickerModel ticker;
  final double size;
  const _Avatar({required this.ticker, required this.size});

  Color _hue(String s) {
    final h = (s.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    return HSLColor.fromAHSL(1, h, 0.60, 0.48).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final c = _hue(ticker.symbol);
    if (ticker.iconUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(ticker.iconUrl,
            width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _circle(c)),
      );
    }
    return _circle(c);
  }

  Widget _circle(Color c) {
    final initials = ticker.symbol.length >= 2
        ? ticker.symbol.substring(0, 2)
        : ticker.symbol;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          c.withValues(alpha: 0.35),
          c.withValues(alpha: 0.12),
        ]),
        border: Border.all(color: c.withValues(alpha: 0.45), width: 0.8),
      ),
      child: Center(
        child: Text(initials,
            style: GoogleFonts.jetBrainsMono(
              color: c,
              fontSize: size * 0.30,
              fontWeight: FontWeight.bold,
            )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing dot
// ─────────────────────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _a.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _a.value * 0.5),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
