import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../models/orderbook_model.dart';
import '../utils/app_colors.dart';
import '../viewmodels/subscription_viewmodel.dart';
import 'package:provider/provider.dart';
import 'paywall_widget.dart';
import '../screens/subscription_screen.dart';
import 'coming_soon_dialog.dart';

import '../utils/responsive.dart';

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
    final res = Responsive(context);

    if (isLoading && snapshot == null) {
      return _buildShimmerSkeleton(res);
    }

    if (errorMessage != null && snapshot == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(res.spacing(24)),
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(color: AppColors.trendRed, fontSize: res.fontSize(12)),
          ),
        ),
      );
    }

    final book = snapshot;
    if (book == null || (book.bids.isEmpty && book.asks.isEmpty)) {
      return _buildShimmerSkeleton(res);
    }

    final isPro = context.watch<SubscriptionViewModel>().isPro;

    if (!isPro) {
      return PaywallWidget(
        title: 'Premium Analytics',
        description: 'Unlock real-time orderbook depth, liquidity walls, and depth charts.',
        onUpgrade: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
        ),
      );
    }

    final asks = book.displayAsks;
    final bids = book.displayBids;
    
    final maxAskCum = asks.isEmpty ? 1.0 : asks.first.cumulative;
    final maxBidCum = bids.isEmpty ? 1.0 : bids.last.cumulative;
    
    final maxAskSize = asks.isEmpty ? 0.0 : asks.map((e) => e.size).reduce((a, b) => a > b ? a : b);
    final maxBidSize = bids.isEmpty ? 0.0 : bids.map((e) => e.size).reduce((a, b) => a > b ? a : b);

    final allLevels = [...asks, ...bids];
    final avgSizes = allLevels.where((l) => l.orders > 0).map((l) => l.size / l.orders).toList();
    avgSizes.sort();
    final medianAvgSize = avgSizes.isEmpty ? 0.0 : avgSizes[avgSizes.length ~/ 2];
    final whaleThreshold = medianAvgSize * 4.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight = constraints.maxHeight;
        // If height is very small (landscape), use a single scroll view instead of Expanded list
        if (availableHeight < 300) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(res.spacing(12)),
            child: Column(
              children: [
                _HeaderRow(sizeLabel: sizeLabel, res: res),
                ...asks.map((l) => _BookRow(level: l, isAsk: true, maxCumulative: maxAskCum, maxSize: maxAskSize, whaleThreshold: whaleThreshold, res: res)),
                _SpreadRow(spread: book.spread, midPrice: (asks.last.price + bids.first.price) / 2, res: res),
                ...bids.map((l) => _BookRow(level: l, isAsk: false, maxCumulative: maxBidCum, maxSize: maxBidSize, whaleThreshold: whaleThreshold, res: res)),
                SizedBox(height: res.spacing(12)),
                _DepthChartHeader(maxBidCum: maxBidCum, maxAskCum: maxAskCum, res: res),
                SizedBox(height: res.spacing(8)),
                _DepthChart(snapshot: book, maxAskCum: maxAskCum, maxBidCum: maxBidCum, res: res),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            res.spacing(12), 
            res.spacing(12), 
            res.spacing(12), 
            res.spacing(10) // Reduced bottom padding
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderRow(sizeLabel: sizeLabel, res: res),
              SizedBox(height: res.spacing(4)),
              Expanded(
                child: ListView( // Changed from SingleChildScrollView+Column to ListView
                  padding: EdgeInsets.zero,
                  children: [
                    ...asks.map((l) => _BookRow(
                          level: l,
                          isAsk: true,
                          maxCumulative: maxAskCum,
                          maxSize: maxAskSize,
                          whaleThreshold: whaleThreshold,
                          res: res,
                        )),
                    _SpreadRow(
                      spread: book.spread, 
                      midPrice: (asks.last.price + bids.first.price) / 2,
                      res: res,
                    ),
                    ...bids.map((l) => _BookRow(
                          level: l,
                          isAsk: false,
                          maxCumulative: maxBidCum,
                          maxSize: maxBidSize,
                          whaleThreshold: whaleThreshold,
                          res: res,
                        )),
                  ],
                ),
              ),
              // Conditional Chart: Hide or shrink if height is too small
              if (availableHeight > 200) ...[
                SizedBox(height: res.spacing(8)),
                _DepthChartHeader(maxBidCum: maxBidCum, maxAskCum: maxAskCum, res: res),
                SizedBox(height: res.spacing(4)),
                _DepthChart(snapshot: book, maxAskCum: maxAskCum, maxBidCum: maxBidCum, res: res),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerSkeleton(Responsive res) {
    return Padding(
      padding: EdgeInsets.all(res.spacing(16)),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF1E222D),
        highlightColor: const Color(0xFF3A3F4E),
        period: const Duration(milliseconds: 1500),
        child: Column(
          children: [
            // Top Stats Box Mock
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 20),
            // Header Skeleton
            Row(
              children: List.generate(
                  3,
                  (i) => Expanded(
                      child: Center(child: _skeletonPill(50, 10)))),
            ),
            const SizedBox(height: 16),
            // Rows Skeleton (Asks)
            ...List.generate(
                8,
                (index) => Padding(
                      padding: EdgeInsets.symmetric(vertical: res.spacing(4)),
                      child: Row(
                        children: [
                          Expanded(child: Center(child: _skeletonPill(40, 10))),
                          Expanded(child: Center(child: _skeletonPill(60, 10))),
                          Expanded(child: Center(child: _skeletonPill(50, 10))),
                        ],
                      ),
                    )),
            // Spread Skeleton
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Rows Skeleton (Bids)
            ...List.generate(
                8,
                (index) => Padding(
                      padding: EdgeInsets.symmetric(vertical: res.spacing(4)),
                      child: Row(
                        children: [
                          Expanded(child: Center(child: _skeletonPill(40, 10))),
                          Expanded(child: Center(child: _skeletonPill(60, 10))),
                          Expanded(child: Center(child: _skeletonPill(50, 10))),
                        ],
                      ),
                    )),
            const SizedBox(height: 20),
            // Depth Chart Skeleton
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonPill(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}



class _HeaderRow extends StatelessWidget {
  final String sizeLabel;
  final Responsive res;
  const _HeaderRow({required this.sizeLabel, required this.res});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.jetBrainsMono(
      color: AppColors.textSecondary,
      fontSize: res.fontSize(10),
    );
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: res.spacing(8), vertical: res.spacing(4)),
      child: Row(
        children: [
          Expanded(child: Center(child: Text('Price', style: style))),
          Expanded(
              child: Center(child: Text('Size ($sizeLabel)', style: style))),
          Expanded(
              child: Center(child: Text('Total ($sizeLabel)', style: style))),
        ],
      ),
    );
  }
}


class _SpreadRow extends StatelessWidget {
  final OrderBookSpread spread;
  final double midPrice;
  final Responsive res;
  const _SpreadRow({required this.spread, required this.midPrice, required this.res});

  @override
  Widget build(BuildContext context) {
    final pct = spread.percentage >= 0.01
        ? '${spread.percentage.toStringAsFixed(3)}%'
        : '${(spread.percentage * 100).toStringAsFixed(4)}%';

    return Container(
      margin: EdgeInsets.symmetric(vertical: res.spacing(8)),
      padding: EdgeInsets.symmetric(horizontal: res.spacing(12), vertical: res.spacing(10)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.15),
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.surfaceBright.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Spread',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary, 
                fontSize: res.fontSize(10), 
                letterSpacing: 0.5
              ),
            ),
          ),
          Column(
            children: [
              Text(
                _fmtNum(midPrice),
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textPrimary,
                  fontSize: res.fontSize(14),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'MID PRICE',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary.withOpacity(0.6),
                  fontSize: res.fontSize(8),
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
                color: AppColors.textPrimary.withOpacity(0.8),
                fontSize: res.fontSize(10),
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
  final Responsive res;

  const _BookRow({
    required this.level,
    required this.isAsk,
    required this.maxCumulative,
    required this.maxSize,
    required this.whaleThreshold,
    required this.res,
  });

  @override
  Widget build(BuildContext context) {
    final priceColor = isAsk ? AppColors.trendRed : AppColors.trendGreen;
    
    final heatFraction = maxSize > 0 ? (level.size / maxSize).clamp(0.0, 1.0) : 0.0;
    final cumFraction = maxCumulative > 0 ? (level.cumulative / maxCumulative).clamp(0.0, 1.0) : 0.0;
    
    final textStyle = GoogleFonts.jetBrainsMono(
      fontSize: res.fontSize(11), 
      fontWeight: FontWeight.w500
    );
    final isWhale = level.orders > 0 && (level.size / level.orders) > whaleThreshold;

    return SizedBox(
      height: res.spacing(24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: isAsk ? Alignment.centerRight : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: cumFraction,
              child: Container(
                height: res.spacing(24),
                decoration: BoxDecoration(
                  color: priceColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: heatFraction,
              child: Container(
                height: res.spacing(20),
                decoration: BoxDecoration(
                  color: priceColor.withOpacity(0.15),
                  border: Border(
                    right: BorderSide(color: priceColor.withOpacity(0.3), width: 2),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: res.spacing(8)),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_fmtNum(level.price),
                            style: textStyle.copyWith(color: priceColor)),
                        if (isWhale) ...[
                          const SizedBox(width: 4),
                          Text('🐳', style: TextStyle(fontSize: res.fontSize(10))),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _fmtNum(level.size),
                      style: textStyle.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.9)),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _fmtNum(level.cumulative),
                      style: textStyle.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.75)),
                    ),
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
  final Responsive res;

  const _DepthChartHeader({required this.maxBidCum, required this.maxAskCum, required this.res});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.jetBrainsMono(
      color: AppColors.textPrimary.withOpacity(0.8),
      fontSize: res.fontSize(9),
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: res.spacing(4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 2,
                height: res.spacing(10),
                decoration: BoxDecoration(
                  color: AppColors.trendGreen.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              SizedBox(width: res.spacing(6)),
              Text('BID DEPTH', style: style),
            ],
          ),
          Row(
            children: [
              Text('ASK DEPTH', style: style),
              SizedBox(width: res.spacing(6)),
              Container(
                width: 2,
                height: res.spacing(10),
                decoration: BoxDecoration(
                  color: AppColors.trendRed.withOpacity(0.8),
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
  final Responsive res;

  const _DepthChart({
    required this.snapshot,
    required this.maxAskCum,
    required this.maxBidCum,
    required this.res,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: res.value(mobile: 80.0, tablet: 120.0, desktop: 150.0),
      padding: EdgeInsets.fromLTRB(
        res.spacing(10), 
        res.spacing(8), 
        res.spacing(10), 
        res.spacing(8)
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.12)),
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
          Positioned(
            left: 0,
            bottom: 0,
            child: Text(
              'Sum: ${_fmtVol(maxBidCum)}',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: res.fontSize(8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Text(
              'Sum: ${_fmtVol(maxAskCum)}',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: res.fontSize(8),
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
      ..color = AppColors.trendGreen.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    
    final bidStrokePaint = Paint()
      ..color = AppColors.trendGreen.withOpacity(0.6)
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
      ..color = AppColors.trendRed.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    final askStrokePaint = Paint()
      ..color = AppColors.trendRed.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;

    canvas.drawPath(askPath, askPaint);
    canvas.drawPath(askPath, askStrokePaint);
    
    // Draw Center Divider Line
    final centerPaint = Paint()
      ..color = AppColors.surfaceBright.withOpacity(0.2)
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
