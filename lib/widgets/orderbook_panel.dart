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
    
    // Find max cumulative per side for the chart/bars
        // displayAsks is [Furthest...Best], so first is max cumulative.
    final maxAskCum = asks.isEmpty ? 1.0 : asks.first.cumulative;
    // displayBids is [Best...Furthest], so last is max cumulative.
    final maxBidCum = bids.isEmpty ? 1.0 : bids.last.cumulative;
    
    // Find max size per side for the "Heat" bars
    final maxAskSize = asks.isEmpty ? 0.0 : asks.map((e) => e.size).reduce((a, b) => a > b ? a : b);
    final maxBidSize = bids.isEmpty ? 0.0 : bids.map((e) => e.size).reduce((a, b) => a > b ? a : b);

    // Calculate global thresholds for whale detection
    final allLevels = [...asks, ...bids];
    final avgSizes = allLevels.where((l) => l.orders > 0).map((l) => l.size / l.orders).toList();
    avgSizes.sort();
    final medianAvgSize = avgSizes.isEmpty ? 0.0 : avgSizes[avgSizes.length ~/ 2];
    final whaleThreshold = medianAvgSize * 4.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(sizeLabel: sizeLabel),
          const SizedBox(height: 4),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...asks.map((l) => _BookRow(
                        level: l,
                        isAsk: true,
                        maxCumulative: maxAskCum,
                        maxSize: maxAskSize,
                        whaleThreshold: whaleThreshold,
                      )),
                  _SpreadRow(spread: book.spread, midPrice: (asks.last.price + bids.first.price) / 2),
                  ...bids.map((l) => _BookRow(
                        level: l,
                        isAsk: false,
                        maxCumulative: maxBidCum,
                        maxSize: maxBidSize,
                        whaleThreshold: whaleThreshold,
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 8),
          _DepthChartHeader(maxBidCum: maxBidCum, maxAskCum: maxAskCum),
          const SizedBox(height: 8),
          _DepthChart(snapshot: book, maxAskCum: maxAskCum, maxBidCum: maxBidCum),
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
  final double midPrice;
  const _SpreadRow({required this.spread, required this.midPrice});

  @override
  Widget build(BuildContext context) {
    final pct = spread.percentage >= 0.01
        ? '${spread.percentage.toStringAsFixed(3)}%'
        : '${(spread.percentage * 100).toStringAsFixed(4)}%';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withValues(alpha: 0.15),
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.surfaceBright.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Spread',
              style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 0.5),
            ),
          ),
          Column(
            children: [
              Text(
                _fmtNum(midPrice),
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'MID PRICE',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Expanded(
            child: Text(
              pct,
              textAlign: TextAlign.end,
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textPrimary.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
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
  final double maxSize;
  final double whaleThreshold;

  const _BookRow({
    required this.level,
    required this.isAsk,
    required this.maxCumulative,
    required this.maxSize,
    required this.whaleThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final priceColor = isAsk ? AppColors.trendRed : AppColors.trendGreen;
    
    // Size-based heat bar (liquidity walls)
    final heatFraction = maxSize > 0 ? (level.size / maxSize).clamp(0.0, 1.0) : 0.0;
    // Cumulative bar (overall depth)
    final cumFraction = maxCumulative > 0 ? (level.cumulative / maxCumulative).clamp(0.0, 1.0) : 0.0;
    
    final textStyle = GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w500);
    final isWhale = level.orders > 0 && (level.size / level.orders) > whaleThreshold;

    return SizedBox(
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Bar (Cumulative) - Subtle background
          Align(
            alignment: isAsk ? Alignment.centerRight : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: cumFraction,
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: priceColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          // Heat Bar (Size) - Darker/more prominent for walls
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: heatFraction,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: priceColor.withValues(alpha: 0.15),
                  border: Border(
                    right: BorderSide(color: priceColor.withValues(alpha: 0.3), width: 2),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(_fmtNum(level.price), style: textStyle.copyWith(color: priceColor)),
                      if (isWhale) ...[
                        const SizedBox(width: 4),
                        const Text('🐳', style: TextStyle(fontSize: 10)),
                      ],
                    ],
                  ),
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

class _DepthChartHeader extends StatelessWidget {
  final double maxBidCum;
  final double maxAskCum;

  const _DepthChartHeader({required this.maxBidCum, required this.maxAskCum});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.jetBrainsMono(
      color: AppColors.textPrimary.withValues(alpha: 0.8),
      fontSize: 9,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 2,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.trendGreen.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 6),
              Text('BID DEPTH', style: style),
            ],
          ),
          Row(
            children: [
              Text('ASK DEPTH', style: style),
              const SizedBox(width: 6),
              Container(
                width: 2,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.trendRed.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A smooth cumulative volume depth chart.
class _DepthChart extends StatelessWidget {
  final OrderBookSnapshot snapshot;
  final double maxAskCum;
  final double maxBidCum;

  const _DepthChart({
    required this.snapshot,
    required this.maxAskCum,
    required this.maxBidCum,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBright.withValues(alpha: 0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _DepthChartPainter(
              bids: snapshot.bids,
              asks: snapshot.asks,
              maxAskCum: maxAskCum,
              maxBidCum: maxBidCum,
            ),
          ),
          // Total Bid Volume
          Positioned(
            left: 0,
            bottom: 0,
            child: Text(
              'Sum: ${_fmtVol(maxBidCum)}',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Total Ask Volume
          Positioned(
            right: 0,
            bottom: 0,
            child: Text(
              'Sum: ${_fmtVol(maxAskCum)}',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepthChartPainter extends CustomPainter {
  final List<OrderBookLevel> bids;
  final List<OrderBookLevel> asks;
  final double maxAskCum;
  final double maxBidCum;

  _DepthChartPainter({
    required this.bids,
    required this.asks,
    required this.maxAskCum,
    required this.maxBidCum,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bids.isEmpty || asks.isEmpty) return;

    final midIndex = size.width / 2;
    // Padding to keep the chart within the container and tabs area
    const vPadding = 4.0;
    final chartHeight = size.height - (vPadding * 2);
    
    // Paint Bids (left side)
    final bidPath = Path();
    bidPath.moveTo(midIndex, size.height);
    
    for (int i = 0; i < bids.length; i++) {
      // i=0 is Best Bid (near center), i=last is Furthest Bid (near edge)
      final fraction = (i + 1) / bids.length;
      final x = midIndex - fraction * midIndex;
      final y = size.height - vPadding - (bids[i].cumulative / maxBidCum) * chartHeight;
      bidPath.lineTo(x, y);
    }
    
    bidPath.lineTo(0, size.height);
    bidPath.close();
    
    final bidPaint = Paint()
      ..color = AppColors.trendGreen.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    
    final bidStrokePaint = Paint()
      ..color = AppColors.trendGreen.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;

    canvas.drawPath(bidPath, bidPaint);
    canvas.drawPath(bidPath, bidStrokePaint);

    // Paint Asks (right side)
    final askPath = Path();
    askPath.moveTo(midIndex, size.height);
    
    // displayAsks is [Furthest...Best]
    // i=last is Best Ask (near center), i=0 is Furthest Ask (near edge)
    for (int i = asks.length - 1; i >= 0; i--) {
      final fraction = (asks.length - i) / asks.length;
      final x = midIndex + fraction * midIndex;
      final y = size.height - vPadding - (asks[i].cumulative / maxAskCum) * chartHeight;
      askPath.lineTo(x, y);
    }
    
    askPath.lineTo(size.width, size.height);
    askPath.close();
    
    final askPaint = Paint()
      ..color = AppColors.trendRed.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final askStrokePaint = Paint()
      ..color = AppColors.trendRed.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;

    canvas.drawPath(askPath, askPaint);
    canvas.drawPath(askPath, askStrokePaint);
    
    // Draw Center Divider Line
    final centerPaint = Paint()
      ..color = AppColors.surfaceBright.withValues(alpha: 0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(midIndex, 0), Offset(midIndex, size.height), centerPaint);
  }

  @override
  bool shouldRepaint(covariant _DepthChartPainter oldDelegate) => true;
}

String _fmtNum(double v) {
  if (v >= 1000) return v.toStringAsFixed(0);
  if (v >= 1) return v.toStringAsFixed(2);
  return v.toStringAsFixed(4);
}

String _fmtVol(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  if (v >= 1) return v.toStringAsFixed(1);
  return v.toStringAsFixed(3);
}
