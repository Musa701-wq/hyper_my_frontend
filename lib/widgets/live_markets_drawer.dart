import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../viewmodels/home_viewmodel.dart';
import '../models/ticker_model.dart';
import '../models/trader_distribution_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen Live Markets dashboard entry point
// ─────────────────────────────────────────────────────────────────────────────
class LiveMarketsScreen extends StatelessWidget {
  const LiveMarketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Live Markets',
            style: GoogleFonts.jetBrainsMono(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: const LiveMarketsBody(),
    );
  }
}

class LiveMarketsBody extends StatefulWidget {
  const LiveMarketsBody({super.key});

  @override
  State<LiveMarketsBody> createState() => _LiveMarketsBodyState();
}

class _LiveMarketsBodyState extends State<LiveMarketsBody> {
  int _selectedTabIndex = 1; // Default to MOST ACTIVE
  String _performanceMode = 'Gainers'; // 'Gainers' or 'Losers'
  String _activeMode = 'Vol'; // 'Vol' or 'OI'
  String _fundingMode = 'Highest'; // 'Highest' or 'Lowest'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().fetchTraderDistribution();
    });
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    final viewModel = context.watch<HomeViewModel>();

    if (viewModel.isLoading && viewModel.allTickers.isEmpty) {
      return _buildShimmer(res);
    }

    // Performance tickers
    final List<TickerModel> perfTickers = _performanceMode == 'Gainers' 
        ? viewModel.gainers 
        : viewModel.losers;

    // Active tickers
    final List<TickerModel> activeTickers = List.from(viewModel.allTickers)
      ..sort((a, b) => _activeMode == 'Vol'
          ? b.volume24hUSD.compareTo(a.volume24hUSD)
          : b.openInterestUSD.compareTo(a.openInterestUSD));

    // Funding tickers
    final List<TickerModel> fundingTickers = List.from(viewModel.allTickers)
      ..sort((a, b) => _fundingMode == 'Highest'
          ? b.funding8hPct.compareTo(a.funding8hPct)
          : a.funding8hPct.compareTo(b.funding8hPct));

    // Get max value for progress bars
    double maxValue = 1.0;
    if (_selectedTabIndex == 1 && activeTickers.isNotEmpty) {
      final top5 = activeTickers.take(5).toList();
      maxValue = _activeMode == 'Vol'
          ? top5.map((e) => e.volume24hUSD).reduce((a, b) => a > b ? a : b)
          : top5.map((e) => e.openInterestUSD).reduce((a, b) => a > b ? a : b);
    } else if (_selectedTabIndex == 0 && perfTickers.isNotEmpty) {
      final top5 = perfTickers.take(5).toList();
      maxValue = top5.map((e) => e.change24hPct.abs()).reduce((a, b) => a > b ? a : b);
    } else if (_selectedTabIndex == 2 && fundingTickers.isNotEmpty) {
      final top5 = fundingTickers.take(5).toList();
      maxValue = top5.map((e) => e.funding8hPct.abs()).reduce((a, b) => a > b ? a : b);
    }
    if (maxValue <= 0) maxValue = 1.0;

    final currentTickers = _selectedTabIndex == 0
        ? perfTickers.take(5).toList()
        : _selectedTabIndex == 1
            ? activeTickers.take(5).toList()
            : fundingTickers.take(5).toList();

    return RefreshIndicator(
      onRefresh: () => viewModel.fetchTickers(forceRefresh: true),
      color: AppColors.brandAccent,
      backgroundColor: AppColors.surfaceBright,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(res.spacing(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ScreenHeader(viewModel: viewModel),
            SizedBox(height: res.spacing(24)),
            
            _TabSelector(
              selectedIndex: _selectedTabIndex,
              onChanged: (index) => setState(() => _selectedTabIndex = index),
            ),
            
            const _TableHeader(),
            
            _buildCategoryHeader(),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentTickers.length,
              itemBuilder: (context, index) => _RankedAssetListItem(
                index: index + 1,
                ticker: currentTickers[index],
                res: res,
                isMarketActive: true, // Always show metrics in this view
                activeMode: _selectedTabIndex == 0 
                    ? _performanceMode 
                    : _selectedTabIndex == 1 
                        ? _activeMode 
                        : _fundingMode,
                maxValue: maxValue,
                type: _selectedTabIndex == 0 
                    ? 'perf' 
                    : _selectedTabIndex == 1 
                        ? 'active' 
                        : 'funding',
              ),
            ),
            
            SizedBox(height: res.spacing(32)),

            // Trader Distribution Charts
            _TraderDistributionSection(viewModel: viewModel, res: res),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader() {
    String label = '';
    List<String> options = [];
    String currentMode = '';
    Function(String) onToggle;

    if (_selectedTabIndex == 0) {
      label = 'PERFORMANCE';
      options = ['Gainers', 'Losers'];
      currentMode = _performanceMode;
      onToggle = (m) => setState(() => _performanceMode = m);
    } else if (_selectedTabIndex == 1) {
      label = 'MOST ACTIVE';
      options = ['Vol', 'OI'];
      currentMode = _activeMode;
      onToggle = (m) => setState(() => _activeMode = m);
    } else {
      label = 'FUNDING RATE';
      options = ['Highest', 'Lowest'];
      currentMode = _fundingMode;
      onToggle = (m) => setState(() => _fundingMode = m);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _selectedTabIndex == 0 ? Icons.trending_up : _selectedTabIndex == 1 ? Icons.bar_chart : Icons.currency_exchange,
                color: AppColors.brandAccent,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.surfaceBright.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.surfaceBright, width: 0.5),
            ),
            child: Row(
              children: options.map((opt) {
                final bool isSelected = currentMode == opt;
                return GestureDetector(
                  onTap: () => onToggle(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brandAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      opt,
                      style: GoogleFonts.jetBrainsMono(
                        color: isSelected ? Colors.black : AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(Responsive res) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E222D),
      highlightColor: const Color(0xFF3A3F4E),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(res.spacing(16)),
        child: Column(
          children: [
            Container(height: 80, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (i) => Container(width: 80, height: 32, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)))),
            ),
            const SizedBox(height: 24),
            Column(
              children: List.generate(10, (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(width: 24, height: 24, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(width: 60, height: 12, color: Colors.black),
                      const SizedBox(height: 4),
                      Container(width: 40, height: 8, color: Colors.black),
                    ])),
                    Container(width: 50, height: 16, color: Colors.black),
                  ],
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _TabSelector({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 1)),
      ),
      child: Row(
        children: [
          _tabItem('PERFORMANCE', 0),
          _tabItem('ACTIVITY', 1),
          _tabItem('FUNDING', 2),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    final bool isActive = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.jetBrainsMono(
                    color: isActive ? AppColors.brandAccent : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: double.infinity,
              color: isActive ? AppColors.brandAccent : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('#', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10))),
          const SizedBox(width: 8),
          Expanded(child: Text('ASSET / PRICE', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10))),
          Text('CHANGE', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _RankedAssetListItem extends StatelessWidget {
  final int index;
  final TickerModel ticker;
  final Responsive res;
  final bool isMarketActive;
  final String activeMode;
  final double maxValue;
  final String type; // 'perf', 'active', 'funding'

  const _RankedAssetListItem({
    required this.index,
    required this.ticker,
    required this.res,
    this.isMarketActive = false,
    this.activeMode = 'Vol',
    this.maxValue = 1.0,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = ticker.change24hPct >= 0;
    final color = isPositive ? AppColors.trendGreen : AppColors.trendRed;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index <= 3 
                ? AppColors.brandAccent.withValues(alpha: 0.2) 
                : Colors.transparent,
              border: Border.all(
                color: index <= 3 ? AppColors.brandAccent : AppColors.surfaceBright,
                width: 1,
              ),
            ),
            child: Text(
              '$index',
              style: GoogleFonts.jetBrainsMono(
                color: index <= 3 ? AppColors.brandAccent : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceBright.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.surfaceBright),
            ),
            child: _buildIcon(ticker.symbol.split(':').last.replaceAll('USDT', ''), ticker.iconUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ticker.symbol.split(':').last.replaceAll('USDT', ''),
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isMarketActive)
                      Text(
                        '${isPositive ? '+' : ''}${ticker.change24hPct.toStringAsFixed(2)}%',
                        style: GoogleFonts.jetBrainsMono(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else 
                      Text(
                        type == 'active' 
                          ? (activeMode == 'Vol' ? _formatValue(ticker.volume24hUSD) : _formatValue(ticker.openInterestUSD))
                          : type == 'perf'
                            ? '${isPositive ? '+' : ''}${ticker.change24hPct.toStringAsFixed(2)}%'
                            : '${ticker.funding8hPct > 0 ? '+' : ''}${(ticker.funding8hPct * 100).toStringAsFixed(4)}%',
                        style: GoogleFonts.jetBrainsMono(
                          color: type == 'perf' 
                            ? color 
                            : type == 'funding'
                              ? (ticker.funding8hPct >= 0 ? AppColors.trendRed : AppColors.trendGreen)
                              : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      Text(
                        '\$${ticker.lastPrice.toStringAsFixed(ticker.lastPrice < 1 ? 6 : 2)}',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    if (isMarketActive)
                      Text(
                        type == 'active'
                          ? '${isPositive ? '+' : ''}${ticker.change24hPct.toStringAsFixed(2)}%'
                          : type == 'perf'
                            ? (ticker.volume24hUSD > 0 ? _formatValue(ticker.volume24hUSD) : '')
                            : '${ticker.funding8hPct * 3 * 365 * 100 >= 0 ? '+' : ''}${(ticker.funding8hPct * 3 * 365 * 100).toStringAsFixed(1)}% APR',
                        style: GoogleFonts.jetBrainsMono(
                          color: (type == 'active' || type == 'perf') ? (type == 'active' ? color : AppColors.textSecondary) : (ticker.funding8hPct >= 0 ? AppColors.trendRed : AppColors.trendGreen),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                if (isMarketActive) ...[
                  const SizedBox(height: 8),
                  _buildAnimatedProgressBar(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double v) {
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(1)}K';
    return '\$${v.toStringAsFixed(0)}';
  }

  Widget _buildAnimatedProgressBar() {
    double value = 1.0;
    if (type == 'active') {
      value = activeMode == 'Vol' ? ticker.volume24hUSD : ticker.openInterestUSD;
    } else if (type == 'perf') {
      value = ticker.change24hPct.abs();
    } else if (type == 'funding') {
      value = ticker.funding8hPct.abs();
    }
    
    final double ratio = (value / maxValue).clamp(0.1, 1.0); // 0.1 min for visibility
    
    return Container(
      height: 3,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 1.0, // Parent takes full width
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCirc,
              width: (res.width - res.spacing(16) * 2 - 32 - 12 - 24 - 12) * ratio, // Apprx width calc
              decoration: BoxDecoration(
                color: type == 'perf' 
                  ? (ticker.change24hPct >= 0 ? AppColors.trendGreen : AppColors.trendRed).withValues(alpha: 0.6)
                  : type == 'funding'
                    ? (ticker.funding8hPct >= 0 ? AppColors.trendRed : AppColors.trendGreen).withValues(alpha: 0.6)
                    : AppColors.brandAccent.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(String symbol, String url) {
    final int hash = symbol.hashCode;
    final double hue = (hash % 360).toDouble();
    final color = HSVColor.fromAHSV(1.0, hue, 0.6, 0.8).toColor();

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        symbol.length >= 2 ? symbol.substring(0, 2).toUpperCase() : symbol.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  final HomeViewModel viewModel;
  const _ScreenHeader({required this.viewModel});

  String _fmt(double v) {
    if (v >= 1e12) return '\$${(v / 1e12).toStringAsFixed(1)}T';
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1)}M';
    return '\$${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1014),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceBright),
      ),
      child: Row(
        children: [
          _statBox('${viewModel.allTickers.length}', 'MARKETS', AppColors.textPrimary),
          _dividerV(),
          _statBox('${viewModel.gainersCount}', 'GAINERS', AppColors.trendGreen),
          _dividerV(),
          _statBox('${viewModel.losersCount}', 'LOSERS', AppColors.trendRed),
          _dividerV(),
          _statBox(_fmt(viewModel.totalVolume), 'VOL 24H', AppColors.textPrimary),
        ],
      ),
    );
  }

  Widget _statBox(String val, String label, Color valColor) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(label,
                  style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8)),
              const SizedBox(height: 6),
              Text(val,
                  style: GoogleFonts.jetBrainsMono(
                      color: valColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );

  Widget _dividerV() => Container(width: 1, height: 48, color: AppColors.surfaceBright);
}

class _MarketSentimentSection extends StatelessWidget {
  final List<TickerModel> tickers;
  final Responsive res;

  const _MarketSentimentSection({required this.tickers, required this.res});

  @override
  Widget build(BuildContext context) {
    if (tickers.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1014),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceBright),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ASSET PERFORMANCE',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 32),
          _DynamicAssetChart(tickers: tickers.take(8).toList(), res: res),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ACTIVE ASSETS DATA', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 9)),
              Text('Total Shown: ${tickers.length > 8 ? 8 : tickers.length}', style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DynamicAssetChart extends StatelessWidget {
  final List<TickerModel> tickers;
  final Responsive res;
  const _DynamicAssetChart({required this.tickers, required this.res});

  @override
  Widget build(BuildContext context) {
    if (tickers.isEmpty) return const SizedBox(height: 120);
    final maxChange = tickers.map((t) => t.change24hPct.abs()).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: tickers.map((t) {
              final double normalizedHeight = maxChange > 0 
                  ? (t.change24hPct.abs() / maxChange * 100).clamp(20.0, 120.0) 
                  : 60.0;
              final bool isPositive = t.change24hPct >= 0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${t.change24hPct.toStringAsFixed(1)}%',
                    style: GoogleFonts.jetBrainsMono(
                      color: isPositive ? AppColors.trendGreen : AppColors.trendRed,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: (res.width - 100) / (tickers.length.clamp(1, 8).toDouble()),
                    height: normalizedHeight,
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.trendGreen : AppColors.trendRed).withValues(alpha: 0.6),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: tickers.map((t) => SizedBox(
            width: (res.width - 100) / (tickers.length.clamp(1, 8).toDouble()),
            child: Text(
              t.symbol.split(':').last.replaceAll('USDT', ''),
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textPrimary,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 16),
        Text('ASSET SYMBOL', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 8, letterSpacing: 1.5)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Technical Trader Distribution Section - 2 Stacked Cards
// ─────────────────────────────────────────────────────────────────────────────
class _TraderDistributionSection extends StatelessWidget {
  final HomeViewModel viewModel;
  final Responsive res;

  const _TraderDistributionSection({required this.viewModel, required this.res});

  @override
  Widget build(BuildContext context) {
    if (viewModel.isDistLoading && viewModel.volumeDist == null && viewModel.valueDist == null) {
      return _buildLoading(res);
    }

    return Column(
      children: [
        _DistributionCard(
          title: 'Trader Distribution By Account Value',
          data: viewModel.valueDist,
          isAccountValue: true,
          res: res,
          onRetry: () => viewModel.fetchTraderDistribution(),
        ),
        const SizedBox(height: 16),
        _DistributionCard(
          title: 'Traders Volume By Account Volume',
          data: viewModel.volumeDist,
          isAccountValue: false,
          res: res,
          onRetry: () => viewModel.fetchTraderDistribution(),
        ),
      ],
    );
  }

  Widget _buildLoading(Responsive res) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E222D),
      highlightColor: const Color(0xFF3A3F4E),
      child: Column(
        children: [
          Container(height: 400, width: double.infinity, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          Container(height: 400, width: double.infinity, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }
}

class _DistributionCard extends StatefulWidget {
  final String title;
  final TraderDistributionModel? data;
  final bool isAccountValue;
  final Responsive res;
  final VoidCallback onRetry;

  const _DistributionCard({
    required this.title,
    required this.data,
    required this.isAccountValue,
    required this.res,
    required this.onRetry,
  });

  @override
  State<_DistributionCard> createState() => _DistributionCardState();
}

class _DistributionCardState extends State<_DistributionCard> {
  int _activeMetricIndex = 0; // 0: Value%/Volume%, 1: Trader% (Only for Value Chart)
  Set<String> _hiddenKeys = {};

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (data == null) return _buildErrorState();

    final segments = _getSegments(data);
    final visibleSegments = segments.where((s) => !_hiddenKeys.contains(s.key)).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1014),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceBright),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildLegendRow(segments),
          const SizedBox(height: 32),
          _buildDonutChart(visibleSegments, data),
          const SizedBox(height: 40),
          _buildDataTable(segments, data),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.title.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (widget.isAccountValue)
          Container(
            height: 28,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.surfaceBright.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                _toggleItem('Value %', 0),
                _toggleItem('Trader %', 1),
              ],
            ),
          ),
      ],
    );
  }

  Widget _toggleItem(String label, int index) {
    final isActive = _activeMetricIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeMetricIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: isActive ? Colors.black : AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendRow(List<DistributionSegment> segments) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: segments.map((s) {
        final bool isHidden = _hiddenKeys.contains(s.key);
        final color = isHidden ? AppColors.textSecondary.withValues(alpha: 0.3) : _getSegmentColor(s.key);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              if (_hiddenKeys.contains(s.key)) {
                _hiddenKeys.remove(s.key);
              } else {
                if (_hiddenKeys.length < segments.length - 1) { // Keep at least one visible
                  _hiddenKeys.add(s.key);
                }
              }
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                s.label.split(' (').first.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  color: isHidden ? AppColors.textSecondary.withValues(alpha: 0.5) : AppColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDonutChart(List<DistributionSegment> visibleSegments, TraderDistributionModel data) {
    if (visibleSegments.isEmpty) return const SizedBox(height: 224);

    // Calculate total for visible slices to redistribute visually to 100%
    final double visibleTotal = visibleSegments.fold(0.0, (sum, s) => sum + _getMetricValue(s));
    
    // Center label data from the largest visible slice
    final topSegment = visibleSegments.isNotEmpty 
        ? (List.from(visibleSegments)..sort((a, b) => _getMetricValue(b).compareTo(_getMetricValue(a)))).first as DistributionSegment
        : null;
    
    final centerPct = topSegment != null ? _getMetricValue(topSegment) : 0.0;
    final centerLabel = topSegment != null 
        ? (widget.isAccountValue 
            ? (_activeMetricIndex == 0 ? 'of value' : 'of traders')
            : topSegment.label.split(' (').first.toUpperCase())
        : '';

    return SizedBox(
      height: 224, // h-56 as per guide
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: widget.res.width * 0.16,
              startDegreeOffset: -90,
              sections: visibleSegments.map((s) {
                final double value = _getMetricValue(s);
                return PieChartSectionData(
                  color: _getSegmentColor(s.key),
                  value: value > 0 ? value : 0.001,
                  title: '',
                  radius: 24,
                  badgeWidget: null,
                );
              }).toList(),
            ),
            swapAnimationDuration: const Duration(milliseconds: 800),
            swapAnimationCurve: Curves.easeInOutExpo,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Column(
              key: ValueKey('${topSegment?.key}_$_activeMetricIndex'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${centerPct.toStringAsFixed(0)}%',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  centerLabel,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<DistributionSegment> segments, TraderDistributionModel data) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(child: Text('SEGMENT', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 8, fontWeight: FontWeight.bold))),
              if (widget.isAccountValue) ...[
                _tableHeaderCell('VAL%', _activeMetricIndex == 0),
                _tableHeaderCell('TRD%', _activeMetricIndex == 1),
              ] else ...[
                _tableHeaderCell('VOL%', true),
              ],
            ],
          ),
        ),
        Container(height: 1, width: double.infinity, color: AppColors.surfaceBright.withValues(alpha: 0.5)),
        const SizedBox(height: 8),
        ...segments.map((s) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: _getSegmentColor(s.key), borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 12),
                      Text(s.label.split(' (').first.toUpperCase(), style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (widget.isAccountValue) ...[
                  _tableDataCell('${s.valuePct.toStringAsFixed(1)}%', _activeMetricIndex == 0),
                  _tableDataCell('${s.traderPct.toStringAsFixed(1)}%', _activeMetricIndex == 1),
                ] else ...[
                  _tableDataCell('${s.valuePct.toStringAsFixed(1)}%', true),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _tableHeaderCell(String label, bool active) => SizedBox(
        width: 60,
        child: Text(
          label,
          textAlign: TextAlign.right,
          style: GoogleFonts.jetBrainsMono(
            color: active ? AppColors.brandAccent : AppColors.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _tableDataCell(String val, bool active) => SizedBox(
        width: 60,
        child: Text(
          val,
          textAlign: TextAlign.right,
          style: GoogleFonts.jetBrainsMono(
            color: active ? Colors.white : AppColors.textSecondary.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );

  double _getMetricValue(DistributionSegment s) {
    if (widget.isAccountValue) {
      return _activeMetricIndex == 0 ? s.valuePct : s.traderPct;
    }
    return s.valuePct; // volumePct in the model
  }

  List<DistributionSegment> _getSegments(TraderDistributionModel data) {
    final keys = widget.isAccountValue 
        ? ['whales', 'large', 'medium', 'small'] 
        : ['extreme', 'very_high', 'high', 'medium', 'low'];
    
    return keys.map((k) => data.distribution[k]).whereType<DistributionSegment>().toList();
  }

  Color _getSegmentColor(String key) {
    if (widget.isAccountValue) {
      final colors = {
        'whales': const Color(0xFF0D9488),
        'large': const Color(0xFF14B8A6),
        'medium': const Color(0xFF5EEAD4),
        'small': const Color(0xFF99F6E4),
      };
      return colors[key] ?? AppColors.brandAccent;
    } else {
      final colors = {
        'extreme': const Color(0xFF0F766E),
        'very_high': const Color(0xFF0D9488),
        'high': const Color(0xFF14B8A6),
        'medium': const Color(0xFF5EEAD4),
        'low': const Color(0xFFA7F3D0),
      };
      return colors[key] ?? AppColors.brandAccent;
    }
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1014),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceBright),
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart, color: AppColors.textSecondary, size: 48),
          const SizedBox(height: 16),
          Text(
            '${widget.title} Unavailable',
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onRetry,
            child: Text('RETRY', style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
