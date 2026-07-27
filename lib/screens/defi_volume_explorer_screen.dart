import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/fee_intelligence_model.dart';
import '../services/fee_intelligence_service.dart';
import '../utils/app_colors.dart';
import '../utils/common_widgets.dart';
import '../utils/responsive.dart';
import 'defi_volume_detail_screen.dart';
import 'defi_volume_chain_detail_screen.dart';
import '../widgets/error_state_widget.dart';
import 'package:shimmer/shimmer.dart';

class DefiVolumeExplorerScreen extends StatefulWidget {
  final List<String>? initialCategories;
  const DefiVolumeExplorerScreen({super.key, this.initialCategories});

  @override
  State<DefiVolumeExplorerScreen> createState() => _DefiVolumeExplorerScreenState();
}

class _DefiVolumeExplorerScreenState extends State<DefiVolumeExplorerScreen> {
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

  String _selectedType = 'all'; // 'all', 'chains', 'hl_l1'
  String _searchQuery = '';
  String _selectedCategory = 'ALL';
  bool _collapseSubProtocols = true;
  final Set<String> _expandedParentSlugs = {};
  final Set<String> _visiblePercentageKeys = {};

  String _sortBy = 'fees24h'; // Maps to volume24h on backend
  String _sortOrder = 'desc';

  List<FeeTopProtocol> _protocols = [];
  List<DexChainMetrics> _chains = [];

  bool get _hasData {
    if (_selectedType == 'chains') {
      return _chains.isNotEmpty;
    }
    return _protocols.isNotEmpty;
  }

  FeeIntelligenceStats? _dashboardStats;
  Timer? _searchDebounce;

  final List<String> _categories = ['ALL'];

  @override
  void initState() {
    super.initState();
    _sortBy = 'fees24h';
    if (widget.initialCategories != null && widget.initialCategories!.isNotEmpty) {
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
      final db = await _service.fetchDashboard(dataType: 'dexs');
      _dashboardStats = db.stats;
    } catch (_) {
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      if (_selectedType == 'chains') {
        final allChains = await _service.fetchChainsList();
        List<DexChainMetrics> filtered = allChains;
        if (_searchQuery.trim().isNotEmpty) {
          final query = _searchQuery.trim().toLowerCase();
          filtered = allChains.where((c) => c.chain.toLowerCase().contains(query)).toList();
        }

        setState(() {
          _totalCount = filtered.length;
          _totalPages = (_totalCount / _limit).ceil();
          if (_totalPages < 1) _totalPages = 1;

          if (_currentPage > _totalPages) {
            _currentPage = _totalPages;
          } else if (_currentPage < 1) {
            _currentPage = 1;
          }

          final startIndex = (_currentPage - 1) * _limit;
          final endIndex = startIndex + _limit;

          _chains = filtered.sublist(
            startIndex,
            endIndex > _totalCount ? _totalCount : endIndex,
          );
          _protocols = [];
          _isLoading = false;
        });
      } else if (_selectedType == 'hl_l1') {
        final list = await _service.fetchTopDexsByVolume();
        final mapped = list.map((item) {
          final slugStr = item.displayName.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-');
          return FeeTopProtocol(
            name: item.displayName,
            slug: slugStr,
            logo: item.logo,
            category: 'Hyperliquid L1',
            chains: ['Hyperliquid L1'],
            fees24h: item.metrics.total24h,
            change1d: item.metrics.change1d,
            change7d: item.metrics.change7d,
            change30d: item.metrics.change30d,
            fees7d: item.metrics.total7d,
            fees30d: item.metrics.total30d,
            fees1y: item.metrics.total1y,
            feesAllTime: item.metrics.totalAllTime,
            children: [],
            childrenSlugs: [],
            protocolType: 'protocol',
            annualized1y: item.metrics.annualized1y,
            average1y: item.metrics.average1y,
          );
        }).toList();

        List<FeeTopProtocol> filtered = mapped;
        if (_searchQuery.trim().isNotEmpty) {
          final query = _searchQuery.trim().toLowerCase();
          filtered = mapped.where((p) => p.name.toLowerCase().contains(query)).toList();
        }

        setState(() {
          _totalCount = filtered.length;
          _totalPages = (_totalCount / _limit).ceil();
          if (_totalPages < 1) _totalPages = 1;

          if (_currentPage > _totalPages) {
            _currentPage = _totalPages;
          } else if (_currentPage < 1) {
            _currentPage = 1;
          }

          final startIndex = (_currentPage - 1) * _limit;
          final endIndex = startIndex + _limit;

          _protocols = filtered.sublist(
            startIndex,
            endIndex > _totalCount ? _totalCount : endIndex,
          );
          _chains = [];
          _isLoading = false;
        });
      } else {
        if (_searchQuery.trim().isNotEmpty) {
          final matches = await _service.searchDexs(_searchQuery.trim());
          List<FeeTopProtocol> filtered = matches;
          if (_selectedCategory != 'ALL') {
            final catLower = _selectedCategory.toLowerCase();
            filtered = matches.where((p) => p.category.toLowerCase() == catLower).toList();
          }

          setState(() {
            _protocols = filtered;
            _chains = [];
            _totalCount = filtered.length;
            _totalPages = 1;
            _currentPage = 1;
            _isLoading = false;
          });
        } else {
          final dataType = _collapseSubProtocols ? 'parents' : 'all';
          final res = await _service.fetchProtocolsPaginated(
            page: _currentPage,
            limit: _limit,
            sortBy: _sortBy,
            sortOrder: _sortOrder,
            category: _selectedCategory == 'ALL' ? null : _selectedCategory,
            dataType: dataType,
            customPrefix: 'dexs',
          );

          setState(() {
            _protocols = res.protocols;
            _chains = [];
            _currentPage = res.page;
            _limit = res.limit;
            _totalCount = res.total;
            _totalPages = res.pages;
            _isLoading = false;
          });
        }
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
            'Volume Explorer',
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
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.brandAccent,
                backgroundColor: const Color(0xFF16191E),
                child: _isLoading && !_hasData
                    ? _buildLoadingSkeleton(res)
                    : _error.isNotEmpty && !_hasData
                    ? _buildErrorView(res)
                    : _buildBodyContent(res),
              ),
            ),
            if (!_isLoading && _hasData) _buildBottomPaginationBar(res),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(Responsive res) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        child: ErrorStateWidget(
          errorMessage: _error.isEmpty ? 'Failed to fetch rankings records.' : _error,
          onRetry: _loadInitialData,
        ),
      ),
    );
  }

  Widget _buildBodyContent(Responsive res) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: res.spacing(14), vertical: res.spacing(10)),
      children: [
        _buildFiltersSection(res),
        const SizedBox(height: 14),
        _selectedType == 'chains' ? _buildChainsTable(res) : _buildTableCard(res),
      ],
    );
  }

  Widget _buildFiltersSection(Responsive res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isSearchFocused ? AppColors.brandAccent.withOpacity(0.5) : AppColors.surfaceBright,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            cursorColor: AppColors.brandAccent,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search protocol or chain...',
              hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary.withOpacity(0.5), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      child: const Icon(Icons.clear_rounded, color: Colors.white60, size: 16),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Type select tabs + hierarchy toggle
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _typeSelectButton('ALL PROTOCOLS', 'all'),
                    const SizedBox(width: 8),
                    _typeSelectButton('CHAINS ONLY', 'chains'),
                    const SizedBox(width: 8),
                    _typeSelectButton('HYPERLIQUID L1', 'hl_l1'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Parent level switch
            if (_selectedType != 'chains' && _selectedType != 'hl_l1')
              GestureDetector(
                onTap: () {
                  setState(() {
                    _collapseSubProtocols = !_collapseSubProtocols;
                    _currentPage = 1;
                  });
                  _loadData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _collapseSubProtocols ? AppColors.brandAccent.withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _collapseSubProtocols ? AppColors.brandAccent.withOpacity(0.3) : AppColors.surfaceBright,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _collapseSubProtocols ? Icons.layers_outlined : Icons.layers_clear_outlined,
                        color: _collapseSubProtocols ? AppColors.brandAccent : AppColors.textSecondary,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Parents',
                        style: GoogleFonts.inter(
                          color: _collapseSubProtocols ? AppColors.brandAccent : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (_selectedType != 'chains' && _selectedType != 'hl_l1') ...[
          const SizedBox(height: 10),
          // Category tags carousel
          SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSel = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                    _currentPage = 1;
                  });
                  _loadData();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.brandAccent : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSel ? AppColors.brandAccent : AppColors.surfaceBright.withOpacity(0.5)),
                  ),
                  child: Text(
                    cat.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      color: isSel ? Colors.black : AppColors.textSecondary,
                      fontSize: res.fontSize(9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
      ],
    );
  }

  Widget _typeSelectButton(String text, String typeVal) {
    final active = _selectedType == typeVal;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = typeVal;
          _currentPage = 1;
        });
        _loadData();
      },
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceBright.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? AppColors.brandAccent.withOpacity(0.4) : Colors.transparent),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: active ? AppColors.brandAccent : AppColors.textSecondary,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCard(Responsive res) {
    if (_protocols.isEmpty && !_isLoading) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded, color: AppColors.textSecondary, size: 28),
              const SizedBox(height: 10),
              Text(
                'No matching records found',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final tableHeaderHeight = 36.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: res.columnWidth(825.0),
              child: Theme(
                data: ThemeData(dividerColor: Colors.transparent),
                child: Column(
                  children: [
                    // Sticky Header row
                    Container(
                      height: tableHeaderHeight,
                      color: const Color(0xFF13161A),
                      child: Row(
                        children: [
                          Container(
                            width: res.columnWidth(130.0),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
                              ),
                            ),
                            child: _buildSortableHeader('NAME', 'name'),
                          ),
                          _buildHeaderCell('24H VOLUME', res, 'fees24h', width: res.columnWidth(85.0)),
                          _buildHeaderCell('1D CHANGE', res, 'change_1d', width: res.columnWidth(80.0)),
                          _buildHeaderCell('7D CHANGE', res, 'change_7d', width: res.columnWidth(80.0)),
                          _buildHeaderCell('7D VOLUME', res, 'fees7d', width: res.columnWidth(90.0)),
                          _buildHeaderCell('30D VOLUME', res, 'fees30d', width: res.columnWidth(90.0)),
                          _buildHeaderCell('1Y VOLUME', res, 'fees1y', width: res.columnWidth(90.0)),
                          _buildHeaderCell('ALL TIME VL', res, 'feesAllTime', width: res.columnWidth(90.0)),
                          Container(
                            width: res.columnWidth(90.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
                              ),
                            ),
                            child: Text(
                              'CATEGORY',
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.textSecondary,
                                fontSize: res.fontSize(8.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Colors.white.withOpacity(0.04), height: 1),
                    // Rows
                    ..._protocols.asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value;
                      final rank = (_currentPage - 1) * _limit + i + 1;

                      final hasSubs = p.childrenSlugs.isNotEmpty;
                      final isExpanded = _expandedParentSlugs.contains(p.slug);

                      return Material(
                        color: i % 2 == 0 ? Colors.transparent : const Color(0xFF13161A).withOpacity(0.2),
                        child: InkWell(
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
                          child: Row(
                            children: [
                              // Name & Logo
                              Container(
                                width: res.columnWidth(130.0),
                                height: 56.0,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      child: Text(
                                        rank.toString(),
                                        style: GoogleFonts.jetBrainsMono(
                                          color: AppColors.textSecondary.withOpacity(0.4),
                                          fontSize: res.fontSize(9),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        p.logo ?? '',
                                        width: 18,
                                        height: 18,
                                        errorBuilder: (_, __, ___) => _fallbackLogo(p.name, res),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: res.fontSize(10.5),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 24H volume
                              Container(
                                width: res.columnWidth(85.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
                                  ),
                                ),
                                child: Text(
                                  _fmtMoney(p.fees24h),
                                  style: GoogleFonts.jetBrainsMono(
                                    color: Colors.white,
                                    fontSize: res.fontSize(10.5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildChangeCell(p.change1d, res, width: res.columnWidth(80.0), cellKey: '${p.slug}_1d'),
                              _buildChangeCell(p.change7d, res, width: res.columnWidth(80.0), cellKey: '${p.slug}_7d'),
                              // 7D Volume
                              Container(
                                width: res.columnWidth(90.0),
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
                              // 30D Volume
                              Container(
                                width: res.columnWidth(90.0),
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
                              // 1Y Volume
                              Container(
                                width: res.columnWidth(90.0),
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
                              // All Time Volume
                              Container(
                                width: res.columnWidth(90.0),
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
                              // Category
                              Container(
                                width: res.columnWidth(90.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
                                  ),
                                ),
                                child: p.category.isNotEmpty
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(p.category).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          p.category.toUpperCase(),
                                          style: GoogleFonts.jetBrainsMono(
                                            color: _getCategoryColor(p.category),
                                            fontSize: res.fontSize(8.5),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        '-',
                                        style: GoogleFonts.jetBrainsMono(
                                          color: AppColors.textSecondary,
                                          fontSize: res.fontSize(11),
                                        ),
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

  Widget _buildHeaderCell(String text, Responsive res, String fieldName, {double? width}) {
    final isSorted = _sortBy == fieldName;
    return GestureDetector(
      onTap: () => _toggleSort(fieldName),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.jetBrainsMono(
                  color: isSorted ? AppColors.brandAccent : AppColors.textSecondary,
                  fontSize: res.fontSize(8.5),
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
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

  Widget _buildChangeCell(double value, Responsive res, {required double width, required String cellKey}) {
    final isZero = value == 0.0;
    final isPositive = value > 0;
    final isVisible = _visiblePercentageKeys.contains(cellKey);

    final absVal = value.abs();
    final double fraction = (absVal / 20.0).clamp(0.0, 1.0);
    final double opacity = 0.06 + (fraction * 0.49);

    final bgColor = isZero
        ? const Color(0xFF1E293B).withOpacity(0.1)
        : (isPositive 
            ? const Color(0xFF047857).withOpacity(opacity)
            : const Color(0xFFB91C1C).withOpacity(opacity));

    final textColor = isZero
        ? const Color(0xFF94A3B8)
        : (isPositive ? const Color(0xFF4ADE80) : const Color(0xFFF87171));
    final arrow = isPositive ? '↑' : (isZero ? '' : '↓');
    final formattedValue = isZero 
        ? '0.00%' 
        : (isVisible ? '$arrow ${value.abs().toStringAsFixed(2)}%' : arrow);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_visiblePercentageKeys.contains(cellKey)) {
            _visiblePercentageKeys.remove(cellKey);
          } else {
            _visiblePercentageKeys.add(cellKey);
          }
        });
      },
      child: Container(
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
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E222D).withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$_currentPage of $_totalPages',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white70,
              fontSize: res.fontSize(10.5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4),
        _buildPageIcon(Icons.chevron_right, _currentPage < _totalPages ? () {
          setState(() => _currentPage++);
          _loadData();
        } : null, res),
      ],
    );
  }

  Widget _buildPageIcon(IconData icon, VoidCallback? onTap, Responsive res) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: enabled ? AppColors.surfaceBright.withOpacity(0.12) : AppColors.surface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : AppColors.textSecondary.withOpacity(0.3),
          size: res.fontSize(16),
        ),
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

  Color _getCategoryColor(String c) {
    switch (c.toLowerCase().trim()) {
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
        return const Color(0xFF8E9AA6);
    }
  }

  Widget _buildChainsTable(Responsive res) {
    if (_chains.isEmpty && !_isLoading) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded, color: AppColors.textSecondary, size: 28),
              const SizedBox(height: 10),
              Text(
                'No matching chains found',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final tableHeaderHeight = 36.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: res.columnWidth(825.0),
              child: Theme(
                data: ThemeData(dividerColor: Colors.transparent),
                child: Column(
                  children: [
                    // Sticky Header row
                    Container(
                      height: tableHeaderHeight,
                      color: const Color(0xFF13161A),
                      child: Row(
                        children: [
                          Container(
                            width: res.columnWidth(150.0),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
                              ),
                            ),
                            child: Text(
                              'CHAIN NAME',
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.textSecondary,
                                fontSize: res.fontSize(8.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildChainsHeaderCell('24H VOLUME', res, width: res.columnWidth(130.0)),
                          _buildChainsHeaderCell('7D VOLUME', res, width: res.columnWidth(130.0)),
                          _buildChainsHeaderCell('30D VOLUME', res, width: res.columnWidth(130.0)),
                          _buildChainsHeaderCell('1Y VOLUME', res, width: res.columnWidth(130.0)),
                          _buildChainsHeaderCell('PROTOCOLS', res, width: res.columnWidth(100.0)),
                        ],
                      ),
                    ),
                    Divider(color: Colors.white.withOpacity(0.04), height: 1),
                    // Rows
                    ..._chains.asMap().entries.map((entry) {
                      final i = entry.key;
                      final c = entry.value;
                      final rank = (_currentPage - 1) * _limit + i + 1;

                      return Material(
                        color: i % 2 == 0 ? Colors.transparent : const Color(0xFF13161A).withOpacity(0.2),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => DefiVolumeChainDetailScreen(chain: c.chain),
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              // Name
                              Container(
                                width: res.columnWidth(150.0),
                                height: 56.0,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      child: Text(
                                        rank.toString(),
                                        style: GoogleFonts.jetBrainsMono(
                                          color: AppColors.textSecondary.withOpacity(0.4),
                                          fontSize: res.fontSize(9),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        c.chain,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.jetBrainsMono(
                                          color: Colors.white,
                                          fontSize: res.fontSize(10),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildChainsCell(_fmtMoney(c.totalVolume24h), res, width: res.columnWidth(130.0)),
                              _buildChainsCell(_fmtMoney(c.totalVolume7d), res, width: res.columnWidth(130.0)),
                              _buildChainsCell(_fmtMoney(c.totalVolume30d), res, width: res.columnWidth(130.0)),
                              _buildChainsCell(_fmtMoney(c.totalVolume1y), res, width: res.columnWidth(130.0)),
                              _buildChainsCell(c.protocolCount.toString(), res, width: res.columnWidth(100.0)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChainsHeaderCell(String label, Responsive res, {required double width}) {
    return Container(
      width: width,
      height: 36,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          color: AppColors.textSecondary,
          fontSize: res.fontSize(8.5),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChainsCell(String text, Responsive res, {required double width}) {
    return Container(
      width: width,
      height: 56,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          color: Colors.white,
          fontSize: res.fontSize(10),
          fontWeight: FontWeight.bold,
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
          children: [
            Container(height: 38, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 10),
            Row(children: [
              Container(width: 80, height: 26, color: Colors.white),
              const SizedBox(width: 8),
              Container(width: 80, height: 26, color: Colors.white),
            ]),
            const SizedBox(height: 14),
            Container(
              height: res.spacing(450),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            )
          ],
        ),
      ),
    );
  }
}
