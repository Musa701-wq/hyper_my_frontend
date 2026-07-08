import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/open_interest_model.dart';
import '../viewmodels/open_interest_viewmodel.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../utils/common_widgets.dart';
import '../widgets/shimmer_skeleton.dart';

class OpenInterestScreen extends StatefulWidget {
  const OpenInterestScreen({super.key});

  @override
  State<OpenInterestScreen> createState() => _OpenInterestScreenState();
}

class _OpenInterestScreenState extends State<OpenInterestScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedChains = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OpenInterestViewModel>().fetchData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    final vm = context.watch<OpenInterestViewModel>();

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
            'Open Interest',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: res.fontSize(16),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        body: vm.isLoading && vm.filteredProtocols.isEmpty
            ? _buildShimmer(res)
            : vm.errorMessage.isNotEmpty
                ? _buildErrorState(vm)
                : _buildContent(vm, res),
      ),
    );
  }

  Widget _buildErrorState(OpenInterestViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.trendRed, size: 48),
            const SizedBox(height: 16),
            Text(
              vm.errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => vm.fetchData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(OpenInterestViewModel vm, Responsive res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => vm.fetchData(),
            color: AppColors.brandAccent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Control bar at the top (dropdowns, tabs, filters, sorting)
                  _buildControlBar(vm, res),

                  // Optional stats summary block if available
                  if (vm.summary != null) _buildSummaryBar(vm, res),

                  // Search Bar Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.surfaceBright.withOpacity(0.3)),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: vm.setSearchQuery,
                              style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search protocol or category...',
                                hintStyle: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 13),
                                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
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
                              vm.setSearchQuery('');
                            },
                          ),
                      ],
                    ),
                  ),

                  // Main Table (Protocols or Chain list)
                  vm.mainTabIndex == 0 ? _buildProtocolsTable(vm, res) : _buildChainsTable(vm, res),
                ],
              ),
            ),
          ),
        ),

        // Pagination for both tabs (remains outside scroll view so it stays sticky)
        _buildBottomPaginationBar(vm, res),
      ],
    );
  }

  Widget _buildShimmer(Responsive res) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Control Bar Shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  ShimmerSkeleton.box(150, 32, radius: 8),
                  const SizedBox(width: 12),
                  ShimmerSkeleton.box(80, 32, radius: 8),
                  const SizedBox(width: 12),
                  ShimmerSkeleton.box(80, 32, radius: 8),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Summary Stats Cards Shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: ShimmerSkeleton.box(double.infinity, 50, radius: 8)),
                  const SizedBox(width: 8),
                  Expanded(child: ShimmerSkeleton.box(double.infinity, 50, radius: 8)),
                  const SizedBox(width: 8),
                  Expanded(child: ShimmerSkeleton.box(double.infinity, 50, radius: 8)),
                  const SizedBox(width: 8),
                  Expanded(child: ShimmerSkeleton.box(double.infinity, 50, radius: 8)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search Bar Shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ShimmerSkeleton.box(double.infinity, 40, radius: 10),
            ),
            const SizedBox(height: 16),
            // Table Header Shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: ShimmerSkeleton.pill(12, 10),
                  ),
                  Expanded(
                    flex: 3,
                    child: ShimmerSkeleton.pill(60, 10),
                  ),
                  Expanded(
                    flex: 2,
                    child: ShimmerSkeleton.pill(40, 10),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ShimmerSkeleton.pill(80, 10),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ShimmerSkeleton.pill(50, 10),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10),
            // Table Rows Shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(8, (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: ShimmerSkeleton.pill(10, 10),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            ShimmerSkeleton.box(24, 24, radius: 12),
                            const SizedBox(width: 8),
                            Expanded(child: ShimmerSkeleton.pill(80, 12)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: ShimmerSkeleton.pill(60, 11),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ShimmerSkeleton.pill(70, 12),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ShimmerSkeleton.pill(45, 12),
                        ),
                      ),
                    ],
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBar(OpenInterestViewModel vm, Responsive res) {
    final showWide = res.width > 800;

    final controlBarChild = Row(
      children: [
        // Tabs: TOP PROTOCOLS | CHAIN
        Container(
          height: res.value(mobile: 32.0, tablet: 40.0, desktop: 44.0),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceBright.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabButton('TOP PROTOCOLS', vm.mainTabIndex == 0, () {
                vm.setMainTab(0);
                setState(() {
                  _expandedChains.clear();
                });
              }, res),
              _buildTabButton('CHAIN', vm.mainTabIndex == 1, () {
                vm.setMainTab(1);
                setState(() {
                  _expandedChains.clear();
                });
              }, res),
            ],
          ),
        ),

        SizedBox(width: res.spacing(12)),

        // Render category selector & filters only if Protocols tab is active
        if (vm.mainTabIndex == 0) ...[
          // Category Dropdown Button (Replaces horizontal scrolling tags)
          _buildCategoryDropdownButton(vm, res),

          SizedBox(width: res.spacing(8)),
          Container(width: 1, height: res.value(mobile: 24.0, tablet: 32.0), color: AppColors.surfaceBright.withOpacity(0.4)),
          SizedBox(width: res.spacing(8)),

          // OI dropdown (Indigo/purple styled)
          _buildOiDropdown(vm, res),

          SizedBox(width: res.spacing(8)),

          // CHANGE dropdown (Dark styled)
          _buildChangeDropdown(vm, res),
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

  Widget _buildTabButton(String text, bool isActive, VoidCallback onTap, Responsive res) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: res.value(mobile: 12.0, tablet: 18.0),
          vertical: res.value(mobile: 6.0, tablet: 8.0),
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandAccent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: GoogleFonts.jetBrainsMono(
            color: isActive ? AppColors.brandAccent : AppColors.textSecondary,
            fontSize: res.fontSize(10),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdownButton(OpenInterestViewModel vm, Responsive res) {
    final isSelected = vm.selectedCategory != 'ALL';
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
              isSelected ? vm.selectedCategory : 'CATEGORY',
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
      onSelected: vm.setSelectedCategory,
      itemBuilder: (context) => vm.categories.map((cat) {
        final active = vm.selectedCategory == cat;
        return PopupMenuItem<String>(
          value: cat,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.brandAccent.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                if (active)
                  Icon(Icons.check_circle_rounded, color: AppColors.brandAccent, size: res.value(mobile: 14.0, tablet: 18.0))
                else
                  Icon(Icons.circle_outlined, color: Colors.white24, size: res.value(mobile: 14.0, tablet: 18.0)),
                const SizedBox(width: 8),
                Text(
                  cat,
                  style: GoogleFonts.jetBrainsMono(
                    color: active ? AppColors.brandAccent : Colors.white70,
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


  Widget _buildOiDropdown(OpenInterestViewModel vm, Responsive res) {
    final labelMap = {
      'total24h': 'OI 24H',
      'total7d': 'OI 7D',
      'total30d': 'OI 30D',
    };
    final activeLabel = labelMap[vm.oiMetric] ?? 'OI 24H';
    final isSortedByOi = vm.sortType == 'oi';

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
          gradient: isSortedByOi
              ? const LinearGradient(
                  colors: [Color(0xFF5D2EE2), Color(0xFF4C27B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSortedByOi ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSortedByOi ? const Color(0xFF7A57FF) : AppColors.surfaceBright.withOpacity(0.3),
            width: isSortedByOi ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, color: Colors.white, size: res.value(mobile: 14.0, tablet: 18.0)),
            const SizedBox(width: 6),
            Text(
              activeLabel,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: res.fontSize(10),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.unfold_more_rounded, color: Colors.white70, size: res.value(mobile: 14.0, tablet: 18.0)),
          ],
        ),
      ),
      onSelected: vm.setOiMetric,
      itemBuilder: (context) => labelMap.entries.map((entry) {
        final active = vm.oiMetric == entry.key;
        return PopupMenuItem<String>(
          value: entry.key,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF4C27B8).withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                if (active)
                  Icon(Icons.check_circle_rounded, color: const Color(0xFF7A57FF), size: res.value(mobile: 14.0, tablet: 18.0))
                else
                  Icon(Icons.circle_outlined, color: Colors.white24, size: res.value(mobile: 14.0, tablet: 18.0)),
                const SizedBox(width: 8),
                Text(
                  entry.value,
                  style: GoogleFonts.jetBrainsMono(
                    color: active ? const Color(0xFF9E85FF) : Colors.white70,
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

  Widget _buildChangeDropdown(OpenInterestViewModel vm, Responsive res) {
    final labelMap = {
      'change_1d': '1D CHANGE',
      'change_7d': '7D CHANGE',
      'change_1m': '1M CHANGE',
    };
    final activeLabel = labelMap[vm.changeMetric] ?? 'CHANGE';
    final isSortedByChange = vm.sortType == 'change';

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
          gradient: isSortedByChange
              ? const LinearGradient(
                  colors: [Color(0xFF384358), Color(0xFF242A36)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSortedByChange ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSortedByChange ? Colors.white24 : AppColors.surfaceBright.withOpacity(0.3),
            width: isSortedByChange ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart_rounded, color: Colors.white, size: res.value(mobile: 14.0, tablet: 18.0)),
            const SizedBox(width: 6),
            Text(
              activeLabel,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: res.fontSize(10),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.unfold_more_rounded, color: Colors.white70, size: res.value(mobile: 14.0, tablet: 18.0)),
          ],
        ),
      ),
      onSelected: vm.setChangeMetric,
      itemBuilder: (context) => labelMap.entries.map((entry) {
        final active = vm.changeMetric == entry.key;
        return PopupMenuItem<String>(
          value: entry.key,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: active ? Colors.white.withOpacity(0.06) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                if (active)
                  Icon(Icons.check_circle_rounded, color: Colors.white70, size: res.value(mobile: 14.0, tablet: 18.0))
                else
                  Icon(Icons.circle_outlined, color: Colors.white24, size: res.value(mobile: 14.0, tablet: 18.0)),
                const SizedBox(width: 8),
                Text(
                  entry.value,
                  style: GoogleFonts.jetBrainsMono(
                    color: active ? Colors.white : Colors.white70,
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

  Widget _buildSummaryBar(OpenInterestViewModel vm, Responsive res) {
    final summary = vm.summary!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(child: _buildSummaryItem('Total OI', _formatOI(summary.totalOI))),
          const SizedBox(width: 8),
          Expanded(child: _buildSummaryItem('Protocols', summary.totalProtocols.toString())),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 8, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolsTable(OpenInterestViewModel vm, Responsive res) {
    final list = vm.paginatedProtocols;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'No protocols found.',
            style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final double leftWidth = res.columnWidth(170.0);
    final double rightWidth = res.columnWidth(345.0);
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
                // Header Rank & Name
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
                        child: Text(
                          'PROTOCOL',
                          style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(10), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // Items
                ...list.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final rank = (vm.currentPage - 1) * vm.itemsPerPage + i + 1;

                  return GestureDetector(
                    onTap: () => _showDetailDialog(context, p, res),
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
                                    child: p.logo.isNotEmpty
                                        ? Image.network(
                                            p.logo,
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
                                        p.displayName,
                                        style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: res.fontSize(11), fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceBright.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          p.category.toUpperCase(),
                                          style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: res.fontSize(8), fontWeight: FontWeight.bold),
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

          // Right Scrollable Column
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: rightWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Right Headers (OI, 24H, 7D, 30D)
                    Container(
                      height: headerH,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: res.columnWidth(120.0),
                            child: Center(
                              child: Text(
                                'OPEN INTEREST',
                                style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(10), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          _buildHeaderCell('24H', res, width: res.columnWidth(75.0)),
                          _buildHeaderCell('7D', res, width: res.columnWidth(75.0)),
                          _buildHeaderCell('30D', res, width: res.columnWidth(75.0)),
                        ],
                      ),
                    ),
                    // Right Items
                    ...list.asMap().entries.map((entry) {
                      final p = entry.value;

                      final activeOiValue = vm.oiMetric == 'total24h'
                          ? p.total24h
                          : vm.oiMetric == 'total7d'
                              ? p.total7d
                              : p.total30d;

                      return GestureDetector(
                        onTap: () => _showDetailDialog(context, p, res),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: rowH,
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: res.columnWidth(120.0),
                                child: Center(
                                  child: Text(
                                    _formatOI(activeOiValue),
                                    style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: res.fontSize(12), fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              _buildChangeCell(p.change1d, res, width: res.columnWidth(75.0)),
                              _buildChangeCell(p.change7d, res, width: res.columnWidth(75.0)),
                              _buildChangeCell(p.change1m, res, width: res.columnWidth(75.0)),
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

  Widget _buildChainsTable(OpenInterestViewModel vm, Responsive res) {
    final list = vm.paginatedChains;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'No chain statistics found.',
            style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    const double headerH = 40.0;
    const double rowH = 56.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
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
                  child: Text(
                    'CHAIN',
                    style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(10), fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: res.columnWidth(110.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'TOTAL OI',
                      style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(10), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                const SizedBox(width: 24.0), // match the arrow column width
              ],
            ),
          ),
          // Items
          ...list.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            final rank = (vm.currentPage - 1) * vm.itemsPerPage + i + 1;
            final isExpanded = _expandedChains.contains(c.chain);
            final hasMultipleProtocols = c.protocols.length > 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: hasMultipleProtocols
                      ? () {
                          setState(() {
                            if (isExpanded) {
                              _expandedChains.remove(c.chain);
                            } else {
                              _expandedChains.add(c.chain);
                            }
                          });
                        }
                      : null,
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
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surfaceBright.withOpacity(0.2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: c.chainIconUrl.isNotEmpty
                                      ? Image.network(
                                          c.chainIconUrl,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.link, color: AppColors.textSecondary, size: 10),
                                        )
                                      : const Icon(Icons.link, color: AppColors.textSecondary, size: 10),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.chain,
                                  style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: res.fontSize(12), fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: res.columnWidth(110.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _formatOI(c.totalOI),
                              style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: res.fontSize(12), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Container(
                          width: 24.0,
                          alignment: Alignment.centerRight,
                          child: hasMultipleProtocols
                              ? Icon(
                                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: AppColors.brandAccent,
                                  size: 16,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded && hasMultipleProtocols)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 38.0, top: 12.0, bottom: 14.0, right: 16.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.15),
                      border: const Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.only(left: 12.0),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AppColors.brandAccent.withOpacity(0.3), width: 1.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.layers_outlined, size: 12, color: AppColors.brandAccent.withOpacity(0.85)),
                              const SizedBox(width: 6),
                              Text(
                                'PROTOCOLS (${c.protocols.length})',
                                style: GoogleFonts.jetBrainsMono(
                                  color: AppColors.brandAccent.withOpacity(0.95),
                                  fontSize: res.fontSize(9),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: c.protocols.map((name) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceBright.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.surfaceBright.withOpacity(0.4), width: 0.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 5,
                                      color: AppColors.brandAccent.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      name,
                                      style: GoogleFonts.jetBrainsMono(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: res.fontSize(10),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChangeWidget(double value) {
    final isPositive = value >= 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          color: isPositive ? AppColors.trendGreen : AppColors.trendRed,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '${value.toStringAsFixed(2)}%',
          style: GoogleFonts.jetBrainsMono(
            color: isPositive ? AppColors.trendGreen : AppColors.trendRed,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, Responsive res, {required double width}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          color: AppColors.textSecondary,
          fontSize: res.fontSize(10),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChangeCell(double value, Responsive res, {required double width}) {
    final isZero = value == 0.0;
    final isPositive = value > 0;

    // Heat-map opacity calculation based on the magnitude of the change.
    // Assume 20% absolute change is maximum highlight.
    final absVal = value.abs();
    final double fraction = (absVal / 20.0).clamp(0.0, 1.0);
    // Dim background ranges from opacity 0.06 (near 0%) up to 0.55 (20% or above).
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

  Widget _buildBottomPaginationBar(OpenInterestViewModel vm, Responsive res) {
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
            _buildRowsPill(vm, res),
            const Spacer(),
            _buildPaginationRow(
              currentPage: vm.currentPage,
              totalPages: vm.totalPages,
              onPage: vm.setPage,
              res: res,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowsPill(OpenInterestViewModel vm, Responsive res) {
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
              vm.itemsPerPage.toString(),
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
      onSelected: vm.setItemsPerPage,
      itemBuilder: (context) => const [10, 20, 50, 100].map((v) {
        final active = vm.itemsPerPage == v;
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
        _buildPageIcon(Icons.chevron_left, currentPage > 1 ? () => onPage(currentPage - 1) : null, res),
        const SizedBox(width: 4),
        ..._buildPageNumbersList(currentPage: currentPage, totalPages: totalPages, onPage: onPage, res: res),
        const SizedBox(width: 4),
        _buildPageIcon(Icons.chevron_right, currentPage < totalPages ? () => onPage(currentPage + 1) : null, res),
      ],
    );
  }

  List<Widget> _buildPageNumbersList({
    required int currentPage,
    required int totalPages,
    required void Function(int) onPage,
    required Responsive res,
  }) {
    final List<Widget> children = [];
    for (int i = 1; i <= totalPages; i++) {
      if (i == 1 || i == totalPages || (i >= currentPage - 1 && i <= currentPage + 1)) {
        children.add(_buildPageNumberItem(i, i == currentPage, () => onPage(i), res));
        if (i < totalPages && (i == 1 && currentPage > 3 || i == currentPage + 1 && currentPage < totalPages - 2)) {
          children.add(Text(
            '...',
            style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(10)),
          ));
        }
      }
    }
    return children;
  }

  Widget _buildPageNumberItem(int page, bool isActive, VoidCallback onTap, Responsive res) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: res.value(mobile: 28.0, tablet: 36.0),
        height: res.value(mobile: 28.0, tablet: 36.0),
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
            fontSize: res.fontSize(11),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
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

  String _formatOI(double oi) {
    if (oi >= 1e9) {
      return '\$${(oi / 1e9).toStringAsFixed(2)}B';
    } else if (oi >= 1e6) {
      return '\$${(oi / 1e6).toStringAsFixed(2)}M';
    } else if (oi >= 1e3) {
      return '\$${(oi / 1e3).toStringAsFixed(1)}K';
    }
    return '\$${oi.toStringAsFixed(0)}';
  }

  void _showDetailDialog(BuildContext context, OpenInterestProtocol protocol, Responsive res) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF111417),
          insetPadding: EdgeInsets.symmetric(
            horizontal: res.value(mobile: 16.0, tablet: 40.0),
            vertical: 24.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          child: Container(
            width: res.value(mobile: double.infinity, tablet: 520.0, desktop: 560.0),
            padding: EdgeInsets.all(res.spacing(18)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Logo, Name, Badge, Close Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: res.value(mobile: 32.0, tablet: 40.0),
                            height: res.value(mobile: 32.0, tablet: 40.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceBright.withOpacity(0.3),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: protocol.logo.isNotEmpty
                                  ? Image.network(
                                      protocol.logo,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.token, color: AppColors.textSecondary),
                                    )
                                  : const Icon(Icons.token, color: AppColors.textSecondary),
                            ),
                          ),
                          SizedBox(width: res.spacing(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  protocol.displayName,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: Colors.white,
                                    fontSize: res.fontSize(16),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceBright.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    protocol.category.toUpperCase(),
                                    style: GoogleFonts.jetBrainsMono(
                                      color: AppColors.brandAccent,
                                      fontSize: res.fontSize(9),
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
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                SizedBox(height: res.spacing(16)),

                // 2x3 Grid of stats cards
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: res.spacing(10),
                  mainAxisSpacing: res.spacing(10),
                  childAspectRatio: res.value(mobile: 1.8, tablet: 1.9, desktop: 2.0),
                  children: [
                    _buildMetricCard('OI 24H', _formatOI(protocol.total24h), res),
                    _buildMetricCard('OI 7D', _formatOI(protocol.total7d), res),
                    _buildMetricCard('OI 30D', _formatOI(protocol.total30d), res),
                    _buildMetricChangeCard('24H CHANGE', protocol.change1d, res),
                    _buildMetricChangeCard('7D CHANGE', protocol.change7d, res),
                    _buildMetricChangeCard('1M CHANGE', protocol.change1m, res),
                  ],
                ),

                SizedBox(height: res.spacing(16)),

                // Detail Metadata
                Container(
                  padding: EdgeInsets.all(res.spacing(10)),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceBright.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      _buildMetaRow('Chains Supported', protocol.chains.join(', '), res),
                      const Divider(color: Colors.white10),
                      _buildMetaRow('Protocol ID', protocol.slug, res),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String label, String value, Responsive res) {
    return Container(
      padding: EdgeInsets.all(res.spacing(10)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(9), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: res.fontSize(18), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChangeCard(String label, double value, Responsive res) {
    final isPositive = value >= 0;
    final color = isPositive ? AppColors.trendGreen : AppColors.trendRed;
    final sign = isPositive ? '+' : '';

    return Container(
      padding: EdgeInsets.all(res.spacing(10)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(9), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: color,
                size: res.value(mobile: 18.0, tablet: 22.0),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$sign${value.toStringAsFixed(2)}%',
                  style: GoogleFonts.jetBrainsMono(color: color, fontSize: res.fontSize(16), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, Responsive res) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: res.value(mobile: 4.0, tablet: 6.0)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: res.fontSize(11), fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
