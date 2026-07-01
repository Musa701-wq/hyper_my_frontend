import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import '../models/trade_model.dart';
import '../services/hip4_trades_service.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';

/// Live recent trades panel for a HIP-4 outcome coin.
/// Manages its own [Hip4TradesService] lifecycle.
class Hip4TradesPanel extends StatefulWidget {
  final String marketId;
  final int side;        // 0 = YES, 1 = NO
  final String coinSymbol;

  const Hip4TradesPanel({
    super.key,
    required this.marketId,
    required this.side,
    required this.coinSymbol,
  });

  @override
  State<Hip4TradesPanel> createState() => _Hip4TradesPanelState();
}

class _Hip4TradesPanelState extends State<Hip4TradesPanel> {
  Hip4TradesService? _service;
  List<Trade> _trades = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _startService();
  }

  @override
  void didUpdateWidget(Hip4TradesPanel old) {
    super.didUpdateWidget(old);
    if (old.side != widget.side || old.coinSymbol != widget.coinSymbol) {
      _service?.dispose();
      _trades = [];
      _loading = true;
      _startService();
    }
  }

  void _startService() {
    _service = Hip4TradesService(
      marketId: widget.marketId,
      side: widget.side,
      coinSymbol: widget.coinSymbol,
    );
    _service!.start(
      onUpdate: (trades) {
        if (!mounted) return;
        // Merge: prepend new unique trades
        final existingKeys = _trades.map((t) => '${t.time}-${t.hash ?? t.price}').toSet();
        final fresh = trades.where((t) =>
            !existingKeys.contains('${t.time}-${t.hash ?? t.price}')).toList();
        if (fresh.isNotEmpty || _loading) {
          setState(() {
            _trades = [...fresh, ..._trades];
            if (_trades.length > 100) _trades = _trades.sublist(0, 100);
            _trades.sort((a, b) => b.time.compareTo(a.time));
            _loading = false;
          });
        } else if (_loading) {
          setState(() => _loading = false);
        }
      },
    );
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    if (_loading) return _shimmer(res);
    if (_trades.isEmpty) return _empty(res);

    final buys = _trades.where((t) => t.isBuy).length;
    final buyPct = (_trades.isEmpty ? 50.0 : (buys / _trades.length) * 100);
    final sellPct = 100.0 - buyPct;
    double vwap = 0;
    double totalSz = 0;
    for (final t in _trades) { vwap += t.value; totalSz += t.size; }
    vwap = totalSz > 0 ? vwap / totalSz : 0;

    return Column(
      children: [
        // ── Stats bar ──
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF161A22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceBright.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statCol('LAST', '\$${_trades.first.price.toStringAsFixed(4)}',
                  _trades.first.isBuy ? AppColors.trendGreen : AppColors.trendRed, res),
              _buySellBar(buyPct, sellPct, res),
              _statCol('VWAP', '\$${vwap.toStringAsFixed(4)}', AppColors.brandAccent, res,
                  align: CrossAxisAlignment.end),
            ],
          ),
        ),
        // ── Table ──
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF161A22),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceBright.withOpacity(0.4)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Column(
                children: [
                  _tableHeader(res),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _trades.length,
                      itemBuilder: (_, i) => _tradeRow(_trades[i], res, i % 2 == 0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCol(String label, String value, Color c, Responsive res,
      {CrossAxisAlignment align = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label,
            style: GoogleFonts.jetBrainsMono(
                color: Colors.white38, fontSize: res.fontSize(8), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 3),
        Text(value,
            style: GoogleFonts.jetBrainsMono(
                color: c, fontSize: res.fontSize(13), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buySellBar(double buyPct, double sellPct, Responsive res) {
    return Column(
      children: [
        Row(
          children: [
            Text('${buyPct.toStringAsFixed(0)}%',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.trendGreen, fontSize: 9, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            Text('${sellPct.toStringAsFixed(0)}%',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.trendRed, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: SizedBox(
            width: 80,
            height: 4,
            child: Row(
              children: [
                Expanded(flex: buyPct.round().clamp(0, 100), child: Container(color: AppColors.trendGreen)),
                Expanded(flex: sellPct.round().clamp(0, 100), child: Container(color: AppColors.trendRed)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text('VOL RATIO',
            style: GoogleFonts.jetBrainsMono(
                color: Colors.white24, fontSize: 7, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _tableHeader(Responsive res) {
    final s = GoogleFonts.jetBrainsMono(
        color: Colors.white38, fontSize: res.fontSize(9), fontWeight: FontWeight.bold, letterSpacing: 0.5);
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        border: Border(bottom: BorderSide(color: AppColors.surfaceBright.withOpacity(0.4))),
      ),
      child: Row(children: [
        Expanded(child: Text('TIME', style: s, textAlign: TextAlign.center)),
        Expanded(child: Text('DIR', style: s, textAlign: TextAlign.center)),
        Expanded(child: Text('PRICE', style: s, textAlign: TextAlign.center)),
        Expanded(child: Text('SIZE', style: s, textAlign: TextAlign.center)),
        Expanded(child: Text('VALUE', style: s, textAlign: TextAlign.center)),
      ]),
    );
  }

  Widget _tradeRow(Trade t, Responsive res, bool even) {
    final color = t.isBuy ? AppColors.trendGreen : AppColors.trendRed;
    final s = GoogleFonts.jetBrainsMono(fontSize: res.fontSize(10));
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: even ? Colors.white.withOpacity(0.015) : Colors.transparent,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.025), width: 0.5)),
      ),
      child: Row(children: [
        Expanded(child: Text(t.timeFormatted, style: s.copyWith(color: Colors.white30), textAlign: TextAlign.center)),
        Expanded(child: Text(t.direction, style: s.copyWith(color: color, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        Expanded(child: Text('\$${t.price.toStringAsFixed(4)}', style: s.copyWith(color: color, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        Expanded(child: Text(NumberFormat('#,##0.##').format(t.size), style: s.copyWith(color: Colors.white60), textAlign: TextAlign.center)),
        Expanded(child: Text('\$${t.value.toStringAsFixed(2)}', style: s.copyWith(color: Colors.white70), textAlign: TextAlign.center)),
      ]),
    );
  }

  Widget _shimmer(Responsive res) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E222D),
      highlightColor: const Color(0xFF3A3F4E),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(height: 58, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 8),
            Expanded(
              child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(Responsive res) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swap_horiz_rounded, color: Colors.white12, size: 48),
          const SizedBox(height: 12),
          Text(
            'No recent trades for ${widget.coinSymbol}',
            style: GoogleFonts.jetBrainsMono(color: Colors.white24, fontSize: res.fontSize(11)),
          ),
        ],
      ),
    );
  }
}
