import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyper/screens/subscription_screen.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_colors.dart';
import '../utils/common_widgets.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/subscription_viewmodel.dart';
import '../models/ticker_model.dart';
import '../widgets/coming_soon_dialog.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/sparkline_widget.dart';
import '../widgets/ticker_detail_dialog.dart';
import '../widgets/funding_legend_dialog.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/responsive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ScrollController _tabScrollController = ScrollController();
  
  void _showTickerDetail(TickerModel ticker) {
    showDialog(
      context: context,
      builder: (context) => TickerDetailDialog(ticker: ticker),
    );
  }

  String _formatVolume(double value) {
    if (value >= 1e9) {
      return '\$${(value / 1e9).toStringAsFixed(1)}B';
    } else if (value >= 1e6) {
      return '\$${(value / 1e6).toStringAsFixed(1)}M';
    } else if (value >= 1e3) {
      return '\$${(value / 1e3).toStringAsFixed(1)}K';
    } else {
      return '\$${value.toStringAsFixed(0)}';
    }
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
          leading: const Icon(Icons.menu, color: AppColors.brandAccent),
          title: Text(
            'HYPERVIEW',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: res.fontSize(18),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          actions: [
            Consumer<SubscriptionViewModel>(
              builder: (context, sub, _) => IconButton(
                icon: Icon(
                  sub.isPro ? Icons.verified : Icons.workspace_premium, 
                  color: sub.isPro ? AppColors.trendGreen : AppColors.brandAccent
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SubscriptionScreen())
                ),
                tooltip: sub.isPro ? 'Pro Active' : 'Go Pro',
              ),
            ),
            const Icon(Icons.sensors, color: AppColors.brandAccent),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => showDialog(context: context, builder: (context) => const ComingSoonDialog(featureName: 'Wallet Connection')),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: res.spacing(12), vertical: 6),
                margin: EdgeInsets.only(right: 16, top: res.spacing(12), bottom: res.spacing(12)),
                decoration: BoxDecoration(
                  color: AppColors.brandAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.brandAccent, width: 1),
                ),
                child: Center(
                  child: Text(
                    'CONNECT',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.brandAccent,
                      fontSize: res.fontSize(12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Consumer<HomeViewModel>(
          builder: (context, viewModel, child) {
            return RefreshIndicator(
              onRefresh: viewModel.fetchTickers,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(res.spacing(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leaderboard',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textPrimary,
                          fontSize: res.fontSize(20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: res.spacing(16)),
                      
                      // Search Bar
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: res.spacing(12)),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          border: Border.all(color: AppColors.surfaceBright),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: AppColors.textSecondary, size: res.fontSize(20)),
                            SizedBox(width: res.spacing(8)),
                            Expanded(
                              child: TextField(
                                onChanged: viewModel.setSearchQuery,
                                style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: res.fontSize(14)),
                                decoration: InputDecoration(
                                  hintText: 'Search by symbol...',
                                  hintStyle: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(14)),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: res.spacing(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: res.spacing(12)),
                      
                      // Tabs
                      Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.surfaceBright),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          controller: _tabScrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTab(viewModel, 'ALL', res),
                              _buildTab(viewModel, 'PERPS', res),
                              _buildTab(viewModel, 'SPOT', res),
                              _buildTab(viewModel, 'CRYPTO', res),
                              _buildTab(viewModel, 'HIP-3', res),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: res.spacing(12)),

                      if (viewModel.isLoading)
                        _buildShimmerSkeleton(res)
                      else if (viewModel.errorMessage.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: res.spacing(40)),
                          child: ErrorStateWidget(
                            errorMessage: viewModel.errorMessage,
                            onRetry: () => viewModel.fetchTickers(),
                          ),
                        )
                      else ...[
                        // Horizontal Filters Row
                        if (viewModel.selectedTab == 'HIP-3' || viewModel.selectedTab == 'CRYPTO')
                          SizedBox(
                            height: 32,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: (viewModel.selectedTab == 'CRYPTO' || viewModel.selectedTab == 'HIP' ? viewModel.cryptoCategories : viewModel.availableDexes).length,
                              separatorBuilder: (context, index) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final isCategoryMode = viewModel.selectedTab == 'CRYPTO' || viewModel.selectedTab == 'HIP';
                                final items = isCategoryMode ? viewModel.cryptoCategories : viewModel.availableDexes;
                                final item = items[index];
                                final isSelected = isCategoryMode 
                                  ? viewModel.selectedCryptoCategory == item 
                                  : viewModel.selectedDex == item;
                                
                                return GestureDetector(
                                  onTap: () {
                                    if (isCategoryMode) {
                                      viewModel.setSelectedCryptoCategory(item);
                                    } else {
                                      viewModel.setSelectedDex(item);
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: res.spacing(12)),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.brandAccent.withValues(alpha: 0.1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isSelected ? AppColors.brandAccent : AppColors.surfaceBright,
                                        width: isSelected ? 1 : 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      item == 'All' ? 'All' : item.toLowerCase(),
                                      style: GoogleFonts.jetBrainsMono(
                                        color: isSelected ? AppColors.brandAccent : AppColors.textSecondary,
                                        fontSize: res.fontSize(12),
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        SizedBox(height: res.spacing(16)),
                        
                        // Extra Filters (USDC, TOTAL)
                        Row(
                          children: [
                            const Spacer(),
                            Text('USDC', style: TextStyle(color: AppColors.textSecondary, fontSize: res.fontSize(12))),
                            SizedBox(width: res.spacing(12)),
                            GestureDetector(
                              onTap: () => showDialog(context: context, builder: (context) => const ComingSoonDialog(featureName: 'TOTAL Filter')),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: res.spacing(12), vertical: res.spacing(6)),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.brandAccent),
                                  borderRadius: BorderRadius.circular(4),
                                  color: AppColors.brandAccent.withValues(alpha: 0.1),
                                ),
                                child: Text('TOTAL', style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: res.fontSize(12))),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: res.spacing(16)),
                        
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fixed Left Column (Symbol)
                            SizedBox(
                              width: res.columnWidth(150),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row for Fixed Part
                                  Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                    child: Row(
                                      children: [
                                        SizedBox(width: res.columnWidth(30), child: Text('#', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)))),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text('Symbol', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)))),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: res.spacing(8)),
                                  // Data Rows
                                  ...viewModel.paginatedTickers.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final ticker = entry.value;
                                    final rank = (viewModel.currentPage - 1) * viewModel.rowsPerPage + (index + 1);
                                    
                                    return GestureDetector(
                                      onTap: () => _showTickerDetail(ticker),
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                      height: 56,
                                      padding: const EdgeInsets.only(left: 8.0, right: 4.0, top: 12.0, bottom: 12.0),
                                      decoration: const BoxDecoration(
                                        border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: res.columnWidth(30), 
                                            child: Text(rank.toString(), style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(10)))
                                          ),
                                          const SizedBox(width: 4),
                                          SizedBox(
                                            width: 20, height: 20,
                                            child: _buildTickerIcon(ticker.iconUrl, 20),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  ticker.displayName.split(':').last,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: res.fontSize(11), fontWeight: FontWeight.bold),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.brandAccent.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                  child: Text(
                                                    viewModel.selectedTab == 'CRYPTO' ? ticker.cryptoCategory.toUpperCase() : ticker.dex.toUpperCase(), 
                                                    style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: 8)
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            // Scrollable Right Section
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header
                                    Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                      child: Row(
                                        children: [
                                          SizedBox(width: res.columnWidth(110), child: Text('Price', textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)))),
                                            SizedBox(width: res.columnWidth(110), child: Text('24h Change', textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)))),
                                            SizedBox(
                                              width: res.columnWidth(100),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text('8h Funding', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11))),
                                                  const SizedBox(width: 4),
                                                  GestureDetector(
                                                    onTap: () => showDialog(
                                                      context: context,
                                                      builder: (context) => const FundingLegendDialog(),
                                                    ),
                                                    child: Icon(Icons.info_outline, size: 12, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          SizedBox(width: res.columnWidth(100), child: Text('VOLUME (24H)', textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)))),
                                          SizedBox(width: res.columnWidth(120), child: Text('Open Interest', textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)))),
                                          SizedBox(width: res.columnWidth(60), child: Text('TRENDS', textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)))),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: res.spacing(8)),
                                    // Data Rows
                                    ...viewModel.paginatedTickers.map((ticker) {
                                      final changeColor = ticker.change24hPct >= 0 ? AppColors.trendGreen : AppColors.trendRed;
                                      final formattedChange = '${ticker.change24hPct >= 0 ? '+' : ''}${ticker.change24hPct.toStringAsFixed(2)}%';
                                      final formattedFunding = '${ticker.funding8hPct.toStringAsFixed(4)}%';
                                      final formattedOI = '\$${(ticker.openInterestUSD / 1e6).toStringAsFixed(1)}M';

                                      return GestureDetector(
                                        onTap: () => _showTickerDetail(ticker),
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                        height: 56,
                                        width: res.columnWidth(616),
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                                        decoration: const BoxDecoration(
                                          border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(width: res.columnWidth(110), child: Text(ticker.lastPrice.toStringAsFixed(4), textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: res.fontSize(11), fontWeight: FontWeight.bold))),
                                            SizedBox(width: res.columnWidth(110), child: Text(formattedChange, textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: changeColor, fontSize: res.fontSize(11)))),
                                            SizedBox(width: res.columnWidth(100), child: Text(formattedFunding, textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: ticker.funding8hPct >= 0 ? AppColors.trendGreen : AppColors.trendRed, fontSize: res.fontSize(11)))),
                                            SizedBox(width: res.columnWidth(100), child: Text(_formatVolume(ticker.volume24hUSD), textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: res.fontSize(11)))),
                                            SizedBox(width: res.columnWidth(120), child: Text(formattedOI, textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: res.fontSize(11)))),
                                            SizedBox(
                                              width: res.columnWidth(60), 
                                              child: Center(
                                                child: SparklineWidget(
                                                  color: changeColor,
                                                  width: res.columnWidth(45),
                                                  height: 24,
                                                  seed: ticker.symbol,
                                                  changePct: ticker.change24hPct,
                                                ),
                                              )
                                            ),
                                          ],
                                        ),
                                      ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: res.spacing(32)),

                        // Pagination Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Rows:', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(12))),
                            const SizedBox(width: 8),
                            Theme(
                              data: Theme.of(context).copyWith(canvasColor: AppColors.background),
                              child: Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  border: Border.all(color: AppColors.surfaceBright),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    dropdownColor: AppColors.background,
                                    value: viewModel.rowsPerPage,
                                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 16),
                                    style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: res.fontSize(12)),
                                    borderRadius: BorderRadius.circular(8),
                                    elevation: 8,
                                    onChanged: (val) => val != null ? viewModel.setRowsPerPage(val) : null,
                                    items: [10, 20, 50, 100].map((v) => DropdownMenuItem(value: v, child: Text(v.toString()))).toList(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _buildPageButton(res, icon: Icons.chevron_left, isEnabled: viewModel.currentPage > 1, isActive: false, onTap: () => viewModel.previousPage()),
                            const SizedBox(width: 8),
                            ...() {
                              final totalPages = (viewModel.totalFilteredCount / viewModel.rowsPerPage).ceil();
                              if (totalPages <= 1) return [_buildPageButton(res, text: '1', isActive: true, onTap: () {})];
                              List<Widget> buttons = [];
                              int start = (viewModel.currentPage - 1).clamp(1, totalPages);
                              int end = (start + 2).clamp(1, totalPages);
                              if (end == totalPages && totalPages > 3) start = end - 2;
                              for (int i = start; i <= end; i++) {
                                buttons.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _buildPageButton(res, text: i.toString(), isActive: i == viewModel.currentPage, onTap: () => viewModel.setPage(i))));
                              }
                              return buttons;
                            }(),
                            const SizedBox(width: 8),
                            _buildPageButton(res, icon: Icons.chevron_right, isEnabled: (viewModel.currentPage * viewModel.rowsPerPage < viewModel.totalFilteredCount), isActive: false, onTap: () => viewModel.nextPage()),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: AppColors.background.withValues(alpha: 0.85),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.brandAccent,
          unselectedItemColor: AppColors.textSecondary,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Markets'),
            BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Trade'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Portfolio'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
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
                return Center(child: CircularProgressIndicator(strokeWidth: 1, valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandAccent.withValues(alpha: 0.3))));
              },
            ),
      ),
    );
  }

  Widget _buildTab(HomeViewModel viewModel, String title, Responsive res) {
    bool isActive = viewModel.selectedTab == title;
    return GestureDetector(
      onTap: () => viewModel.setTab(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: res.spacing(20)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceBright : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: GoogleFonts.jetBrainsMono(
            color: isActive ? AppColors.brandAccent : AppColors.textSecondary,
            fontSize: res.fontSize(12),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton(Responsive res, {String? text, IconData? icon, VoidCallback? onTap, required bool isActive, bool isEnabled = true}) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: res.spacing(32),
        height: res.spacing(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandAccent : AppColors.background,
          border: Border.all(color: isActive ? AppColors.brandAccent : AppColors.surfaceBright),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.4,
          child: text != null 
            ? Text(text, style: GoogleFonts.jetBrainsMono(color: isActive ? Colors.black : AppColors.textPrimary, fontSize: res.fontSize(12), fontWeight: isActive ? FontWeight.bold : FontWeight.normal))
            : Icon(icon, size: res.fontSize(16), color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildShimmerSkeleton(Responsive res) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: res.spacing(8)),
        child: Shimmer.fromColors(
          baseColor: const Color(0xFF1E222D),
          highlightColor: const Color(0xFF3A3F4E),
          period: const Duration(milliseconds: 1500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(10, (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  _skeletonPill(res.columnWidth(150), 12), // Column 1 (Icon + Name)
                  const SizedBox(width: 24),
                  _skeletonPill(res.columnWidth(110), 12), // Price
                  const SizedBox(width: 8),
                  _skeletonPill(res.columnWidth(110), 12), // Change
                  const SizedBox(width: 8),
                  _skeletonPill(res.columnWidth(100), 12), // Funding
                  const SizedBox(width: 8),
                  _skeletonPill(res.columnWidth(100), 12), // Volume
                  const SizedBox(width: 8),
                  _skeletonPill(res.columnWidth(120), 12), // OI
                  const SizedBox(width: 8),
                  _skeletonPill(res.columnWidth(60), 12),  // Trend
                ],
              ),
            )),
          ),
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
