import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/orderbook_model.dart';
import '../utils/app_colors.dart';

class OrderBookPanel extends StatelessWidget {
  final OrderBookSnapshot? snapshot;
  final bool isLoading;
  final String? errorMessage;
  final String sizeLabel;

  const OrderBookPanel({
    super.key,
    required this.snapshot,
    required this.isLoading,
    this.errorMessage,
    required this.sizeLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && snapshot == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.brandAccent, strokeWidth: 2),
        ),
      );
    }

    if (errorMessage != null && snapshot == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(color: AppColors.trendRed, fontSize: 12),
          ),
        ),
      );
    }

    final book = snapshot;
    if (book == null || (book.bids.isEmpty && book.asks.isEmpty)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(color: AppColors.brandAccent, strokeWidth: 2),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading live order book…',
              style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final asks = book.displayAsks;
    final bids = book.displayBids;
    final maxAskCum = asks.isEmpty ? 0.0 : asks.map((e) => e.cumulative).reduce((a, b) => a > b ? a : b);
    final maxBidCum = bids.isEmpty ? 0.0 : bids.map((e) => e.cumulative).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(sizeLabel: sizeLabel),
          const SizedBox(height: 4),
          ...asks.map((l) => _BookRow(level: l, isAsk: true, maxCumulative: maxAskCum)),
          _SpreadRow(spread: book.spread),
          ...bids.map((l) => _BookRow(level: l, isAsk: false, maxCumulative: maxBidCum)),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final String sizeLabel;
  const _HeaderRow({required this.sizeLabel});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text('Price', style: style)),
          Expanded(child: Text('Size ($sizeLabel)', textAlign: TextAlign.center, style: style)),
          Expanded(child: Text('Total ($sizeLabel)', textAlign: TextAlign.end, style: style)),
        ],
      ),
    );
  }
}

class _SpreadRow extends StatelessWidget {
  final OrderBookSpread spread;
  const _SpreadRow({required this.spread});

  @override
  Widget build(BuildContext context) {
    final pct = spread.percentage >= 0.01
        ? '${spread.percentage.toStringAsFixed(3)}%'
        : '${(spread.percentage * 100).toStringAsFixed(4)}%';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Spread', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11)),
          Text(
            '${_fmtNum(spread.absolute)}  $pct',
            style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  final OrderBookLevel level;
  final bool isAsk;
  final double maxCumulative;

  const _BookRow({
    required this.level,
    required this.isAsk,
    required this.maxCumulative,
  });

  @override
  Widget build(BuildContext context) {
    final priceColor = isAsk ? AppColors.trendRed : AppColors.trendGreen;
    final barColor = priceColor.withValues(alpha: 0.18);
    final fraction = maxCumulative > 0 ? (level.cumulative / maxCumulative).clamp(0.0, 1.0) : 0.0;
    final textStyle = GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w500);

    return SizedBox(
      height: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                height: 26,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(_fmtNum(level.price), style: textStyle.copyWith(color: priceColor)),
                ),
                Expanded(
                  child: Text(
                    _fmtNum(level.size),
                    textAlign: TextAlign.center,
                    style: textStyle.copyWith(color: AppColors.textPrimary.withValues(alpha: 0.9)),
                  ),
                ),
                Expanded(
                  child: Text(
                    _fmtNum(level.cumulative),
                    textAlign: TextAlign.end,
                    style: textStyle.copyWith(color: AppColors.textPrimary.withValues(alpha: 0.75)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtNum(double v) {
  if (v >= 1000) return v.toStringAsFixed(0);
  if (v >= 1) return v.toStringAsFixed(2);
  return v.toStringAsFixed(4);
}
