import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/fee_intelligence_model.dart';
import '../services/fee_intelligence_service.dart';
import '../utils/app_colors.dart';
import '../utils/common_widgets.dart';
import '../utils/responsive.dart';
import '../widgets/error_state_widget.dart';


class FeeCompareScreen extends StatefulWidget {
  const FeeCompareScreen({super.key});

  @override
  State<FeeCompareScreen> createState() => _FeeCompareScreenState();
}

class _FeeCompareScreenState extends State<FeeCompareScreen> {
  final FeeIntelligenceService _service = FeeIntelligenceService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _chartScrollController = ScrollController();

  bool _isLoading = false;
  String _error = '';

  // Selected protocols to compare (max 5)
  final List<FeeTopProtocol> _selectedProtocols = [];
  
  // All protocols retrieved for suggestion list search
  List<FeeTopProtocol> _suggestionPool = [];
  List<FeeTopProtocol> _filteredSuggestions = [];
  bool _showSuggestions = false;

  // Comparison response data
  FeeCompareResponse? _compareData;
  String _selectedRange = '90d';
  List<ShowingTooltipIndicators> _showingTooltips = [];

  static const List<Color> compareColors = [
    AppColors.brandAccent,        // Teal/Green
    Color(0xFFE91E63),            // Pink
    Color(0xFF9C27B0),            // Purple
    Color(0xFF2196F3),            // Blue
    Color(0xFFFF9800),            // Orange
  ];

  @override
  void initState() {
    super.initState();
    _loadSuggestionPool();
    _searchFocus.addListener(() {
      setState(() {
        _showSuggestions = _searchFocus.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _chartScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestionPool() async {
    try {
      final list = await _service.fetchProtocols(limit: 50);
      setState(() {
        _suggestionPool = list;
        _filteredSuggestions = list;
      });
    } catch (e) {
      debugPrint('Error fetching comparison suggestions pool: $e');
    }
  }

  void _onSearchChanged(String text) {
    if (text.isEmpty) {
      setState(() {
        _filteredSuggestions = _suggestionPool;
      });
    } else {
      final query = text.toLowerCase();
      setState(() {
        _filteredSuggestions = _suggestionPool.where((p) {
          return p.name.toLowerCase().contains(query) ||
              p.category.toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  void _scrollToLatestData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chartScrollController.hasClients) {
        _chartScrollController.jumpTo(_chartScrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _updateComparisonData() async {
    if (_selectedProtocols.isEmpty) {
      setState(() {
        _compareData = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final slugs = _selectedProtocols.map((e) => e.slug).toList();
      final data = await _service.fetchCompare(slugs, range: _selectedRange);
      setState(() {
        _compareData = data;
        _isLoading = false;
      });
      _scrollToLatestData();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _addProtocol(FeeTopProtocol protocol) {
    if (_selectedProtocols.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum 5 protocols can be compared at one time.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppColors.lossRed,
        ),
      );
      return;
    }

    if (_selectedProtocols.any((element) => element.slug == protocol.slug)) {
      return;
    }

    setState(() {
      _selectedProtocols.add(protocol);
      _searchController.clear();
      _filteredSuggestions = _suggestionPool;
      _showSuggestions = false;
      _searchFocus.unfocus();
    });

    _updateComparisonData();
  }

  void _removeProtocol(String slug) {
    setState(() {
      _selectedProtocols.removeWhere((p) => p.slug == slug);
    });
    _updateComparisonData();
  }

  String _fmtMoney(double v) {
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(1)}K';
    return '\$${v.toStringAsFixed(0)}';
  }

  String _fmtPct(double v) {
    return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
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
            'Head-to-Head Comparison',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: res.fontSize(15),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: GestureDetector(
          onTap: () {
            if (_searchFocus.hasFocus) {
              _searchFocus.unfocus();
            }
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: res.spacing(16), vertical: res.spacing(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderIntro(res),
                SizedBox(height: res.spacing(12)),
                _buildSearchAutoComplete(res),
                SizedBox(height: res.spacing(12)),
                _buildSelectedPills(res),
                SizedBox(height: res.spacing(16)),
                _buildMainComparisonContainer(res),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIntro(Responsive res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Protocol Comparison',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: res.fontSize(18),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Compare daily fee generation of up to 5 protocols.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: res.fontSize(11),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAutoComplete(Responsive res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceBright.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _searchFocus.hasFocus
                  ? AppColors.brandAccent
                  : Colors.white.withOpacity(0.06),
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            onChanged: _onSearchChanged,
            style: GoogleFonts.inter(color: Colors.white, fontSize: res.fontSize(13)),
            cursorColor: AppColors.brandAccent,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              hintText: 'Add protocol to compare...',
              hintStyle: GoogleFonts.inter(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: res.fontSize(13),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: _searchFocus.hasFocus ? AppColors.brandAccent : AppColors.textSecondary,
                size: res.fontSize(18),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      child: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                    )
                  : null,
            ),
          ),
        ),
        if (_showSuggestions && _filteredSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: const Color(0xFF16191E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _filteredSuggestions.length,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.04), height: 1),
              itemBuilder: (context, index) {
                final p = _filteredSuggestions[index];
                final isAdded = _selectedProtocols.any((e) => e.slug == p.slug);

                return ListTile(
                  dense: true,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      p.logo ?? '',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 24,
                        height: 24,
                        color: AppColors.surfaceBright.withOpacity(0.12),
                        child: const Icon(Icons.token_outlined, color: AppColors.brandAccent, size: 12),
                      ),
                    ),
                  ),
                  title: Text(
                    p.name,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: res.fontSize(12), fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    p.category,
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(10)),
                  ),
                  trailing: isAdded
                      ? Text(
                          'Added',
                          style: GoogleFonts.inter(
                            color: AppColors.brandAccent,
                            fontSize: res.fontSize(11),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.brandAccent,
                          size: res.fontSize(18),
                        ),
                  onTap: () {
                    if (!isAdded) {
                      _addProtocol(p);
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedPills(Responsive res) {
    if (_selectedProtocols.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_selectedProtocols.length, (index) {
        final p = _selectedProtocols[index];
        final color = compareColors[index % compareColors.length];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                p.name,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: res.fontSize(11),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _removeProtocol(p.slug),
                child: Icon(
                  Icons.close,
                  color: Colors.white.withOpacity(0.7),
                  size: 13,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMainComparisonContainer(Responsive res) {
    if (_selectedProtocols.isEmpty) {
      return _buildEmptyState(res);
    }

    if (_isLoading && _compareData == null) {
      return _buildLoadingState(res);
    }

    if (_error.isNotEmpty) {
      return _buildErrorState(res);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChartCard(res),
        SizedBox(height: res.spacing(16)),
        _buildMetricsTableCard(res),
      ],
    );
  }

  Widget _buildEmptyState(Responsive res) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows_rounded,
            color: AppColors.textSecondary.withOpacity(0.3),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Search and add protocols above to compare.',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: res.fontSize(12),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Responsive res) {
    return Container(
      width: double.infinity,
      height: 240,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        color: AppColors.brandAccent,
      ),
    );
  }

  Widget _buildErrorState(Responsive res) {
    return ErrorStateWidget(
      errorMessage: _error.isEmpty
          ? 'Failed to fetch comparison details. Please check your network connection.'
          : _error,
      onRetry: _updateComparisonData,
    );
  }

  Widget _buildChartCard(Responsive res) {
    if (_compareData == null || _compareData!.labels.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      padding: EdgeInsets.all(res.spacing(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fee Comparison (${_selectedRange.toUpperCase()})',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: res.fontSize(13),
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildRangeSwitches(res),
            ],
          ),
          SizedBox(height: res.spacing(20)),
          _buildLineChartWidget(res),
        ],
      ),
    );
  }

  Widget _buildRangeSwitches(Responsive res) {
    final ranges = ['7d', '30d', '90d', '1y', 'all'];

    return Row(
      children: ranges.map((r) {
        final isActive = _selectedRange == r;
        return GestureDetector(
          onTap: () {
            if (_selectedRange != r) {
              setState(() {
                _selectedRange = r;
              });
              _updateComparisonData();
            }
          },
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? AppColors.brandAccent.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive ? AppColors.brandAccent.withOpacity(0.3) : Colors.transparent,
              ),
            ),
            child: Text(
              r.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                color: isActive ? AppColors.brandAccent : AppColors.textSecondary,
                fontSize: res.fontSize(9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLineChartWidget(Responsive res) {
    final labels = _compareData!.labels;
    final series = _compareData!.series;

    // Calculate overall min/max bounds representation for Y scale
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    final lineBars = <LineChartBarData>[];

    for (int index = 0; index < _selectedProtocols.length; index++) {
      final p = _selectedProtocols[index];
      final color = compareColors[index % compareColors.length];
      final records = series[p.slug];

      if (records == null || records.isEmpty) continue;

      final spots = <FlSpot>[];
      final len = labels.length < records.length ? labels.length : records.length;
      for (int i = 0; i < len; i++) {
        final val = records[i];
        spots.add(FlSpot(i.toDouble(), val));

        if (val < minY) minY = val;
        if (val > maxY) maxY = val;
      }

      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 2.0,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [color.withOpacity(0.08), color.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }

    if (lineBars.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Text(
          'No chart history points found.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
      );
    }

    if (minY == double.infinity) minY = 0;
    if (maxY == double.negativeInfinity) maxY = 1e6;

    final diff = maxY - minY;
    minY = (minY - diff * 0.05).clamp(0, double.infinity);
    maxY = maxY + diff * 0.05;

    final double chartHeight = res.spacing(180);
    const double bottomReserved = 20.0;
    final double gridHeight = chartHeight - bottomReserved;

    final yLabels = [
      maxY,
      minY + (maxY - minY) * (2 / 3),
      minY + (maxY - minY) * (1 / 3),
      minY,
    ];

    final double chartWidth = (labels.length * 9.0).clamp(
      MediaQuery.of(context).size.width - 104,
      1200.0,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sticky dynamic Y-Axis labels
        Container(
          width: 44,
          height: gridHeight,
          padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: yLabels.map((val) {
              return Text(
                _fmtMoney(val),
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: res.fontSize(8.5),
                ),
              );
            }).toList(),
          ),
        ),
        // Scrollable Area Chart
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _chartScrollController,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: chartWidth,
              height: chartHeight,
              child: LineChart(
                LineChartData(
                  showingTooltipIndicators: _showingTooltips,
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: false,
                    touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                      if (event is FlPanEndEvent ||
                          event is FlPanCancelEvent ||
                          event is FlTapUpEvent ||
                          event is FlTapCancelEvent ||
                          event is FlLongPressEnd) {
                        return;
                      }
                      if (response == null ||
                          response.lineBarSpots == null ||
                          response.lineBarSpots!.isEmpty) {
                        setState(() {
                          _showingTooltips = [];
                        });
                        return;
                      }
                      final firstSpot = response.lineBarSpots!.first;
                      final xIndex = firstSpot.spotIndex;
                      setState(() {
                        _showingTooltips = [
                          ShowingTooltipIndicators([
                            _CenteredLineBarSpot(
                              firstSpot.bar,
                              firstSpot.barIndex,
                              firstSpot.bar.spots[xIndex],
                              minY + (maxY - minY) / 2,
                            ),
                          ]),
                        ];
                      });
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF1C1F26),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      tooltipMargin: 8,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        if (touchedSpots.isEmpty) return [];
                        final xIndex = touchedSpots.first.spotIndex;
                        if (xIndex < 0 || xIndex >= labels.length) return [];

                        final dateStr = DateFormat('MMM dd, yyyy').format(labels[xIndex]);
                        final List<TextSpan> spans = [
                          TextSpan(
                            text: '$dateStr\n',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: res.fontSize(9),
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ];

                        final List<Map<String, dynamic>> items = [];
                        _selectedProtocols.asMap().forEach((colIdx, protocol) {
                          final pts = _compareData?.series[protocol.slug];
                          if (pts == null || xIndex >= pts.length) return;
                          final val = pts[xIndex];
                          final color = compareColors[colIdx % compareColors.length];

                          items.add({
                            'name': protocol.name,
                            'value': val,
                            'color': color,
                          });
                        });

                        // Sort descending by value
                        items.sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));

                        for (final item in items) {
                          final itemColor = item['color'] as Color;
                          final itemVal = item['value'] as double;
                          spans.add(
                            TextSpan(
                              text: '• ',
                              style: GoogleFonts.inter(
                                color: itemColor,
                                fontSize: res.fontSize(10),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          );
                          spans.add(
                            TextSpan(
                              text: '${item['name']}: ',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: res.fontSize(9.5),
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          );
                          spans.add(
                            TextSpan(
                              text: '${_fmtMoney(itemVal)}\n',
                              style: GoogleFonts.inter(
                                color: itemColor,
                                fontSize: res.fontSize(9.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        return [
                          LineTooltipItem(
                            '',
                            GoogleFonts.inter(color: Colors.white, fontSize: 10),
                            children: spans,
                          ),
                        ];
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 3 > 0 ? (maxY - minY) / 3 : 1.0,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.03),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: bottomReserved,
                        interval: (labels.length / 6).clamp(1, double.infinity),
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
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: lineBars,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsTableCard(Responsive res) {
    if (_selectedProtocols.isEmpty) return const SizedBox.shrink();
    // Prefer fully-resolved protocol statistics returned by search/compare API response
    final list = _compareData != null && _compareData!.protocols.isNotEmpty
        ? _compareData!.protocols
        : _selectedProtocols;

    // Metric Rows with Icons mapping
    final labelData = [
      {'name': 'Category', 'icon': Icons.category_rounded},
      {'name': 'Chains', 'icon': Icons.link_rounded},
      {'name': '24H Fees', 'icon': Icons.today_rounded},
      {'name': '1D Change', 'icon': Icons.trending_up_rounded},
      {'name': '7D Change', 'icon': Icons.trending_up_rounded},
      {'name': '30D Change', 'icon': Icons.trending_up_rounded},
      {'name': '7D Fees', 'icon': Icons.date_range_rounded},
      {'name': '30D Fees', 'icon': Icons.calendar_month_rounded},
      {'name': '1Y Fees', 'icon': Icons.timeline_rounded},
      {'name': 'All-Time Fees', 'icon': Icons.all_inclusive_rounded},
      {'name': 'Annualized', 'icon': Icons.insights_rounded},
    ];

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'Comparative Performance Metrics',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: res.fontSize(12.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.04), height: 1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticky left metric labels column
              Container(
                width: 110,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // header block tag
                    Container(
                      height: 72,
                      margin: const EdgeInsets.only(top: 4),
                      alignment: Alignment.bottomLeft,
                      padding: const EdgeInsets.only(left: 10, bottom: 8),
                      child: Text(
                        'METRIC',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                          fontSize: res.fontSize(9),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Divider(color: Colors.white.withValues(alpha: 0.04), height: 1),
                    ...labelData.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final data = entry.value;
                      final lbl = data['name'] as String;
                      final icon = data['icon'] as IconData;
                      final isEven = idx % 2 == 0;

                      return Container(
                        height: 48,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isEven ? Colors.white.withValues(alpha: 0.012) : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              color: AppColors.textSecondary.withValues(alpha: 0.45),
                              size: res.fontSize(11.5),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                lbl,
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: res.fontSize(9),
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // Scrolling protocols data columns
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(list.length, (colIdx) {
                      final p = list[colIdx];
                      final barColor = compareColors[colIdx % compareColors.length];

                      return Container(
                        width: 144,
                        decoration: BoxDecoration(
                          border: Border(
                            right: colIdx < list.length - 1
                                ? BorderSide(color: Colors.white.withValues(alpha: 0.04))
                                : BorderSide.none,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Header segment (glow card styled matching chart line)
                            Container(
                              height: 72,
                              margin: const EdgeInsets.only(top: 4, left: 4, right: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: barColor.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: barColor.withValues(alpha: 0.12)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          p.logo ?? '',
                                          width: 18,
                                          height: 18,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 18,
                                            height: 18,
                                            color: AppColors.surfaceBright.withValues(alpha: 0.12),
                                            child: const Icon(Icons.token_outlined, color: AppColors.brandAccent, size: 10),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          p.name,
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: res.fontSize(11),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: barColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Divider(color: Colors.white.withValues(alpha: 0.04), height: 1),

                            // Category (Idx: 0)
                            _buildCategoryBadge(p.category, res, 0),
                            // Chains (Idx: 1)
                            _buildChainsScroll(
                              p.chains.isEmpty ? '—' : p.chains.join(', '),
                              res,
                              1,
                            ),
                            // 24H Fees (Idx: 2)
                            _buildTableCell(_fmtMoney(p.fees24h), res, 2, isBoldDateText: true),
                            // 1D Change (Idx: 3)
                            _buildPctCell(p.change1d, res, 3),
                            // 7D Change (Idx: 4)
                            _buildPctCell(p.change7d, res, 4),
                            // 30D Change (Idx: 5)
                            _buildPctCell(p.change30d, res, 5),
                            // 7D Fees (Idx: 6)
                            _buildTableCell(_fmtMoney(p.fees7d), res, 6),
                            // 30D Fees (Idx: 7)
                            _buildTableCell(_fmtMoney(p.fees30d), res, 7),
                            // 1Y Fees (Idx: 8)
                            _buildTableCell(_fmtMoney(p.fees1y), res, 8),
                            // All-Time Fees (Idx: 9)
                            _buildTableCell(_fmtMoney(p.feesAllTime), res, 9),
                            // Annualized projection (Idx: 10)
                            _buildTableCell(
                              p.fees1y > 0 ? _fmtMoney(p.fees1y) : '—',
                              res,
                              10,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String text, Responsive res, int rowIdx) {
    final isEven = rowIdx % 2 == 0;
    final cleanText = text.trim();
    final hasCategory = cleanText.isNotEmpty && cleanText != '—';

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isEven ? Colors.white.withValues(alpha: 0.012) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        hasCategory ? cleanText : '—',
        style: GoogleFonts.inter(
          color: hasCategory ? Colors.white : AppColors.textSecondary.withValues(alpha: 0.5),
          fontSize: res.fontSize(10.5),
          fontWeight: hasCategory ? FontWeight.w600 : FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildChainsScroll(String text, Responsive res, int rowIdx) {
    final isEven = rowIdx % 2 == 0;
    final list = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final hasChains = list.isNotEmpty && text != '—';

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isEven ? Colors.white.withValues(alpha: 0.012) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        hasChains ? list.join(', ') : '—',
        style: GoogleFonts.inter(
          color: hasChains ? Colors.white.withValues(alpha: 0.9) : AppColors.textSecondary.withValues(alpha: 0.5),
          fontSize: res.fontSize(10.5),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTableCell(String text, Responsive res, int rowIdx, {bool isBoldDateText = false}) {
    final isEven = rowIdx % 2 == 0;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isEven ? Colors.white.withValues(alpha: 0.012) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          color: Colors.white,
          fontSize: res.fontSize(10.5),
          fontWeight: isBoldDateText ? FontWeight.bold : FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPctCell(double val, Responsive res, int rowIdx) {
    final isEven = rowIdx % 2 == 0;
    final isUp = val > 0;
    final isDown = val < 0;
    final color = isUp
        ? AppColors.trendGreen
        : isDown
            ? AppColors.trendRed
            : AppColors.textSecondary;
    final sign = isUp ? '+' : '';
    final arrow = isUp ? '▲ ' : isDown ? '▼ ' : '';

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isEven ? Colors.white.withValues(alpha: 0.012) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        '$arrow$sign${_fmtPct(val)}',
        style: GoogleFonts.jetBrainsMono(
          color: color,
          fontSize: res.fontSize(10.5),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CenteredLineBarSpot extends LineBarSpot {
  final double centeredY;

  _CenteredLineBarSpot(super.bar, super.barIndex, super.spot, this.centeredY);

  @override
  double get y => centeredY;
}

