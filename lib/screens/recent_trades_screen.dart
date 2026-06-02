import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import '../viewmodels/trades_viewmodel.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../models/trade_model.dart';

class RecentTradesScreen extends StatefulWidget {
  final String symbol;
  final String? dex;
  final String? iconUrl;

  const RecentTradesScreen({super.key, required this.symbol, this.dex, this.iconUrl});

  @override
  State<RecentTradesScreen> createState() => _RecentTradesScreenState();
}

class _RecentTradesScreenState extends State<RecentTradesScreen> {
  late TradesViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TradesViewModel(symbol: widget.symbol, dex: widget.dex);
    _viewModel.startUpdates();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: const Color(0xFF161A22),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              _buildTickerIcon(widget.iconUrl ?? '', 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.symbol,
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textPrimary,
                      fontSize: res.fontSize(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'RECENT TRADES',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.brandAccent,
                      fontSize: res.fontSize(9),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _LiveIndicator(res: res),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: AppColors.surfaceBright.withValues(alpha: 0.5)),
          ),
        ),
        body: Consumer<TradesViewModel>(
          builder: (context, vm, child) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: (vm.trades.isEmpty)
                  ? _buildShimmerSkeleton(res)
                  : Padding(
                      key: const ValueKey('trades_content'),
                      padding: EdgeInsets.all(res.spacing(16)),
                      child: Column(
                        children: [
                          _buildStats(vm, res),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF161A22),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.surfaceBright
                                        .withValues(alpha: 0.5)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildTradesTable(vm, res),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerSkeleton(Responsive res) {
    return Padding(
      key: const ValueKey('shimmer_skeleton'),
      padding: EdgeInsets.all(res.spacing(16)),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF1E222D),
        highlightColor: const Color(0xFF3A3F4E), // Brighter for better visibility
        period: const Duration(milliseconds: 1500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Mock
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      color: Colors.black, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonPill(100, 12),
                    const SizedBox(height: 6),
                    _skeletonPill(60, 8),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Stats Skeleton
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(res.spacing(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _skeletonPill(40, 8),
                        const SizedBox(height: 10),
                        _skeletonPill(60, 16),
                      ],
                    ),
                    _skeletonPill(80, 20),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _skeletonPill(40, 8),
                        const SizedBox(height: 10),
                        _skeletonPill(60, 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Table Header Mock
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (i) => _skeletonPill(40, 12)),
            ),
            const SizedBox(height: 12),
            // Table Rows Skeleton
            Expanded(
              child: Column(
                children: List.generate(
                    8,
                    (index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Center(child: _skeletonPill(50, 10))),
                              Expanded(child: Center(child: _skeletonPill(30, 10))),
                              Expanded(child: Center(child: _skeletonPill(60, 10))),
                              Expanded(child: Center(child: _skeletonPill(40, 10))),
                              Expanded(child: Center(child: _skeletonPill(50, 10))),
                            ],
                          ),
                        )),
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

  Widget _buildStats(TradesViewModel vm, Responsive res) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161A22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBright.withValues(alpha: 0.5)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: res.spacing(16),
        vertical: res.spacing(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatBlock(
            label: 'LAST PRICE',
            value: '\$${vm.lastPrice.toStringAsFixed(2)}',
            valueColor: AppColors.textPrimary,
            res: res,
          ),
          _BuySellRatio(
            buyPct: vm.buyPercentage,
            sellPct: vm.sellPercentage,
            res: res,
          ),
          _StatBlock(
            label: 'VWAP',
            value: '\$${vm.vwap.toStringAsFixed(2)}',
            valueColor: AppColors.brandAccent,
            res: res,
            crossAxisAlignment: CrossAxisAlignment.end,
          ),
        ],
      ),
    );
  }

  Widget _buildTradesTable(TradesViewModel vm, Responsive res) {
    if (vm.trades.isEmpty && !vm.isLoading) {
      return Center(
        child: Text(
          'No recent trades found for ${widget.symbol}',
          style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        // Table Header
        _buildTableHeader(res),
        // Scrollable Body
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: vm.paginatedTrades.length,
            itemBuilder: (context, index) {
              return _buildTradeRow(
                  vm.paginatedTrades[index], res, index % 2 != 0);
            },
          ),
        ),
        // Pagination Footer
        _buildPaginationControls(vm, res),
      ],
    );
  }

  Widget _buildTableHeader(Responsive res) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        border: Border(
            bottom: BorderSide(
                color: AppColors.surfaceBright.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(child: Center(child: Text('TIME', style: _headerStyle(res)))),
          Expanded(child: Center(child: Text('DIR', style: _headerStyle(res)))),
          Expanded(child: Center(child: Text('PRICE', style: _headerStyle(res)))),
          Expanded(child: Center(child: Text('SIZE', style: _headerStyle(res)))),
          Expanded(child: Center(child: Text('VALUE', style: _headerStyle(res)))),
        ],
      ),
    );
  }

  Widget _buildTradeRow(Trade trade, Responsive res, bool isEven) {
    final color = trade.isBuy ? AppColors.trendGreen : AppColors.trendRed;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color:
            isEven ? Colors.white.withValues(alpha: 0.015) : Colors.transparent,
        border: Border(
            bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.03), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
              child: Center(
                  child: Text(trade.timeFormatted,
                      style: _rowStyle(res, color: AppColors.textSecondary)))),
          Expanded(
              child: Center(
                  child: Text(trade.direction,
                      style: _rowStyle(res, color: color, bold: true)))),
          Expanded(
            child: Center(
              child: Text(
                '\$${trade.price.toStringAsFixed(2)}',
                style: _rowStyle(res, color: color, bold: true),
              ),
            ),
          ),
          Expanded(
              child: Center(
                  child: Text(trade.size.toStringAsFixed(4),
                      style: _rowStyle(res)))),
          Expanded(
              child: Center(
                  child: Text('\$${trade.value.toStringAsFixed(2)}',
                      style: _rowStyle(res,
                          color: AppColors.textPrimary.withValues(alpha: 0.8))))),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(TradesViewModel vm, Responsive res) {
    final totalPages = (vm.totalTrades / vm.rowsPerPage).ceil();

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        border: Border(top: BorderSide(color: AppColors.surfaceBright.withValues(alpha: 0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Rows:', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(10))),
          const SizedBox(width: 8),
          _buildRowsDropdown(vm, res),
          const SizedBox(width: 16),
          _buildPageButton(res, icon: Icons.chevron_left, isEnabled: vm.currentPage > 1, isActive: false, onTap: () => vm.setPage(vm.currentPage - 1)),
          const SizedBox(width: 8),
          ...() {
            if (totalPages <= 1) return [_buildPageButton(res, text: '1', isActive: true, onTap: () {})];
            List<Widget> buttons = [];
            int start = (vm.currentPage - 1).clamp(1, totalPages);
            int end = (start + 2).clamp(1, totalPages);
            if (end == totalPages && totalPages > 3) start = end - 2;
            for (int i = start; i <= end; i++) {
              buttons.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _buildPageButton(res, text: i.toString(), isActive: i == vm.currentPage, onTap: () => vm.setPage(i))));
            }
            return buttons;
          }(),
          const SizedBox(width: 8),
          _buildPageButton(res, icon: Icons.chevron_right, isEnabled: (vm.currentPage < totalPages), isActive: false, onTap: () => vm.setPage(vm.currentPage + 1)),
        ],
      ),
    );
  }

  Widget _buildRowsDropdown(TradesViewModel vm, Responsive res) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.surfaceBright),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          dropdownColor: const Color(0xFF1E222D),
          value: vm.rowsPerPage,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 14),
          style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: res.fontSize(10)),
          onChanged: (val) => val != null ? vm.setRowsPerPage(val) : null,
          items: [10, 20, 50].map((v) => DropdownMenuItem(value: v, child: Text(v.toString()))).toList(),
        ),
      ),
    );
  }

  Widget _buildPageButton(Responsive res, {String? text, IconData? icon, VoidCallback? onTap, required bool isActive, bool isEnabled = true}) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: res.spacing(28),
        height: res.spacing(28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandAccent : AppColors.background,
          border: Border.all(color: isActive ? AppColors.brandAccent : AppColors.surfaceBright),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.4,
          child: text != null 
            ? Text(text, style: GoogleFonts.jetBrainsMono(color: isActive ? Colors.black : AppColors.textPrimary, fontSize: res.fontSize(10), fontWeight: isActive ? FontWeight.bold : FontWeight.normal))
            : Icon(icon, size: res.fontSize(14), color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary),
        ),
      ),
    );
  }

  TextStyle _headerStyle(Responsive res) => GoogleFonts.jetBrainsMono(
    color: AppColors.textSecondary,
    fontSize: res.fontSize(11),
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  TextStyle _rowStyle(Responsive res, {Color color = AppColors.textPrimary, bool bold = false}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: res.fontSize(11),
      color: color,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
  }

  Widget _buildTickerIcon(String iconUrl, double size) {
    if (iconUrl.isEmpty) {
      return Icon(Icons.star_border, size: size, color: AppColors.textSecondary);
    }

    final bool isSvg = iconUrl.toLowerCase().contains('.svg');

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.surfaceBright,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: isSvg
            ? SvgPicture.network(
                iconUrl,
                fit: BoxFit.cover,
                placeholderBuilder: (context) => Icon(Icons.star_border, size: size * 0.7, color: AppColors.textSecondary),
                errorBuilder: (context, error, stackTrace) => Icon(Icons.star_border, size: size * 0.7, color: AppColors.textSecondary),
              )
            : Image.network(
                iconUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.star_border, size: size * 0.7, color: AppColors.textSecondary),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 1, valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandAccent.withValues(alpha: 0.3))));
                },
              ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Responsive res;
  final CrossAxisAlignment crossAxisAlignment;

  const _StatBlock({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.res,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: res.fontSize(9),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: valueColor,
            fontSize: res.fontSize(18),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _BuySellRatio extends StatelessWidget {
  final double buyPct;
  final double sellPct;
  final Responsive res;

  const _BuySellRatio({required this.buyPct, required this.sellPct, required this.res});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: res.value(mobile: 100.0, tablet: 150.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${buyPct.toStringAsFixed(0)}%', style: _pctStyle(AppColors.trendGreen)),
              Text('${sellPct.toStringAsFixed(0)}%', style: _pctStyle(AppColors.trendRed)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 5,
              child: Row(
                children: [
                  Expanded(flex: buyPct.round(), child: Container(color: AppColors.trendGreen)),
                  Expanded(flex: sellPct.round(), child: Container(color: AppColors.trendRed)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'VOL RATIO',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _pctStyle(Color color) => GoogleFonts.jetBrainsMono(
    color: color,
    fontSize: 9,
    fontWeight: FontWeight.bold,
  );
}

class _LiveIndicator extends StatelessWidget {
  final Responsive res;
  const _LiveIndicator({required this.res});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.trendGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.trendGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(color: AppColors.trendGreen, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.trendGreen,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
