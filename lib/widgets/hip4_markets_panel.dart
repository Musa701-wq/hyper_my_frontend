import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../viewmodels/hip4_viewmodel.dart';
import '../models/hip4_model.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import 'hip4_probability_bar.dart';
import 'hip4_detail_dialog.dart';
import 'hip4_market_row.dart';

class Hip4MarketsPanel extends StatefulWidget {
  const Hip4MarketsPanel({super.key});

  @override
  State<Hip4MarketsPanel> createState() => _Hip4MarketsPanelState();
}

class _Hip4MarketsPanelState extends State<Hip4MarketsPanel> {
  // One shared horizontal offset — all rows scroll together
  final _hScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<Hip4ViewModel>().init();
    });
  }

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    final vm  = context.watch<Hip4ViewModel>();

    if (vm.isLoading && vm.markets.isEmpty) {
      return _buildShimmer();
    }
    if (vm.errorMessage.isNotEmpty && vm.markets.isEmpty) {
      return Center(
          child: Column(children: [
        Text(vm.errorMessage,
            style: GoogleFonts.jetBrainsMono(color: AppColors.trendRed)),
        TextButton(
            onPressed: () => vm.fetchMarkets(), child: const Text('Retry')),
      ]));
    }
    if (vm.filteredMarkets.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text('No prediction markets found.',
                  style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary))));
    }

    final markets     = vm.filteredMarkets;
    final screenW     = MediaQuery.of(context).size.width;
    final leftWidth   = (screenW * 0.42).clamp(140.0, 185.0);
    final probWidth   = res.columnWidth(180);
    final expiryWidth = res.columnWidth(130);
    final rightContentW = probWidth + 16 + expiryWidth + 24 + 16; // +chevron area

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──────────────────────────────────────────────
        Container(
          height: 48,
          decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.surfaceBright))),
          child: Row(
            children: [
              // Left header (fixed)
              SizedBox(
                width: leftWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(children: [
                    SizedBox(
                      width: 24,
                      child: Text('#',
                          style: GoogleFonts.jetBrainsMono(
                              color: AppColors.textSecondary,
                              fontSize: res.fontSize(11))),
                    ),
                    const SizedBox(width: 4),
                    Text('MARKET',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary.withOpacity(0.6),
                          fontSize: res.fontSize(9),
                          fontWeight: FontWeight.bold,
                        )),
                  ]),
                ),
              ),
              // Right header (scrollable — synced with rows)
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (_) => true, // absorb — driven by row scroll
                  child: SingleChildScrollView(
                    controller: _hScroll,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: rightContentW,
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Row(children: [
                          _sortBtn('PROBABILITY', 'probability', probWidth, res, vm),
                          const SizedBox(width: 16),
                          _sortBtn('EXPIRY', 'expiry', expiryWidth, res, vm,
                              align: MainAxisAlignment.end),
                          const SizedBox(width: 24),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Data rows ───────────────────────────────────────────────
        ...markets.asMap().entries.map((e) => _buildRow(
              context,
              e.value,
              e.key,
              res,
              leftWidth,
              probWidth,
              expiryWidth,
              rightContentW,
            )),
      ],
    );
  }

  Widget _buildShimmer() {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth > 0
          ? constraints.maxWidth
          : MediaQuery.of(context).size.width;
      return Shimmer.fromColors(
        baseColor: const Color(0xFF1E222D),
        highlightColor: const Color(0xFF3A3F4E),
        period: const Duration(milliseconds: 1500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(12, (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                _pill(24, 10),
                const SizedBox(width: 8),
                _pill(20, 20), // icon circle
                const SizedBox(width: 8),
                _pill(w * 0.28, 10),
                const SizedBox(width: 12),
                Expanded(child: _pill(double.infinity, 8)),
                const SizedBox(width: 12),
                _pill(w * 0.20, 9),
              ],
            ),
          )),
        ),
      );
    });
  }

  Widget _pill(double width, double height) => Container(
        width: width == double.infinity ? null : width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );

  // Each row = IntrinsicHeight(Row([left, right]))
  // IntrinsicHeight makes both sides adopt the taller side's height.
  Widget _buildRow(
    BuildContext context,
    Hip4Market market,
    int index,
    Responsive res,
    double leftWidth,
    double probWidth,
    double expiryWidth,
    double rightContentW,
  ) {
    final expiryStr = market.expiry != null
        ? DateFormat('MMM dd, yyyy HH:mm').format(market.expiry!.toLocal())
        : '--';
    final iconSize = res.fontSize(20);

    return GestureDetector(
      onTap: () => showDialog(
          context: context,
          builder: (_) => Hip4DetailDialog(market: market)),
      behavior: HitTestBehavior.opaque,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Fixed left ──────────────────────────────────────────
            SizedBox(
              width: leftWidth,
              child: Container(
                padding: const EdgeInsets.only(
                    left: 8, right: 4, top: 10, bottom: 10),
                decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: AppColors.surfaceBright, width: 0.5))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text('${index + 1}',
                          style: GoogleFonts.jetBrainsMono(
                              color: AppColors.textSecondary,
                              fontSize: res.fontSize(10))),
                    ),
                    const SizedBox(width: 4),
                    Hip4CoinIcon(market: market, size: iconSize),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ..._nameLines(market.name, res),
                          const SizedBox(height: 4),
                          Hip4ClassBadge(
                              marketClass: market.marketClass, res: res),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Scrollable right ────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: _hScroll,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: rightContentW,
                  child: Container(
                    padding: const EdgeInsets.only(
                        left: 4, right: 4, top: 10, bottom: 10),
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: AppColors.surfaceBright, width: 0.5))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: probWidth,
                          child: Hip4ProbabilityBar(
                              outcomes: market.outcomes, height: 8),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: expiryWidth,
                          child: Text(
                            expiryStr,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.textSecondary
                                  .withOpacity(0.7),
                              fontSize: res.fontSize(9),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right,
                            size: 16,
                            color: AppColors.textSecondary
                                .withOpacity(0.4)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortBtn(
    String label,
    String key,
    double width,
    Responsive res,
    Hip4ViewModel vm, {
    MainAxisAlignment align = MainAxisAlignment.start,
  }) {
    final active = vm.sortColumn == key;
    return SizedBox(
      width: width,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => vm.setSort(key),
        child: Row(
          mainAxisAlignment: align,
          children: [
            Text(label,
                style: GoogleFonts.jetBrainsMono(
                  color: active
                      ? AppColors.brandAccent
                      : AppColors.textSecondary.withOpacity(0.6),
                  fontSize: res.fontSize(9),
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(width: 3),
            Icon(
              active
                  ? (vm.sortAscending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward)
                  : Icons.unfold_more,
              size: 12,
              color: active
                  ? AppColors.brandAccent
                  : AppColors.textSecondary.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _nameLines(String name, Responsive res) {
    final style = GoogleFonts.jetBrainsMono(
      color: AppColors.textPrimary,
      fontSize: res.fontSize(11),
      fontWeight: FontWeight.bold,
    );
    final i = name.indexOf(':');
    if (i == -1) return [Text(name, style: style)];
    return [
      Text(name.substring(0, i + 1).trim(), style: style),
      const SizedBox(height: 2),
      Text(name.substring(i + 1).trim(), style: style),
    ];
  }
}
