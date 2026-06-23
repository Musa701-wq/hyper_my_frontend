import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/common_widgets.dart';
import '../viewmodels/protocol_viewmodel.dart';
import '../models/protocol_model.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/tvl/category_distribution_chart.dart';
import '../widgets/tvl/chain_focus_chart.dart';
import '../widgets/tvl/top_chains_chart.dart';
import '../widgets/tvl/ecosystem_treemap.dart';
import '../widgets/shimmer_skeleton.dart';
import 'protocol_detail_screen.dart';

class ProtocolsScreen extends StatefulWidget {
  const ProtocolsScreen({super.key});

  @override
  State<ProtocolsScreen> createState() => _ProtocolsScreenState();
}

class _ProtocolsScreenState extends State<ProtocolsScreen> {
  bool _isSearchVisible = false;
  bool _isFooterShowBar = false;
  bool _showAllBarProtocols = false;

  static const double headerH = 48.0;
  static const double rowH = 60.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ProtocolViewModel>();
      vm.fetchProtocols();
      vm.fetchCategoryDistribution();
      vm.fetchChainFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    final vm = context.watch<ProtocolViewModel>();

    return AppBackground(
      child: DefaultTabController(
        length: 2,
        initialIndex: vm.mainTabIndex,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(res, vm),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(), // Handle switching via VM if needed, or keeping it enabled
          children: [
            _buildCategoryView(vm, res),
            _buildChainView(vm, res),
          ],
        ),
      ),
    ),
  );
  }

  PreferredSizeWidget _buildAppBar(Responsive res, ProtocolViewModel vm) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Protocol TVL',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.brandAccent,
                  fontSize: res.fontSize(18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              if (vm.isLoading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandAccent),
                ),
            ],
          ),
          Text(
            'Explore Total Value Locked across the ecosystem',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: res.fontSize(10),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            vm.isSearchExpanded ? Icons.search_off_rounded : Icons.search_rounded,
            color: vm.isSearchExpanded ? AppColors.brandAccent : Colors.white,
          ),
          onPressed: () => vm.toggleSearchExpanded(),
          tooltip: 'Toggle Search',
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          width: double.infinity,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceBright.withOpacity(0.1)),
          ),
          child: TabBar(
            onTap: (index) => vm.setMainTab(index),
            indicator: BoxDecoration(
              color: AppColors.brandAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.brandAccent.withOpacity(0.4), width: 1.5),
            ),
            dividerColor: Colors.transparent,
            labelColor: AppColors.brandAccent,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
            unselectedLabelStyle: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
            padding: EdgeInsets.zero,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'TVL BY CATEGORY'),
              Tab(text: 'TVL BY CHAIN'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryView(ProtocolViewModel vm, Responsive res) {
    return Column(
      children: [
        _buildFilterBar(vm, res),
        Expanded(
          child: IndexedStack(
            index: vm.tvlViewIndex,
            children: [
              _buildGridView(vm, res),
              _buildListView(vm, res),
              _buildChartView(vm, res),
            ],
          ),
        ),
        if (vm.tvlViewIndex != 2) // Hide for Charts view
          _buildBottomPaginationBar(vm, res),
      ],
    );
  }

  Widget _buildChainView(ProtocolViewModel vm, Responsive res) {
    if (vm.isChainsLoading) {
      return _buildShimmer(res);
    }

    if (vm.topChains.isEmpty) {
      return Center(
        child: Text(
          'No chain data available',
          style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(res.spacing(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChainFocusChart(
            allData: vm.chainFocusData,
            chains: vm.chainFocusData.map((e) => e.chain).toList(),
            selectedChain: vm.selectedChain,
            onChainChanged: (chain) => vm.setSelectedChain(chain),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector(ProtocolViewModel vm, Responsive res) {
    return Container(
      height: 30, // Decreased from 36
      padding: const EdgeInsets.all(2.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSelectorIcon(0, Icons.grid_view_rounded, vm.tvlViewIndex == 0, () => vm.setTvlView(0)),
          const SizedBox(width: 4),
          _buildSelectorIcon(1, Icons.list_alt_rounded, vm.tvlViewIndex == 1, () => vm.setTvlView(1)),
          const SizedBox(width: 4),
          _buildSelectorIcon(2, Icons.bar_chart_rounded, vm.tvlViewIndex == 2, () => vm.setTvlView(2)),
        ],
      ),
    );
  }

  Widget _buildSelectorIcon(int index, IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Adjusted from 12, 6
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandAccent.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: AppColors.brandAccent.withOpacity(0.4), width: 1)
              : Border.all(color: Colors.transparent, width: 1),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isActive ? AppColors.brandAccent : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFilterBar(ProtocolViewModel vm, Responsive res) {
    final currentSearch = vm.tvlViewIndex == 0 ? vm.gridSearch : (vm.tvlViewIndex == 1 ? vm.listSearch : vm.chartSearch);

    return Container(
      padding: EdgeInsets.fromLTRB(
        res.spacing(16),
        res.spacing(16),
        res.spacing(16),
        res.spacing(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 130,
                child: _buildCategoryDropdown(vm, res, vm.tvlViewIndex == 0 ? 'GRID' : (vm.tvlViewIndex == 1 ? 'LIST' : 'CHARTS')),
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                label: vm.isAscending ? 'Lowest' : 'Highest',
                icon: vm.isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                isActive: true,
                res: res,
                onTap: () => vm.toggleSortOrder(),
              ),
              const Spacer(),
              _buildViewSelector(vm, res),
            ],
          ),
          const SizedBox(height: 12),
          if (vm.tvlViewIndex != 2 && vm.isSearchExpanded) // Hide search for Charts or if not expanded
            Row(
              children: [
                Expanded(
                  child: _buildSearchField(vm, res, vm.tvlViewIndex == 0 ? 'GRID' : (vm.tvlViewIndex == 1 ? 'LIST' : 'CHARTS')),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                  onPressed: () => vm.toggleSearchExpanded(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBottomPaginationBar(ProtocolViewModel vm, Responsive res) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: res.spacing(16), vertical: res.spacing(10)),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.surfaceBright.withOpacity(0.1))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Left: Rows selector
            Text(
              'Rows:',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            _buildRowsPill(vm, res),

            const Spacer(),

            // Right: Pagination controls
            _buildPaginationRow(vm, res),
          ],
        ),
      ),
    );
  }

  Widget _buildRowsPill(ProtocolViewModel vm, Responsive res) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: vm.limit,
          dropdownColor: AppColors.background,
          icon: const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textSecondary),
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          items: [20, 50, 100].map((val) {
            return DropdownMenuItem<int>(
              value: val,
              child: Text(val.toString()),
            );
          }).toList(),
          onChanged: (val) => vm.setLimit(val ?? 20),
        ),
      ),
    );
  }

  Widget _buildPaginationRow(ProtocolViewModel vm, Responsive res) {
    if (vm.totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPageIcon(Icons.chevron_left, vm.currentPage > 1 ? () => vm.setPage(vm.currentPage - 1) : null),
        const SizedBox(width: 4),
        ..._buildPageNumbersList(vm),
        const SizedBox(width: 4),
        _buildPageIcon(Icons.chevron_right, vm.currentPage < vm.totalPages ? () => vm.setPage(vm.currentPage + 1) : null),
      ],
    );
  }

  List<Widget> _buildPageNumbersList(ProtocolViewModel vm) {
    List<Widget> children = [];
    int total = vm.totalPages;
    int current = vm.currentPage;

    for (int i = 1; i <= total; i++) {
      if (i == 1 || i == total || (i >= current - 1 && i <= current + 1)) {
        children.add(_buildPageNumberItem(i, i == current, () => vm.setPage(i)));
        if (i < total && (i == 1 && current > 3 || i == current + 1 && current < total - 2)) {
          children.add(Text('...', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10)));
        }
      }
    }
    return children;
  }

  Widget _buildPageNumberItem(int page, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.brandAccent.withOpacity(0.14)
              : AppColors.surfaceBright.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppColors.brandAccent.withOpacity(0.4)
                : AppColors.surfaceBright.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Text(
          page.toString(),
          style: GoogleFonts.jetBrainsMono(
            color: isActive ? AppColors.brandAccent : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(ProtocolViewModel vm, Responsive res, String viewType) {
    final currentSearch = viewType == 'GRID' ? vm.gridSearch : (viewType == 'LIST' ? vm.listSearch : vm.chartSearch);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: currentSearch)..selection = TextSelection.collapsed(offset: currentSearch.length),
              onChanged: (val) {
                if (viewType == 'GRID') vm.setGridSearch(val);
                else if (viewType == 'LIST') vm.setListSearch(val);
                else vm.setChartSearch(val);
              },
              style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search protocols...',
                hintStyle: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (currentSearch.isNotEmpty)
            GestureDetector(
              onTap: () {
                if (viewType == 'GRID') vm.setGridSearch('');
                else if (viewType == 'LIST') vm.setListSearch('');
                else vm.setChartSearch('');
              },
              child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(ProtocolViewModel vm, Responsive res, String viewType) {
    final selectedCat = viewType == 'GRID' ? vm.gridCategory : (viewType == 'LIST' ? vm.listCategory : vm.chartCategory);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, size: 14, color: AppColors.brandAccent),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCat,
                dropdownColor: AppColors.background,
                icon: const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textSecondary),
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                isExpanded: true,
                items: vm.categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val == null) return;
                  if (viewType == 'GRID') vm.setGridCategory(val);
                  else if (viewType == 'LIST') vm.setListCategory(val);
                  else vm.setChartCategory(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownPill<T>({
    required T value,
    required IconData icon,
    String? prefix,
    required List<T> options,
    required ValueChanged<T?> onChanged,
    required Responsive res,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brandAccent),
          const SizedBox(width: 8),
          DropdownButton<T>(
            value: value,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textSecondary),
            dropdownColor: AppColors.surfaceBright,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold
            ),
            items: options.map((opt) {
              return DropdownMenuItem<T>(
                value: opt,
                child: Text(prefix != null ? '$prefix $opt' : opt.toString()),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required IconData icon,
    bool isActive = false,
    required Responsive res,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.brandAccent.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.brandAccent.withOpacity(0.4)
                : AppColors.surfaceBright.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.brandAccent : AppColors.textSecondary
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(ProtocolViewModel vm, Responsive res) {
    return _buildListBody(vm, res);
  }

  Widget _buildListBody(ProtocolViewModel vm, Responsive res) {
    if (vm.isLoading && vm.protocols.isEmpty) {
      return _buildShimmer(res);
    }

    if (vm.errorMessage.isNotEmpty) {
      return ErrorStateWidget(
        errorMessage: vm.errorMessage,
        onRetry: () => vm.fetchProtocols(),
      );
    }

    final protocols = vm.paginatedListProtocols;

    if (protocols.isEmpty) {
      return Center(
        child: Text(
          'No protocols found',
          style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary),
        ),
      );
    }

    final headerH = 40.0;
    final rowH = 56.0;
    final fixedW = res.columnWidth(180);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed Left Column
              SizedBox(
                width: fixedW,
                child: Column(
                  children: [
                    _buildFixedHeader(headerH, res),
                    ...protocols.asMap().entries.map((entry) {
                       final p = entry.value;
                       final globalIndex = (vm.currentPage - 1) * vm.itemsPerPage + entry.key + 1;
                       return _buildFixedRow(p, globalIndex, rowH, res);
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
                      _buildScrollableHeader(headerH, res),
                      ...protocols.map((p) => _buildScrollableRow(p, rowH, res)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (vm.listCategory != 'All Categories' || vm.listSearch.isNotEmpty)
            _buildCategorySummary(vm, res, vm.listProtocols, vm.listCategory),
        ],
      ),
    );
  }

  Widget _buildFixedHeader(double height, Responsive res) {
    return Container(
      height: height,
      padding: const EdgeInsets.only(left: 8, right: 4), // Matched Home screen
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('#', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
          const SizedBox(width: 4),
          Expanded(child: Text('PROTOCOL', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildFixedRow(Protocol p, int index, double height, Responsive res) {
    return InkWell(
      onTap: () => _navigateToDetail(p),
      child: Container(
        height: height,
        padding: const EdgeInsets.only(left: 8, right: 4, top: 10, bottom: 10), // Matched Home screen
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
        ),
        child: Row(
          children: [
            SizedBox(width: 30, child: Text(index.toString(), style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10))),
            const SizedBox(width: 4),
            _buildProtocolIcon(p.logo, 20), // Matched Home icon size
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Flexible(
                        child: Text(
                          p.name,
                          style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (p.type == 'core')
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified, size: 10, color: AppColors.brandAccent),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableHeader(double height, Responsive res) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
      ),
      child: Row(
        children: [
          _buildTableHeader('CATEGORY', 120, res),
          _buildTableHeader('TYPE', 90, res),
          _buildTableHeader('TVL', 140, res),
        ],
      ),
    );
  }

  Widget _buildScrollableRow(Protocol p, double height, Responsive res) {
    return InkWell(
      onTap: () => _navigateToDetail(p),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
        ),
        child: Row(
          children: [
            _buildTextCell(p.category.toUpperCase(), 120, Colors.white.withOpacity(0.8), res),
            _buildTextCell(p.type.toUpperCase(), 90, p.type == 'core' ? AppColors.brandAccent : AppColors.textSecondary, res),
            _buildTvlCell(p, 140, res),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String title, double width, Responsive res, {TextAlign textAlign = TextAlign.center}) {
    return SizedBox(
      width: width,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            textAlign: textAlign,
            style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCell(String category, double width, Responsive res) {
    return SizedBox(
      width: width,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceBright.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            category,
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildTextCell(String text, double width, Color color, Responsive res) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.jetBrainsMono(color: color, fontSize: 10, fontWeight: FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildTvlCell(Protocol p, double width, Responsive res) {
    return SizedBox(
      width: width,
      child: Container(
        alignment: Alignment.center, // Changed from centerRight
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          p.fullTvl,
          style: GoogleFonts.jetBrainsMono(
            color: p.type == 'core'
                ? AppColors.brandAccent.withOpacity(0.85)
                : Colors.white.withOpacity(0.85),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildChangeCell(double? change, double width, Responsive res) {
    if (change == null) return _buildTextCell('-', width, AppColors.textSecondary, res);
    final isPositive = change >= 0;
    final color = isPositive ? AppColors.trendGreen : AppColors.trendRed;
    return SizedBox(
      width: width,
      child: Container(
        alignment: Alignment.center, // Changed from centerRight
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: color, size: 16),
            Text(
              '${change.abs().toStringAsFixed(2)}%',
              style: GoogleFonts.jetBrainsMono(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildPageIcon(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceBright.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 20, color: onTap != null ? Colors.white : AppColors.textSecondary.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildPageNumber(int current, int total) {
    return Text(
      'PAGE $current OF $total',
      style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
    );
  }

  void _navigateToDetail(Protocol p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProtocolDetailScreen(
          slug: p.slug,
          name: p.name,
          logo: p.logo,
        ),
      ),
    );
  }

  Widget _buildCategorySummary(ProtocolViewModel vm, Responsive res, List<Protocol> protocols, String categoryName) {
    if (protocols.isEmpty) return const SizedBox.shrink();

    final categoryTvl = protocols.fold<double>(0, (sum, p) => sum + p.tvl);
    final globalTvl = vm.totalTvl;
    final pctOfTotal = globalTvl > 0 ? (categoryTvl / globalTvl * 100) : 0.0;

    final displayProtocols = protocols.take(8).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16191F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${protocols.length} PROJECTS',
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textSecondary.withOpacity(0.5),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${pctOfTotal.toStringAsFixed(1)}% OF TOTAL TVL',
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.brandAccent.withOpacity(0.7),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Compact Toggle
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBright.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildFooterToggleItem(Icons.pie_chart_outline, !_isFooterShowBar, () => setState(() => _isFooterShowBar = false)),
                    const SizedBox(width: 4),
                    _buildFooterToggleItem(Icons.leaderboard_rounded, _isFooterShowBar, () => setState(() => _isFooterShowBar = true)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          if (_isFooterShowBar)
            _buildFooterBarChart(displayProtocols, categoryTvl)
          else
            _buildFooterPieChart(displayProtocols, categoryTvl),
        ],
      ),
    );
  }

  Widget _buildFooterToggleItem(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isActive ? Colors.black : AppColors.textSecondary.withOpacity(0.5)
        ),
      ),
    );
  }

  Widget _buildFooterBarChart(List<Protocol> protocols, double total) {
    final colors = [
      AppColors.brandAccent,
      const Color(0xFF7C3AED),
      const Color(0xFFD97706),
      const Color(0xFF0D9488),
      const Color(0xFF60A5FA),
      const Color(0xFFF43F5E),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = 80.0;
        return Column(
          children: protocols.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final share = total > 0 ? (p.tvl / total) : 0.0;
            final color = colors[i % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: labelWidth,
                    child: Text(
                      p.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBright.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          height: 14,
                          width: (constraints.maxWidth - labelWidth - 10 - 60) * share,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '${(share * 100).toStringAsFixed(1)}%',
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              shadows: [const Shadow(color: Colors.black, blurRadius: 2)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 50,
                    child: Text(
                      p.fullTvl,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 8),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      }
    );
  }

  Widget _buildFooterPieChart(List<Protocol> protocols, double total) {
    final colors = [
      AppColors.brandAccent,
      const Color(0xFF7C3AED),
      const Color(0xFFD97706),
      const Color(0xFF0D9488),
      const Color(0xFF60A5FA),
      const Color(0xFFF43F5E),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
    ];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 50,
              sections: protocols.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                final share = total > 0 ? (p.tvl / total * 100) : 0.0;

                return PieChartSectionData(
                  color: colors[i % colors.length],
                  value: p.tvl,
                  title: share > 8 ? '${share.toStringAsFixed(0)}%' : '',
                  radius: 50,
                  titleStyle: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  badgeWidget: share > 15 ? Text(
                    p.name,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ) : null,
                  badgePositionPercentageOffset: 1.3,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: protocols.asMap().entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors[entry.key % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  entry.value.name.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProtocolIcon(String logoUrl, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        logoUrl,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => Icon(Icons.token, size: size, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildGridView(ProtocolViewModel vm, Responsive res) {
    return _buildGridBody(vm, res);
  }



  Widget _buildGridBody(ProtocolViewModel vm, Responsive res) {
    if (vm.isLoading) {
      return _buildShimmer(res);
    }

    if (vm.errorMessage.isNotEmpty) {
      return ErrorStateWidget(
        errorMessage: vm.errorMessage,
        onRetry: () => vm.fetchProtocols(),
      );
    }

    final displayProtocols = vm.gridProtocols;

    if (displayProtocols.isEmpty) {
      return Center(
        child: Text(
          'No protocols found',
          style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 4 : screenWidth > 800 ? 3 : 2;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(res.spacing(16)),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: res.spacing(16),
              mainAxisSpacing: res.spacing(16),
              childAspectRatio: 1.1,
            ),
            itemCount: displayProtocols.length,
            itemBuilder: (context, index) {
              final p = displayProtocols[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProtocolDetailScreen(
                        slug: p.slug,
                        name: p.name,
                        logo: p.logo,
                      ),
                    ),
                  );
                },
                child: _ProtocolCard(protocol: p),
              );
            },
          ),
          if (vm.gridCategory != 'All Categories' || vm.gridSearch.isNotEmpty)
            _buildCategorySummary(vm, res, vm.gridProtocols, vm.gridCategory),
        ],
      ),
    );
  }

  Widget _buildChartView(ProtocolViewModel vm, Responsive res) {
    if (vm.isLoading && vm.protocols.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brandAccent));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(res.spacing(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _buildSummaryRow(vm, res),
          ),
          const SizedBox(height: 28),
          EcosystemTreeMap(protocols: vm.chartProtocols),
          const SizedBox(height: 24),
          _buildProtocolBarChart(vm, res),
          const SizedBox(height: 24),
          if (res.isMobile) ...[
            _buildCategoryDist(vm, res),
          ] else
            _buildCategoryDist(vm, res),
        ],
      ),
    );
  }
  Widget _buildSummaryRow(ProtocolViewModel vm, Responsive res) {
    final protocols = vm.chartProtocols;
    final uniqueTypes = protocols.map((p) => p.type).toSet().length;

    final stats = [
      {'label': 'ALL', 'value': protocols.length.toString(), 'icon': Icons.layers_outlined},
      {'label': 'HIGHEST', 'value': protocols.isEmpty ? '\$0' : _fmtCompactTvl(protocols.map((p) => p.tvl).reduce((a, b) => a > b ? a : b)), 'icon': Icons.trending_up_rounded},
      {'label': 'TYPES', 'value': uniqueTypes.toString(), 'icon': Icons.category_outlined},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 12.0;
        return Row(
          children: stats.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return [
              Expanded(child: _buildStatCard(s['label'] as String, s['value'] as String, s['icon'] as IconData)),
              if (i < stats.length - 1) SizedBox(width: spacing),
            ];
          }).expand((w) => w).toList(),
        );
      }
    );
  }

  String _fmtCompactTvl(double value) {
    if (value >= 1e9) return '\$${(value / 1e9).toStringAsFixed(1)}B';
    if (value >= 1e6) return '\$${(value / 1e6).toStringAsFixed(1)}M';
    if (value >= 1e3) return '\$${(value / 1e3).toStringAsFixed(1)}K';
    return '\$${value.toStringAsFixed(0)}';
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    const accentColor = Color(0xFF2EE2BA);
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: accentColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolBarChart(ProtocolViewModel vm, Responsive res) {
    final protocols = vm.chartProtocols;
    if (protocols.isEmpty) {
      return const SizedBox.shrink();
    }

    final allSorted = List<Protocol>.from(protocols)
      ..sort((a, b) => b.tvl.compareTo(a.tvl));
    final sorted = _showAllBarProtocols ? allSorted : allSorted.take(10).toList();

    final maxTvl = sorted.first.tvl;
    const double yLabelWidth = 85.0;
    const double barH = 20.0;
    final chartH = sorted.length * rowH;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Protocols by TVL',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _showAllBarProtocols ? 'All ${allSorted.length} protocols' : 'Showing top 10 of ${allSorted.length}',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _showAllBarProtocols = !_showAllBarProtocols),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brandAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.brandAccent.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _showAllBarProtocols ? 'COLLAPSE' : 'VIEW ALL',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.brandAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showAllBarProtocols ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.brandAccent,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLegend(),
          const SizedBox(height: 12),
          SizedBox(
            height: chartH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y Labels
                SizedBox(
                  width: yLabelWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: sorted.map((p) {
                      return SizedBox(
                        height: rowH,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              p.name,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.jetBrainsMono(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Bars Area
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final chartW = constraints.maxWidth;
                      return Stack(
                        children: [
                          // Grid lines
                          ...List.generate(5, (i) {
                            final x = chartW * (i / 4.0);
                            return Positioned(
                              left: x,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 1,
                                color: AppColors.surfaceBright.withOpacity(0.08),
                              ),
                            );
                          }),
                          // Bars
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: sorted.map((p) {
                              final isHyperliquid = p.type == 'core' || p.type == 'ecosystem';
                              final ratio = maxTvl > 0 ? (p.tvl / maxTvl) : 0.0;
                              final barColor = isHyperliquid ? AppColors.brandAccent : _categoryColor(p.category);
                              return SizedBox(
                                height: rowH,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: (rowH - barH) / 2),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            Container(
                                              height: barH,
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceBright.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 800),
                                              curve: Curves.easeOutCubic,
                                              width: (chartW * ratio).clamp(4.0, chartW).toDouble(), // Min width fix
                                              height: barH,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(4),
                                                color: barColor,
                                                boxShadow: isHyperliquid ? [
                                                  BoxShadow(
                                                    color: barColor.withOpacity(0.3),
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  )
                                                ] : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 90,
                                        child: Text(
                                          p.fullTvl,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.jetBrainsMono(
                                            color: isHyperliquid
                                                ? AppColors.brandAccent.withOpacity(0.85)
                                                : Colors.white70.withOpacity(0.85),
                                            fontSize: 10,
                                            fontWeight: isHyperliquid ? FontWeight.bold : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDist(ProtocolViewModel vm, Responsive res) {
    return CategoryDistributionChart(data: vm.categoryDistribution);
  }

  Widget _buildTopProtocolsByCategory(ProtocolViewModel vm, Responsive res) {
    return _TopProtocolsByCategoryWidget(protocols: vm.chartProtocols);
  }


  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Hyperliquid', AppColors.brandAccent),
        const SizedBox(width: 20),
        _legendItem('Other Protocols', const Color(0xFF60A5FA)),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  Color _categoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('cex')) return const Color(0xFF7C3AED);
    if (lower.contains('dex')) return const Color(0xFF0D9488);
    if (lower.contains('lending')) return const Color(0xFFD97706);
    if (lower.contains('rwa')) return const Color(0xFF60A5FA);
    if (lower.contains('liquid')) return const Color(0xFF10B981);
    if (lower.contains('bridge')) return const Color(0xFFF43F5E);
    if (lower.contains('yield')) return const Color(0xFF8B5CF6);
    if (lower.contains('derivative')) return const Color(0xFFEC4899);
    return const Color(0xFF60A5FA);
  }

  Widget _buildShimmer(Responsive res) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(res.spacing(16)),
        child: Column(
          children: List.generate(8, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                ShimmerSkeleton.box(40, 40, radius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerSkeleton.pill(120, 14),
                      const SizedBox(height: 8),
                      ShimmerSkeleton.pill(80, 10),
                    ],
                  ),
                ),
                ShimmerSkeleton.pill(60, 16),
              ],
            ),
          )),
        ),
      ),
    );
  }
}



class _ProtocolCard extends StatelessWidget {
  final Protocol protocol;

  const _ProtocolCard({required this.protocol});

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);

    return Container(
      padding: EdgeInsets.all(res.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.surfaceBright.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    protocol.logo,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 38,
                      height: 38,
                      color: AppColors.surfaceBright,
                      child: const Icon(Icons.token, size: 20, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            protocol.name,
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white,
                              fontSize: res.fontSize(13),
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (protocol.type == 'core')
                          const Icon(Icons.verified, size: 14, color: AppColors.brandAccent),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brandAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.brandAccent.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        protocol.category.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.brandAccent,
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL VALUE LOCKED',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 7,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        protocol.fullTvl,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: res.fontSize(14),
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  if (protocol.change1d != null)
                    _buildMiniChangePill(protocol.change1d!),
                ],
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBright.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'RANK #${protocol.rank}',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'DETAILS',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.brandAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.brandAccent),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChangePill(double change) {
    final isPositive = change >= 0;
    final color = isPositive ? AppColors.trendGreen : AppColors.trendRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: color, size: 14),
          Text(
            '${change.abs().toStringAsFixed(1)}%',
            style: GoogleFonts.jetBrainsMono(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Protocols by Category Widget ─────────────────────────────────────────
class _TopProtocolsByCategoryWidget extends StatefulWidget {
  final List<Protocol> protocols;
  const _TopProtocolsByCategoryWidget({required this.protocols});

  @override
  State<_TopProtocolsByCategoryWidget> createState() => _TopProtocolsByCategoryWidgetState();
}

class _TopProtocolsByCategoryWidgetState extends State<_TopProtocolsByCategoryWidget> {
  String? _expandedCategory;
  static const int _previewCount = 10;

  static const _categoryColors = [
    Color(0xFF2EE2BA), Color(0xFF7C3AED), Color(0xFFD97706), Color(0xFF0D9488),
    Color(0xFF60A5FA), Color(0xFFF43F5E), Color(0xFF10B981), Color(0xFF8B5CF6),
    Color(0xFFEC4899), Color(0xFF14B8A6), Color(0xFFF97316), Color(0xFF6366F1),
  ];

  Map<String, List<Protocol>> _groupByCategory() {
    final map = <String, List<Protocol>>{};
    for (final p in widget.protocols) {
      map.putIfAbsent(p.category, () => []).add(p);
    }
    // Sort each category's protocols by TVL desc
    for (final key in map.keys) {
      map[key]!.sort((a, b) => b.tvl.compareTo(a.tvl));
    }
    // Sort categories by total TVL desc
    final sorted = map.entries.toList()
      ..sort((a, b) {
        final tvlA = a.value.fold<double>(0, (s, p) => s + p.tvl);
        final tvlB = b.value.fold<double>(0, (s, p) => s + p.tvl);
        return tvlB.compareTo(tvlA);
      });
    return Map.fromEntries(sorted);
  }

  String _fmt(double v) {
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1)}M';
    return '\$${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByCategory();
    final categories = grouped.keys.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.category_outlined, color: Color(0xFF2EE2BA), size: 16),
              const SizedBox(width: 8),
              Text(
                'TOP PROTOCOLS BY CATEGORY',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...categories.asMap().entries.map((entry) {
            final idx = entry.key;
            final cat = entry.value;
            final protocols = grouped[cat]!;
            final color = _categoryColors[idx % _categoryColors.length];
            final isExpanded = _expandedCategory == cat;
            final preview = protocols.take(_previewCount).toList();
            final hasMore = protocols.length > _previewCount;
            final displayed = isExpanded ? protocols : preview;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category header row
                GestureDetector(
                  onTap: hasMore
                      ? () => setState(() => _expandedCategory = isExpanded ? null : cat)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cat.toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${protocols.length}',
                            style: GoogleFonts.jetBrainsMono(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (hasMore) ...[
                          Text(
                            isExpanded ? 'COLLAPSE' : 'VIEW ALL',
                            style: GoogleFonts.jetBrainsMono(
                              color: color.withOpacity(0.7),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: color.withOpacity(0.7),
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Protocol rows
                ...displayed.asMap().entries.map((pEntry) {
                  final rank = pEntry.key + 1;
                  final p = pEntry.value;
                  final isHL = p.name.toLowerCase().contains('hyperliquid');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isHL
                          ? AppColors.brandAccent.withOpacity(0.05)
                          : AppColors.surfaceBright.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isHL
                            ? AppColors.brandAccent.withOpacity(0.15)
                            : AppColors.surfaceBright.withOpacity(0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text(
                            '#$rank',
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.textSecondary.withOpacity(0.35),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.jetBrainsMono(
                              color: isHL ? AppColors.brandAccent : Colors.white,
                              fontSize: 10,
                              fontWeight: isHL ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          _fmt(p.tvl),
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }
}
