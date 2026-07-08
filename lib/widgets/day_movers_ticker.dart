import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/leaderboard_model.dart';
import '../services/leaderboard_service.dart';
import '../utils/app_colors.dart';
import '../screens/profile_screen.dart';

class DayMoversTicker extends StatefulWidget {
  const DayMoversTicker({super.key});

  @override
  State<DayMoversTicker> createState() => _DayMoversTickerState();
}

class _DayMoversTickerState extends State<DayMoversTicker> {
  final _service = LeaderboardService();
  List<Trader> _traders = [];
  bool _isLoaded = false;

  Timer? _scrollTimer;
  Timer? _fetchTimer;
  final ScrollController _scrollController = ScrollController();
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh every 60 seconds
    _fetchTimer = Timer.periodic(const Duration(seconds: 60), (_) => _loadData());
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _fetchTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final res = await _service.getHeadline(limit: 5);
      final combined = [...res.gainers, ...res.losers];
      if (mounted) {
        setState(() {
          _traders = combined;
          _isLoaded = true;
        });

        // Initialize scrolling action if there are traders and no active scroll timer
        if (_traders.isNotEmpty && _scrollTimer == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startScrollTimer();
          });
        }
      }
    } catch (e) {
      debugPrint('DayMoversTicker error: $e');
      // Silently ignore failures as per integration guide
    }
  }

  void _startScrollTimer() {
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (_isPaused) return;
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentOffset = _scrollController.offset;
        const double speed = 0.6; // elegant scrolling speed
        if (currentOffset >= maxScroll) {
          _scrollController.jumpTo(0.0);
        } else {
          _scrollController.jumpTo(currentOffset + speed);
        }
      }
    });
  }

  String _getShortName(Trader t) {
    final name = t.displayName;
    if (name.isEmpty || name == 'Anonymous' || name.startsWith('0x')) {
      final addr = t.ethAddress;
      if (addr.length >= 10) {
        return '${addr.substring(0, 6)}..${addr.substring(addr.length - 4)}';
      }
      return addr;
    }
    if (name.length > 12) {
      return '${name.substring(0, 6)}..${name.substring(name.length - 4)}';
    }
    return name;
  }

  String _fmtPnl(double val) {
    final abs = val.abs();
    final sign = val >= 0 ? '+' : '-';
    if (abs >= 1e9) {
      return '$sign\$${(abs / 1e9).toStringAsFixed(2)}B';
    } else if (abs >= 1e6) {
      return '$sign\$${(abs / 1e6).toStringAsFixed(2)}M';
    } else if (abs >= 1e3) {
      return '$sign\$${(abs / 1e3).toStringAsFixed(1)}K';
    } else {
      return '$sign\$${abs.toStringAsFixed(2)}';
    }
  }

  String _fmtRoi(double roi) {
    final sign = roi >= 0 ? '+' : '';
    final arrow = roi >= 0 ? '↑' : '↓';
    return '$arrow ROI$sign${roi.toStringAsFixed(2)}%';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _traders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 32.0,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceBright.withOpacity(0.3),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Fixed Info Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: AppColors.surface,
            alignment: Alignment.center,
            child: Text(
              'DAY MOVERS',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.brandAccent,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Vertical Separator Bar
          Container(
            width: 1,
            height: 14,
            color: AppColors.surfaceBright,
          ),
          const SizedBox(width: 8),

          // Horizontal Scrolling Section
          Expanded(
            child: GestureDetector(
              onTapDown: (_) => _isPaused = true,
              onTapUp: (_) => _isPaused = false,
              onTapCancel: () => _isPaused = false,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(), // Managed strictly by our timer
                itemCount: 10000,
                itemBuilder: (context, index) {
                  final trader = _traders[index % _traders.length];
                  final isGainer = trader.pnl >= 0;
                  final pnlColor = isGainer ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
                  final shortName = _getShortName(trader);

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(walletAddress: trader.ethAddress),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            shortName,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '|',
                            style: TextStyle(color: AppColors.surfaceBright, fontSize: 10),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PnL  ',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            _fmtPnl(trader.pnl),
                            style: GoogleFonts.jetBrainsMono(
                              color: pnlColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _fmtRoi(trader.roi),
                            style: GoogleFonts.jetBrainsMono(
                              color: pnlColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
