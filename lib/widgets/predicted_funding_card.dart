import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/predicted_funding_service.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';

class PredictedFundingCard extends StatefulWidget {
  final String coin;
  const PredictedFundingCard({super.key, required this.coin});

  @override
  State<PredictedFundingCard> createState() => _PredictedFundingCardState();
}

class _PredictedFundingCardState extends State<PredictedFundingCard> {
  final _service = PredictedFundingsService();
  PredictedFunding? _funding;
  String _selectedVenue = 'HlPerp';
  bool _isLoading = false;
  String _error = '';
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  String _countdownStr = '00:00';

  @override
  void initState() {
    super.initState();
    _loadData();
    // Refresh every 15 seconds as per server cache guidelines
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadData());
    // Countdown ticks every 1 second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PredictedFundingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coin != widget.coin) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    setState(() {
      _error = '';
    });
    try {
      final cleanCoin = widget.coin.split('-').first.toUpperCase();
      final f = await _service.getCoinFunding(cleanCoin);
      if (!mounted) return;
      setState(() {
        _funding = f;
        _isLoading = false;
        // Make sure selected venue is still valid / exists in response
        if (f != null && f.venues.isNotEmpty) {
          final hasSelected = f.venues.any((v) => v.venue == _selectedVenue);
          if (!hasSelected) {
            _selectedVenue = f.venues.first.venue;
          }
        }
      });
      _updateCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _updateCountdown() {
    if (_funding == null || _funding!.venues.isEmpty) return;
    final venue = _funding!.venues.firstWhere(
      (v) => v.venue == _selectedVenue,
      orElse: () => _funding!.venues.first,
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    final diffMs = venue.nextFundingTime - now;

    if (diffMs <= 0) {
      if (mounted) {
        setState(() {
          _countdownStr = '00:00';
        });
      }
      return;
    }

    final hours = (diffMs / 3600000).floor();
    final minutes = ((diffMs % 3600000) / 60000).floor();
    final seconds = ((diffMs % 60000) / 1000).floor();

    String formatted;
    if (hours > 0) {
      formatted = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      formatted = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    if (mounted) {
      setState(() {
        _countdownStr = formatted;
      });
    }
  }

  Color _getFundingColor(double rate) {
    if (rate > 0) return AppColors.trendRed; // Longs pay shorts
    if (rate < 0) return AppColors.trendGreen; // Shorts pay longs
    return AppColors.textSecondary;
  }

  String _formatFundingRate(double rate) {
    final pct = rate * 100;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(4)}%';
  }

  String _formatAnnualAPR(double rate, int intervalHours) {
    final periodsPerDay = 24 / intervalHours;
    final annual = rate * periodsPerDay * 365 * 100;
    final sign = annual >= 0 ? '+' : '';
    return '$sign${annual.toStringAsFixed(1)}% APR';
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);

    if (_funding == null) {
      if (_isLoading) {
        return const SizedBox(
          height: 110,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandAccent),
            ),
          ),
        );
      }
      // If error or null, don't break the UI, return a tidy empty placeholder or info
      return const SizedBox.shrink();
    }

    final venues = _funding!.venues;
    if (venues.isEmpty) return const SizedBox.shrink();

    final activeVenue = venues.firstWhere(
      (v) => v.venue == _selectedVenue,
      orElse: () => venues.first,
    );

    final color = _getFundingColor(activeVenue.fundingRate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.4), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '🔮 PREDICTED FUNDING',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white70,
                      fontSize: res.fontSize(9.5),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Animated Pulsing Indicator
                  _PulsingDot(color: color),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: AppColors.textSecondary, size: 10),
                  const SizedBox(width: 4),
                  Text(
                    _countdownStr,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: res.fontSize(9.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Venues Row Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: venues.map((v) {
                final isSelected = v.venue == _selectedVenue;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVenue = v.venue;
                      });
                      _updateCountdown();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brandAccent.withOpacity(0.12) : AppColors.surfaceBright.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? AppColors.brandAccent : Colors.transparent,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        v.venue,
                        style: GoogleFonts.jetBrainsMono(
                          color: isSelected ? AppColors.brandAccent : AppColors.textSecondary,
                          fontSize: res.fontSize(9.5),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Rate & APR display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatFundingRate(activeVenue.fundingRate),
                    style: GoogleFonts.jetBrainsMono(
                      color: color,
                      fontSize: res.fontSize(22),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activeVenue.fundingRate > 0
                        ? 'Longs pay Shorts'
                        : activeVenue.fundingRate < 0
                            ? 'Shorts pay Longs'
                            : 'Neutral market',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: res.fontSize(9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.2), width: 0.8),
                ),
                child: Text(
                  _formatAnnualAPR(activeVenue.fundingRate, activeVenue.fundingIntervalHours),
                  style: GoogleFonts.jetBrainsMono(
                    color: color,
                    fontSize: res.fontSize(11),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
