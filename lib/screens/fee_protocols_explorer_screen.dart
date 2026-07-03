import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/fee_intelligence_model.dart';
import '../services/fee_intelligence_service.dart';
import '../utils/app_colors.dart';
import '../utils/common_widgets.dart';
import '../utils/responsive.dart';
import 'fee_protocol_detail_screen.dart';
import '../widgets/error_state_widget.dart';
import 'package:shimmer/shimmer.dart';



class FeeProtocolsExplorerScreen extends StatefulWidget {
  final List<String>? initialCategories;
  const FeeProtocolsExplorerScreen({super.key, this.initialCategories});

  @override
  State<FeeProtocolsExplorerScreen> createState() => _FeeProtocolsExplorerScreenState();
}

class _FeeProtocolsExplorerScreenState extends State<FeeProtocolsExplorerScreen> {
  final _service = FeeIntelligenceService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String _error = '';

  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  // Pagination & Filter States
  int _currentPage = 1;
  int _limit = 20;
  int _totalPages = 1;
  int _totalCount = 0;

  String _selectedType = 'all'; // 'all', 'dapps', 'chains'
  String _searchQuery = '';
  String _selectedCategory = 'ALL';
  bool _collapseSubProtocols = true;

  String _sortBy = 'fees24h';
  String _sortOrder = 'desc';

  List<FeeTopProtocol> _protocols = [];
  FeeIntelligenceStats? _dashboardStats;
  Timer? _searchDebounce;

  final List<String> _categories = ['ALL'];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategories != null && widget.initialCategories!.isNotEmpty) {
      // Remove duplicates and capitalised ALL
      final clean = widget.initialCategories!
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e.toLowerCase() != 'all')
          .toList();
      _categories.addAll(clean);
    } else {
      _categories.addAll([
        'Stablecoin Issuer',
        'Dexs',
        'Chain',
        'Derivatives',
        'Liquid Staking',
        'Staking Pool',
        'Lending',
        'RWA',
        'Bridge',
        'Yield'
      ]);
    }
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final db = await _service.fetchDashboard();
      _dashboardStats = db.stats;
    } catch (_) {
      // Allow fallback if dashboard fails, just parse stats or keep empty
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      String? dataType;
      if (_selectedType == 'chains') {
        dataType = 'chains';
      } else if (_selectedType == 'dapps') {
        dataType = _collapseSubProtocols ? 'parents' : 'all';
      } else {
        dataType = null;
      }

      if (_searchQuery.trim().isNotEmpty) {
        // Since backend does not filter on-server by query query string, we fetch top 1000 items and filter client-side
        final res = await _service.fetchProtocolsPaginated(
          page: 1,
          limit: 1000,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
          category: _selectedCategory == 'ALL' ? null : _selectedCategory,
          dataType: dataType,
        );

        final query = _searchQuery.trim().toLowerCase();
        final filteredList = res.protocols.where((p) {
          final nameMatch = p.name.toLowerCase().contains(query);
          final catMatch = p.category.toLowerCase().contains(query);
          return nameMatch || catMatch;
        }).toList();

        setState(() {
          _totalCount = filteredList.length;
          _totalPages = (_totalCount / _limit).ceil();
          if (_totalPages < 1) _totalPages = 1;
          
          if (_currentPage > _totalPages) {
            _currentPage = _totalPages;
          } else if (_currentPage < 1) {
            _currentPage = 1;
          }

          final startIndex = (_currentPage - 1) * _limit;
          final endIndex = startIndex + _limit;

          _protocols = filteredList.sublist(
            startIndex,
            endIndex > _totalCount ? _totalCount : endIndex,
          );
          _isLoading = false;
        });
      } else {
        final res = await _service.fetchProtocolsPaginated(
          page: _currentPage,
          limit: _limit,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
          category: _selectedCategory == 'ALL' ? null : _selectedCategory,
          dataType: dataType,
        );

        setState(() {
          _protocols = res.protocols;
          _currentPage = res.page;
          _limit = res.limit;
          _totalCount = res.total;
          _totalPages = res.pages;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = val;
        _currentPage = 1;
      });
      _loadData();
    });
  }

  void _toggleSort(String field) {
    setState(() {
      if (_sortBy == field) {
        _sortOrder = _sortOrder == 'desc' ? 'asc' : 'desc';
      } else {
        _sortBy = field;
        _sortOrder = 'desc';
      }
      _currentPage = 1;
    });
    _loadData();
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

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Stablecoin Issuer':
        return const Color(0xFF2563EB);
      case 'Dexs':
        return const Color(0xFF10B981);
      case 'Chain':
        return const Color(0xFF6366F1);
      case 'Derivatives':
        return const Color(0xFFF59E0B);
      case 'Liquid Staking':
        return const Color(0xFFEF4444);
      case 'Staking Pool':
        return const Color(0xFF06B6D4);
      case 'Lending':
        return const Color(0xFFA855F7);
      case 'RWA':
        return const Color(0xFF34D399);
      default:
        return AppColors.textSecondary.withOpacity(0.5);
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
            'Protocol Explorer',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: res.fontSize(16),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        body: _buildBodyContent(res),
      ),
    );
  }

  Widget _buildBodyContent(Responsive res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadInitialData,
            color: AppColors.brandAccent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Control Bar matching Open Interest screen alignment
                  _buildControlBar(res),

                  // Summary stats blocks
                  if (_dashboardStats != null) _buildSummaryBar(res),

                  // Search Row matching Open Interest screen
                  _buildSearchRow(res),

                  // Content view (loading, error, table)
                  _isLoading && _protocols.isEmpty
                      ? _buildLoadingSkeleton(res)
                      : _error.isNotEmpty
                          ? _buildErrorView(res)
                          : _buildTableLayout(res),
                ],
              ),
            ),
          ),
        ),
        // Sticky Bottom Pagination Bar matching Open Interest screen
        if (!_isLoading && _error.isEmpty && _protocols.isNotEmpty)
          _buildBottomPaginationBar(res),
      ],
    );
  }

  Widget _buildControlBar(Responsive res) {
    final controlBarChild = Row(
      children: [
        // Dropdown Type selector: All Types | Dapps Only | Chains Only
        _buildTypeDropdownButton(res),

        const SizedBox(width: 12),

        // Render category filters & collapse button only if Chains Only is NOT active
        if (_selectedType != 'chains') ...[
          // Category selector popup
          _buildCategoryDropdownButton(res),

          const SizedBox(width: 8),
          Container(width: 1, height: res.value(mobile: 24.0, tablet: 32.0), color: AppColors.surfaceBright.withOpacity(0.4)),
          const SizedBox(width: 8),

          // Collapse Sub-Protocols Toggle Button
          OutlinedButton(
            onPressed: () {
              setState(() {
                _collapseSubProtocols = !_collapseSubProtocols;
                _currentPage = 1;
              });
              _loadData();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _collapseSubProtocols
                    ? AppColors.brandAccent.withOpacity(0.6)
                    : AppColors.surfaceBright.withOpacity(0.3),
                width: _collapseSubProtocols ? 1.5 : 1.0,
              ),
              backgroundColor: _collapseSubProtocols
                  ? AppColors.brandAccent.withOpacity(0.12)
                  : AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 32),
            ),
            child: Text(
              _collapseSubProtocols ? 'COLLAPSED' : 'EXPANDED',
              style: GoogleFonts.jetBrainsMono(
                color: _collapseSubProtocols ? AppColors.brandAccent : Colors.white,
                fontSize: res.fontSize(10),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: res.spacing(16.0),
        vertical: res.value(mobile: 10.0, tablet: 14.0, desktop: 16.0),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: controlBarChild,
      ),
    );
  }

  Widget _buildTypeDropdownButton(Responsive res) {
    final Map<String, String> typeLabels = {
      'all': 'All Types',
      'dapps': 'Dapps Only',
      'chains': 'Chains Only',
    };
    final activeLabel = typeLabels[_selectedType] ?? 'All Types';
    final isSelected = _selectedType != 'all';

    return PopupMenuButton<String>(
      offset: const Offset(0, 36),
      elevation: 12,
      shadowColor: Colors.black54,
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: res.value(mobile: 12.0, tablet: 16.0),
          vertical: res.value(mobile: 8.0, tablet: 10.0),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandAccent.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.brandAccent.withOpacity(0.4) : AppColors.surfaceBright.withOpacity(0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              color: isSelected ? AppColors.brandAccent : AppColors.textSecondary,
              size: res.value(mobile: 14.0, tablet: 18.0),
            ),
            const SizedBox(width: 6),
            Text(
              activeLabel.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                color: isSelected ? AppColors.brandAccent : Colors.white,
                fontSize: res.fontSize(10),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.unfold_more_rounded, color: Colors.white54, size: res.value(mobile: 14.0, tablet: 18.0)),
          ],
        ),
      ),
      onSelected: (val) {
        setState(() {
          _selectedType = val;
          _currentPage = 1;
        });
        _loadData();
      },
      itemBuilder: (context) => typeLabels.entries.map((entry) {
        final active = _selectedType == entry.key;
        return PopupMenuItem<String>(
          value: entry.key,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.brandAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (active) ...[
                  const Icon(Icons.check, color: Colors.black, size: 14),
                  const SizedBox(width: 6),
                ],
                Text(
                  entry.value,
                  style: GoogleFonts.jetBrainsMono(
                    color: active ? Colors.black : Colors.white,
                    fontSize: res.fontSize(11),
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryDropdownButton(Responsive res) {
    final isSelected = _selectedCategory != 'ALL';
    return PopupMenuButton<String>(
      offset: const Offset(0, 36),
      elevation: 12,
      shadowColor: Colors.black54,
      color: const Color(0xFF0F1115),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: res.value(mobile: 12.0, tablet: 16.0),
          vertical: res.value(mobile: 8.0, tablet: 10.0),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandAccent.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.brandAccent.withOpacity(0.4) : AppColors.surfaceBright.withOpacity(0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.grid_view_rounded,
              color: isSelected ? AppColors.brandAccent : AppColors.textSecondary,
              size: res.value(mobile: 14.0, tablet: 18.0),
            ),
            const SizedBox(width: 6),
            Text(
              isSelected ? _selectedCategory : 'CATEGORY',
              style: GoogleFonts.jetBrainsMono(
                color: isSelected ? AppColors.brandAccent : Colors.white,
                fontSize: res.fontSize(10),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.unfold_more_rounded, color: Colors.white54, size: res.value(mobile: 14.0, tablet: 18.0)),
          ],
        ),
      ),
      onSelected: (cat) {
        setState(() {
          _selectedCategory = cat;
          _currentPage = 1;
        });
        _loadData();
      },
      itemBuilder: (context) => _categories.map((cat) {
        final active = _selectedCategory == cat;
        return PopupMenuItem<String>(
          value: cat,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.brandAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (active) ...[
                  const Icon(Icons.check, color: Colors.black, size: 14),
                  const SizedBox(width: 6),
                ],
                Text(
                  cat,
                  style: GoogleFonts.jetBrainsMono(
                    color: active ? Colors.black : Colors.white70,
                    fontSize: res.fontSize(11),
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryBar(Responsive res) {
    if (_dashboardStats == null) return const SizedBox.shrink();

    final item1 = _buildSummaryItem('Total 24H', _fmtMoney(_dashboardStats!.total24h), res);
    final item2 = _buildSummaryItem('Total 7D', _fmtMoney(_dashboardStats!.total7d), res);
    final item3 = _buildSummaryItem('Protocols', _dashboardStats!.activeProtocols.toString(), res);
    final item4 = _buildSummaryItem('Chains', _dashboardStats!.activeChains.toString(), res);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 16,
        child: Row(
          children: [
            Expanded(child: item1),
            _buildVerticalDivider(),
            Expanded(child: item2),
            _buildVerticalDivider(),
            Expanded(child: item3),
            _buildVerticalDivider(),
            Expanded(child: item4),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withOpacity(0.06),
    );
  }

  Widget _buildSummaryItem(String label, String value, Responsive res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: res.fontSize(9),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: res.fontSize(13),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchRow(Responsive res) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isSearchFocused
                      ? AppColors.brandAccent
                      : (_searchController.text.isNotEmpty
                          ? AppColors.brandAccent.withOpacity(0.5)
                          : AppColors.surfaceBright.withOpacity(0.3)),
                  width: _isSearchFocused ? 1.5 : 1.0,
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                cursorColor: AppColors.brandAccent,
                style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search protocol or category...',
                  hintStyle: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 13),
                  prefixIcon: Icon(
                    Icons.search,
                    color: _isSearchFocused || _searchController.text.isNotEmpty ? AppColors.brandAccent : AppColors.textSecondary,
                    size: 18,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTableLayout(Responsive res) {
    if (_protocols.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60.0),
          child: Text(
            'No elements found matching the filters.',
            style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final double leftWidth = res.columnWidth(170.0);
    final double rightWidth = res.columnWidth(635.0);
    const double headerH = 40.0;
    const double rowH = 56.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sticky Column
          SizedBox(
            width: leftWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Rank & Title Column
                Container(
                  height: headerH,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: res.columnWidth(30.0),
                        child: Text(
                          '#',
                          style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(10), fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: _buildSortableHeader('PROTOCOL', 'name'),
                      ),
                    ],
                  ),
                ),
                // Left Items list
                ..._protocols.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  final rank = (_currentPage - 1) * _limit + idx + 1;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, __, ___) => FeeProtocolDetailScreen(protocol: p),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: rowH,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: res.columnWidth(30.0),
                            child: Text(
                              rank.toString(),
                              style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceBright.withOpacity(0.3),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: p.logo != null && p.logo!.isNotEmpty
                                        ? Image.network(
                                            p.logo!,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.token, color: AppColors.textSecondary, size: 14),
                                          )
                                        : const Icon(Icons.token, color: AppColors.textSecondary, size: 14),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        p.name,
                                        style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: res.fontSize(11), fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      if (p.category.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: _getCategoryColor(p.category).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            p.category.toUpperCase(),
                                            style: GoogleFonts.jetBrainsMono(
                                              color: _getCategoryColor(p.category),
                                              fontSize: res.fontSize(8),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
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
                    // Right Header Cells (24H FEES, 1D, 7D, 7D FEES, 30D FEES, 1Y FEES, ALL TIME)
                    Container(
                      height: headerH,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          _buildHeaderCell('24H FEES', res, 'fees24h', width: res.columnWidth(90.0)),
                          _buildHeaderCell('1D CHANGE', res, 'change1d', width: res.columnWidth(80.0)),
                          _buildHeaderCell('7D CHANGE', res, 'change7d', width: res.columnWidth(80.0)),
                          _buildHeaderCell('7D FEES', res, 'fees7d', width: res.columnWidth(95.0)),
                          _buildHeaderCell('30D FEES', res, 'fees30d', width: res.columnWidth(95.0)),
                          _buildHeaderCell('1Y FEES', res, 'fees1y', width: res.columnWidth(95.0)),
                          _buildHeaderCell('ALL TIME', res, 'feesAllTime', width: res.columnWidth(100.0)),
                        ],
                      ),
                    ),
                    // Right Content Rows
                    ..._protocols.asMap().entries.map((entry) {
                      final p = entry.value;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, __, ___) => FeeProtocolDetailScreen(protocol: p),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: rowH,
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                          ),
                          child: Row(
                            children: [
                              // 24H Fees
                              Container(
                                width: res.columnWidth(90.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
                                  ),
                                ),
                                child: Text(
                                  _fmtMoney(p.fees24h),
                                  style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: res.fontSize(11.5), fontWeight: FontWeight.bold),
                                ),
                              ),
                              // 1D Change (Heat-map)
                              _buildChangeCell(p.change1d, res, width: res.columnWidth(80.0)),
                              // 7D Change (Heat-map)
                              _buildChangeCell(p.change7d, res, width: res.columnWidth(80.0)),
                              // 7D Fees
                              Container(
                                width: res.columnWidth(95.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
                                  ),
                                ),
                                child: Text(
                                  _fmtMoney(p.fees7d),
                                  style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: res.fontSize(10.5)),
                                ),
                              ),
                              // 30D Fees
                              Container(
                                width: res.columnWidth(95.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
                                  ),
                                ),
                                child: Text(
                                  _fmtMoney(p.fees30d),
                                  style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: res.fontSize(10.5)),
                                ),
                              ),
                              // 1Y Fees
                              Container(
                                width: res.columnWidth(95.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
                                  ),
                                ),
                                child: Text(
                                  _fmtMoney(p.fees1y),
                                  style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: res.fontSize(10.5)),
                                ),
                              ),
                              // All Time Fees
                              Container(
                                width: res.columnWidth(100.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
                                  ),
                                ),
                                child: Text(
                                  _fmtMoney(p.feesAllTime),
                                  style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: res.fontSize(10.5)),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, Responsive res, String fieldName, {required double width}) {
    final isSorted = _sortBy == fieldName;
    return GestureDetector(
      onTap: () => _toggleSort(fieldName),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: GoogleFonts.jetBrainsMono(
                color: isSorted ? AppColors.brandAccent : AppColors.textSecondary,
                fontSize: res.fontSize(10),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isSorted) ...[
              const SizedBox(width: 2),
              Icon(
                _sortOrder == 'desc' ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                color: AppColors.brandAccent,
                size: 14,
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSortableHeader(String title, String fieldName) {
    final isSorted = _sortBy == fieldName;
    return GestureDetector(
      onTap: () => _toggleSort(fieldName),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.jetBrainsMono(
                color: isSorted ? AppColors.brandAccent : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSorted)
            Icon(
              _sortOrder == 'desc' ? Icons.arrow_drop_down : Icons.arrow_drop_up,
              color: AppColors.brandAccent,
              size: 14,
            ),
        ],
      ),
    );
  }

  Widget _buildChangeCell(double value, Responsive res, {required double width}) {
    final isZero = value == 0.0;
    final isPositive = value > 0;

    final absVal = value.abs();
    final double fraction = (absVal / 20.0).clamp(0.0, 1.0);
    final double opacity = 0.06 + (fraction * 0.49);

    final bgColor = isZero
        ? const Color(0xFF1E293B).withOpacity(0.1) // slate 800
        : (isPositive 
            ? const Color(0xFF047857).withOpacity(opacity) // emerald 700
            : const Color(0xFFB91C1C).withOpacity(opacity)); // red 700

    final textColor = isZero
        ? const Color(0xFF94A3B8) // slate 400
        : (isPositive ? const Color(0xFF4ADE80) : const Color(0xFFF87171)); // green 400 / red 400
    final arrow = isPositive ? '↑' : (isZero ? '' : '↓');
    final formattedValue = isZero ? '0.00%' : '$arrow ${value.abs().toStringAsFixed(2)}%';

    return Container(
      width: width,
      height: 56.0,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        formattedValue,
        style: GoogleFonts.jetBrainsMono(
          color: textColor,
          fontSize: res.fontSize(10),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomPaginationBar(Responsive res) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: res.spacing(16), vertical: res.spacing(10)),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(
              'Rows:',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary,
                fontSize: res.fontSize(12),
              ),
            ),
            const SizedBox(width: 8),
            _buildRowsPill(res),
            const Spacer(),
            _buildPaginationRow(res),
          ],
        ),
      ),
    );
  }

  Widget _buildRowsPill(Responsive res) {
    return PopupMenuButton<int>(
      offset: const Offset(0, 36),
      elevation: 12,
      shadowColor: Colors.black54,
      color: const Color(0xFF0F1115),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceBright.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceBright.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _limit.toString(),
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: res.fontSize(11),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.unfold_more_rounded, color: Colors.white54, size: 14),
          ],
        ),
      ),
      onSelected: (val) {
        setState(() {
          _limit = val;
          _currentPage = 1;
        });
        _loadData();
      },
      itemBuilder: (context) => const [10, 20, 50, 100].map((v) {
        final active = _limit == v;
        return PopupMenuItem<int>(
          value: v,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.brandAccent.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                if (active)
                  const Icon(Icons.check_circle_rounded, color: AppColors.brandAccent, size: 14)
                else
                  const Icon(Icons.circle_outlined, color: Colors.white24, size: 14),
                const SizedBox(width: 8),
                Text(
                  v.toString(),
                  style: GoogleFonts.jetBrainsMono(
                    color: active ? AppColors.brandAccent : Colors.white70,
                    fontSize: 11,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaginationRow(Responsive res) {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPageIcon(Icons.chevron_left, _currentPage > 1 ? () {
          setState(() => _currentPage--);
          _loadData();
        } : null, res),
        const SizedBox(width: 4),
        ..._buildPageNumbersList(res),
        const SizedBox(width: 4),
        _buildPageIcon(Icons.chevron_right, _currentPage < _totalPages ? () {
          setState(() => _currentPage++);
          _loadData();
        } : null, res),
      ],
    );
  }

  List<Widget> _buildPageNumbersList(Responsive res) {
    final List<Widget> children = [];
    for (int i = 1; i <= _totalPages; i++) {
      if (i == 1 || i == _totalPages || (i >= _currentPage - 1 && i <= _currentPage + 1)) {
        final isCurrent = i == _currentPage;
        children.add(GestureDetector(
          onTap: () {
            if (!isCurrent) {
              setState(() => _currentPage = i);
              _loadData();
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: res.value(mobile: 28.0, tablet: 36.0),
            height: res.value(mobile: 28.0, tablet: 36.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.brandAccent.withOpacity(0.14)
                  : AppColors.surfaceBright.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrent
                    ? AppColors.brandAccent.withOpacity(0.4)
                    : AppColors.surfaceBright.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Text(
              i.toString(),
              style: GoogleFonts.jetBrainsMono(
                color: isCurrent ? AppColors.brandAccent : Colors.white,
                fontSize: res.fontSize(11),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ));
        
        if (i < _totalPages && (i == 1 && _currentPage > 3 || i == _currentPage + 1 && _currentPage < _totalPages - 2)) {
          children.add(Text(
            '...',
            style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(10)),
          ));
        }
      }
    }
    return children;
  }

  Widget _buildPageIcon(IconData icon, VoidCallback? onTap, Responsive res) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(res.value(mobile: 4.0, tablet: 6.0)),
        decoration: BoxDecoration(
          color: AppColors.surfaceBright.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: res.value(mobile: 18.0, tablet: 22.0),
          color: onTap != null ? Colors.white : AppColors.textSecondary.withOpacity(0.3),
        ),
      ),
    );
  }


  Widget _buildLoadingSkeleton(Responsive res) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E222D),
      highlightColor: const Color(0xFF2E3340),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(8, (idx) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceBright.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 40,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 60,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorView(Responsive res) {
    return ErrorStateWidget(
      errorMessage: _error.isEmpty
          ? 'Failed to load explorer protocols. Please check your network connection.'
          : _error,
      onRetry: _loadData,
    );
  }
}
