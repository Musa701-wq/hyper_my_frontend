import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../models/fee_intelligence_model.dart';
import '../services/fee_intelligence_service.dart';
import '../utils/app_colors.dart';
import '../utils/common_widgets.dart';
import '../utils/responsive.dart';
import 'defi_volume_chain_detail_screen.dart';
import 'defi_volume_explorer_screen.dart';
import 'defi_volume_compare_screen.dart';
import 'defi_volume_detail_screen.dart';
import '../widgets/error_state_widget.dart';

class DefiVolumeScreen extends StatefulWidget {
  const DefiVolumeScreen({super.key});

  @override
  State<DefiVolumeScreen> createState() => _DefiVolumeScreenState();
}

class _DefiVolumeScreenState extends State<DefiVolumeScreen> {
  final _service = FeeIntelligenceService();
  bool _isLoading = true;
  String _error = '';
  final String _dataType = 'dexs';
  
  FeeIntelligenceDashboard? _dashboard;
  FeeHistoryData? _history;
  String _selectedRange = '30d';
  bool _isHistoryLoading = false;

  bool _isBreakdown = false;
  List<String> _breakdownSlugs = [];
  FeeCompareResponse? _breakdownData;
  bool _isBreakdownLoading = false;
  List<FeeTopProtocol> _suggestionPool = [];
  final ScrollController _chartScrollController = ScrollController();
  List<ShowingTooltipIndicators> _historyShowingTooltips = [];
  List<ShowingTooltipIndicators> _breakdownShowingTooltips = [];

  final List<Color> compareColors = const [
    Color(0xFF38E54D), // Neon Green
    Color(0xFFFF0D66), // Pinkish Red
    Color(0xFF00E5FF), // Cyan
    Color(0xFFFFB300), // Orange
    Color(0xFF9D4EDD), // Purple
  ];

  List<FeeTopProtocol> _leaderboardProtocols = [];
  List<FeeTopProtocol> _chainsSuggestionPool = [];
  String _leaderboardType = 'protocols'; // 'protocols' or 'chains'
  int _touchedCategoryIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _chartScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final results = await Future.wait([
        _service.fetchDashboard(dataType: _dataType),
        _service.fetchHistory(range: _selectedRange, dataType: _dataType),
        _service.fetchProtocols(limit: 50, dataType: _dataType),
        _service.fetchChainsList(),
      ]);
      _dashboard = results[0] as FeeIntelligenceDashboard;
      _history = results[1] as FeeHistoryData;
      _suggestionPool = results[2] as List<FeeTopProtocol>;

      final rawChains = results[3] as List<DexChainMetrics>;
      _chainsSuggestionPool = rawChains.map((c) => FeeTopProtocol(
        name: c.chain,
        slug: c.chain.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-'),
        logo: null,
        category: 'Chain',
        chains: [c.chain],
        fees24h: c.totalVolume24h,
        change1d: 0.0,
        change7d: 0.0,
        change30d: 0.0,
        fees7d: c.totalVolume7d,
        fees30d: c.totalVolume30d,
        fees1y: c.totalVolume1y,
        feesAllTime: 0.0,
        children: [],
        childrenSlugs: [],
        protocolType: 'chain',
        annualized1y: 0.0,
        average1y: 0.0,
      )).toList();

      if (_leaderboardType == 'chains') {
        _leaderboardProtocols = _chainsSuggestionPool.take(15).toList();
      } else {
        _leaderboardProtocols = _suggestionPool.take(15).toList();
      }
      _isLoading = false;

      if (_breakdownSlugs.isEmpty && _dashboard != null && _dashboard!.topProtocols.isNotEmpty) {
        _breakdownSlugs = _dashboard!.topProtocols.take(2).map((e) => e.slug).toList();
      }

      setState(() {});
      _scrollToEnd();

      if (_isBreakdown) {
        await _loadBreakdownData();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHistory(String range) async {
    setState(() {
      _selectedRange = range;
      _isHistoryLoading = true;
    });
    try {
      final historyData = await _service.fetchHistory(range: range, dataType: _dataType);
      setState(() {
        _history = historyData;
        _isHistoryLoading = false;
      });
      _scrollToEnd();
      if (_isBreakdown) {
        await _loadBreakdownData();
      }
    } catch (e) {
      setState(() {
        _isHistoryLoading = false;
      });
    }
  }

  Future<void> _loadBreakdownData() async {
    if (!_isBreakdown) return;
    if (_breakdownSlugs.isEmpty) {
      if (_dashboard != null && _dashboard!.topProtocols.isNotEmpty) {
        _breakdownSlugs = _dashboard!.topProtocols.take(2).map((e) => e.slug).toList();
      }
    }
    if (_breakdownSlugs.isEmpty) return;

    setState(() {
      _isBreakdownLoading = true;
    });
    try {
      final data = await _service.fetchCompare(_breakdownSlugs, range: _selectedRange, dataType: _dataType);
      setState(() {
        _breakdownData = data;
        _isBreakdownLoading = false;
      });
      _scrollToEnd();
    } catch (e) {
      setState(() {
        _isBreakdownLoading = false;
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chartScrollController.hasClients) {
        _chartScrollController.jumpTo(_chartScrollController.position.maxScrollExtent);
      }
    });
  }

  String _fmtMoney(double v) {
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(1)}K';
    return '\$${v.toStringAsFixed(0)}';
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
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.brandAccent, size: res.fontSize(20)),
          ),
          title: Text(
            'Volume Intelligence',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: res.fontSize(15),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const DefiVolumeCompareScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.brandAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.compare_arrows_rounded,
                          color: const Color(0xFF0F1115),
                          size: res.fontSize(13),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Compare',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0F1115),
                            fontSize: res.fontSize(10),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _isLoading 
            ? _buildLoadingSkeleton(res)
            : _error.isNotEmpty 
            ? _buildErrorView(res)
            : RefreshIndicator(
                onRefresh: _loadAllData,
                color: AppColors.brandAccent,
                backgroundColor: const Color(0xFF16191E),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: res.spacing(14), vertical: res.spacing(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(res),
                      SizedBox(height: res.spacing(14)),
                      _buildKpiGrid(res),
                      SizedBox(height: res.spacing(16)),
                      _buildHistoryChartCard(res),
                      SizedBox(height: res.spacing(16)),
                      _buildDashboardTopProtocolsCard(res),
                      SizedBox(height: res.spacing(16)),
                      _buildCategoryBreakdownCard(res),
                      SizedBox(height: res.spacing(16)),
                      _buildTopProtocolsCard(res),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTitleSection(Responsive res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DeFi Volume Intelligence',
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: res.fontSize(20),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Real-time protocol volume rankings, history, and analytics.',
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: res.fontSize(11),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(Responsive res) {
    return ErrorStateWidget(
      errorMessage: _error.isEmpty
          ? 'Failed to load volume intelligence data. Please check your network connection.'
          : _error,
      onRetry: _loadAllData,
    );
  }

  Widget _buildKpiGrid(Responsive res) {
    final s = _dashboard?.stats;
    if (s == null) return const SizedBox.shrink();

    final isUp = s.change1d >= 0;

    final item1 = _kpiItem(
      title: 'TOTAL VOLUME (24H)',
      value: _fmtMoney(s.total24h),
      bottomWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down, 
            color: isUp ? AppColors.trendGreen : AppColors.trendRed, size: res.fontSize(14)),
          Text(
            '${isUp ? '+' : ''}${s.change1d.toStringAsFixed(2)}% vs yesterday',
            style: GoogleFonts.inter(
              color: isUp ? AppColors.trendGreen : AppColors.trendRed,
              fontSize: res.fontSize(9),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      res: res,
    );

    final item2 = _kpiItem(
      title: 'TOTAL VOLUME (7D)',
      value: _fmtMoney(s.total7d),
      bottomWidget: Text(
        'Weekly cumulative volume',
        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(9)),
      ),
      res: res,
    );

    final item3 = _kpiItem(
      title: 'ACTIVE PROTOCOLS',
      value: NumberFormat('#,##0').format(s.activeProtocols),
      bottomWidget: Text(
        'With trade volume (24h)',
        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(9)),
      ),
      res: res,
    );

    final item4 = _kpiItem(
      title: 'ACTIVE CHAINS',
      value: NumberFormat('#,##0').format(s.activeChains),
      bottomWidget: Text(
        'Integrated ecosystems',
        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(9)),
      ),
      res: res,
    );

    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: res.spacing(16),
        vertical: res.spacing(14),
      ),
      child: res.isMobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: item1),
                    Container(
                      width: 1,
                      height: res.spacing(55),
                      margin: EdgeInsets.symmetric(horizontal: res.spacing(14)),
                      color: Colors.white.withOpacity(0.06),
                    ),
                    Expanded(child: item2),
                  ],
                ),
                Divider(
                  color: Colors.white.withOpacity(0.06),
                  height: res.spacing(24),
                  thickness: 1,
                ),
                Row(
                  children: [
                    Expanded(child: item3),
                    Container(
                      width: 1,
                      height: res.spacing(55),
                      margin: EdgeInsets.symmetric(horizontal: res.spacing(14)),
                      color: Colors.white.withOpacity(0.06),
                    ),
                    Expanded(child: item4),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: item1),
                Container(
                  width: 1,
                  height: res.spacing(60),
                  margin: EdgeInsets.symmetric(horizontal: res.spacing(16)),
                  color: Colors.white.withOpacity(0.06),
                ),
                Expanded(child: item2),
                Container(
                  width: 1,
                  height: res.spacing(60),
                  margin: EdgeInsets.symmetric(horizontal: res.spacing(16)),
                  color: Colors.white.withOpacity(0.06),
                ),
                Expanded(child: item3),
                Container(
                  width: 1,
                  height: res.spacing(60),
                  margin: EdgeInsets.symmetric(horizontal: res.spacing(16)),
                  color: Colors.white.withOpacity(0.06),
                ),
                Expanded(child: item4),
              ],
            ),
    );
  }

  Widget _kpiItem({
    required String title,
    required String value,
    required Widget bottomWidget,
    required Responsive res,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: res.fontSize(8.5),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: res.fontSize(16),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        bottomWidget,
      ],
    );
  }

  Widget _buildHistoryChartCard(Responsive res) {
    return AppCard(
      padding: EdgeInsets.all(res.spacing(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Global Volume Trend',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: res.fontSize(13),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isBreakdown
                          ? 'Protocol breakdown comparative analysis'
                          : 'Total daily volume across all DeFi protocols',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: res.fontSize(9.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildAllBreakdownToggle(res),
              const SizedBox(width: 8),
              _buildRangeSelector(res),
            ],
          ),
          if (_isBreakdown) ...[
            const SizedBox(height: 8),
            _buildSearchRow(res),
          ],
          SizedBox(height: res.spacing(16)),
          if (!_isBreakdown && _isHistoryLoading && _history == null)
            SizedBox(
              height: res.spacing(180),
              child: const Center(child: CircularProgressIndicator(color: AppColors.brandAccent, strokeWidth: 2)),
            )
          else if (_isBreakdown && _isBreakdownLoading && _breakdownData == null)
            SizedBox(
              height: res.spacing(180),
              child: const Center(child: CircularProgressIndicator(color: AppColors.brandAccent, strokeWidth: 2)),
            )
          else if (!_isBreakdown && (_history == null || _history!.points.isEmpty))
            SizedBox(
              height: res.spacing(180),
              child: Center(
                child: Text(
                  'No trend history data available',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(11)),
                ),
              ),
            )
          else
            _buildHistoryLineChart(res),
          if (_isBreakdown) _buildSelectedPillsRow(res),
        ],
      ),
    );
  }

  Widget _buildAllBreakdownToggle(Responsive res) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.08),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (_isBreakdown) {
                setState(() {
                  _isBreakdown = false;
                });
                _scrollToEnd();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: !_isBreakdown ? AppColors.brandAccent : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                ),
              ),
              child: Text(
                'All',
                style: GoogleFonts.inter(
                  color: !_isBreakdown ? Colors.black : AppColors.textSecondary,
                  fontSize: res.fontSize(9.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (!_isBreakdown) {
                setState(() {
                  _isBreakdown = true;
                });
                _loadBreakdownData();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _isBreakdown ? AppColors.brandAccent : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
              ),
              child: Text(
                'Breakdown',
                style: GoogleFonts.inter(
                  color: _isBreakdown ? Colors.black : AppColors.textSecondary,
                  fontSize: res.fontSize(9.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow(Responsive res) {
    return SizedBox(
      height: 38,
      child: Autocomplete<FeeTopProtocol>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<FeeTopProtocol>.empty();
          }
          return _suggestionPool.where((p) {
            final query = textEditingValue.text.toLowerCase();
            return p.name.toLowerCase().contains(query) ||
                p.slug.toLowerCase().contains(query) ||
                p.category.toLowerCase().contains(query);
          });
        },
        displayStringForOption: (option) => option.name,
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          return SizedBox(
            height: 36,
            child: TextField(
              controller: textEditingController,
              focusNode: focusNode,
              cursorColor: AppColors.brandAccent,
              style: GoogleFonts.inter(color: Colors.white, fontSize: res.fontSize(10.5)),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceBright.withOpacity(0.1),
                hintText: '+ Add protocol...',
                hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withOpacity(0.6), fontSize: res.fontSize(10)),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary.withOpacity(0.6), size: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.brandAccent.withOpacity(0.5)),
                ),
              ),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 260,
                constraints: const BoxConstraints(maxHeight: 200),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF14171C),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.white.withOpacity(0.02)),
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                option.logo ?? '',
                                width: 16,
                                height: 16,
                                errorBuilder: (_, __, ___) => const Icon(Icons.token_outlined, color: AppColors.brandAccent, size: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option.name,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: res.fontSize(10.5), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
        onSelected: (FeeTopProtocol selection) {
          if (!_breakdownSlugs.contains(selection.slug)) {
            if (_breakdownSlugs.length >= 5) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Compare limit is 5 protocols')),
              );
              return;
            }
            setState(() {
              _breakdownSlugs.add(selection.slug);
            });
            _loadBreakdownData();
          }
        },
      ),
    );
  }

  Widget _buildSelectedPillsRow(Responsive res) {
    if (_breakdownSlugs.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 10),
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _breakdownSlugs.length,
        itemBuilder: (context, index) {
          final slug = _breakdownSlugs[index];
          final match = _suggestionPool.firstWhere(
            (p) => p.slug == slug,
            orElse: () => FeeTopProtocol(
              name: slug.toUpperCase(),
              slug: slug,
              category: 'Other',
              chains: [],
              fees24h: 0,
              change1d: 0,
              change7d: 0,
              change30d: 0,
              fees7d: 0,
              fees30d: 0,
              fees1y: 0,
              feesAllTime: 0,
              children: [],
              childrenSlugs: [],
              protocolType: 'protocol',
              annualized1y: 0.0,
              average1y: 0.0,
            ),
          );
          final color = compareColors[index % compareColors.length];

          return Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  match.name,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: res.fontSize(9.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_breakdownSlugs.length > 2) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _breakdownSlugs.removeAt(index);
                      });
                      _loadBreakdownData();
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.6),
                      size: 10,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRangeSelector(Responsive res) {
    final ranges = ['7D', '30D', '90D', '1Y', 'ALL'];
    final current = _selectedRange.toUpperCase();
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.08),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          dropdownColor: const Color(0xFF14171C),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 14),
          style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: res.fontSize(10), fontWeight: FontWeight.bold),
          isDense: true,
          onChanged: (v) {
            if (v != null) {
              _loadHistory(v.toLowerCase());
            }
          },
          items: ranges.map((r) => DropdownMenuItem(
            value: r,
            child: Text(
              r,
              style: GoogleFonts.jetBrainsMono(
                color: r == current ? AppColors.brandAccent : AppColors.textSecondary,
                fontSize: res.fontSize(10),
                fontWeight: r == current ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildHistoryLineChart(Responsive res) {
    if (_isBreakdown) {
      if (_isBreakdownLoading && _breakdownData == null) {
        return SizedBox(
          height: res.spacing(180),
          child: const Center(child: CircularProgressIndicator(color: AppColors.brandAccent, strokeWidth: 2)),
        );
      }
      if (_breakdownData == null || _breakdownData!.labels.isEmpty) {
        return SizedBox(
          height: res.spacing(180),
          child: Center(
            child: Text(
              'No breakdown data available',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(11)),
            ),
          ),
        );
      }
      return _buildScrollableBreakdownChart(res);
    } else {
      return _buildScrollableAllChart(res);
    }
  }

  Widget _buildScrollableAllChart(Responsive res) {
    final points = _history!.points;
    final spots = points.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final values = points.map((e) => e.value).toList();
    final minY = values.reduce((a, b) => a < b ? a : b) * 0.95;
    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.05;

    final step = (maxY - minY) / 3 > 0 ? (maxY - minY) / 3 : 1.0;
    final yLabels = [minY, minY + step, minY + 2 * step, maxY];
    final chartWidth = (spots.length * 8.0).clamp(400.0, 1200.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          height: res.spacing(180) - 20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: yLabels.reversed.map((val) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  _fmtMoney(val),
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: res.fontSize(8.5),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _chartScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: chartWidth,
              height: res.spacing(180),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: step,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.03),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (spots.length / 4).clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                          final date = points[idx].date;
                          final label = DateFormat('MMM d').format(date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary.withOpacity(0.5),
                                fontSize: res.fontSize(8.5),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: spots.length.toDouble() - 1,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.brandAccent,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.brandAccent.withOpacity(0.12),
                            AppColors.brandAccent.withOpacity(0.0)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableBreakdownChart(Responsive res) {
    final labels = _breakdownData!.labels;
    final series = _breakdownData!.series;

    double maxVal = 100.0;
    for (final key in series.keys) {
      for (final val in series[key]!) {
        if (val > maxVal) maxVal = val;
      }
    }
    maxVal = maxVal * 1.05;
    final step = maxVal / 3 > 0 ? maxVal / 3 : 1.0;
    final yLabels = [0.0, step, 2 * step, maxVal];

    final chartWidth = (labels.length * 8.0).clamp(400.0, 1200.0);

    final lineBars = <LineChartBarData>[];
    int lineIdx = 0;
    for (final slug in _breakdownSlugs) {
      if (series.containsKey(slug)) {
        final list = series[slug]!;
        final spots = <FlSpot>[];
        for (int i = 0; i < list.length; i++) {
          spots.add(FlSpot(i.toDouble(), list[i]));
        }
        final color = compareColors[lineIdx % compareColors.length];
        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        );
      }
      lineIdx++;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          height: res.spacing(180) - 20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: yLabels.reversed.map((val) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  _fmtMoney(val),
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: res.fontSize(8.5),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _chartScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: chartWidth,
              height: res.spacing(180),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: step,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.03),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (labels.length / 4).clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                          final date = labels[idx];
                          final label = DateFormat('MMM d').format(date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary.withOpacity(0.5),
                                fontSize: res.fontSize(8.5),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: labels.length.toDouble() - 1,
                  minY: 0,
                  maxY: maxVal,
                  lineBarsData: lineBars,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardTopProtocolsCard(Responsive res) {
    final top = _dashboard?.topProtocols;
    if (top == null || top.isEmpty) return const SizedBox.shrink();

    final displays = top.take(5).toList();

    return AppCard(
      padding: EdgeInsets.all(res.spacing(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Protocols by Volume (24h)',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: res.fontSize(13),
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const DefiVolumeExplorerScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
                child: Text(
                  'View all',
                  style: GoogleFonts.inter(
                    color: AppColors.brandAccent,
                    fontSize: res.fontSize(11),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Parents only · sorted by volume',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: res.fontSize(9.5),
            ),
          ),
          SizedBox(height: res.spacing(14)),
          ...displays.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final p = entry.value;
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => DefiVolumeDetailScreen(protocol: p),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Text(
                      '#$idx',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textSecondary,
                        fontSize: res.fontSize(11),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        p.logo ?? '',
                        width: 20,
                        height: 20,
                        errorBuilder: (_, __, ___) => const Icon(Icons.token_outlined, color: AppColors.brandAccent, size: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: res.fontSize(11.5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1.5),
                          Text(
                            p.category,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: res.fontSize(9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmtMoney(p.fees24h),
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white,
                            fontSize: res.fontSize(12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              p.change1d >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                              color: p.change1d >= 0 ? AppColors.trendGreen : AppColors.trendRed,
                              size: 14,
                            ),
                            Text(
                              '${p.change1d >= 0 ? '+' : ''}${p.change1d.toStringAsFixed(1)}%',
                              style: GoogleFonts.inter(
                                color: p.change1d >= 0 ? AppColors.trendGreen : AppColors.trendRed,
                                fontSize: res.fontSize(9),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(Responsive res) {
    final breakdown = _dashboard?.categoryBreakdown ?? [];
    if (breakdown.isEmpty) return const SizedBox.shrink();

    // Filter categories above 0 fees, sort from highest to lowest
    final sortedBreakdown = breakdown
        .where((element) => element.fees > 0)
        .toList()
      ..sort((a, b) => b.fees.compareTo(a.fees));

    if (sortedBreakdown.isEmpty) return const SizedBox.shrink();

    List<FeeCategoryBreakdown> displayBreakdown;
    if (sortedBreakdown.length > 3) {
      final topTwo = sortedBreakdown.take(2).toList();
      final othersFees = sortedBreakdown.skip(2).map((e) => e.fees).fold(0.0, (a, b) => a + b);
      topTwo.add(FeeCategoryBreakdown(category: 'Others', fees: othersFees));
      displayBreakdown = topTwo;
    } else {
      displayBreakdown = sortedBreakdown;
    }

    final totalTop8Fees = displayBreakdown.map((e) => e.fees).fold(0.0, (a, b) => a + b);

    return AppCard(
      padding: EdgeInsets.all(res.spacing(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Volume by Category',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: res.fontSize(13),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Comparative market share (24h)',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: res.fontSize(9.5),
            ),
          ),
          SizedBox(height: res.spacing(18)),
          if (totalTop8Fees > 0)
            Center(
              child: SizedBox(
                height: res.spacing(200),
                width: res.spacing(200),
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedCategoryIndex = -1;
                            return;
                          }
                          _touchedCategoryIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 0,
                    centerSpaceRadius: 0,
                    startDegreeOffset: -90,
                    sections: displayBreakdown.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final val = entry.value;
                      final isTouched = _touchedCategoryIndex == idx;
                      final radius = isTouched ? res.spacing(100) : res.spacing(90);
                      final pct = totalTop8Fees > 0 ? (val.fees / totalTop8Fees) : 0.0;

                      return PieChartSectionData(
                        color: _getCategoryColor(val.category, idx),
                        value: val.fees,
                        radius: radius,
                        showTitle: true,
                        title: '${(pct * 100).toStringAsFixed(0)}%',
                        titlePositionPercentageOffset: 0.6,
                        borderSide: BorderSide.none,
                        titleStyle: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: res.fontSize(10.5),
                          fontWeight: FontWeight.w800,
                          shadows: [
                            const Shadow(
                              color: Colors.black54,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          SizedBox(height: res.spacing(20)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: displayBreakdown.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final pct = totalTop8Fees > 0 ? (item.fees / totalTop8Fees) : 0.0;
              final isTouched = _touchedCategoryIndex == idx;
              final color = _getCategoryColor(item.category, idx);

              return GestureDetector(
                onTapDown: (_) {
                  setState(() => _touchedCategoryIndex = idx);
                },
                onTapCancel: () {
                  setState(() => _touchedCategoryIndex = -1);
                },
                onTapUp: (_) {
                  setState(() => _touchedCategoryIndex = -1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: isTouched 
                        ? color.withOpacity(0.15) 
                        : AppColors.surfaceBright.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isTouched 
                          ? color.withOpacity(0.4) 
                          : AppColors.surfaceBright.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.category.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          color: isTouched ? Colors.white : AppColors.textSecondary,
                          fontSize: res.fontSize(9.5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(pct * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          color: isTouched ? color : AppColors.textSecondary.withOpacity(0.6),
                          fontSize: res.fontSize(9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProtocolsCard(Responsive res) {
    return AppCard(
      padding: EdgeInsets.all(res.spacing(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 28,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceBright.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTabToggleItem('PROTOCOLS', _leaderboardType == 'protocols', res, () {
                      if (_leaderboardType != 'protocols') {
                        setState(() {
                          _leaderboardType = 'protocols';
                          _leaderboardProtocols = _suggestionPool.take(15).toList();
                        });
                      }
                    }),
                    _buildTabToggleItem('CHAINS', _leaderboardType == 'chains', res, () {
                      if (_leaderboardType != 'chains') {
                        setState(() {
                          _leaderboardType = 'chains';
                          _leaderboardProtocols = _chainsSuggestionPool.take(15).toList();
                        });
                      }
                    }),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const DefiVolumeExplorerScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
                child: Text(
                  'View Full Rankings',
                  style: GoogleFonts.inter(
                    color: AppColors.brandAccent,
                    fontSize: res.fontSize(11),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Top 15 sorted by 24h volume',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: res.fontSize(9.5),
            ),
          ),
          SizedBox(height: res.spacing(16)),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'NAME',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(8.5), fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '24H VOLUME',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(8.5), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '1D CHANGE',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(8.5), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: res.spacing(8)),
          Divider(color: Colors.white.withOpacity(0.04), height: 1),
          // Rows
          ..._leaderboardProtocols.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final p = entry.value;
            final isUp = p.change1d >= 0;

            return GestureDetector(
              onTap: () {
                if (_leaderboardType == 'chains') {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => DefiVolumeChainDetailScreen(chain: p.name),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => DefiVolumeDetailScreen(protocol: p),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          SizedBox(
                            width: res.columnWidth(24.0),
                            child: Text(
                              '$idx',
                              style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary.withOpacity(0.5), fontSize: res.fontSize(10), fontWeight: FontWeight.bold),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              p.logo ?? '',
                              width: 18,
                              height: 18,
                              errorBuilder: (_, __, ___) => _fallbackLogo(p.name, res),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: res.fontSize(11), fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_leaderboardType == 'protocols') ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    p.chains.isNotEmpty ? p.chains.join(', ') : 'Off Chain',
                                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(8.5)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _fmtMoney(p.fees24h),
                          style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: res.fontSize(11), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                            color: isUp ? AppColors.trendGreen : AppColors.trendRed,
                            size: res.fontSize(14),
                          ),
                          Text(
                            '${isUp ? '+' : ''}${p.change1d.toStringAsFixed(1)}%',
                            style: GoogleFonts.inter(
                              color: isUp ? AppColors.trendGreen : AppColors.trendRed,
                              fontSize: res.fontSize(10),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _fallbackLogo(String name, Responsive res) {
    return Container(
      width: res.spacing(14),
      height: res.spacing(14),
      color: AppColors.surfaceBright.withOpacity(0.12),
      child: const Icon(Icons.token_outlined, color: AppColors.brandAccent, size: 8),
    );
  }

  Color _getBarColor(int index) {
    const colors = [
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF06B6D4),
      Color(0xFF6366F1),
      Color(0xFF14B8A6),
      Color(0xFFEAB308),
      Color(0xFFD946EF),
    ];
    return colors[index % colors.length];
  }

  Color _getCategoryColor(String category, [int index = 0]) {
    final normalized = category.toLowerCase().trim();
    switch (normalized) {
      case 'others':
        return const Color(0xFF8E9AA6);
      case 'stablecoin issuer':
        return const Color(0xFF2563EB);
      case 'dexs':
        return const Color(0xFF00E5FF);
      case 'chain':
        return const Color(0xFF38E54D);
      case 'derivatives':
        return const Color(0xFFF97316);
      case 'liquid staking':
        return const Color(0xFF9D4EDD);
      case 'staking pool':
        return const Color(0xFF06B6D4);
      case 'lending':
        return const Color(0xFFFFB300);
      case 'rwa':
        return const Color(0xFF10B981);
      case 'bridge':
        return const Color(0xFFEF4444);
      case 'prediction market':
        return const Color(0xFFEC4899);
      case 'launchpad':
        return const Color(0xFFF43F5E);
      case 'otc marketplace':
        return const Color(0xFF84CC16);
      case 'trading app':
        return const Color(0xFFEAB308);
      case 'telegram bot':
        return const Color(0xFF8B5CF6);
      case 'yield':
        return const Color(0xFF14B8A6);
      default:
        const list = [
          Color(0xFF3B82F6),
          Color(0xFF10B981),
          Color(0xFFF59E0B),
          Color(0xFF8B5CF6),
          Color(0xFFEC4899),
          Color(0xFF14B8A6),
          Color(0xFFF43F5E),
          Color(0xFF06B6D4),
        ];
        return list[index % list.length];
    }
  }

  Widget _buildTabToggleItem(String label, bool isSelected, Responsive res, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontSize: res.fontSize(9),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(Responsive res) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: res.spacing(14), vertical: res.spacing(10)),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF1E222D),
        highlightColor: const Color(0xFF3A3F4E),
        period: const Duration(milliseconds: 1500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 180, height: 22, color: Colors.white),
            const SizedBox(height: 6),
            Container(width: 250, height: 12, color: Colors.white),
            SizedBox(height: res.spacing(14)),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: res.spacing(10),
              mainAxisSpacing: res.spacing(10),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: List.generate(4, (index) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              )),
            ),
            SizedBox(height: res.spacing(16)),
            Container(
              height: res.spacing(240),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            SizedBox(height: res.spacing(16)),
            Container(
              height: res.spacing(200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
