import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/ticker_model.dart';
import '../utils/app_colors.dart';
import '../viewmodels/home_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Live Markets drawer item — navigates to LiveMarketsScreen
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
            Container(
              width: 3,
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
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
                  Text(
                    'Live Markets',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Gainers • Losers • Active',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary.withValues(alpha: 0.55),
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
            _MiniPulseDot(color: AppColors.trendGreen),
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
            // ── Top bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: AppColors.textPrimary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                  ),
                  Text(
                    'Live Markets',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _MiniPulseDot(color: AppColors.trendGreen),
                  const Spacer(),
                  Text(
                    'Real-time',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: Consumer<HomeViewModel>(
                builder: (context, vm, _) {
                  final tickers = vm.tickers
                      .where((t) => !t.isDelisted)
                      .toList();

                  if (vm.isLoading && tickers.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brandAccent,
                        strokeWidth: 2,
                      ),
                    );
                  }

                  if (tickers.isEmpty) {
                    return Center(
                      child: Text(
                        'No market data',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Gainers + Top Losers side by side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _SectionCard(
                                icon: Icons.trending_up_rounded,
                                label: 'Top Gainers',
                                tag: '24h',
                                iconColor: AppColors.trendGreen,
                                iconBg: AppColors.trendGreen
                                    .withValues(alpha: 0.12),
                                child: _GainersLosersRows(
                                  tickers: tickers,
                                  isGainer: true,
                                  compact: false,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SectionCard(
                                icon: Icons.trending_down_rounded,
                                label: 'Top Losers',
                                tag: '24h',
                                iconColor: AppColors.trendRed,
                                iconBg: AppColors.trendRed
                                    .withValues(alpha: 0.12),
                                child: _GainersLosersRows(
                                  tickers: tickers,
                                  isGainer: false,
                                  compact: false,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Most Active full width
                        _MostActiveCard(
                            tickers: tickers, compact: false),
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
// Reusable card wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tag;
  final Color iconColor;
  final Color iconBg;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.label,
    required this.tag,
    required this.iconColor,
    required this.iconBg,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1014),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.surfaceBright.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(icon, size: 11, color: iconColor),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                tag,
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gainers / Losers rows
// ─────────────────────────────────────────────────────────────────────────────
class _GainersLosersRows extends StatelessWidget {
  final List<TickerModel> tickers;
  final bool isGainer;
  final bool compact;

  const _GainersLosersRows({
    required this.tickers,
    required this.isGainer,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = tickers
        .where((t) => isGainer ? t.change24hPct > 0 : t.change24hPct < 0)
        .toList();

    if (isGainer) {
      filtered.sort((a, b) => b.change24hPct.compareTo(a.change24hPct));
    } else {
      filtered.sort((a, b) => a.change24hPct.compareTo(b.change24hPct));
    }

    final top = filtered.take(3).toList();

    if (top.isEmpty) {
      return Text('No data',
          style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary, fontSize: 9));
    }

    final avatarSize = compact ? 16.0 : 20.0;
    final symFontSize = compact ? 10.0 : 12.0;
    final priceFontSize = compact ? 8.0 : 9.5;
    final badgeFontSize = compact ? 9.0 : 10.5;
    final rowSpacing = compact ? 5.0 : 8.0;

    final color = isGainer ? AppColors.trendGreen : AppColors.trendRed;

    return Column(
      children: List.generate(top.length, (i) {
        final t = top[i];
        final changeTxt =
            '${t.change24hPct >= 0 ? '+' : ''}${t.change24hPct.toStringAsFixed(2)}%';

        return Padding(
          padding: EdgeInsets.only(bottom: i < top.length - 1 ? rowSpacing : 0),
          child: Row(
            children: [
              SizedBox(
                width: 12,
                child: Text('${i + 1}',
                    style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textSecondary, fontSize: 8)),
              ),
              const SizedBox(width: 3),
              _CoinAvatar(ticker: t, size: avatarSize),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.symbol,
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textPrimary,
                          fontSize: symFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis),
                    Text(_fmtPrice(t.lastPrice),
                        style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textSecondary,
                            fontSize: priceFontSize)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: compact ? 5 : 7,
                    vertical: compact ? 2 : 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(changeTxt,
                    style: GoogleFonts.jetBrainsMono(
                      color: color,
                      fontSize: badgeFontSize,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _fmtPrice(double v) {
    if (v == 0) return '\$0';
    if (v < 0.0001) return '\$${v.toStringAsFixed(6)}';
    if (v < 0.01) return '\$${v.toStringAsFixed(4)}';
    if (v < 1) return '\$${v.toStringAsFixed(4)}';
    if (v < 1000) return '\$${v.toStringAsFixed(2)}';
    return '\$${(v / 1000).toStringAsFixed(1)}K';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Most Active card
// ─────────────────────────────────────────────────────────────────────────────
class _MostActiveCard extends StatefulWidget {
  final List<TickerModel> tickers;
  final bool compact;
  const _MostActiveCard({required this.tickers, this.compact = true});

  @override
  State<_MostActiveCard> createState() => _MostActiveCardState();
}

class _MostActiveCardState extends State<_MostActiveCard> {
  bool _byVolume = true;

  @override
  Widget build(BuildContext context) {
    final sorted = widget.tickers.toList();
    if (_byVolume) {
      sorted.sort((a, b) => b.volume24hUSD.compareTo(a.volume24hUSD));
    } else {
      sorted.sort((a, b) => b.openInterestUSD.compareTo(a.openInterestUSD));
    }
    final count = widget.compact ? 5 : 5;
    final top = sorted.take(count).toList();
    final maxVal = top.isEmpty
        ? 1.0
        : top
            .map((t) => _byVolume ? t.volume24hUSD : t.openInterestUSD)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1.0, double.infinity);

    final avatarSize = widget.compact ? 16.0 : 20.0;
    final symFontSize = widget.compact ? 10.0 : 11.0;
    final valFontSize = widget.compact ? 8.0 : 9.5;
    final rowSpacing = widget.compact ? 6.0 : 9.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1014),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.surfaceBright.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    size: 11, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 6),
              Text('Most Active',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  )),
              const Spacer(),
              // Vol / OI toggle
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBright.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ToggleBtn(
                        label: 'Vol',
                        active: _byVolume,
                        activeColor: const Color(0xFF7C3AED),
                        onTap: () => setState(() => _byVolume = true)),
                    _ToggleBtn(
                        label: 'OI',
                        active: !_byVolume,
                        activeColor: const Color(0xFFF59E0B),
                        onTap: () => setState(() => _byVolume = false)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ...List.generate(top.length, (i) {
            final t = top[i];
            final val = _byVolume ? t.volume24hUSD : t.openInterestUSD;
            final barPct = val / maxVal;
            final barColor = _byVolume
                ? const Color(0xFF7C3AED)
                : const Color(0xFFF59E0B);
            final changeColor = t.change24hPct >= 0
                ? AppColors.trendGreen
                : AppColors.trendRed;

            return Padding(
              padding:
                  EdgeInsets.only(bottom: i < top.length - 1 ? rowSpacing : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 12,
                        child: Text('${i + 1}',
                            style: GoogleFonts.jetBrainsMono(
                                color: AppColors.textSecondary, fontSize: 8)),
                      ),
                      const SizedBox(width: 3),
                      _CoinAvatar(ticker: t, size: avatarSize),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(t.symbol,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: AppColors.textPrimary,
                                    fontSize: symFontSize,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${t.change24hPct >= 0 ? '+' : ''}${t.change24hPct.toStringAsFixed(2)}%',
                              style: GoogleFonts.jetBrainsMono(
                                  color: changeColor, fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                      Text(_fmtCompact(val),
                          style: GoogleFonts.jetBrainsMono(
                              color: AppColors.textSecondary,
                              fontSize: valFontSize)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const SizedBox(width: 15),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: barPct,
                            minHeight: 2,
                            backgroundColor: barColor.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
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

  String _fmtCompact(double v) {
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
class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  const _ToggleBtn(
      {required this.label,
      required this.active,
      required this.activeColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: GoogleFonts.jetBrainsMono(
              color: active ? activeColor : AppColors.textSecondary,
              fontSize: 8,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coin avatar
// ─────────────────────────────────────────────────────────────────────────────
class _CoinAvatar extends StatelessWidget {
  final TickerModel ticker;
  final double size;
  const _CoinAvatar({required this.ticker, required this.size});

  Color _hashColor(String s) {
    final hue = (s.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    return HSLColor.fromAHSL(1, hue, 0.65, 0.50).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final color = _hashColor(ticker.symbol);
    if (ticker.iconUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          ticker.iconUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(color),
        ),
      );
    }
    return _fallback(color);
  }

  Widget _fallback(Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Center(
        child: Text(
          ticker.symbol.length >= 2
              ? ticker.symbol.substring(0, 2)
              : ticker.symbol,
          style: GoogleFonts.jetBrainsMono(
            color: color,
            fontSize: size * 0.32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini pulsing dot
// ─────────────────────────────────────────────────────────────────────────────
class _MiniPulseDot extends StatefulWidget {
  final Color color;
  const _MiniPulseDot({required this.color});

  @override
  State<_MiniPulseDot> createState() => _MiniPulseDotState();
}

class _MiniPulseDotState extends State<_MiniPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _anim.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _anim.value * 0.4),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
