import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/liquidatable_model.dart';
import '../services/liquidatable_service.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/shimmer_skeleton.dart';
import '../utils/common_widgets.dart';

class LiquidatablePage extends StatefulWidget {
  const LiquidatablePage({super.key});

  @override
  State<LiquidatablePage> createState() => _LiquidatablePageState();
}

class _LiquidatablePageState extends State<LiquidatablePage> {
  final _service = LiquidatableService();
  LiquidatableResponse? _data;
  bool _loading = true;
  String? _error;
  String _selectedCoin = ''; // Empty means 'All'

  // Text controller for filtering
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false, String? coinOverride}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final coin = coinOverride ?? _selectedCoin;
      final result = await _service.getLiquidatable(coin: coin.isNotEmpty ? coin : null);
      if (mounted) {
        setState(() {
          _data = result;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  // Helper formatting methods
  Color _getPnlColor(double pnl) {
    if (pnl > 0) return const Color(0xFF10B981);
    if (pnl < 0) return const Color(0xFFEF4444);
    return const Color(0xFF6B7280);
  }

  Color _getDirectionColor(LiquidatablePosition pos) {
    return pos.isLong ? const Color(0xFF10B981) : const Color(0xFFEF4444);
  }

  String _formatRoe(double roe) {
    final pct = roe * 100;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  String _shortAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  String _formatPrice(double price) {
    if (price >= 1000) return '\$${price.toStringAsFixed(0)}';
    if (price >= 1) return '\$${price.toStringAsFixed(2)}';
    return '\$${price.toStringAsFixed(6)}';
  }

  String _formatUsd(double value) {
    final abs = value.abs();
    final sign = value < 0 ? '-' : '';
    if (abs >= 1000000) return '$sign\$${(abs / 1000000).toStringAsFixed(2)}M';
    if (abs >= 1000) return '$sign\$${(abs / 1000).toStringAsFixed(1)}K';
    return '$sign\$${abs.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.brandAccent, size: res.fontSize(20)),
        ),
        title: Text(
          '⚡ LIQUIDATIONS',
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.brandAccent,
            fontSize: res.fontSize(16),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          if (_data != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _data!.count > 0
                        ? Colors.red.withOpacity(0.12)
                        : Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _data!.count > 0 ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '${_data!.count} AT RISK',
                    style: GoogleFonts.jetBrainsMono(
                      color: _data!.count > 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Search Input Row
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.surfaceBright),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.search, size: 16, color: Colors.white38),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12),
                            onSubmitted: (val) {
                              final cleaned = val.trim().toUpperCase();
                              setState(() {
                                _selectedCoin = cleaned;
                              });
                              _load(coinOverride: cleaned);
                            },
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'FILTER COIN: e.g. BTC, ETH',
                              hintStyle: GoogleFonts.jetBrainsMono(color: Colors.white24, fontSize: 11),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_selectedCoin.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close, size: 14, color: Colors.white38),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _selectedCoin = '';
                              });
                              _load(coinOverride: '');
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _loading ? null : () => _load(),
                  child: Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.surfaceBright),
                    ),
                    alignment: Alignment.center,
                    child: _loading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.brandAccent,
                            ),
                          )
                        : const Icon(Icons.refresh, size: 16, color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),

          // Main body
          Expanded(child: _buildBody(res)),
        ],
      ),
    ),
  );
  }

  Widget _buildBody(Responsive res) {
    if (_loading && _data == null) {
      return _buildShimmerLoading(res);
    }
    if (_error != null && _data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 36, color: Colors.redAccent),
              const SizedBox(height: 8),
              Text(
                'Fetch Error',
                style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(color: Colors.white38, fontSize: 10),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _load(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandAccent,
                  foregroundColor: Colors.black,
                  textStyle: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    if (_data == null || _data!.data.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _load(silent: true),
        color: AppColors.brandAccent,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 100),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                const SizedBox(height: 12),
                Text(
                  'NO LIQUIDATIONS',
                  style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedCoin.isNotEmpty ? 'No positions found for $_selectedCoin' : 'Market is healthy and calm right now',
                  style: GoogleFonts.jetBrainsMono(color: Colors.white38, fontSize: 10),
                ),
                const SizedBox(height: 8),
                if (_data != null)
                  Text(
                    'Checked: ${_data!.fetchedAt.replaceAll('T', ' ').substring(0, 19)} UTC',
                    style: GoogleFonts.jetBrainsMono(color: Colors.white12, fontSize: 9),
                  ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _load(),
                  icon: const Icon(Icons.refresh, size: 14),
                  label: Text('CHECK AGAIN', style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandAccent,
                    side: BorderSide(color: AppColors.brandAccent.withOpacity(0.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      color: AppColors.brandAccent,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _data!.data.length,
        itemBuilder: (context, i) => _buildAccountCard(_data!.data[i], res),
      ),
    );
  }

  Widget _buildShimmerLoading(Responsive res) {
    return ShimmerSkeleton(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: 4,
        itemBuilder: (context, i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceBright.withOpacity(0.4), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shimmer Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBright.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerSkeleton.box(80, 10, radius: 4),
                      ShimmerSkeleton.box(70, 10, radius: 4),
                    ],
                  ),
                ),
                // Shimmer Position Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ShimmerSkeleton.box(36, 16, radius: 4),
                      const SizedBox(width: 8),
                      ShimmerSkeleton.box(80, 10, radius: 4),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ShimmerSkeleton.box(60, 10, radius: 4),
                          const SizedBox(height: 4),
                          ShimmerSkeleton.box(90, 8, radius: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountCard(LiquidatableAccount account, Responsive res) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.4), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceBright.withOpacity(0.35),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _shortAddress(account.user),
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: res.fontSize(11),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: account.user));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Address copied!',
                              style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.black),
                            ),
                            backgroundColor: AppColors.brandAccent,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: const Icon(Icons.copy, size: 12, color: Colors.white38),
                    ),
                  ],
                ),
                Text(
                  'Value: ${_formatUsd(account.accountValue)}',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.brandAccent,
                    fontSize: res.fontSize(11),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Positions loop
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: account.positions.map((pos) => _buildPositionRow(pos, res)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionRow(LiquidatablePosition pos, Responsive res) {
    final directionColor = _getDirectionColor(pos);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: directionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: directionColor.withOpacity(0.3), width: 0.5),
            ),
            child: Text(
              pos.coin,
              style: GoogleFonts.jetBrainsMono(
                color: directionColor,
                fontWeight: FontWeight.bold,
                fontSize: res.fontSize(10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            pos.isLong ? 'LONG / ${pos.leverageValue}x' : 'SHORT / ${pos.leverageValue}x',
            style: GoogleFonts.jetBrainsMono(
              color: directionColor.withOpacity(0.7),
              fontSize: res.fontSize(9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Liq: ${_formatPrice(pos.liquidationPx)}',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white70,
                  fontSize: res.fontSize(11),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'PnL: ${_formatUsd(pos.unrealizedPnl)} (${_formatRoe(pos.returnOnEquity)})',
                style: GoogleFonts.jetBrainsMono(
                  color: _getPnlColor(pos.unrealizedPnl),
                  fontSize: res.fontSize(10),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
