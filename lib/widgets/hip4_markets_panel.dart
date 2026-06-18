import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../viewmodels/hip4_viewmodel.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import 'hip4_market_row.dart';

class Hip4MarketsPanel extends StatefulWidget {
  const Hip4MarketsPanel({super.key});

  @override
  State<Hip4MarketsPanel> createState() => _Hip4MarketsPanelState();
}

class _Hip4MarketsPanelState extends State<Hip4MarketsPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<Hip4ViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    final viewModel = context.watch<Hip4ViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table with Horizontal Scroll
        SizedBox(
          width: res.width,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: res.isMobile ? 800 : (res.width < 1000 ? 1000 : res.width - 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Header
                  _buildTableHeader(res, viewModel),
                  
                  // Markets List
                  if (viewModel.isLoading && viewModel.markets.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.brandAccent)))
                  else if (viewModel.errorMessage.isNotEmpty && viewModel.markets.isEmpty)
                    _buildErrorState(viewModel)
                  else if (viewModel.filteredMarkets.isEmpty)
                    _buildEmptyState()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: viewModel.filteredMarkets.length,
                      separatorBuilder: (context, index) => const Divider(color: AppColors.surfaceBright, height: 1),
                      itemBuilder: (context, index) {
                        return Hip4MarketRow(market: viewModel.filteredMarkets[index], index: index);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(Responsive res, Hip4ViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceBright)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 28),          // # rank
          const SizedBox(width: 12),          // gap
          Expanded(flex: 3, child: Text('MARKET', style: _headerStyle(res))),
          const SizedBox(width: 20),
          SizedBox(width: 100, child: Center(child: _sortHeader('CLASS', 'class', res, vm))),
          const SizedBox(width: 20),
          Expanded(flex: 6, child: _sortHeader('PROBABILITY', 'probability', res, vm)),
          const SizedBox(width: 20),
          SizedBox(width: 150, child: Align(alignment: Alignment.centerRight, child: _sortHeader('EXPIRY', 'expiry', res, vm))),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _sortHeader(String label, String key, Responsive res, Hip4ViewModel vm) {
    final active = vm.sortColumn == key;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => vm.setSort(key),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: _headerStyle(res).copyWith(
            color: active ? AppColors.brandAccent : AppColors.textSecondary.withValues(alpha: 0.6),
          )),
          const SizedBox(width: 3),
          Icon(
            active
                ? (vm.sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.unfold_more,
            size: 14,
            color: active ? AppColors.brandAccent : AppColors.textSecondary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle(Responsive res) => GoogleFonts.jetBrainsMono(
    color: AppColors.textSecondary.withValues(alpha: 0.6),
    fontSize: res.fontSize(9),
    fontWeight: FontWeight.bold,
  );

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Text(
          'No prediction markets found matches your criteria.',
          style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildErrorState(Hip4ViewModel viewModel) {
    return Center(
      child: Column(
        children: [
          Text(viewModel.errorMessage, style: GoogleFonts.jetBrainsMono(color: AppColors.trendRed)),
          TextButton(onPressed: () => viewModel.fetchMarkets(), child: const Text('Retry')),
        ],
      ),
    );
  }
}
