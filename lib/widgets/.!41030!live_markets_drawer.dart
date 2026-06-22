import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/ticker_model.dart';
import '../utils/app_colors.dart';
import '../utils/common_widgets.dart';
import '../viewmodels/home_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Drawer nav item → navigates to LiveMarketsScreen
// ─────────────────────────────────────────────────────────────────────────────
class LiveMarketsDrawerItem extends StatefulWidget {
  final VoidCallback onTap;
  const LiveMarketsDrawerItem({super.key, required this.onTap});

  @override
  State<LiveMarketsDrawerItem> createState() => _LiveMarketsDrawerItemState();
}

class _LiveMarketsDrawerItemState extends State<LiveMarketsDrawerItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bg;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _bg = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandAccent.withOpacity(_bg.value * 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.surfaceBright.withOpacity(0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Container(width: 3, height: 60, color: Colors.transparent),
                const SizedBox(width: 12),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBright.withOpacity(0.6),
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
                              color: AppColors.textSecondary.withOpacity(0.55),
                              fontSize: 9.5)),
                    ],
                  ),
                ),
                const PulseDot(color: AppColors.trendGreen),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppColors.surfaceBright),
                const SizedBox(width: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Markets full screen
// ─────────────────────────────────────────────────────────────────────────────
class LiveMarketsScreen extends StatelessWidget {
  const LiveMarketsScreen({super.key});

  String _compact(double v) {
    if (v >= 1e12) return '\$${(v / 1e12).toStringAsFixed(1)}T';
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(0)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(0)}K';
    return '\$${v.toStringAsFixed(0)}';
  }

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
                  const PulseDot(color: AppColors.trendGreen),
                  const Spacer(),
                  Text('Real-time',
                      style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.brandAccent.withOpacity(0.0),
                  AppColors.brandAccent.withOpacity(0.5),
                  AppColors.brandAccent.withOpacity(0.0),
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

                  final gainers = all.where((t) => t.change24hPct > 0).toList()
                    ..sort((a, b) => b.change24hPct.compareTo(a.change24hPct));
                  final losers = all.where((t) => t.change24hPct < 0).toList()
                    ..sort((a, b) => a.change24hPct.compareTo(b.change24hPct));
                  final totalVol = all.fold<double>(0, (s, t) => s + t.volume24hUSD);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Stats Summary ────────────────────────────
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _statCard('Markets', '${all.length}', Icons.show_chart_rounded),
                              _statCard('Gainers', '${gainers.length}', Icons.trending_up_rounded, color: AppColors.trendGreen),
                              _statCard('Losers', '${losers.length}', Icons.trending_down_rounded, color: AppColors.trendRed),
                              _statCard('Vol 24h', _compact(totalVol), Icons.bar_chart_rounded, isLast: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Top Gainers ───────────────────────────────
                        _GainersCard(tickers: gainers.take(5).toList()),
                        const SizedBox(height: 12),

                        // ── Top Losers ────────────────────────────────
                        _LosersCard(tickers: losers.take(5).toList()),
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

  Widget _statBlock(String label, String value, IconData icon, {Color? color}) {
    final c = color ?? AppColors.brandAccent;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: c.withOpacity(0.7)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              )),
          Text(label,
              style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary, fontSize: 8)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Gainers card
