import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/common_widgets.dart';
import '../viewmodels/protocol_viewmodel.dart';
import '../models/protocol_model.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/tvl/category_distribution_chart.dart';
import '../widgets/tvl/chain_focus_chart.dart';
import '../widgets/tvl/ecosystem_treemap.dart';
import '../widgets/shimmer_skeleton.dart';
import 'protocol_detail_screen.dart';
class ProtocolsScreen extends StatefulWidget {
  const ProtocolsScreen({super.key});

  @override
  State<ProtocolsScreen> createState() => _ProtocolsScreenState();
}

class _ProtocolsScreenState extends State<ProtocolsScreen> {
  bool _isFooterShowBar = false;
  bool _showAllBarProtocols = false;

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
      padding: EdgeInsets.symmetric(
        horizontal: res.spacing(8),
        vertical: res.spacing(12),
      ),
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

  Widget _buildViewDropdown(ProtocolViewModel vm, Responsive res) {
    final views = ['Grid', 'List', 'Chart'];
    final icons = [Icons.grid_view_rounded, Icons.list_alt_rounded, Icons.bar_chart_rounded];
    final currentIndex = vm.tvlViewIndex;

    return _buildPopupSelector<int>(
      value: currentIndex,
      labelBuilder: (i) => views[i].toUpperCase(),
      iconBuilder: (i) => icons[i],
      options: List.generate(views.length, (i) => i),
      onChanged: vm.setTvlView,
      res: res,
    );
  }

  Widget _buildPopupSelector<T>({
    required T value,
    required String Function(T) labelBuilder,
    required IconData Function(T) iconBuilder,
    required List<T> options,
    required ValueChanged<T> onChanged,
    required Responsive res,
    IconData? leadingIcon,
    double? width,
    bool showTriggerIcon = true,
    bool expand = false,
  }) {
    return PopupMenuButton<T>(
      offset: const Offset(0, 36),
      elevation: 8,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15)),
      ),
      color: const Color(0xFF12151A),
      padding: EdgeInsets.zero,
      onSelected: onChanged,
      itemBuilder: (context) => options.map((opt) {
        final selected = opt == value;
        return PopupMenuItem<T>(
          value: opt,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                iconBuilder(opt),
                size: 14,
                color: selected ? AppColors.brandAccent : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  labelBuilder(opt),
                  style: GoogleFonts.jetBrainsMono(
                    color: selected ? AppColors.brandAccent : Colors.white,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 14, color: AppColors.brandAccent),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 32,
        width: expand ? double.infinity : width,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceBright.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceBright.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTriggerIcon) ...[
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 14, color: AppColors.brandAccent),
                const SizedBox(width: 6),
              ] else ...[
                Icon(iconBuilder(value), size: 14, color: AppColors.brandAccent),
                const SizedBox(width: 6),
              ],
            ],
            Flexible(
              child: Text(
                labelBuilder(value),
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(ProtocolViewModel vm, Responsive res) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        res.spacing(12),
        res.spacing(6),
        res.spacing(12),
        res.spacing(6),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Category dropdown — takes available space
              Expanded(
                flex: 3,
                child: _buildCategoryDropdown(vm, res, vm.tvlViewIndex == 0 ? 'GRID' : (vm.tvlViewIndex == 1 ? 'LIST' : 'CHARTS')),
              ),
              const SizedBox(width: 8),
              // Sort pill — fixed size
              _buildFilterPill(
                label: vm.isAscending ? 'Lowest' : 'Highest',
                icon: vm.isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                isActive: true,
                res: res,
                onTap: () => vm.toggleSortOrder(),
              ),
              const SizedBox(width: 8),
              // View dropdown — fixed size
              _buildViewDropdown(vm, res),
            ],
          ),
          if (vm.tvlViewIndex != 2 && vm.isSearchExpanded) ...[
            const SizedBox(height: 8),
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
        ],
      ),
    );
  }

  Widget _buildBottomPaginationBar(ProtocolViewModel vm, Responsive res) {
    final isGrid = vm.tvlViewIndex == 0;
    final currentPage = isGrid ? vm.gridPage : vm.currentPage;
    final totalPages  = isGrid ? vm.gridTotalPages : vm.totalPages;

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
            Text(
              'Rows:',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            _buildRowsPill(vm, res, isGrid: isGrid),
            const Spacer(),
            _buildPaginationRow(
              currentPage: currentPage,
              totalPages: totalPages,
              onPage: isGrid ? vm.setGridPageNum : vm.setPage,
              res: res,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowsPill(ProtocolViewModel vm, Responsive res, {bool isGrid = false}) {
    final currentVal = isGrid ? vm.gridItemsPerPage : vm.limit;
    return _buildPopupSelector<int>(
      value: currentVal,
      labelBuilder: (v) => v.toString(),
      iconBuilder: (_) => Icons.format_list_numbered_rounded,
      options: const [10, 20, 50, 100],
      onChanged: isGrid ? vm.setGridLimit : vm.setLimit,
      res: res,
      showTriggerIcon: false,
      width: 64,
    );
  }

  Widget _buildPaginationRow({
    required int currentPage,
    required int totalPages,
    required void Function(int) onPage,
    required Responsive res,
  }) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPageIcon(Icons.chevron_left, currentPage > 1 ? () => onPage(currentPage - 1) : null),
        const SizedBox(width: 4),
        ..._buildPageNumbersList(currentPage: currentPage, totalPages: totalPages, onPage: onPage),
        const SizedBox(width: 4),
        _buildPageIcon(Icons.chevron_right, currentPage < totalPages ? () => onPage(currentPage + 1) : null),
      ],
    );
  }

  List<Widget> _buildPageNumbersList({
    required int currentPage,
    required int totalPages,
    required void Function(int) onPage,
  }) {
    final List<Widget> children = [];
    for (int i = 1; i <= totalPages; i++) {
      if (i == 1 || i == totalPages || (i >= currentPage - 1 && i <= currentPage + 1)) {
        children.add(_buildPageNumberItem(i, i == currentPage, () => onPage(i)));
        if (i < totalPages && (i == 1 && currentPage > 3 || i == currentPage + 1 && currentPage < totalPages - 2)) {
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

    return _buildPopupSelector<String>(
      value: selectedCat,
      labelBuilder: (v) => v == 'All' ? 'ALL' : v.toUpperCase(),
      iconBuilder: (_) => Icons.category_outlined,
      options: vm.categories,
      leadingIcon: Icons.category_outlined,
      expand: true,
      onChanged: (val) {
        if (viewType == 'GRID') vm.setGridCategory(val);
        else if (viewType == 'LIST') vm.setListCategory(val);
        else vm.setChartCategory(val);
      },
      res: res,
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.brandAccent.withOpacity(0.12)
              : AppColors.surfaceBright.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.brandAccent.withOpacity(0.35)
                : AppColors.surfaceBright.withOpacity(0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive ? AppColors.brandAccent : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                color: isActive ? AppColors.brandAccent : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildProtocolListTable(vm, res, protocols),
          if (vm.listCategory != 'All' || vm.listSearch.isNotEmpty)
            _buildCategorySummary(vm, res, vm.listProtocols, vm.listCategory),
        ],
      ),
    );
  }

  Widget _buildProtocolListTable(ProtocolViewModel vm, Responsive res, List<Protocol> protocols) {
    final double leftW = res.value(mobile: 150.0, tablet: 200.0, desktop: 240.0);
    final double wCat  = res.value(mobile: 100.0, tablet: 120.0, desktop: 130.0);
    final double wType = res.value(mobile: 72.0,  tablet: 90.0,  desktop: 100.0);
    final double wTvl  = res.value(mobile: 100.0, tablet: 130.0, desktop: 150.0);
    final double rightW = wCat + wType + wTvl;

    if (!res.isMobile) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final colW = (constraints.maxWidth - leftW) / 3;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: leftW,
                  child: _ProtocolStickyTable(
                    header: _listLeftHeader(res),
                    itemCount: protocols.length,
                    itemBuilder: (i) {
                      final rank = (vm.currentPage - 1) * vm.itemsPerPage + i + 1;
                      return _listLeftRow(protocols[i], rank, res);
                    },
                  ),
                ),
                Expanded(
                  child: _ProtocolStickyTable(
                    header: _listRightHeader(res, colW, colW, colW),
                    itemCount: protocols.length,
                    itemBuilder: (i) => _listRightRow(protocols[i], res, colW, colW, colW),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: leftW,
            child: _ProtocolStickyTable(
              header: _listLeftHeader(res),
              itemCount: protocols.length,
              itemBuilder: (i) {
                final rank = (vm.currentPage - 1) * vm.itemsPerPage + i + 1;
                return _listLeftRow(protocols[i], rank, res);
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: rightW,
                child: _ProtocolStickyTable(
                  header: _listRightHeader(res, wCat, wType, wTvl),
                  itemCount: protocols.length,
                  itemBuilder: (i) => _listRightRow(protocols[i], res, wCat, wType, wTvl),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listLeftHeader(Responsive res) {
    final s = res.value(mobile: 10.0, tablet: 11.0, desktop: 12.0);
    final h = res.value(mobile: 38.0, tablet: 42.0, desktop: 46.0);
    return Container(
      height: h,
      color: const Color(0xFF0D0F13),
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text('#',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: s)),
          ),
          Text('Protocol',
              style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary, fontSize: s)),
        ],
      ),
    );
  }

  Widget _listRightHeader(Responsive res, double wCat, double wType, double wTvl) {
    final s = res.value(mobile: 10.0, tablet: 11.0, desktop: 12.0);
    final h = res.value(mobile: 38.0, tablet: 42.0, desktop: 46.0);
    return Container(
      height: h,
      color: const Color(0xFF0D0F13),
      child: Row(
        children: [
          _listHeaderCell('Category', wCat, s),
          _listHeaderCell('Type', wType, s),
          _listHeaderCell('TVL', wTvl, s),
        ],
      ),
    );
  }

  Widget _listHeaderCell(String label, double width, double fontSize) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _rankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppColors.textSecondary;
  }

  Widget _listLeftRow(Protocol p, int rank, Responsive res) {
    final rowH = res.value(mobile: 48.0, tablet: 54.0, desktop: 58.0);
    final nameSize = res.value(mobile: 11.0, tablet: 12.0, desktop: 13.0);
    final rankSize = res.value(mobile: 11.0, tablet: 12.0, desktop: 13.0);

    return GestureDetector(
      onTap: () => _navigateToDetail(p),
      child: Container(
        height: rowH,
        padding: const EdgeInsets.only(left: 4, right: 4),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text('$rank',
                  style: GoogleFonts.jetBrainsMono(
                    color: _rankColor(rank),
                    fontSize: rankSize,
                    fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
                  )),
            ),
            _buildProtocolIcon(p.logo, res.value(mobile: 16.0, tablet: 18.0, desktop: 20.0)),
            const SizedBox(width: 6),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textPrimary,
                        fontSize: nameSize,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (p.type == 'core')
                    const Padding(
                      padding: EdgeInsets.only(left: 2),
                      child: Icon(Icons.verified, size: 10, color: AppColors.brandAccent),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listRightRow(Protocol p, Responsive res, double wCat, double wType, double wTvl) {
    final rowH = res.value(mobile: 48.0, tablet: 54.0, desktop: 58.0);
    final cellSize = res.value(mobile: 10.0, tablet: 11.0, desktop: 12.0);

    return GestureDetector(
      onTap: () => _navigateToDetail(p),
      child: Container(
        height: rowH,
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
        ),
        child: Row(
          children: [
            _listDataCell(p.category.toUpperCase(), wCat, cellSize,
                color: Colors.white.withOpacity(0.85)),
            _listDataCell(p.type.toUpperCase(), wType, cellSize,
                color: p.type == 'core' ? AppColors.brandAccent : AppColors.textSecondary),
            _listDataCell(p.formattedTvl, wTvl, cellSize,
                color: p.type == 'core'
                    ? AppColors.brandAccent.withOpacity(0.85)
                    : Colors.white.withOpacity(0.85),
                bold: true),
          ],
        ),
      ),
    );
  }

  Widget _listDataCell(String text, double width, double fontSize,
      {Color? color, bool bold = false}) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.jetBrainsMono(
            color: color ?? AppColors.textPrimary,
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          ),
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

    final displayProtocols = vm.paginatedGridProtocols;

    if (displayProtocols.isEmpty && vm.gridProtocols.isEmpty) {
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
              mainAxisExtent: 148,
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
          if (vm.gridCategory != 'All' || vm.gridSearch.isNotEmpty)
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
      padding: EdgeInsets.symmetric(
        horizontal: res.spacing(12),
        vertical: res.spacing(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryRow(vm, res),
          const SizedBox(height: 16),
          EcosystemTreeMap(protocols: vm.chartProtocols),
          const SizedBox(height: 16),
          _buildProtocolBarChart(vm, res),
          const SizedBox(height: 16),
          _buildCategoryDist(vm, res),
        ],
      ),
    );
  }
  String _fmtCompactTvl(double value) {
    if (value >= 1e9) return '\$${(value / 1e9).toStringAsFixed(1)}B';
    if (value >= 1e6) return '\$${(value / 1e6).toStringAsFixed(1)}M';
    if (value >= 1e3) return '\$${(value / 1e3).toStringAsFixed(1)}K';
    return '\$${value.toStringAsFixed(0)}';
  }

  Widget _buildSummaryRow(ProtocolViewModel vm, Responsive res) {
    final protocols = vm.chartProtocols;
    final uniqueTypes = protocols.map((p) => p.type).toSet().length;
    final highestTvl = protocols.isEmpty
        ? '\$0'
        : _fmtCompactTvl(protocols.map((p) => p.tvl).reduce((a, b) => a > b ? a : b));

    return Row(
      children: [
        Expanded(
          child: _tvlProfileStatCard(
            title: 'ALL',
            value: protocols.length.toString(),
            icon: Icons.layers_outlined,
            res: res,
          ),
        ),
        SizedBox(width: res.spacing(8)),
        Expanded(
          child: _tvlProfileStatCard(
            title: 'HIGHEST',
            value: highestTvl,
            icon: Icons.trending_up_rounded,
            res: res,
          ),
        ),
        SizedBox(width: res.spacing(8)),
        Expanded(
          child: _tvlProfileStatCard(
            title: 'TYPES',
            value: uniqueTypes.toString(),
            icon: Icons.category_outlined,
            res: res,
          ),
        ),
      ],
    );
  }

  Widget _tvlProfileStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Responsive res,
  }) {
    const accent = AppColors.brandAccent;
    return Container(
      padding: EdgeInsets.all(res.spacing(12)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.2),
        borderRadius: BorderRadius.circular(res.value(mobile: 16, tablet: 14, desktop: 20)),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: res.value(mobile: 9, tablet: 8, desktop: 10),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(res.value(mobile: 6, tablet: 4, desktop: 6)),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: res.value(mobile: 14, tablet: 12, desktop: 16),
                ),
              ),
            ],
          ),
          SizedBox(height: res.spacing(8)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: res.value(mobile: 16, tablet: 13, desktop: 16),
                fontWeight: FontWeight.bold,
              ),
            ),
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
        mainAxisSize: MainAxisSize.min,
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
                              fontSize: res.fontSize(12),
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (protocol.type == 'core')
                          const Icon(Icons.verified, size: 13, color: AppColors.brandAccent),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.brandAccent,
                          fontSize: 8,
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
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL VALUE LOCKED',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 8,
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
                          fontSize: res.fontSize(13),
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
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.only(top: 6),
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
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBright.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'RANK #${protocol.rank}',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.brandAccent),
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
              fontSize: 9,
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

class _ProtocolStickyTable extends StatelessWidget {
  final Widget header;
  final int itemCount;
  final Widget Function(int index) itemBuilder;

  const _ProtocolStickyTable({
    required this.header,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        Container(height: 0.5, color: AppColors.surfaceBright),
        ...List.generate(itemCount, (i) => itemBuilder(i)),
      ],
    );
  }
}
