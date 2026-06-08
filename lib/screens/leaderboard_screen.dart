import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyperscreener/widgets/error_state_widget.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../utils/common_widgets.dart';
import '../viewmodels/leaderboard_viewmodel.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  /// Linked scroll controllers so both list-views scroll in sync vertically.
  late final ScrollController _leftScroll;
  late final ScrollController _rightScroll;
  bool _syncingLeft  = false;
  bool _syncingRight = false;

  @override
  void initState() {
    super.initState();
    _leftScroll  = ScrollController();
    _rightScroll = ScrollController();

    _leftScroll.addListener(() {
      if (_syncingRight) return;
      _syncingLeft = true;
      if (_rightScroll.hasClients) {
        _rightScroll.jumpTo(_leftScroll.offset);
      }
      _syncingLeft = false;
    });

    _rightScroll.addListener(() {
      if (_syncingLeft) return;
      _syncingRight = true;
      if (_leftScroll.hasClients) {
        _leftScroll.jumpTo(_rightScroll.offset);
      }
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
                  _buildSearchBar(vm, res),
                  _buildFilters(vm, res),
                  const SizedBox(height: 4),
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

  // ── Top bar ──────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, LeaderboardViewModel vm, Responsive res) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
          Text(
            'Top Traders',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (vm.topTraders.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              '${vm.totalPages * vm.rowsPerPage} total',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.brandAccent,
                fontSize: 11,
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 18),
            onPressed: () => vm.fetchAllData(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // ── Search bar (matches home screen style) ────────────────────────────────
  Widget _buildSearchBar(LeaderboardViewModel vm, Responsive res) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
                onChanged: (v) {
                  vm.setSearchQuery(v);
                  setState(() {});
                },
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textPrimary,
                  fontSize: res.fontSize(14),
                ),
                decoration: InputDecoration(
                  hintText: 'Search address or name...',
                  hintStyle: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: res.fontSize(14),
                  ),
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

  // ── Period filter chips (matches home screen tab style) ───────────────────
  Widget _buildFilters(LeaderboardViewModel vm, Responsive res) {
    const periods = [
      ('allTime', 'ALL'),
      ('day', '24H'),
      ('week', '7D'),
      ('month', '30D'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
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
              final selected = vm.selectedPeriod == p.$1;
              return GestureDetector(
                onTap: () => vm.setPeriod(p.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.surfaceBright : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.$2,
                    style: GoogleFonts.jetBrainsMono(
                      color: selected ? AppColors.brandAccent : AppColors.textSecondary,
                      fontSize: res.fontSize(12),
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody(Responsive res, LeaderboardViewModel vm) {
    if (vm.isLoading && vm.topTraders.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brandAccent));
    }
    if (vm.error != null && vm.topTraders.isEmpty) {
      return ErrorStateWidget(errorMessage: vm.error!, onRetry: () => vm.fetchAllData());
    }
    if (vm.topTraders.isEmpty) {
      return Center(
        child: Text('No traders found',
            style: GoogleFonts.jetBrainsMono(color: Colors.white24)),
      );
    }
    return _buildTable(res, vm);
  }

  // ── Table: fixed left + scrollable right, both synchronized ──────────────
  Widget _buildTable(Responsive res, LeaderboardViewModel vm) {
    final double leftW  = res.isMobile ? 190.0 : 220.0;
    const double wAccVal = 120.0;
    const double wPnl    = 120.0;
    const double wRoi    = 100.0;
    const double wVol    = 110.0;
    const double scrollW = wAccVal + wPnl + wRoi + wVol + 8;
    const double rowH    = 56.0;
    const double headerH = 48.0;

    final traders = vm.topTraders;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Fixed left section ───────────────────────────────────────────────
        SizedBox(
          width: leftW,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Container(
                height: headerH,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    Expanded(
                      child: Text('Trader',
                          style: GoogleFonts.jetBrainsMono(
                              color: AppColors.textSecondary,
                              fontSize: res.fontSize(11))),
                    ),
                  ],
                ),
              ),
              // Divider below header
              Container(height: 0.5, color: AppColors.surfaceBright),
              // Data rows
              Expanded(
                child: ListView.builder(
                  controller: _leftScroll,
                  physics: const BouncingScrollPhysics(),
                  itemCount: traders.length,
                  itemBuilder: (context, i) {
                    final rank = i + 1 + (vm.currentPage - 1) * vm.rowsPerPage;
                    final t    = traders[i];
                    final addr = t.ethAddress;
                    final name = t.displayName.isNotEmpty
                        ? t.displayName
                        : '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';

                    return Container(
                      height: rowH,
                      padding: const EdgeInsets.only(left: 8, right: 4, top: 10, bottom: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              '$rank',
                              style: GoogleFonts.jetBrainsMono(
                                color: rank <= 3 ? AppColors.brandAccent : AppColors.textSecondary,
                                fontSize: res.fontSize(10),
                                fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: AppColors.textPrimary,
                                    fontSize: res.fontSize(11),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${addr.substring(0, 8)}...',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: AppColors.textSecondary,
                                    fontSize: res.fontSize(8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Vertical divider
        Container(width: 0.5, color: AppColors.surfaceBright),

        // ── Scrollable right section ─────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: scrollW,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    height: headerH,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Row(
                      children: [
                        _hCell('ACCOUNT VALUE', width: wAccVal, res: res),
                        _hCell('PNL',           width: wPnl,    res: res),
                        _hCell('ROI',           width: wRoi,    res: res),
                        _hCell('VOLUME',        width: wVol,    res: res),
                      ],
                    ),
                  ),
                  // Divider below header
                  Container(height: 0.5, color: AppColors.surfaceBright),
                  // Data rows — uses ListView.builder to prevent overflow
                  Expanded(
                    child: ListView.builder(
                      controller: _rightScroll,
                      physics: const BouncingScrollPhysics(),
                      itemCount: traders.length,
                      itemBuilder: (context, i) {
                        final t = traders[i];
                        return Container(
                          height: rowH,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              _dCell(
                                _fmt(t.accountValue, isCurrency: true),
                                width: wAccVal, res: res,
                              ),
                              _dCell(
                                _fmt(t.pnl, isCurrency: true),
                                width: wPnl, res: res,
                                color: t.pnl >= 0 ? AppColors.trendGreen : AppColors.trendRed,
                              ),
                              _dCell(
                                _fmt(t.roi, isPct: true),
                                width: wRoi, res: res,
                                color: t.roi >= 0 ? AppColors.trendGreen : AppColors.trendRed,
                              ),
                              _dCell(
                                _fmt(t.volume, isCurrency: true),
                                width: wVol, res: res,
                              ),
                            ],
                          ),
                        );
                      },
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

  Widget _hCell(String label, {required double width, required Responsive res}) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: res.fontSize(11),
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _dCell(String text, {required double width, required Responsive res, Color? color}) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.jetBrainsMono(
            color: color ?? AppColors.textPrimary,
            fontSize: res.fontSize(11),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Pagination ─────────────────────────────────────────────────────────────
  Widget _buildPagination(LeaderboardViewModel vm, Responsive res) {
    if (vm.totalPages <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(icon: Icons.chevron_left,  enabled: vm.currentPage > 1,              onTap: vm.previousPage, res: res),
          const SizedBox(width: 12),
          Text(
            'Page ${vm.currentPage} of ${vm.totalPages}',
            style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)),
          ),
          const SizedBox(width: 12),
          _pageBtn(icon: Icons.chevron_right, enabled: vm.currentPage < vm.totalPages, onTap: vm.nextPage, res: res),
        ],
      ),
    );
  }

  Widget _pageBtn({required IconData icon, required bool enabled, required VoidCallback onTap, required Responsive res}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: res.spacing(32),
        height: res.spacing(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.surfaceBright),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Icon(icon, size: res.fontSize(16), color: enabled ? AppColors.textPrimary : AppColors.textSecondary),
        ),
      ),
    );
  }
}
