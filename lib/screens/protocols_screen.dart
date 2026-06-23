import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../viewmodels/protocol_viewmodel.dart';
import '../models/protocol_model.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/tvl/category_distribution_chart.dart';
import '../widgets/tvl/top_chains_chart.dart';
import 'protocol_detail_screen.dart';

class ProtocolsScreen extends StatefulWidget {
  const ProtocolsScreen({super.key});

  @override
  State<ProtocolsScreen> createState() => _ProtocolsScreenState();
}

class _ProtocolsScreenState extends State<ProtocolsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ProtocolViewModel>();
      vm.fetchProtocols();
      vm.fetchCategoryDistribution();
      vm.fetchTopChains();
    });
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    final vm = context.watch<ProtocolViewModel>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(res),
        body: TabBarView(
          children: [
            _buildGridView(vm, res),
            _buildListView(vm, res),
            _buildChartView(vm, res),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Responsive res) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Protocol TVL Analytics',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: res.fontSize(18),
              fontWeight: FontWeight.bold,
            ),
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(32),
        child: Container(
          width: double.infinity,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: BoxDecoration(
              color: AppColors.surfaceBright,
              borderRadius: BorderRadius.circular(6),
            ),
            dividerColor: Colors.transparent,
            labelColor: AppColors.brandAccent,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.normal,
            ),
            padding: EdgeInsets.zero,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('GRID'))),
              Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('LIST'))),
              Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('CHARTS'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(ProtocolViewModel vm, Responsive res) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: res.spacing(16), vertical: res.spacing(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildDropdownPill<int>(
              value: vm.limit,
              icon: Icons.list_alt_rounded,
              prefix: 'Top',
              options: [20, 50, 100],
              onChanged: (val) => vm.setLimit(val ?? 20),
              res: res,
            ),
            SizedBox(width: res.spacing(10)),
            _buildFilterPill(
              label: vm.isAscending ? 'Lowest TVL' : 'Highest TVL',
              icon: vm.isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              isActive: true,
              res: res,
              onTap: () => vm.toggleSortOrder(),
            ),
            SizedBox(width: res.spacing(10)),
            _buildDropdownPill<String>(
              value: vm.selectedCategory,
              icon: Icons.filter_alt_outlined,
              options: vm.categories,
              onChanged: (val) => vm.setCategory(val ?? 'All Categories'),
              res: res,
            ),
          ],
        ),
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
        color: AppColors.surfaceBright.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBright.withValues(alpha: 0.2)),
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
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive 
              ? AppColors.brandAccent.withValues(alpha: 0.15)
              : AppColors.surfaceBright.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive 
                ? AppColors.brandAccent.withValues(alpha: 0.4)
                : AppColors.surfaceBright.withValues(alpha: 0.2),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterBar(vm, res),
        Expanded(
          child: _buildListBody(vm, res),
        ),
      ],
    );
  }

  Widget _buildListBody(ProtocolViewModel vm, Responsive res) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brandAccent));
    }

    if (vm.errorMessage.isNotEmpty) {
      return ErrorStateWidget(
        errorMessage: vm.errorMessage,
        onRetry: () => vm.fetchProtocols(),
      );
    }

    if (vm.protocols.isEmpty) {
      return Center(
        child: Text(
          'No protocols found',
          style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary),
        ),
      );
    }

    final headerH = 48.0;
    final rowH = res.value(mobile: 56.0, tablet: 64.0);
    final fixedW = res.columnWidth(160);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed Left Column (Rank + Protocol)
          SizedBox(
            width: fixedW,
            child: Column(
              children: [
                // Fixed Header
                Container(
                  height: headerH,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.surfaceBright.withValues(alpha: 0.2))),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 30, child: Text('#', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 4),
                      Expanded(child: Text('PROTOCOL', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                // Fixed Data Rows
                ...vm.protocols.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final p = entry.value;
                  return InkWell(
                    onTap: () => _navigateToDetail(p),
                    child: Container(
                      height: rowH,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.surfaceBright.withValues(alpha: 0.1))),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 30, child: Text(index.toString(), style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11))),
                          const SizedBox(width: 4),
                          _buildProtocolIcon(p.logo, 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              p.name,
                              style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
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
          // Scrollable Right Section (Category + TVL)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scrollable Header
                  Container(
                    height: headerH,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.surfaceBright.withValues(alpha: 0.2))),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 100, child: Text('CATEGORY', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                        SizedBox(width: 120, child: Text('TVL', textAlign: TextAlign.right, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  // Scrollable Data Rows
                  ...vm.protocols.map((p) {
                    return InkWell(
                      onTap: () => _navigateToDetail(p),
                      child: Container(
                        height: rowH,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.surfaceBright.withValues(alpha: 0.1))),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                p.category,
                                style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(
                                p.fullTvl,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.jetBrainsMono(
                                  color: AppColors.brandAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterBar(vm, res),
        Expanded(
          child: _buildGridBody(vm, res),
        ),
      ],
    );
  }

  Widget _buildGridBody(ProtocolViewModel vm, Responsive res) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brandAccent));
    }

    if (vm.errorMessage.isNotEmpty) {
      return ErrorStateWidget(
        errorMessage: vm.errorMessage,
        onRetry: () => vm.fetchProtocols(),
      );
    }

    if (vm.protocols.isEmpty) {
      return Center(
        child: Text(
          'No protocols found',
          style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 4 : screenWidth > 800 ? 3 : 2;

    return GridView.builder(
      padding: EdgeInsets.all(res.spacing(16)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: res.spacing(16),
        mainAxisSpacing: res.spacing(16),
        childAspectRatio: 1.1,
      ),
      itemCount: vm.protocols.length,
      itemBuilder: (context, index) {
        final p = vm.protocols[index];
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
          _buildProtocolBarChart(vm, res),
          SizedBox(height: res.spacing(20)),
          _buildCategoryDist(vm, res),
          SizedBox(height: res.spacing(20)),
          _buildTopChains(vm, res),
        ],
      ),
    );
  }

  Widget _buildProtocolBarChart(ProtocolViewModel vm, Responsive res) {
    if (vm.protocols.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = List<Protocol>.from(vm.protocols)
      ..sort((a, b) => b.tvl.compareTo(a.tvl));

    final maxTvl = sorted.first.tvl;
    const double yLabelWidth = 100.0;
    const double barH = 24.0;
    const double rowH = 44.0;
    final chartH = sorted.length * rowH;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBright.withValues(alpha: 0.3)),
      ),
      child: Column(
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
            'Comparing Total Value Locked across protocols',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
          const SizedBox(height: 8),
          SizedBox(
            height: chartH,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final chartW = constraints.maxWidth;
                                  return Stack(
                                    children: [
                                      ...List.generate(6, (i) {
                                        final val = (maxTvl / 5) * i;
                                        final x = chartW * (val / maxTvl.clamp(1, double.infinity));
                                        return Positioned(
                                          left: x,
                                          top: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 1,
                                            color: AppColors.surfaceBright.withValues(alpha: 0.08),
                                          ),
                                        );
                                      }),
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
                                                            color: AppColors.surfaceBright.withValues(alpha: 0.12),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                        ),
                                                        AnimatedContainer(
                                                          duration: const Duration(milliseconds: 800),
                                                          curve: Curves.easeOutCubic,
                                                          width: (chartW * ratio).clamp(0.0, chartW),
                                                          height: barH,
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(6),
                                                            gradient: LinearGradient(
                                                              colors: [
                                                                barColor.withValues(alpha: 0.7),
                                                                barColor,
                                                              ],
                                                            ),
                                                            boxShadow: isHyperliquid ? [
                                                              BoxShadow(
                                                                color: barColor.withValues(alpha: 0.3),
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
                                                    width: 70,
                                                    child: Text(
                                                      p.formattedTvl,
                                                      style: GoogleFonts.jetBrainsMono(
                                                        color: isHyperliquid ? AppColors.brandAccent : Colors.white70,
                                                        fontSize: 11,
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

  Widget _buildTopChains(ProtocolViewModel vm, Responsive res) {
    return TopChainsChart(data: vm.topChains);
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.surfaceBright.withValues(alpha: 0.3),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.01),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
                      color: Colors.black.withValues(alpha: 0.3),
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
                        color: AppColors.brandAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.brandAccent.withValues(alpha: 0.2),
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
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  fontSize: 7,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  protocol.fullTvl,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.brandAccent,
                    fontSize: res.fontSize(18),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05),
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
                    color: AppColors.surfaceBright.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'RANK #${protocol.rank}',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
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
}
