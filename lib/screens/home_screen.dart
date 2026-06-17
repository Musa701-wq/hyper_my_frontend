import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyperscreener/screens/subscription_screen.dart';
import 'package:hyperscreener/screens/leaderboard_stats_screen.dart';
import 'package:hyperscreener/screens/defillama_screen.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_colors.dart';
import '../utils/common_widgets.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/subscription_viewmodel.dart';
import '../viewmodels/wallet_viewmodel.dart';
import '../viewmodels/portfolio_viewmodel.dart';
import '../models/ticker_model.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/funding_legend_dialog.dart';
import '../widgets/live_markets_drawer.dart' show LiveMarketsBody;
import '../widgets/sparkline_widget.dart';
import '../widgets/ticker_detail_dialog.dart';
import 'profile_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/responsive.dart';
import '../analytics/analytics_service.dart';
import '../widgets/account_management_sheet.dart';

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
            // ── Live Signal button commented out (coming soon) ──
            // GestureDetector(
            //   onTap: () {
            //     AnalyticsService.logFeatureClick('Live Signal');
            //     showDialog(
            //       context: context,
            //       builder: (context) => const ComingSoonDialog(featureName: 'Live Signal'),
            //     );
            //   },
            //   child: const Icon(Icons.sensors, color: AppColors.brandAccent),
            // ),
            // const SizedBox(width: 8),
            /*
            Consumer<WalletViewModel>(
              builder: (context, wallet, _) {
                final connected = wallet.isConnected;
                return GestureDetector(
                  onTap: () {
                    if (connected) {
                      _showAccountManagement(context, wallet);
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
                          connected ? wallet.shortAddress : 'ADD ADDRESS',
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
            */
          ],
        ),
        body: _buildTabBody(res),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: AppColors.background.withValues(alpha: 0.85),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.brandAccent,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.jetBrainsMono(fontSize: 10),
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Markets'),
            // BottomNavigationBarItem(icon: Icon(Icons.leaderboard_outlined), label: 'Leaderboard'),
            // BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Portfolio'),
          ],
        ),
      ),
    );
  }
  Widget _buildTabBody(Responsive res) {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeBody(res);
      case 1:
        return const LiveMarketsBody();
      case 2:
        return const LeaderboardStatsBody(showTopBar: false);
      case 3:
        return Consumer<PortfolioViewModel>(
          builder: (context, portfolioVm, _) => _buildPortfolioBody(portfolioVm),
        );
      default:
        return _buildHomeBody(res);
    }
  }

  Widget _buildHomeBody(Responsive res) {
    return Consumer<HomeViewModel>(
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
                    'Market Screener',
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
                                    _buildSortableHeader(
                                      label: 'Symbol',
                                      columnKey: 'symbol',
                                      viewModel: viewModel,
                                      width: res.columnWidth(120),
                                      isExpanded: true,
                                    ),
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
                                              ticker.displaySymbol,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.jetBrainsMono(
                                                color: viewModel.sortColumn == 'symbol' ? Colors.white : AppColors.textPrimary,
                                                fontSize: res.fontSize(11),
                                                fontWeight: viewModel.sortColumn == 'symbol' ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            _buildMarketBadge(ticker, res),
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
                                      _buildSortableHeader(
                                        label: 'Price',
                                        columnKey: 'lastPrice',
                                        viewModel: viewModel,
                                        width: res.columnWidth(85),
                                        textAlign: TextAlign.center,
                                      ),
                                      _buildSortableHeader(
                                        label: '24h Change',
                                        columnKey: 'change24hPct',
                                        viewModel: viewModel,
                                        width: res.columnWidth(85),
                                        textAlign: TextAlign.center,
                                      ),
                                      _buildSortableHeader(
                                        label: '8h Fund',
                                        columnKey: 'funding8hPct',
                                        viewModel: viewModel,
                                        width: res.columnWidth(85),
                                        textAlign: TextAlign.center,
                                        hasInfo: true,
                                        onInfoTap: () => showDialog(
                                          context: context,
                                          builder: (context) => const FundingLegendDialog(),
                                        ),
                                      ),
                                      _buildSortableHeader(
                                        label: 'Vol 24H',
                                        columnKey: 'volume24hUSD',
                                        viewModel: viewModel,
                                        width: res.columnWidth(80),
                                        textAlign: TextAlign.center,
                                      ),
                                      _buildSortableHeader(
                                        label: 'Open Int.',
                                        columnKey: 'openInterestUSD',
                                        viewModel: viewModel,
                                        width: res.columnWidth(90),
                                        textAlign: TextAlign.center,
                                      ),
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
                                        SizedBox(width: res.columnWidth(85), child: Text(ticker.lastPrice.toStringAsFixed(4), textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: viewModel.sortColumn == 'lastPrice' ? Colors.white : AppColors.textPrimary, fontSize: res.fontSize(11), fontWeight: viewModel.sortColumn == 'lastPrice' ? FontWeight.bold : FontWeight.normal))),
                                        SizedBox(width: res.columnWidth(85), child: Text(formattedChange, textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: changeColor, fontSize: res.fontSize(11), fontWeight: viewModel.sortColumn == 'change24hPct' ? FontWeight.bold : FontWeight.normal))),
                                        SizedBox(width: res.columnWidth(85), child: Text(formattedFunding, textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: ticker.funding8hPct >= 0 ? AppColors.trendGreen : AppColors.trendRed, fontSize: res.fontSize(11), fontWeight: viewModel.sortColumn == 'funding8hPct' ? FontWeight.bold : FontWeight.normal))),
                                        SizedBox(width: res.columnWidth(80), child: Text(_formatVolume(ticker.volume24hUSD), textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: viewModel.sortColumn == 'volume24hUSD' ? Colors.white : AppColors.textPrimary, fontSize: res.fontSize(11), fontWeight: viewModel.sortColumn == 'volume24hUSD' ? FontWeight.bold : FontWeight.normal))),
                                        SizedBox(width: res.columnWidth(90), child: Text(formattedOI, textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: viewModel.sortColumn == 'openInterestUSD' ? Colors.white : AppColors.textPrimary, fontSize: res.fontSize(11), fontWeight: viewModel.sortColumn == 'openInterestUSD' ? FontWeight.bold : FontWeight.normal))),
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

  Widget _buildMarketBadge(TickerModel ticker, Responsive res) {
    String? categoryLabel;
    
    // Identify category (DEX or Crypto Category)
    if (ticker.dex.isNotEmpty && ticker.dex.toLowerCase() != 'hyperliquid') {
      categoryLabel = ticker.dex.toUpperCase();
    } else if (ticker.cryptoCategory.isNotEmpty) {
      final standardCategories = ['layer1', 'layer2', 'defi', 'ai', 'gaming', 'meme'];
      if (!standardCategories.contains(ticker.cryptoCategory.toLowerCase().trim())) {
        categoryLabel = ticker.cryptoCategory.toUpperCase();
      }
    }






    final List<Widget> badges = [];
    
    // 1. Check for SPOT
    if (ticker.marketType == 'spot') {
      badges.add(
        _Badge(
          label: 'SPOT',
          res: res,
          bgColor: const Color(0xFF0D2D2A),
          textColor: const Color(0xFF5EEAD4),
        ),
      );
    }

    // 2. Category badge (if identified above)
    if (categoryLabel != null) {
      if (badges.isNotEmpty) badges.add(const SizedBox(width: 4));
      badges.add(
        _Badge(
          label: categoryLabel,
          res: res,
          bgColor: const Color(0xFF0D2D2A),
          textColor: const Color(0xFF5EEAD4),
        ),
      );
    }



    // 3. Leverage Badge (for everything except SPOT, if > 0)
    if (ticker.marketType != 'spot' && ticker.maxLeverage > 0) {
      if (badges.isNotEmpty) badges.add(const SizedBox(width: 4));
      badges.add(
        _Badge(
          label: '${ticker.maxLeverage}x',
          res: res,
          bgColor: const Color(0xFF0D2D2A),
          textColor: const Color(0xFF5EEAD4),
        ),
      );
    }





    if (badges.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: badges,
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
    final wallet = context.watch<WalletViewModel>();

    if (!wallet.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brandAccent),
      );
    }

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
    return ProfileScreen(walletAddress: wallet.address!);
  }

  // ── Connect dialog ─────────────────────────────────────────────────────────
  void _showConnectDialog(BuildContext ctx, WalletViewModel wallet) {
    showDialog(
      context: ctx,
      builder: (_) => _ConnectDialog(
        onConnect: (address, name) async {
          await wallet.connect(address, name: name);
          if (!mounted) return;
          // Initialize portfolio with the address
          context.read<PortfolioViewModel>().initializePortfolio(address);
          setState(() => _selectedIndex = 3); // Go to portfolio tab
        },
      ),
    );
  }

  void _showAccountManagement(BuildContext ctx, WalletViewModel wallet) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AccountManagementSheet(
        onAddAccount: () => _showConnectDialog(ctx, wallet),
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
    final walletVm = context.watch<WalletViewModel>();
    final wallet = walletVm.address ?? '';
    final shortWallet = wallet.isNotEmpty
        ? '0x${wallet.substring(2, 6)}...${wallet.substring(wallet.length - 4)}'
        : '';

    final navItems = [
      _DrawerItemData(
        icon: Icons.home_rounded,
        label: 'Home',
        subtitle: 'Markets & screener',
        onTap: () { Navigator.pop(context); setState(() => _selectedIndex = 0); },
      ),
      _DrawerItemData(
        icon: Icons.bar_chart_rounded,
        label: 'Markets',
        subtitle: 'Live gainers/losers',
        onTap: () { Navigator.pop(context); setState(() => _selectedIndex = 1); },
      ),
      /*
      _DrawerItemData(
        icon: Icons.leaderboard_rounded,
        label: 'Leaderboard',
        subtitle: 'Global performance',
        onTap: () { Navigator.pop(context); setState(() => _selectedIndex = 2); },
      ),
      */
      /*
      _DrawerItemData(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Portfolio',
        subtitle: 'Your positions',
        onTap: () {
          Navigator.pop(context);
          setState(() => _selectedIndex = 3);
        },
      ),
      */
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
                Row(
                  children: [
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
                Row(
                  children: [
                    const PulseDot(),
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

          const SizedBox(height: 8),

          _sectionLabel('NAVIGATION'),
          ...navItems.asMap().entries.map((e) {
            final isActive = (e.key == _selectedIndex);
            return _DrawerNavItem(
              data: e.value,
              isActive: isActive,
            );
          }),

          const SizedBox(height: 4),

          // ── ANALYTICS ───────────────────────────────────────────────────
          _sectionLabel('ANALYTICS'),

          _DrawerNavItem(
            data: _DrawerItemData(
              icon: Icons.analytics_rounded,
              label: 'DefiLlama',
              subtitle: 'Fees & revenue',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DefiLlamaScreen()),
                );
              },
            ),
            isActive: false,
          ),

          const SizedBox(height: 4),

          const Spacer(),

          // ── Bottom: wallet + settings ───────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            height: 0.5,
            color: AppColors.surfaceBright.withValues(alpha: 0.3),
          ),
/*
          if (wallet.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceBright.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.surfaceBright.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.brandAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        size: 14, color: AppColors.brandAccent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Wallet',
                            style: GoogleFonts.jetBrainsMono(
                                color: AppColors.textSecondary, fontSize: 8,
                                letterSpacing: 1)),
                        Text(shortWallet,
                            style: GoogleFonts.jetBrainsMono(
                                color: AppColors.textPrimary, fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.trendGreen,
                    ),
                  ),
                ],
              ),
            ),
            */
          // ── Settings item commented out (coming soon) ──
          // _DrawerNavItem(
          //   data: _DrawerItemData(
          //     icon: Icons.settings_outlined,
          //     label: 'Settings',
          //     subtitle: 'App preferences',
          //     onTap: () {
          //       Navigator.pop(context);
          //       showDialog(
          //         context: context,
          //         builder: (_) => const ComingSoonDialog(featureName: 'Settings'),
          //       );
          //     },
          //   ),
          //   isActive: false,
          // ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Text(
            label,
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

  Widget _buildSortableHeader({
    required String label,
    required String columnKey,
    required HomeViewModel viewModel,
    required double width,
    TextAlign textAlign = TextAlign.start,
    bool isExpanded = false,
    bool hasInfo = false,
    VoidCallback? onInfoTap,
  }) {
    final bool isSorted = viewModel.sortColumn == columnKey;
    final res = Responsive(context);

    Widget content = GestureDetector(
      onTap: () => viewModel.setSortColumn(columnKey),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: textAlign == TextAlign.center ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              textAlign: textAlign,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.jetBrainsMono(
                color: isSorted ? Colors.white : AppColors.textSecondary,
                fontSize: res.fontSize(11),
                fontWeight: isSorted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isSorted) ...[
            const SizedBox(width: 2),
            Icon(
              viewModel.isAscending ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 14,
              color: AppColors.brandAccent,
            ),
          ],
          if (hasInfo) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onInfoTap,
              child: Icon(Icons.info_outline, size: 12, color: AppColors.textSecondary.withValues(alpha: 0.8)),
            ),
          ],
        ],
      ),
    );

    if (isExpanded) {
      return Expanded(child: content);
    }
    return SizedBox(width: width, child: content);
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
              gradient: widget.isActive
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.brandAccent.withValues(alpha: 0.15),
                        AppColors.brandAccent.withValues(alpha: 0.04),
                      ],
                    )
                  : null,
              color: widget.isActive
                  ? null
                  : AppColors.brandAccent.withValues(alpha: _bg.value * 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isActive
                    ? AppColors.brandAccent.withValues(alpha: 0.3)
                    : AppColors.surfaceBright.withValues(alpha: 0.3),
                width: widget.isActive ? 0.8 : 0.8,
              ),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: AppColors.brandAccent.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // ── Left accent bar ───────────────────────────────────────
                Container(
                  width: 3.5,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: widget.isActive
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.brandAccent,
                              AppColors.brandAccent.withValues(alpha: 0.3),
                            ],
                          )
                        : null,
                    color: widget.isActive ? null : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: widget.isActive
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.brandAccent.withValues(alpha: 0.2),
                              AppColors.brandAccent.withValues(alpha: 0.08),
                            ],
                          )
                        : null,
                    color: widget.isActive
                        ? null
                        : AppColors.surfaceBright.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: widget.isActive
                        ? Border.all(
                            color: AppColors.brandAccent.withValues(alpha: 0.2),
                            width: 0.5,
                          )
                        : null,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.data.label,
                        style: GoogleFonts.jetBrainsMono(
                          color: widget.isActive
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.data.subtitle,
                        style: GoogleFonts.jetBrainsMono(
                          color: widget.isActive
                              ? AppColors.brandAccent.withValues(alpha: 0.6)
                              : AppColors.textSecondary.withValues(alpha: 0.55),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: widget.isActive
                      ? BoxDecoration(
                          color: AppColors.brandAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        )
                      : null,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: widget.isActive
                        ? AppColors.brandAccent
                        : AppColors.surfaceBright,
                  ),
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
// Leaderboard drawer item — animated press + chevron
// ─────────────────────────────────────────────────────────────────────────────
class _LeaderboardDrawerItem extends StatefulWidget {
  final VoidCallback onTap;
  const _LeaderboardDrawerItem({required this.onTap});

  @override
  State<_LeaderboardDrawerItem> createState() => _LeaderboardDrawerItemState();
}

class _LeaderboardDrawerItemState extends State<_LeaderboardDrawerItem>
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
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandAccent.withValues(alpha: _bg.value * 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.surfaceBright.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Container(width: 3, height: 50,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBright.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.leaderboard_rounded,
                    size: 17,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Leaderboard',
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                          )),
                      Text('Stats & rankings',
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textSecondary.withValues(alpha: 0.55),
                            fontSize: 9.5,
                          )),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppColors.surfaceBright),
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
// Connect Wallet Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _ConnectDialog extends StatefulWidget {
  final Future<void> Function(String address, String name) onConnect;
  const _ConnectDialog({required this.onConnect});

  @override
  State<_ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends State<_ConnectDialog> {
  final _addressCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _nameCtrl.dispose();
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
            'NICKNAME (E.G. MAIN WALLET)',
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
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                hintText: 'My Wallet',
                hintStyle: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: 12),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
              ),
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
              controller: _addressCtrl,
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary, fontSize: 13)),
        ),
        SizedBox(
          width: 125,
          child: ElevatedButton(
            onPressed: _loading
                ? null
                : () async {
                    final addr = _addressCtrl.text.trim();
                    final name = _nameCtrl.text.trim().isEmpty 
                        ? 'Wallet ${addr.length > 4 ? addr.substring(addr.length - 4) : ""}' 
                        : _nameCtrl.text.trim();
                    if (addr.length < 40) return;
                    
                    setState(() => _loading = true);
                    await widget.onConnect(addr, name);
                    if (mounted) Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                : Text('Continue',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Responsive res;
  final Color bgColor;
  final Color textColor;

  const _Badge({
    required this.label,
    required this.res,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          color: textColor,
          fontSize: res.fontSize(9),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
