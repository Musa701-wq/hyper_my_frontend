import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyperscreener/widgets/error_state_widget.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../utils/common_widgets.dart';
import '../viewmodels/leaderboard_viewmodel.dart';
import '../models/leaderboard_model.dart';
import 'home_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Synced scroll controllers
  late final ScrollController _leftScroll;
  late final ScrollController _rightScroll;
  bool _syncingLeft = false;
  bool _syncingRight = false;

  @override
  void initState() {
    super.initState();
    _leftScroll = ScrollController();
    _rightScroll = ScrollController();

    _leftScroll.addListener(() {
      if (_syncingRight) return;
      _syncingLeft = true;
      if (_rightScroll.hasClients) _rightScroll.jumpTo(_leftScroll.offset);
      _syncingLeft = false;
    });
    _rightScroll.addListener(() {
      if (_syncingLeft) return;
      _syncingRight = true;
      if (_leftScroll.hasClients) _leftScroll.jumpTo(_rightScroll.offset);
      _syncingRight = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaderboardViewModel>(context, listen: false).fetchAllData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _leftScroll.dispose();
    _rightScroll.dispose();
    super.dispose();
  }

  String _fmt(double v, {bool isCurrency = false, bool isPct = false}) {
    if (isPct) return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
    final p = isCurrency ? '\$' : '';
    final a = v.abs();
    if (a >= 1e12) return '$p${(v / 1e12).toStringAsFixed(2)}T';
    if (a >= 1e9)  return '$p${(v / 1e9).toStringAsFixed(2)}B';
    if (a >= 1e6)  return '$p${(v / 1e6).toStringAsFixed(2)}M';
    if (a >= 1e3)  return '$p${(v / 1e3).toStringAsFixed(2)}K';
    return '$p${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Consumer<LeaderboardViewModel>(
            builder: (context, vm, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context, vm, res),
                  const SizedBox(height: 6),
                  _buildSearchBar(vm, res),
                  const SizedBox(height: 8),
                  _buildPeriodTabs(vm, res),
                  const SizedBox(height: 8),
                  _buildRowsPerPage(vm, res),
                  const SizedBox(height: 6),
                  Expanded(child: _buildBody(res, vm)),
                  _buildPagination(vm, res),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, LeaderboardViewModel vm, Responsive res) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const HomeScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                transitionsBuilder: (_, __, ___, child) => child,
              ),
            ),
            padding: EdgeInsets.zero,
          ),
          Text(
            'Top Traders',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textPrimary,
              fontSize: res.fontSize(18),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (vm.topTraders.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.brandAccent.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${vm.totalPages * vm.rowsPerPage} traders',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.brandAccent,
                  fontSize: res.fontSize(10),
                ),
              ),
            ),
          ],
          const Spacer(),
          if (vm.isLoading)
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandAccent),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 18),
              onPressed: () => vm.fetchAllData(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar(LeaderboardViewModel vm, Responsive res) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.surfaceBright),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.textSecondary, size: res.fontSize(20)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) { vm.setSearchQuery(v); setState(() {}); },
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textPrimary, fontSize: res.fontSize(14)),
                decoration: InputDecoration(
                  hintText: 'Search address or name...',
                  hintStyle: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: res.fontSize(14)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: res.spacing(12)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            vm.setSearchQuery('');
                            setState(() {});
                          },
                          child: const Icon(Icons.close, color: AppColors.textSecondary, size: 16),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Period tabs ────────────────────────────────────────────────────────────
  Widget _buildPeriodTabs(LeaderboardViewModel vm, Responsive res) {
    const periods = [
      ('allTime', 'ALL'),
      ('day',     '24H'),
      ('week',    '7D'),
      ('month',   '30D'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceBright),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: periods.map((p) {
              final sel = vm.selectedPeriod == p.$1;
              return GestureDetector(
                onTap: () => vm.setPeriod(p.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel ? AppColors.surfaceBright : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.$2,
                    style: GoogleFonts.jetBrainsMono(
                      color: sel ? AppColors.brandAccent : AppColors.textSecondary,
                      fontSize: res.fontSize(12),
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Rows per page ──────────────────────────────────────────────────────────
  Widget _buildRowsPerPage(LeaderboardViewModel vm, Responsive res) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Show:',
              style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary,
                  fontSize: res.fontSize(11))),
          const SizedBox(width: 8),
          Theme(
            data: Theme.of(context).copyWith(canvasColor: AppColors.background),
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.surfaceBright),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: vm.rowsPerPage,
                  dropdownColor: AppColors.background,
                  style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textPrimary,
                      fontSize: res.fontSize(12)),
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary, size: 14),
                  isDense: true,
                  onChanged: (v) {
                    if (v != null) vm.setRowsPerPage(v);
                  },
                  items: [10, 20, 30, 50]
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text('$v rows',
                                style: GoogleFonts.jetBrainsMono(
                                    color: AppColors.textPrimary,
                                    fontSize: res.fontSize(11))),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody(Responsive res, LeaderboardViewModel vm) {
    if (vm.isLoading && vm.topTraders.isEmpty) {
      return _buildShimmer(res);
    }
    if (vm.error != null && vm.topTraders.isEmpty) {
      return ErrorStateWidget(
          errorMessage: vm.error!, onRetry: () => vm.fetchAllData());
    }
    if (vm.topTraders.isEmpty) {
      return Center(
        child: Text('No traders found',
            style: GoogleFonts.jetBrainsMono(color: Colors.white24)),
      );
    }
    return Stack(
      children: [
        _buildTable(res, vm),
        if (vm.isLoading)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Shimmer.fromColors(
              baseColor: Colors.transparent,
              highlightColor: AppColors.brandAccent.withValues(alpha: 0.15),
              child: Container(height: 2, color: Colors.white),
            ),
          ),
      ],
    );
  }

  // ── Shimmer skeleton ───────────────────────────────────────────────────────
  Widget _buildShimmer(Responsive res) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF1E222D),
        highlightColor: const Color(0xFF2E3340),
        period: const Duration(milliseconds: 1400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row skeleton
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  _sPill(24, 10),
                  const SizedBox(width: 10),
                  _sPill(80, 10),
                  const Spacer(),
                  Flexible(child: _sPill(65, 10)),
                  const SizedBox(width: 12),
                  Flexible(child: _sPill(55, 10)),
                  const SizedBox(width: 12),
                  Flexible(child: _sPill(45, 10)),
                  const SizedBox(width: 12),
                  Flexible(child: _sPill(60, 10)),
                ],
              ),
            ),
            Container(height: 0.5, color: Colors.white12),
            const SizedBox(height: 4),
            ...List.generate(14, (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  _sPill(22, 10),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sPill(double.infinity, 11),
                        const SizedBox(height: 5),
                        _sPill(70, 8),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: _sPill(65, 11)),
                  const SizedBox(width: 8),
                  Flexible(child: _sPill(55, 11)),
                  const SizedBox(width: 8),
                  Flexible(child: _sPill(45, 11)),
                  const SizedBox(width: 8),
                  Flexible(child: _sPill(60, 11)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _sPill(double w, double h) => Container(
        width: w == double.infinity ? null : w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(h / 2),
        ),
      );

  // ── Table ──────────────────────────────────────────────────────────────────
  // Single CustomScrollView approach — no extra divider between columns,
  // no extra spacing. Header is a SliverPersistentHeader (sticky).
  Widget _buildTable(Responsive res, LeaderboardViewModel vm) {
    final double leftW  = res.isMobile ? 150.0 : 180.0;
    const double wAcc   = 110.0;
    const double wPnl   = 105.0;
    const double wRoi   =  95.0;
    const double wVol   = 110.0;
    const double rightW = wAcc + wPnl + wRoi + wVol;

    final traders = vm.topTraders;

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fixed left column ──────────────────────────────────────────────
          SizedBox(
            width: leftW,
            child: _StickyTable(
              controller: _leftScroll,
              header: _leftHeader(res),
              itemCount: traders.length,
              itemBuilder: (i) => _leftRow(i, traders[i], vm, res),
            ),
          ),

          // ── Scrollable right columns ───────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: rightW,
                child: _StickyTable(
                  controller: _rightScroll,
                  header: _rightHeader(res, vm, wAcc, wPnl, wRoi, wVol),
                  itemCount: traders.length,
                  itemBuilder: (i) => _rightRow(traders[i], res, wAcc, wPnl, wRoi, wVol),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Left sticky header
  Widget _leftHeader(Responsive res) {
    return Container(
      height: 44,
      color: Colors.black,
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('#',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: res.fontSize(11))),
          ),
          const SizedBox(width: 4),
          Text('Trader',
              style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary,
                  fontSize: res.fontSize(11))),
        ],
      ),
    );
  }

  // Right sticky header — tapping a cell sorts by that metric
  Widget _rightHeader(Responsive res, LeaderboardViewModel vm,
      double wAcc, double wPnl, double wRoi, double wVol) {
    return Container(
      height: 44,
      color: Colors.black,
      child: Row(
        children: [
          _sortableHCell('ACC. VALUE', 'accountValue', wAcc, res, vm),
          _sortableHCell('PNL',         'pnl',          wPnl, res, vm),
          _sortableHCell('ROI',         'roi',          wRoi, res, vm),
          _sortableHCell('VOLUME',      'volume',       wVol, res, vm),
        ],
      ),
    );
  }

  Widget _sortableHCell(String label, String metric, double width,
      Responsive res, LeaderboardViewModel vm) {
    final active = vm.selectedMetric == metric;
    return GestureDetector(
      onTap: () => vm.setMetric(metric),
      child: SizedBox(
        width: width,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (active) ...[
                Icon(Icons.arrow_downward_rounded,
                    size: 10, color: AppColors.brandAccent),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  color: active ? AppColors.brandAccent : AppColors.textSecondary,
                  fontSize: res.fontSize(11),
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Left data row
  Widget _leftRow(int i, Trader t, LeaderboardViewModel vm, Responsive res) {
    final rank = i + 1 + (vm.currentPage - 1) * vm.rowsPerPage;
    final addr = t.ethAddress;
    final hasName = t.displayName.isNotEmpty &&
        t.displayName != 'Anonymous' &&
        !t.displayName.startsWith('0x');
    final name = hasName
        ? t.displayName
        : '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';

    final rankColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : rank <= 10
                    ? AppColors.brandAccent
                    : AppColors.textSecondary;

    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 8, right: 4),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('$rank',
                style: GoogleFonts.jetBrainsMono(
                  color: rankColor,
                  fontSize: res.fontSize(10),
                  fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
                )),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name,
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textPrimary,
                      fontSize: res.fontSize(11),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis),
                Text('${addr.substring(0, 8)}...',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary,
                      fontSize: res.fontSize(8),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Right data row
  Widget _rightRow(Trader t, Responsive res,
      double wAcc, double wPnl, double wRoi, double wVol) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
      ),
      child: Row(
        children: [
          _dCell(_fmt(t.accountValue, isCurrency: true),
              width: wAcc, res: res),
          _dCell(_fmt(t.pnl, isCurrency: true),
              width: wPnl,
              res: res,
              color: t.pnl >= 0 ? AppColors.trendGreen : AppColors.trendRed),
          _dCell(_fmt(t.roi, isPct: true),
              width: wRoi,
              res: res,
              color: t.roi >= 0 ? AppColors.trendGreen : AppColors.trendRed),
          _dCell(_fmt(t.volume, isCurrency: true),
              width: wVol, res: res),
        ],
      ),
    );
  }

  Widget _dCell(String text,
      {required double width, required Responsive res, Color? color}) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              color: color ?? AppColors.textPrimary,
              fontSize: res.fontSize(11),
              fontWeight: FontWeight.w500,
            )),
      ),
    );
  }

  // ── Pagination ─────────────────────────────────────────────────────────────
  Widget _buildPagination(LeaderboardViewModel vm, Responsive res) {
    if (vm.totalPages <= 1) return const SizedBox.shrink();

    final total = vm.totalPages;
    final cur   = vm.currentPage;
    int start = (cur - 1).clamp(1, total);
    int end   = (start + 2).clamp(1, total);
    if (end == total && total > 3) start = (end - 2).clamp(1, total);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pgBtn(icon: Icons.chevron_left,  enabled: cur > 1,      onTap: vm.previousPage, res: res),
          const SizedBox(width: 6),
          for (int p = start; p <= end; p++) ...[
            _pgNumBtn(p, cur == p, () => vm.setPage(p), res),
            const SizedBox(width: 4),
          ],
          const SizedBox(width: 2),
          _pgBtn(icon: Icons.chevron_right, enabled: cur < total, onTap: vm.nextPage, res: res),
        ],
      ),
    );
  }

  Widget _pgNumBtn(int page, bool active, VoidCallback onTap, Responsive res) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: res.spacing(32), height: res.spacing(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.brandAccent : AppColors.background,
          border: Border.all(
              color: active ? AppColors.brandAccent : AppColors.surfaceBright),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('$page',
            style: GoogleFonts.jetBrainsMono(
              color: active ? Colors.black : AppColors.textPrimary,
              fontSize: res.fontSize(12),
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }

  Widget _pgBtn({required IconData icon, required bool enabled,
      required VoidCallback onTap, required Responsive res}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: res.spacing(32), height: res.spacing(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.surfaceBright),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.3,
          child: Icon(icon, size: res.fontSize(16), color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sticky-header list — header stays pinned while rows scroll
// ─────────────────────────────────────────────────────────────────────────────
class _StickyTable extends StatelessWidget {
  final ScrollController controller;
  final Widget header;
  final int itemCount;
  final Widget Function(int index) itemBuilder;

  const _StickyTable({
    required this.controller,
    required this.header,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Sticky header
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                Container(height: 0.5, color: AppColors.surfaceBright),
              ],
            ),
            height: 44.5,
          ),
        ),
        // Data rows
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => itemBuilder(i),
            childCount: itemCount,
          ),
        ),
      ],
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  const _StickyHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(color: Colors.transparent, child: child);
  }

  @override double get maxExtent => height;
  @override double get minExtent => height;
  @override bool shouldRebuild(_StickyHeaderDelegate old) =>
      old.child != child || old.height != height;
}
