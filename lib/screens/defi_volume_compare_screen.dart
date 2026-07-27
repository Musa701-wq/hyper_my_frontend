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

class DefiVolumeCompareScreen extends StatefulWidget {
  const DefiVolumeCompareScreen({super.key});

  @override
  State<DefiVolumeCompareScreen> createState() => _DefiVolumeCompareScreenState();
}

class _DefiVolumeCompareScreenState extends State<DefiVolumeCompareScreen> {
  final FeeIntelligenceService _service = FeeIntelligenceService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _chartScrollController = ScrollController();

  bool _isLoading = false;
  String _error = '';

  final List<FeeTopProtocol> _selectedProtocols = [];
  
  List<FeeTopProtocol> _suggestionPool = [];
  List<FeeTopProtocol> _filteredSuggestions = [];
  bool _showSuggestions = false;

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
      final list = await _service.fetchProtocols(
        limit: 50, 
        dataType: 'dexs',
      );
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
      final data = await _service.fetchCompare(
        slugs, 
        range: _selectedRange, 
        dataType: 'dexs',
      );
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
            'Volume Compare',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: res.fontSize(15),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(horizontal: res.spacing(14), vertical: res.spacing(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompareSearchBox(res),
                    const SizedBox(height: 14),
                    _buildPillGrid(res),
                    const SizedBox(height: 14),
                    if (_isLoading && _compareData == null)
                      SizedBox(
                        height: 250,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.brandAccent,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else if (_error.isNotEmpty)
                      ErrorStateWidget(
                        errorMessage: _error,
                        onRetry: _updateComparisonData,
                      )
                    else if (_selectedProtocols.isEmpty)
                      _buildEmptyState(res)
                    else
                      _buildComparisonResultSection(res),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareSearchBox(Responsive res) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _searchFocus.hasFocus ? AppColors.brandAccent.withOpacity(0.5) : AppColors.surfaceBright,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.textSecondary.withOpacity(0.6), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  cursorColor: AppColors.brandAccent,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Search to compare protocols...',
                    hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 13.5),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  child: const Icon(Icons.clear_rounded, color: Colors.white60, size: 16),
                ),
            ],
          ),
        ),
        if (_showSuggestions && _filteredSuggestions.isNotEmpty)
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              elevation: 8,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: const Color(0xFF14171C),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _filteredSuggestions.length,
                  itemBuilder: (context, index) {
                    final item = _filteredSuggestions[index];
                    final isSel = _selectedProtocols.any((p) => p.slug == item.slug);

                    return InkWell(
                      onTap: isSel ? null : () => _addProtocol(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.02))),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                item.logo ?? '',
                                width: 16,
                                height: 16,
                                errorBuilder: (_, __, ___) => const Icon(Icons.token_outlined, color: AppColors.brandAccent, size: 12),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.name,
                                style: GoogleFonts.inter(
                                  color: isSel ? Colors.white38 : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isSel)
                              Text(
                                'Added',
                                style: GoogleFonts.inter(
                                  color: AppColors.brandAccent,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
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
          ),
      ],
    );
  }

  Widget _buildPillGrid(Responsive res) {
    if (_selectedProtocols.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedProtocols.asMap().entries.map((entry) {
        final idx = entry.key;
        final p = entry.value;
        final color = compareColors[idx % compareColors.length];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                p.name,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _removeProtocol(p.slug),
                child: const Icon(Icons.close_rounded, color: Colors.white60, size: 14),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(Responsive res) {
    return Container(
      height: 300,
      width: double.infinity,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compare_arrows_rounded, color: AppColors.textSecondary.withOpacity(0.4), size: 48),
          const SizedBox(height: 14),
          Text(
            'Select protocols above to compare performance',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Compare market volume trends, growth rates, and analytics.',
            style: GoogleFonts.inter(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 10.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonResultSection(Responsive res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChartCard(res),
        const SizedBox(height: 16),
        _buildStatsTableCard(res),
      ],
    );
  }

  Widget _buildChartCard(Responsive res) {
    return AppCard(
      padding: EdgeInsets.all(res.spacing(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Volume Trend Comparison',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: res.fontSize(13),
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildRangeSelector(res),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading && _compareData == null)
            SizedBox(
              height: 200,
              child: const Center(child: CircularProgressIndicator(color: AppColors.brandAccent, strokeWidth: 2)),
            )
          else if (_compareData == null || _compareData!.labels.isEmpty)
            SizedBox(
              height: 200,
              child: Center(child: Text('No comparison dataset returned.', style: GoogleFonts.inter(color: AppColors.textSecondary))),
            )
          else
            _buildLineChart(res),
        ],
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
              setState(() {
                _selectedRange = v.toLowerCase();
              });
              _updateComparisonData();
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

  Widget _buildLineChart(Responsive res) {
    final labels = _compareData!.labels;
    final series = _compareData!.series;

    double maxVal = 100.0;
    for (final slug in series.keys) {
      final list = series[slug]!;
      for (final val in list) {
        if (val > maxVal) maxVal = val;
      }
    }
    maxVal = maxVal * 1.05;
    final step = maxVal / 3 > 0 ? maxVal / 3 : 1.0;
    final yLabels = [0.0, step, 2 * step, maxVal];

    final chartWidth = (labels.length * 8.5).clamp(400.0, 1200.0);

    final lineBars = <LineChartBarData>[];
    for (int i = 0; i < _selectedProtocols.length; i++) {
      final slug = _selectedProtocols[i].slug;
      if (series.containsKey(slug)) {
        final list = series[slug]!;
        final spots = <FlSpot>[];
        for (int j = 0; j < list.length; j++) {
          spots.add(FlSpot(j.toDouble(), list[j]));
        }
        final color = compareColors[i % compareColors.length];
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
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          height: 180,
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
              height: 200,
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

  Widget _buildStatsTableCard(Responsive res) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 14, bottom: 8),
            child: Text(
              'Detail Statistical Metrics',
              style: GoogleFonts.inter(color: Colors.white, fontSize: res.fontSize(13), fontWeight: FontWeight.bold),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              width: res.columnWidth(660.0),
              child: Table(
                border: TableBorder(
                  horizontalInside: BorderSide(color: Colors.white.withOpacity(0.04), width: 0.5),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                  4: FlexColumnWidth(2.5),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFF13161A)),
                    children: [
                      _tblCellHeader('PROTOCOL'),
                      _tblCellHeader('24H VOLUME'),
                      _tblCellHeader('1D CHANGE'),
                      _tblCellHeader('7D VOLUME'),
                      _tblCellHeader('30D VOLUME'),
                    ],
                  ),
                  ..._selectedProtocols.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final p = entry.value;

                    return TableRow(
                      children: [
                        TableCell(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: compareColors[idx % compareColors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: res.fontSize(11.5), fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _tblCellData(_fmtMoney(p.fees24h)),
                        TableCell(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            alignment: Alignment.centerRight,
                            child: Text(
                              _fmtPct(p.change1d),
                              style: GoogleFonts.jetBrainsMono(
                                color: p.change1d >= 0 ? AppColors.trendGreen : AppColors.trendRed,
                                fontSize: res.fontSize(11),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        _tblCellData(_fmtMoney(p.fees7d)),
                        _tblCellData(_fmtMoney(p.fees30d)),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tblCellHeader(String label) {
    return TableCell(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        alignment: label == 'PROTOCOL' ? Alignment.centerLeft : Alignment.centerRight,
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _tblCellData(String label) {
    return TableCell(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        alignment: Alignment.centerRight,
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
