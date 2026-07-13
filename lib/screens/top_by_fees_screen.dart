import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../models/fee_intelligence_model.dart';
import '../services/fee_intelligence_service.dart';
import '../utils/app_colors.dart';
import '../utils/common_widgets.dart';
import '../utils/responsive.dart';
import '../widgets/error_state_widget.dart';

class TopByFeesScreen extends StatefulWidget {
  final bool isRevenue;
  const TopByFeesScreen({super.key, this.isRevenue = false});

  @override
  State<TopByFeesScreen> createState() => _TopByFeesScreenState();
}

class _TopByFeesScreenState extends State<TopByFeesScreen> {
  final _service = FeeIntelligenceService();
  List<TopByFeesProtocol> _protocols = [];
  bool _isLoading = true;
  String _error = '';

  // Search State
  final _searchController = TextEditingController();
  String _searchQuery = '';

  int _currentPage = 1;
  int _itemsPerPage = 10;

  int get _totalPages {
    if (_filteredProtocols.isEmpty) return 1;
    return (_filteredProtocols.length / _itemsPerPage).ceil();
  }

  List<TopByFeesProtocol> get _paginatedProtocols {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    if (startIndex >= _filteredProtocols.length) return [];
    final endIndex = startIndex + _itemsPerPage;
    return _filteredProtocols.sublist(startIndex, endIndex.clamp(0, _filteredProtocols.length));
  }

  // Selector States
  String _selectedFeeMetric = '24H FEES'; // '24H FEES', '7D FEES', '30D FEES', '1Y FEES', 'ALL TIME'
  String _selectedChangeMetric = '24H CHANGE'; // '24H CHANGE', '7D CHANGE', '30D CHANGE'
  String _selectedAnnualMetric = 'ANNUALIZED'; // 'ANNUALIZED', 'AVERAGE 1Y'

  // Scroll Controllers for sticky column sync
  final ScrollController _leftVerticalController = ScrollController();
  final ScrollController _rightVerticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedFeeMetric = widget.isRevenue ? '24H REVENUE' : '24H FEES';
    _loadData();
    _leftVerticalController.addListener(_syncRightScroll);
    _rightVerticalController.addListener(_syncLeftScroll);
  }

  void _syncRightScroll() {
    if (_leftVerticalController.hasClients && _rightVerticalController.hasClients) {
      if (_rightVerticalController.offset != _leftVerticalController.offset) {
        _rightVerticalController.jumpTo(_leftVerticalController.offset);
      }
    }
  }

  void _syncLeftScroll() {
    if (_leftVerticalController.hasClients && _rightVerticalController.hasClients) {
      if (_leftVerticalController.offset != _rightVerticalController.offset) {
        _leftVerticalController.jumpTo(_rightVerticalController.offset);
      }
    }
  }

  @override
  void dispose() {
    _leftVerticalController.dispose();
    _rightVerticalController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final data = await _service.fetchTopByFees(isRevenue: widget.isRevenue);
      setState(() {
        _protocols = data;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<TopByFeesProtocol> get _filteredProtocols {
    if (_searchQuery.isEmpty) return _protocols;
    final query = _searchQuery.toLowerCase().trim();
    return _protocols.where((p) {
      return p.displayName.toLowerCase().contains(query);
    }).toList();
  }

  String _fmtMoney(double val) {
    if (val >= 1e9) {
      return '\$${(val / 1e9).toStringAsFixed(2)}B';
    } else if (val >= 1e6) {
      return '\$${(val / 1e6).toStringAsFixed(2)}M';
    } else if (val >= 1e3) {
      return '\$${(val / 1e3).toStringAsFixed(1)}K';
    } else if (val == 0) {
      return '\$0';
    } else {
      return '\$${val.toStringAsFixed(0)}';
    }
  }

  String _fmtPct(double val) {
    final sign = val >= 0 ? '+' : '';
    return '$sign${val.toStringAsFixed(2)}%';
  }

  double _getFeeValue(FeeTopProtocolMetrics m) {
    final metric = _selectedFeeMetric.replaceAll(' FEES', '').replaceAll(' REVENUE', '');
    switch (metric) {
      case '7D':
        return m.total7d;
      case '30D':
        return m.total30d;
      case '1Y':
        return m.total1y;
      case 'ALL TIME':
        return m.totalAllTime;
      case '24H':
      default:
        return m.total24h;
    }
  }

  double _getChangeValue(FeeTopProtocolMetrics m) {
    switch (_selectedChangeMetric) {
      case '7D CHANGE':
        return m.change7d;
      case '30D CHANGE':
        return m.change30d;
      case '24H CHANGE':
      default:
        return m.change1d;
    }
  }

  double _getAnnualValue(FeeTopProtocolMetrics m) {
    switch (_selectedAnnualMetric) {
      case 'AVERAGE 1Y':
        return m.average1y;
      case 'ANNUALIZED':
      default:
        return m.annualized1y;
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
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.brandAccent, size: res.fontSize(20)),
          ),
          titleSpacing: 0,
          title: Text(
            widget.isRevenue ? 'Top Protocols by Revenue' : 'Top Protocols by Fees',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: res.fontSize(16),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.brandAccent,
          backgroundColor: const Color(0xFF16191E),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleHeader(res),
              _buildSearchBar(res),
              const SizedBox(height: 4),
              _buildDropdownBar(res),
              const SizedBox(height: 16),

              Expanded(
                child: _isLoading
                    ? _buildLoadingSkeleton(res)
                    : _error.isNotEmpty
                        ? _buildErrorView(res)
                        : _buildTableLayout(res),
              ),
              if (!_isLoading && _error.isEmpty && _filteredProtocols.isNotEmpty)
                AppPaginationBar(
                  currentPage: _currentPage,
                  itemsPerPage: _itemsPerPage,
                  totalItems: _filteredProtocols.length,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  onItemsPerPageChanged: (limit) => setState(() {
                    _itemsPerPage = limit;
                    _currentPage = 1;
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleHeader(Responsive res) {
    final count = _isLoading ? '50' : '${_filteredProtocols.length}';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: res.spacing(16), vertical: res.spacing(8)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceBright.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.surfaceBright.withOpacity(0.3), width: 0.8),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$count ',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: res.fontSize(11),
                    ),
                  ),
                  TextSpan(
                    text: 'protocols',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary,
                      fontSize: res.fontSize(11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.isRevenue ? 'Top Hyperliquid Apps by Revenue' : 'Top Hyperliquid Apps by Fees',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: res.fontSize(14),
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Responsive res) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: res.spacing(16), vertical: res.spacing(6)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: res.spacing(12)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.surfaceBright.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.textSecondary, size: res.fontSize(18)),
            SizedBox(width: res.spacing(8)),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 1;
                  });
                },
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: res.fontSize(12),
                ),
                decoration: InputDecoration(
                  hintText: 'Search protocols...',
                  hintStyle: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: res.fontSize(12),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: res.value(mobile: 10.0, tablet: 12.0),
                  ),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _currentPage = 1;
                  });
                },
                child: Icon(Icons.close, color: AppColors.textSecondary, size: res.fontSize(16)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownButton({
    required Responsive res,
    required String activeLabel,
    required List<String> options,
    required ValueChanged<String> onChanged,
    IconData? icon,
    bool isPrimary = false,
  }) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 36),
      elevation: 12,
      shadowColor: Colors.black54,
      color: const Color(0xFF16191E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      onSelected: onChanged,
      itemBuilder: (context) {
        return options.map((opt) {
          final isSelected = opt == activeLabel || ('\$ $opt' == activeLabel);
          return PopupMenuItem<String>(
            value: opt,
            height: 38,
            child: Row(
              children: [
                if (isSelected) ...[
                  const Icon(Icons.circle, color: AppColors.brandAccent, size: 6),
                  const SizedBox(width: 8),
                ] else ...[
                  const SizedBox(width: 14),
                ],
                Text(
                  opt,
                  style: GoogleFonts.jetBrainsMono(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: res.fontSize(11),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: res.spacing(12),
          vertical: res.spacing(8),
        ),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.brandAccent.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isPrimary ? AppColors.brandAccent.withOpacity(0.4) : AppColors.surfaceBright.withOpacity(0.4),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: res.fontSize(12), color: isPrimary ? AppColors.brandAccent : AppColors.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              activeLabel,
              style: GoogleFonts.jetBrainsMono(
                color: isPrimary ? AppColors.brandAccent : Colors.white,
                fontSize: res.fontSize(10),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: res.fontSize(14), color: isPrimary ? AppColors.brandAccent : Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownBar(Responsive res) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: res.spacing(16)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildDropdownButton(
              res: res,
              activeLabel: '\$ $_selectedFeeMetric',
              options: widget.isRevenue 
                  ? ['24H REVENUE', '7D REVENUE', '30D REVENUE', '1Y REVENUE', 'ALL TIME']
                  : ['24H FEES', '7D FEES', '30D FEES', '1Y FEES', 'ALL TIME'],
              isPrimary: true,
              onChanged: (val) {
                setState(() {
                  _selectedFeeMetric = val;
                  _currentPage = 1;
                });
              },
            ),
            const SizedBox(width: 8),
            _buildDropdownButton(
              res: res,
              icon: Icons.trending_up_rounded,
              activeLabel: _selectedChangeMetric,
              options: ['24H CHANGE', '7D CHANGE', '30D CHANGE'],
              onChanged: (val) {
                setState(() {
                  _selectedChangeMetric = val;
                  _currentPage = 1;
                });
              },
            ),
            const SizedBox(width: 8),
            _buildDropdownButton(
              res: res,
              icon: Icons.calendar_today_outlined,
              activeLabel: _selectedAnnualMetric,
              options: ['ANNUALIZED', 'AVERAGE 1Y'],
              onChanged: (val) {
                setState(() {
                  _selectedAnnualMetric = val;
                  _currentPage = 1;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(Responsive res) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF1E222D),
        highlightColor: const Color(0xFF2E3340),
        period: const Duration(milliseconds: 1400),
        child: ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 100,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 60,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 50,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('SocketException') || error.contains('Failed host lookup') || error.contains('HttpException')) {
      return 'Connection error. Please check your internet connection and try again.';
    }
    return 'Failed to load protocols. Please try again later.';
  }

  Widget _buildErrorView(Responsive res) {
    return ErrorStateWidget(
      errorMessage: _getFriendlyErrorMessage(_error),
      onRetry: _loadData,
    );
  }

  Widget _buildTableLayout(Responsive res) {
    final filtered = _paginatedProtocols;
    if (_filteredProtocols.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No protocols ranked currently.'
              : 'No protocols found matching "$_searchQuery".',
          style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary),
        ),
      );
    }

    final double leftWidth = res.columnWidth(150.0);
    final double rightWidth = res.columnWidth(250.0);
    const double headerH = 40.0;
    const double rowH = 56.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Sticky Columns: Rank and Name
          SizedBox(
            width: leftWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Fixed Header
                Container(
                  height: headerH,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      SizedBox(
                        width: res.columnWidth(25.0),
                        child: Text(
                          '#',
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textSecondary,
                            fontSize: res.fontSize(10),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'PROTOCOL',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary,
                          fontSize: res.fontSize(10),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Left Scrollable Rows list
                Expanded(
                  child: SingleChildScrollView(
                    controller: _leftVerticalController,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(filtered.length, (index) {
                        final p = filtered[index];
                        return Container(
                          height: rowH,
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFF14171C), width: 0.5)),
                          ),
                          child: Row(
                            children: [
                              // Rank Number
                              SizedBox(
                                width: res.columnWidth(25.0),
                                child: Text(
                                  '${(_currentPage - 1) * _itemsPerPage + index + 1}',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: AppColors.textSecondary,
                                    fontSize: res.fontSize(11),
                                  ),
                                ),
                              ),
                              // Protocol Logo + Name
                              Expanded(
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        p.logo ?? '',
                                        width: 18,
                                        height: 18,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.token_outlined,
                                          color: AppColors.brandAccent,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        p.displayName,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: res.fontSize(11),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
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
          ),

          // Right Scrollable Columns
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: rightWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Right Fixed Header Row
                    Container(
                      height: headerH,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          _buildHeaderCell(_selectedFeeMetric, width: res.columnWidth(85.0)),
                          _buildHeaderCell(_selectedChangeMetric, width: res.columnWidth(75.0)),
                          _buildHeaderCell(_selectedAnnualMetric, width: res.columnWidth(90.0)),
                        ],
                      ),
                    ),
                    // Right Scrollable Rows list
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _rightVerticalController,
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(filtered.length, (index) {
                            final p = filtered[index];
                            final m = p.metrics;
                            return Container(
                              height: rowH,
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Color(0xFF14171C), width: 0.5)),
                              ),
                              child: Row(
                                children: [
                                    _buildValueCell(_fmtMoney(_getFeeValue(m)), isAccent: true, width: res.columnWidth(85.0)),
                                    _buildPctCell(_getChangeValue(m), width: res.columnWidth(75.0)),
                                    _buildValueCell(_fmtMoney(_getAnnualValue(m)), width: res.columnWidth(90.0)),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, {required double width}) {
    return Container(
      width: width,
      alignment: Alignment.centerRight,
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildValueCell(String val, {bool isAccent = false, required double width}) {
    return Container(
      width: width,
      alignment: Alignment.centerRight,
      child: Text(
        val,
        style: GoogleFonts.jetBrainsMono(
          color: isAccent ? Colors.white : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: isAccent ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPctCell(double val, {required double width}) {
    final isUp = val >= 0;
    return Container(
      width: width,
      alignment: Alignment.centerRight,
      child: Text(
        _fmtPct(val),
        style: GoogleFonts.jetBrainsMono(
          color: isUp ? AppColors.trendGreen : AppColors.trendRed,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

}
