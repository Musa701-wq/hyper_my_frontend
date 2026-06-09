import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyperscreener/screens/subscription_screen.dart';
import 'package:hyperscreener/screens/leaderboard_screen.dart';
import 'package:hyperscreener/screens/leaderboard_stats_screen.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_colors.dart';
import '../utils/common_widgets.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/subscription_viewmodel.dart';
import '../viewmodels/wallet_viewmodel.dart';
import '../viewmodels/portfolio_viewmodel.dart';
import '../models/ticker_model.dart';
import '../widgets/coming_soon_dialog.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/sparkline_widget.dart';
import '../widgets/ticker_detail_dialog.dart';
import '../widgets/funding_legend_dialog.dart';
import 'profile_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/responsive.dart';
import '../analytics/analytics_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ScrollController _tabScrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Fetch tickers here instead of in main.dart to ensure it happens after permissions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().fetchTickers();
    });
  }
  
  void _showTickerDetail(TickerModel ticker) {
    AnalyticsService.logTickerClick(ticker.symbol);
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
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        drawer: _buildDrawer(context, res),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GestureDetector(
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            child: const Icon(Icons.menu, color: AppColors.brandAccent),
          ),
          title: Text(
            'HyperScreener',
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
                  color: sub.isPro ? AppColors.trendGreen : AppColors.brandAccent,
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                ),
                tooltip: sub.isPro ? 'Pro Active' : 'Go Pro',
              ),
            ),
            GestureDetector(
              onTap: () {
                AnalyticsService.logFeatureClick('Live Signal');
                showDialog(
                  context: context,
                  builder: (context) => const ComingSoonDialog(featureName: 'Live Signal'),
                );
              },
              child: const Icon(Icons.sensors, color: AppColors.brandAccent),
            ),
            const SizedBox(width: 8),
            Consumer<WalletViewModel>(
              builder: (context, wallet, _) {
                final connected = wallet.isConnected;
                return GestureDetector(
                  onTap: () {
                    if (connected) {
                      _showDisconnectDialog(context, wallet);
                    } else {
                      _showConnectDialog(context, wallet);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: res.spacing(10), vertical: 6),
                    margin: EdgeInsets.only(
                      right: 16,
                      top: res.isMobile ? res.spacing(12) : 8.0,
                      bottom: res.isMobile ? res.spacing(12) : 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: connected
                          ? AppColors.trendGreen.withValues(alpha: 0.1)
                          : AppColors.brandAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: connected
                            ? AppColors.trendGreen
                            : AppColors.brandAccent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: connected
                                ? AppColors.trendGreen
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          connected ? wallet.shortAddress : 'CONNECT',
                          style: GoogleFonts.jetBrainsMono(
                            color: connected
                                ? AppColors.trendGreen
                                : AppColors.brandAccent,
                            fontSize: res.fontSize(11),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: _selectedIndex == 3
          ? Consumer<PortfolioViewModel>(
              builder: (context, portfolioVm, _) => _buildPortfolioBody(portfolioVm),
            )
          : Consumer<HomeViewModel>(
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
                                onChanged: (value) {
                                  viewModel.setSearchQuery(value);
                                  AnalyticsService.logSearch(value);
                                },
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
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 180,
                          child: _buildShimmerSkeleton(res),
                        )
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
                              itemCount: (viewModel.selectedTab == 'CRYPTO' || viewModel.selectedTab == 'HIP-3' ? viewModel.cryptoCategories : viewModel.availableDexes).length,
                              separatorBuilder: (context, index) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final isCategoryMode = viewModel.selectedTab == 'CRYPTO' || viewModel.selectedTab == 'HIP-3';
                                final items = isCategoryMode ? viewModel.cryptoCategories : viewModel.availableDexes;
                                final item = items[index];
                                final isSelected = isCategoryMode 
                                  ? viewModel.selectedCryptoCategory == item 
                                  : viewModel.selectedDex == item;
                                
                                return GestureDetector(
                                  onTap: () {
                                    if (isCategoryMode) {
                                      viewModel.setSelectedCryptoCategory(item);
                                      AnalyticsService.logCategoryClick(item);
                                    } else {
                                      viewModel.setSelectedDex(item);
                                      AnalyticsService.logFeatureClick('Dex: $item');
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
                            GestureDetector(
                              onTap: () {
                                AnalyticsService.logFeatureClick('USDC Filter');
                                showDialog(context: context, builder: (context) => const ComingSoonDialog(featureName: 'USDC Filter'));
                              },
                              child: Text('USDC', style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent.withValues(alpha: 0.8), fontSize: res.fontSize(12), decoration: TextDecoration.underline, decorationColor: AppColors.brandAccent.withValues(alpha: 0.4))),
                            ),
                            SizedBox(width: res.spacing(12)),
                            GestureDetector(
                              onTap: () {
                                AnalyticsService.logFeatureClick('TOTAL Filter');
                                showDialog(context: context, builder: (context) => const ComingSoonDialog(featureName: 'TOTAL Filter'));
                              },
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
                                      height: res.value(mobile: 56.0, tablet: 64.0),
                                      padding: const EdgeInsets.only(left: 8.0, right: 4.0, top: 10.0, bottom: 10.0),
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
                                            width: res.fontSize(20), height: res.fontSize(20),
                                            child: _buildTickerIcon(ticker.iconUrl, res.fontSize(20)),
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
                                                    style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: res.fontSize(8))
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
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                                      child: Row(
                                        children: [
                                          SizedBox(width: res.columnWidth(85), child: Text('Price', textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)))),
                                          SizedBox(width: res.columnWidth(85), child: Text('24h Change', textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)))),
                                          SizedBox(
                                            width: res.columnWidth(85),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text('8h Fund', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11))),
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
                                          SizedBox(width: res.columnWidth(80), child: Text('Vol 24H', textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)))),
                                          SizedBox(width: res.columnWidth(90), child: Text('Open Int.', textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)))),
                                          SizedBox(width: res.columnWidth(50), child: Text('Trend', textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)))),
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
                                        height: res.value(mobile: 56.0, tablet: 64.0),
                                        width: res.columnWidth(490),
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 10.0),
                                        decoration: const BoxDecoration(
                                          border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(width: res.columnWidth(85), child: Text(ticker.lastPrice.toStringAsFixed(4), textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: res.fontSize(11), fontWeight: FontWeight.bold))),
                                            SizedBox(width: res.columnWidth(85), child: Text(formattedChange, textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: changeColor, fontSize: res.fontSize(11)))),
                                            SizedBox(width: res.columnWidth(85), child: Text(formattedFunding, textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: ticker.funding8hPct >= 0 ? AppColors.trendGreen : AppColors.trendRed, fontSize: res.fontSize(11)))),
                                            SizedBox(width: res.columnWidth(80), child: Text(_formatVolume(ticker.volume24hUSD), textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: res.fontSize(11)))),
                                            SizedBox(width: res.columnWidth(90), child: Text(formattedOI, textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: res.fontSize(11)))),
                                            SizedBox(
                                              width: res.columnWidth(50), 
                                              child: Center(
                                                child: SparklineWidget(
                                                  color: changeColor,
                                                  width: res.columnWidth(40),
                                                  height: res.value(mobile: 24.0, tablet: 32.0),
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
          onTap: (index) {
            if (index == 0 || index == 3) {
              setState(() => _selectedIndex = index);
            } else {
              final names = ['Home', 'Markets', 'Trade', 'Portfolio'];
              showDialog(
                context: context,
                builder: (context) => ComingSoonDialog(featureName: names[index]),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Markets'),
            BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Trade'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Portfolio'),
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
      onTap: () {
        viewModel.setTab(title);
        AnalyticsService.logTabClick(title);
      },
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

  // ── Portfolio body (shown when wallet connected + index 3) ───────────────
  Widget _buildPortfolioBody(PortfolioViewModel vm) {
    final wallet = context.read<WalletViewModel>();
    if (!wallet.isConnected) {
      // Not connected — prompt user
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 52, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No wallet connected',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Tap CONNECT in the top bar to get started',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    fontSize: 11)),
          ],
        ),
      );
    }
    return const ProfileScreen();
  }

  // ── Connect dialog ─────────────────────────────────────────────────────────
  void _showConnectDialog(BuildContext ctx, WalletViewModel wallet) {
    showDialog(
      context: ctx,
      builder: (_) => _ConnectDialog(
        onConnect: (address) async {
          await wallet.connect(address);
          if (!mounted) return;
          // Initialize portfolio with the address
          context.read<PortfolioViewModel>().initializePortfolio(address);
          setState(() => _selectedIndex = 3);
        },
      ),
    );
  }

  // ── Disconnect dialog ──────────────────────────────────────────────────────
  void _showDisconnectDialog(BuildContext ctx, WalletViewModel wallet) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16191E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.surfaceBright.withValues(alpha: 0.5)),
        ),
        title: Text('Disconnect Wallet',
            style: GoogleFonts.jetBrainsMono(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connected address:',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceBright.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                wallet.address ?? '',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.brandAccent, fontSize: 10),
              ),
            ),
            const SizedBox(height: 12),
            Text('Are you sure you want to disconnect?',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await wallet.disconnect();
              if (mounted) setState(() => _selectedIndex = 0);
            },
            child: Text('Disconnect',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.trendRed,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Smooth fade+slide route — no home flash
  Route<T> _smoothRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      opaque: true,
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (_, __, ___, child) => child,
    );
  }

  Widget _buildDrawer(BuildContext context, Responsive res) {
    final navItems = [
      _DrawerItemData(
        icon: Icons.home_rounded,
        label: 'Home',
        subtitle: 'Markets & screener',
        onTap: () { Navigator.pop(context); setState(() => _selectedIndex = 0); },
      ),
      _DrawerItemData(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Portfolio',
        subtitle: 'Your positions',
        onTap: () {
          Navigator.pop(context);
          setState(() => _selectedIndex = 3);
        },
      ),
    ];

    return Drawer(
      backgroundColor: const Color(0xFF0D1014),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brandAccent.withValues(alpha: 0.12),
                  const Color(0xFF0D1014),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.brandAccent.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo row
                Row(
                  children: [
                    // Logo icon with app icon image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/LOGO.png',
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.brandAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.brandAccent.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.candlestick_chart_rounded,
                              color: AppColors.brandAccent, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HyperScreener',
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.brandAccent,
                            fontSize: res.fontSize(16),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        // PRO badge — only when user has purchased
                        Consumer<SubscriptionViewModel>(
                          builder: (_, sub, __) => sub.isPro
                              ? Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      AppColors.brandAccent.withValues(alpha: 0.25),
                                      AppColors.brandAccent.withValues(alpha: 0.08),
                                    ]),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppColors.brandAccent.withValues(alpha: 0.5),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    'PRO VERSION',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: AppColors.brandAccent,
                                      fontSize: 8,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Live indicator
                Row(
                  children: [
                    _PulseDot(),
                    const SizedBox(width: 6),
                    Text(
                      'Live data • Hyperliquid Mainnet',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Nav label ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Text(
                  'NAVIGATION',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    fontSize: 9,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 0.5,
                    color: AppColors.surfaceBright.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),

          // ── Nav items ───────────────────────────────────────────────────
          ...navItems.asMap().entries.map((e) {
            final isActive = (e.value.label == 'Home' && _selectedIndex == 0) ||
                (e.value.label == 'Portfolio' && _selectedIndex == 3);
            return _DrawerNavItem(
              data: e.value,
              isActive: isActive,
            );
          }),

          // ── Leaderboard expandable ───────────────────────────────────────
          _LeaderboardDrawerItem(
            onStatsTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                _smoothRoute(const LeaderboardStatsScreen()),
                (route) => false,
              );
            },
            onTopTradersTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                _smoothRoute(const LeaderboardScreen()),
                (route) => false,
              );
            },
          ),

          const Spacer(),

          // ── Bottom section ───────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            height: 0.5,
            color: AppColors.surfaceBright.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 4),
          _DrawerNavItem(
            data: _DrawerItemData(
              icon: Icons.settings_outlined,
              label: 'Settings',
              subtitle: 'App preferences',
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => const ComingSoonDialog(featureName: 'Settings'),
                );
              },
            ),
            isActive: false,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }


  Widget _buildShimmerSkeleton(Responsive res) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth > 0 ? constraints.maxWidth : MediaQuery.of(context).size.width;
        // Column widths that must add up to fill the available width
        final col1 = availableWidth * 0.30;
        final col2 = availableWidth * 0.18;
        final col3 = availableWidth * 0.18;
        final col4 = availableWidth * 0.16;
        final col5 = availableWidth * 0.18;

        return Shimmer.fromColors(
          baseColor: const Color(0xFF1E222D),
          highlightColor: const Color(0xFF3A3F4E),
          period: const Duration(milliseconds: 1500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(20, (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  _skeletonPill(col1, 12),
                  const SizedBox(width: 6),
                  _skeletonPill(col2, 12),
                  const SizedBox(width: 6),
                  _skeletonPill(col3, 12),
                  const SizedBox(width: 6),
                  _skeletonPill(col4, 12),
                  const SizedBox(width: 6),
                  Expanded(child: _skeletonPill(col5, 12)),
                ],
              ),
            )),
          ),
        );
      },
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

// ─────────────────────────────────────────────────────────────────────────────
// Drawer helper data class
// ─────────────────────────────────────────────────────────────────────────────
class _DrawerItemData {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _DrawerItemData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Drawer nav item — animated press + active highlight
// ─────────────────────────────────────────────────────────────────────────────
class _DrawerNavItem extends StatefulWidget {
  final _DrawerItemData data;
  final bool isActive;
  const _DrawerNavItem({required this.data, required this.isActive});

  @override
  State<_DrawerNavItem> createState() => _DrawerNavItemState();
}

class _DrawerNavItemState extends State<_DrawerNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bg;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _bg = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.data.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? AppColors.surfaceBright
                  : AppColors.brandAccent.withValues(alpha: _bg.value * 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isActive
                    ? AppColors.surfaceBright
                    : AppColors.surfaceBright.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                // ── Left accent bar ───────────────────────────────────────
                Container(
                  width: 3,
                  height: 60,
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? AppColors.brandAccent
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // ── Icon ──────────────────────────────────────────────────
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? AppColors.brandAccent.withValues(alpha: 0.15)
                        : AppColors.surfaceBright.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.data.icon,
                    size: 17,
                    color: widget.isActive
                        ? AppColors.brandAccent
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                // ── Label + subtitle ──────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.data.label,
                        style: GoogleFonts.jetBrainsMono(
                          color: widget.isActive
                              ? AppColors.brandAccent
                              : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: widget.isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        widget.data.subtitle,
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary.withValues(alpha: 0.55),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Chevron ───────────────────────────────────────────────
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: widget.isActive
                      ? AppColors.brandAccent.withValues(alpha: 0.7)
                      : AppColors.surfaceBright,
                ),
                const SizedBox(width: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Leaderboard expandable drawer item
// ─────────────────────────────────────────────────────────────────────────────
class _LeaderboardDrawerItem extends StatefulWidget {
  final VoidCallback onStatsTap;
  final VoidCallback onTopTradersTap;
  const _LeaderboardDrawerItem({
    required this.onStatsTap,
    required this.onTopTradersTap,
  });

  @override
  State<_LeaderboardDrawerItem> createState() => _LeaderboardDrawerItemState();
}

class _LeaderboardDrawerItemState extends State<_LeaderboardDrawerItem>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Parent item ────────────────────────────────────────────────
        GestureDetector(
          onTap: _toggle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _expanded
                  ? AppColors.surfaceBright
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _expanded
                    ? AppColors.surfaceBright
                    : AppColors.surfaceBright.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                // Left accent bar
                Container(
                  width: 3,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _expanded
                        ? AppColors.brandAccent
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: _expanded
                        ? AppColors.brandAccent.withValues(alpha: 0.15)
                        : AppColors.surfaceBright.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.leaderboard_rounded,
                    size: 17,
                    color: _expanded
                        ? AppColors.brandAccent
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leaderboard',
                        style: GoogleFonts.jetBrainsMono(
                          color: _expanded
                              ? AppColors.brandAccent
                              : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: _expanded
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        'Stats & rankings',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary.withValues(alpha: 0.55),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: _expanded
                        ? AppColors.brandAccent.withValues(alpha: 0.7)
                        : AppColors.surfaceBright,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),

        // ── Sub items (animated) ────────────────────────────────────────
        SizeTransition(
          sizeFactor: _expandAnim,
          child: Column(
            children: [
              _SubItem(
                icon: Icons.query_stats_rounded,
                label: 'Market Stats',
                subtitle: 'Global overview',
                onTap: widget.onStatsTap,
              ),
              _SubItem(
                icon: Icons.workspace_premium_rounded,
                label: 'Top Traders',
                subtitle: 'Leaderboard rankings',
                onTap: widget.onTopTradersTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _SubItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 28, right: 12, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceBright.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.surfaceBright.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            // Connector line
            Container(
              width: 2,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.brandAccent.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.surfaceBright,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      )),
                  Text(subtitle,
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        fontSize: 9,
                      )),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 14, color: AppColors.surfaceBright),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing live dot
// ─────────────────────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.trendGreen.withValues(alpha: _anim.value),
          boxShadow: [
            BoxShadow(
              color: AppColors.trendGreen.withValues(alpha: _anim.value * 0.5),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Connect Wallet Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _ConnectDialog extends StatefulWidget {
  final Future<void> Function(String address) onConnect;
  const _ConnectDialog({required this.onConnect});

  @override
  State<_ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends State<_ConnectDialog> {
  final _ctrl = TextEditingController(text: kDummyWallet);
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16191E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: AppColors.brandAccent.withValues(alpha: 0.3)),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.brandAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: AppColors.brandAccent, size: 17),
          ),
          const SizedBox(width: 10),
          Text(
            'Connect Wallet',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your Hyperliquid ETH address to\nview portfolio data.',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ADDRESS',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: 9,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.brandAccent.withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              controller: _ctrl,
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                hintText: '0x...',
                hintStyle: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: 12),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Testing note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppColors.brandAccent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 12,
                    color: AppColors.brandAccent.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Testing mode — dummy address pre-filled',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.brandAccent.withValues(alpha: 0.7),
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary, fontSize: 13)),
        ),
        TextButton(
          onPressed: _loading
              ? null
              : () async {
                  final addr = _ctrl.text.trim();
                  if (addr.isEmpty) return;
                  setState(() => _loading = true);
                  Navigator.pop(context);
                  await widget.onConnect(addr);
                },
          child: _loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.brandAccent),
                )
              : Text(
                  'Continue',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.brandAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
