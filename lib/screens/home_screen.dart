import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:coinduck/screens/subscription_screen.dart';
import 'package:coinduck/screens/leaderboard_stats_screen.dart';
import 'package:coinduck/screens/leaderboard_screen.dart';
import 'package:coinduck/screens/defillama_screen.dart';
import 'package:coinduck/screens/protocols_screen.dart';
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
import '../widgets/day_movers_ticker.dart';
import 'hl_tvl_screen.dart';
import 'ticker_detail_screen.dart';
import 'profile_screen.dart';
import 'liquidatable_page.dart';
import 'leverage_margin_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/responsive.dart';
import '../analytics/analytics_service.dart';
import '../widgets/account_management_sheet.dart';
import '../widgets/hip4_markets_panel.dart';
import '../viewmodels/hip4_viewmodel.dart';
import 'dex_volume_page.dart';
import 'open_interest_screen.dart';
import 'borrow_lend_page.dart';
import 'fee_intelligence_screen.dart';
import 'top_by_fees_screen.dart';
import 'defi_volume_screen.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ScrollController _tabScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Fetch tickers here instead of in main.dart to ensure it happens after permissions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().fetchTickers();
    });
  }

  @override
  void dispose() {
    _tabScrollController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  void _showTickerDetail(TickerModel ticker) {
    AnalyticsService.logTickerClick(ticker.symbol);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TickerDetailScreen(ticker: ticker),
      ),
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
        appBar: _selectedIndex == 3 ? null : AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GestureDetector(
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            child: const Icon(Icons.menu, color: AppColors.brandAccent),
          ),
          title: Consumer<HomeViewModel>(
            builder: (context, homeVm, child) {
              final isVariational = homeVm.selectedProtocol == 'Variational';
              return DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: isVariational ? 'Omni Variations' : 'Hyperliquid',
                  dropdownColor: AppColors.background,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.brandAccent),
                  onChanged: (String? value) {
                    if (value != null) {
                      homeVm.setSelectedProtocol(value == 'Omni Variations' ? 'Variational' : 'CoinDuck');
                      if (_mainScrollController.hasClients) {
                        _mainScrollController.jumpTo(0.0);
                      }
                    }
                  },
                  selectedItemBuilder: (BuildContext context) {
                    return ['Hyperliquid', 'Omni Variations'].map<Widget>((String item) {
                      return Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item,
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.brandAccent,
                            fontSize: res.fontSize(18),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  items: ['Hyperliquid', 'Omni Variations'].map<DropdownMenuItem<String>>((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textPrimary,
                          fontSize: res.fontSize(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            Consumer<SubscriptionViewModel>(
              builder: (context, sub, _) => IconButton(
                icon: Icon(
                  sub.isPro ? Icons.verified : Icons.workspace_premium,
                  color: sub.isPro ? AppColors.trendGreen : AppColors.brandAccent,
                ),
                onPressed: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const SubscriptionScreen(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                    transitionsBuilder: (_, __, ___, child) => child,
                  ),
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
                          ? AppColors.trendGreen.withOpacity(0.1)
                          : AppColors.brandAccent.withOpacity(0.1),
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
          backgroundColor: AppColors.background.withOpacity(0.85),
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
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.candlestick_chart_outlined),
              activeIcon: Icon(Icons.candlestick_chart),
              label: 'Markets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Leaderboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_outlined),
              activeIcon: Icon(Icons.account_balance),
              label: 'HL TVL',
            ),
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
        return const LeaderboardScreen();
      case 3:
        return const HlTvlScreen(isTab: true);
      case 4:
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
            controller: _mainScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(res.spacing(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DayMoversTicker(),
                  SizedBox(height: res.spacing(12)),

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
                              try {
                                context.read<Hip4ViewModel>().setSearchQuery(value);
                              } catch (_) {}
                              AnalyticsService.logSearch(value);
                            },
                            style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: res.fontSize(14)),
                            decoration: InputDecoration(
                              hintText: 'Search by symbol...',
                              hintStyle: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(14)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: res.value(mobile: 12.0, tablet: 16.0)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: res.spacing(12)),

                  if (viewModel.selectedProtocol != 'Variational') ...[
                    Container(
                      height: res.value(mobile: 38.0, tablet: 48.0),
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
                            _buildTab(viewModel, 'OUTCOME', res),
                            _buildTab(viewModel, 'WATCHLIST', res),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: res.spacing(12)),
                  ],

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
                    if (viewModel.selectedProtocol != 'Variational' && (viewModel.selectedTab == 'HIP-3' || viewModel.selectedTab == 'CRYPTO' || viewModel.selectedTab == 'OUTCOME'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          height: res.value(mobile: 32.0, tablet: 40.0),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: viewModel.selectedTab == 'OUTCOME'
                              ? context.watch<Hip4ViewModel>().categories.length
                              : (viewModel.selectedTab == 'CRYPTO' || viewModel.selectedTab == 'HIP-3' ? viewModel.cryptoCategories : viewModel.availableDexes).length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final isCategoryMode = viewModel.selectedTab == 'CRYPTO' || viewModel.selectedTab == 'HIP-3';
                              final items = viewModel.selectedTab == 'OUTCOME'
                                ? context.read<Hip4ViewModel>().categories
                                : (isCategoryMode ? viewModel.cryptoCategories : viewModel.availableDexes);
                              final item = items[index];
                              final isSelected = viewModel.selectedTab == 'OUTCOME'
                                ? context.watch<Hip4ViewModel>().selectedCategory == item
                                : (isCategoryMode
                                  ? viewModel.selectedCryptoCategory == item
                                  : viewModel.selectedDex == item);

                              return GestureDetector(
                                onTap: () {
                                  if (viewModel.selectedTab == 'OUTCOME') {
                                    final hip4Vm = context.read<Hip4ViewModel>();
                                    hip4Vm.setCategory(item);
                                    AnalyticsService.logCategoryClick(item);
                                  } else if (isCategoryMode) {
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
                                    color: isSelected ? AppColors.brandAccent.withOpacity(0.1) : Colors.transparent,
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
                      ),

                    if (viewModel.selectedTab == 'OUTCOME')
                      const Hip4MarketsPanel()
                    else ...[
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
                                    SizedBox(width: res.columnWidth(36), child: Text('#', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)))),
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
                                        width: res.columnWidth(36),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                viewModel.toggleFavorite(ticker.symbol);
                                              },
                                              child: Icon(
                                                viewModel.isFavorited(ticker.symbol) ? Icons.star : Icons.star_border,
                                                size: res.fontSize(14),
                                                color: viewModel.isFavorited(ticker.symbol)
                                                    ? Colors.amber
                                                    : AppColors.textSecondary.withOpacity(0.3),
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            Expanded(
                                              child: Text(
                                                rank.toString(),
                                                style: GoogleFonts.jetBrainsMono(
                                                  color: AppColors.textSecondary,
                                                  fontSize: res.fontSize(9),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      SizedBox(
                                        width: res.fontSize(28), height: res.fontSize(28),
                                        child: viewModel.selectedProtocol == 'Variational'
                                            ? _buildVariationalTickerIcon(ticker.displaySymbol, res.fontSize(28))
                                            : _buildTickerIcon(ticker.iconUrl, res.fontSize(28)),
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
                            physics: const BouncingScrollPhysics(),
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
                                      if (viewModel.selectedTab != 'SPOT')
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
                                      if (viewModel.selectedTab != 'SPOT')
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
                                  final isSpotOnly = viewModel.selectedTab == 'SPOT';

                                  return GestureDetector(
                                    onTap: () => _showTickerDetail(ticker),
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                    height: res.value(mobile: 56.0, tablet: 64.0),
                                    width: isSpotOnly ? res.columnWidth(315) : res.columnWidth(490),
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 10.0),
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(width: res.columnWidth(85), child: Text(ticker.lastPrice.toStringAsFixed(4), textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: viewModel.sortColumn == 'lastPrice' ? Colors.white : AppColors.textPrimary, fontSize: res.fontSize(11), fontWeight: viewModel.sortColumn == 'lastPrice' ? FontWeight.bold : FontWeight.normal))),
                                        SizedBox(width: res.columnWidth(85), child: Text(formattedChange, textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: changeColor, fontSize: res.fontSize(11), fontWeight: viewModel.sortColumn == 'change24hPct' ? FontWeight.bold : FontWeight.normal))),
                                        if (!isSpotOnly)
                                          SizedBox(width: res.columnWidth(85), child: Text(formattedFunding, textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: ticker.funding8hPct >= 0 ? AppColors.trendGreen : AppColors.trendRed, fontSize: res.fontSize(11), fontWeight: viewModel.sortColumn == 'funding8hPct' ? FontWeight.bold : FontWeight.normal))),
                                        SizedBox(width: res.columnWidth(80), child: Text(_formatVolume(ticker.volume24hUSD), textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: viewModel.sortColumn == 'volume24hUSD' ? Colors.white : AppColors.textPrimary, fontSize: res.fontSize(11), fontWeight: viewModel.sortColumn == 'volume24hUSD' ? FontWeight.bold : FontWeight.normal))),
                                        if (!isSpotOnly)
                                          SizedBox(width: res.columnWidth(90), child: Text(formattedOI, textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: viewModel.sortColumn == 'openInterestUSD' ? Colors.white : AppColors.textPrimary, fontSize: res.fontSize(11), fontWeight: viewModel.sortColumn == 'openInterestUSD' ? FontWeight.bold : FontWeight.normal))),
                                        SizedBox(
                                          width: res.columnWidth(50),
                                          child: Center(
                                            child: SparklineWidget(
                                              color: changeColor,
                                              width: res.columnWidth(40),
                                              height: res.value(mobile: 24.0, tablet: 40.0),
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
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVariationalTickerIcon(String symbol, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF1B2023),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        symbol.isNotEmpty ? symbol.substring(0, 1).toUpperCase() : '',
        style: GoogleFonts.jetBrainsMono(
          color: AppColors.textSecondary,
          fontSize: size * 0.45,
          fontWeight: FontWeight.bold,
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
                return Center(child: CircularProgressIndicator(strokeWidth: 1, valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandAccent.withOpacity(0.3))));
              },
            ),
      ),
    );
  }

  Widget _buildMarketBadge(TickerModel ticker, Responsive res) {
    String? categoryLabel;

    // Identify category (DEX or Crypto Category)
    if (ticker.dex.isNotEmpty && ticker.dex.toLowerCase() != 'hyperliquid' && ticker.dex.toLowerCase() != 'variational') {
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
    final displayTitle = title == 'WATCHLIST' ? 'WATCHLIST' : title;
    return GestureDetector(
      onTap: () {
        viewModel.setTab(title);
        AnalyticsService.logTabClick(title);
        if (_mainScrollController.hasClients) {
          _mainScrollController.jumpTo(0.0);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: res.spacing(14)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceBright : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title == 'WATCHLIST') ...[
              Icon(
                Icons.star,
                size: res.fontSize(13),
                color: Colors.amber,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              displayTitle,
              style: GoogleFonts.jetBrainsMono(
                color: isActive ? AppColors.brandAccent : AppColors.textSecondary,
                fontSize: res.fontSize(12),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
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
                size: 52, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('No wallet connected',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Tap CONNECT in the top bar to get started',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary.withOpacity(0.5),
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
          side: BorderSide(color: AppColors.surfaceBright.withOpacity(0.5)),
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
                color: AppColors.surfaceBright.withOpacity(0.3),
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

    return Drawer(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                gradient: RadialGradient(
                  center: const Alignment(0.0, 1.0),
                  radius: 0.8,
                  colors: [
                    AppColors.brandAccent.withOpacity(0.1),
                    AppColors.background.withOpacity(0.0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: DotGridPainter(
                dotColor: AppColors.surfaceBright.withOpacity(0.5),
                spacing: 35.0,
              ),
            ),
          ),
          Column(
            children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 28),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.surfaceBright.withOpacity(0.3),
                  width: 0.8,
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
                            color: AppColors.brandAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.brandAccent.withOpacity(0.4)),
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
                          'CoinDuck',
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
                                      AppColors.brandAccent.withOpacity(0.25),
                                      AppColors.brandAccent.withOpacity(0.08),
                                    ]),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppColors.brandAccent.withOpacity(0.5),
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

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [

                  _DrawerExpandableNavItem(
                    label: 'Fees & Revenue',
                    subtitle: 'Protocol earnings & analytics',
                    iconAsset: 'assets/appicons/feeandrevenue.png',
                    children: [
                      _SubDrawerItemData(
                        label: 'Hyperliquid Fees & Revenue',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(_smoothRoute(const DefiLlamaScreen()));
                        },
                      ),
                      _SubDrawerItemData(
                        label: 'DEX Fees & Revenue',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(_smoothRoute(const FeeIntelligenceScreen()));
                        },
                      ),
                    ],
                  ),

                  _DrawerNavItem(
                    data: _DrawerItemData(
                      iconAsset: 'assets/appicons/feeintelligence.png',
                      label: 'L1 Top Fees',
                      subtitle: 'Top L1 protocols by fees',
                      onTap: () {
                        Navigator.of(context).push(_smoothRoute(const TopByFeesScreen()));
                      },
                    ),
                    isActive: false,
                  ),


                  _DrawerNavItem(
                    data: _DrawerItemData(
                      iconAsset: 'assets/appicons/stats.png',
                      label: 'Stats',
                      subtitle: 'Market overview',
                      onTap: () {
                        Navigator.of(context).push(_smoothRoute(const LeaderboardStatsScreen()));
                      },
                    ),
                    isActive: false,
                  ),

                  _DrawerExpandableNavItem(
                    label: 'Volume',
                    subtitle: 'Protocol volume',
                    iconAsset: 'assets/appicons/dexvolume.png',
                    children: [
                      _SubDrawerItemData(
                        label: 'Hyperliquid Volume',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(_smoothRoute(const DexVolumePage()));
                        },
                      ),
                      _SubDrawerItemData(
                        label: 'DeFi Volume',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(_smoothRoute(const DefiVolumeScreen()));
                        },
                      ),
                    ],
                  ),

                  _DrawerNavItem(
                    data: _DrawerItemData(
                      iconAsset: 'assets/appicons/protocoltvl.png',
                      label: 'Protocol TVL',
                      subtitle: 'DeFi ecosystem liquidity',
                      onTap: () {
                        Navigator.of(context).push(_smoothRoute(const ProtocolsScreen()));
                      },
                    ),
                    isActive: false,
                  ),

                  _DrawerNavItem(
                    data: _DrawerItemData(
                      iconAsset: 'assets/appicons/hyperliquidtvl.png',
                      label: 'Hyperliquid TVL',
                      subtitle: 'HL protocol value locked',
                      onTap: () {
                        Navigator.of(context).push(_smoothRoute(const HlTvlScreen()));
                      },
                    ),
                    isActive: false,
                  ),

                  _DrawerNavItem(
                    data: _DrawerItemData(
                      iconAsset: 'assets/appicons/openinterst.png',
                      label: 'Open Interest',
                      subtitle: 'Derivatives open interest',
                      onTap: () {
                        Navigator.of(context).push(_smoothRoute(const OpenInterestScreen()));
                      },
                    ),
                    isActive: false,
                  ),

                  _DrawerNavItem(
                    data: _DrawerItemData(
                      iconAsset: 'assets/appicons/liquidation.png',
                      label: 'Liquidations',
                      subtitle: 'Positions at risk',
                      onTap: () {
                        Navigator.of(context).push(_smoothRoute(const LiquidatablePage()));
                      },
                    ),
                    isActive: false,
                  ),

                  _DrawerNavItem(
                    data: _DrawerItemData(
                      iconAsset: 'assets/appicons/balance.png',
                      label: 'Leverage & Margin',
                      subtitle: 'Margin tiers & requirements',
                      onTap: () {
                        Navigator.of(context).push(_smoothRoute(const LeverageMarginPage()));
                      },
                    ),
                    isActive: false,
                  ),

                  _DrawerNavItem(
                    data: _DrawerItemData(
                      iconAsset: 'assets/appicons/balance.png',
                      label: 'Borrow & Lend',
                      subtitle: 'Hyperliquid reserve states & rates',
                      onTap: () {
                        Navigator.of(context).push(_smoothRoute(const BorrowLendPage()));
                      },
                    ),
                    isActive: false,
                  ),
                ],
              ),
            ),
          ),


          // ── Bottom: wallet + settings ───────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            height: 0.5,
            color: AppColors.surfaceBright.withOpacity(0.3),
          ),
/*
          if (wallet.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceBright.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.surfaceBright.withOpacity(0.3),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.brandAccent.withOpacity(0.15),
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
              color: AppColors.textSecondary.withOpacity(0.5),
              fontSize: 9,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 0.5,
              color: AppColors.surfaceBright.withOpacity(0.4),
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
          baseColor: const Color(0xFF2C2F3A),
          highlightColor: const Color(0xFF3F4452),
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
              child: Icon(Icons.info_outline, size: 12, color: AppColors.textSecondary.withOpacity(0.8)),
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
  final String iconAsset;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _DrawerItemData({
    required this.iconAsset,
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
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? AppColors.brandAccent.withOpacity(0.08)
                  : Color.lerp(
                      AppColors.surface.withOpacity(0.2),
                      AppColors.surfaceBright.withOpacity(0.35),
                      _bg.value,
                    ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isActive
                    ? AppColors.brandAccent.withOpacity(0.4)
                    : Color.lerp(
                        AppColors.surfaceBright.withOpacity(0.15),
                        AppColors.brandAccent.withOpacity(0.25),
                        _bg.value,
                      )!,
                width: 0.8,
              ),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: AppColors.brandAccent.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                const SizedBox(width: 6),
                // ── Left accent bar ───────────────────────────────────────
                Container(
                  width: 3.0,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: widget.isActive
                          ? [
                              AppColors.brandAccent,
                              AppColors.brandAccent.withOpacity(0.3),
                            ]
                          : [
                              Colors.transparent,
                              Colors.transparent,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Image.asset(
                        widget.data.iconAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.data.label,
                        style: GoogleFonts.inter(
                          color: widget.isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.85),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.data.subtitle,
                        style: GoogleFonts.inter(
                          color: widget.isActive
                              ? AppColors.brandAccent
                              : Colors.white.withOpacity(0.45),
                          fontSize: 10,
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
                          color: AppColors.brandAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        )
                      : null,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: widget.isActive
                        ? AppColors.brandAccent
                        : AppColors.textSecondary.withOpacity(0.4),
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
              color: AppColors.brandAccent.withOpacity(_bg.value * 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.surfaceBright.withOpacity(0.3),
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
                    color: AppColors.surfaceBright.withOpacity(0.6),
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
                            color: AppColors.textSecondary.withOpacity(0.55),
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
            color: AppColors.brandAccent.withOpacity(0.3)),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.brandAccent.withOpacity(0.12),
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
                  color: AppColors.brandAccent.withOpacity(0.3)),
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
                  color: AppColors.brandAccent.withOpacity(0.3)),
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

class _SubDrawerItemData {
  final String label;
  final VoidCallback onTap;
  const _SubDrawerItemData({
    required this.label,
    required this.onTap,
  });
}

class _SubDrawerNavItem extends StatelessWidget {
  final _SubDrawerItemData data;
  const _SubDrawerNavItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.brandAccent.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                data.label,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerExpandableNavItem extends StatefulWidget {
  final String label;
  final String subtitle;
  final String iconAsset;
  final List<_SubDrawerItemData> children;

  const _DrawerExpandableNavItem({
    required this.label,
    required this.subtitle,
    required this.iconAsset,
    required this.children,
  });

  @override
  State<_DrawerExpandableNavItem> createState() => _DrawerExpandableNavItemState();
}

class _DrawerExpandableNavItemState extends State<_DrawerExpandableNavItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: _isExpanded
                  ? AppColors.brandAccent.withOpacity(0.08)
                  : AppColors.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isExpanded
                    ? AppColors.brandAccent.withOpacity(0.4)
                    : AppColors.surfaceBright.withOpacity(0.15),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 6),
                // ── Left accent bar ───────────────────────────────────────
                Container(
                  width: 3.0,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: _isExpanded
                          ? [
                              AppColors.brandAccent,
                              AppColors.brandAccent.withOpacity(0.3),
                            ]
                          : [
                              Colors.transparent,
                              Colors.transparent,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Image.asset(
                        widget.iconAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.label,
                              style: GoogleFonts.inter(
                                color: _isExpanded
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.85),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle,
                              style: GoogleFonts.inter(
                                color: _isExpanded
                                    ? AppColors.brandAccent
                                    : Colors.white.withOpacity(0.45),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18,
                  color: _isExpanded ? AppColors.brandAccent : AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 44.5, right: 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 1.5,
                    margin: const EdgeInsets.only(right: 14, top: 4, bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBright.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: widget.children.map((subItem) {
                        return _SubDrawerNavItem(data: subItem);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
