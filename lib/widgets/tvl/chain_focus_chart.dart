import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/protocol_model.dart';
import '../../utils/app_colors.dart';

class ChainFocusChart extends StatefulWidget {
  final List<ChainFocus> allData;
  final List<String> chains;
  final String selectedChain;
  final Function(String) onChainChanged;

  const ChainFocusChart({
    super.key,
    required this.allData,
    required this.chains,
    required this.selectedChain,
    required this.onChainChanged,
  });

  @override
  State<ChainFocusChart> createState() => _ChainFocusChartState();
}

class _ChainFocusChartState extends State<ChainFocusChart> {
  int _touchedIndex = -1;

  final List<Color> _chartColors = [
    const Color(0xFF2EE2BA), // Hyperliquid Green
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFFF59E0B), // Orange
    const Color(0xFF10B981), // Emerald
    const Color(0xFF6366F1), // Indigo
    const Color(0xFFEF4444), // Red
    const Color(0xFF84CC16), // Lime
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.allData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF2EE2BA))),
      );
    }

    final isOverall = widget.selectedChain == 'Overall';
    
    // Preparation for Overall Mode
    final List<ChainFocusProject> displayItems;
    final double totalTvl;

    if (isOverall) {
      displayItems = widget.allData.map((e) => ChainFocusProject(
        name: e.chain,
        tvl: e.totalTvl,
        pct: e.pct,
      )).toList();
      displayItems.sort((a, b) => b.tvl.compareTo(a.tvl));
      totalTvl = displayItems.fold(0.0, (sum, item) => sum + item.tvl);
    } else {
      final selectedData = widget.allData.firstWhere(
        (e) => e.chain == widget.selectedChain,
        orElse: () => widget.allData.first,
      );
      displayItems = selectedData.projects;
      totalTvl = selectedData.totalTvl;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E28).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 40),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildPieChart(displayItems, totalTvl),
                    ),
                    const SizedBox(width: 60),
                    Expanded(
                      flex: 6,
                      child: _buildProjectList(displayItems, totalTvl, isOverall: isOverall),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildPieChart(displayItems, totalTvl),
                    const SizedBox(height: 60),
                    _buildProjectList(displayItems, totalTvl, isOverall: isOverall),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.selectedChain == 'Overall' ? 'Total TVL By Chain' : 'TVL by Specific Chain',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.selectedChain == 'Overall' ? 'Distribution across all integrated networks.' : 'Project distribution within a selected chain.',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildChainSelector(),
      ],
    );
  }

  Widget _buildChainSelector() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.selectedChain,
          isExpanded: true,
          dropdownColor: const Color(0xFF13151C),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 16),
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          items: [
            const DropdownMenuItem(
              value: 'Overall',
              child: Text('Overall Chains'),
            ),
            ...widget.chains.map((chain) {
              return DropdownMenuItem(
                value: chain,
                child: Text(
                  chain,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: (val) {
            if (val != null) widget.onChainChanged(val);
          },
        ),
      ),
    );
  }

  Widget _buildPieChart(List<ChainFocusProject> projects, double totalTvl) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 50,
              sections: _buildSections(projects, totalTvl),
            ),
          ),
          // Center text info
          if (_touchedIndex == -1)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total TVL',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  _formatTotal(totalTvl),
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatTotal(double val) {
    if (val >= 1e9) return '${(val / 1e9).toStringAsFixed(1)}B';
    if (val >= 1e6) return '${(val / 1e6).toStringAsFixed(1)}M';
    return '${(val / 1e3).toStringAsFixed(0)}K';
  }

  List<PieChartSectionData> _buildSections(List<ChainFocusProject> projects, double totalTvl) {
    if (totalTvl == 0) return [];
    
    final topCount = 7;
    final topProjects = projects.take(topCount).toList();
    final othersTvl = projects.length > topCount
        ? projects.skip(topCount).fold<double>(0, (sum, p) => sum + p.tvl)
        : 0.0;

    final sections = <PieChartSectionData>[];

    for (int i = 0; i < topProjects.length; i++) {
      final p = topProjects[i];
      final isTouched = i == _touchedIndex;
      final pct = p.pct;
      final color = _chartColors[i % _chartColors.length];
      final radius = isTouched ? 70.0 : 60.0;

      sections.add(
        PieChartSectionData(
          color: color,
          value: p.tvl,
          title: '', // Titles handled by badges for better control
          radius: radius,
          badgeWidget: _buildExternalLabel(p.name, pct, color, isTouched),
          badgePositionPercentageOffset: 1.45,
        ),
      );
    }

    if (othersTvl > 0) {
      final isTouched = _touchedIndex == topProjects.length;
      final othersPct = (othersTvl / totalTvl) * 100;
      const color = Color(0xFF475569); // Slightly lighter slate
      final radius = isTouched ? 70.0 : 60.0;

      sections.add(
        PieChartSectionData(
          color: color,
          value: othersTvl,
          title: '',
          radius: radius,
          badgeWidget: _buildExternalLabel('Others', othersPct, color, isTouched),
          badgePositionPercentageOffset: 1.45,
        ),
      );
    }

    return sections;
  }

  Widget _buildExternalLabel(String name, double pct, Color color, bool isTouched) {
    if (pct < 2.0 && !isTouched) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isTouched ? color : Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            '${pct.toStringAsFixed(1)}%',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name.length > 10 ? '${name.substring(0, 8)}..' : name,
          style: GoogleFonts.jetBrainsMono(
            color: isTouched ? Colors.white : color.withOpacity(0.9),
            fontSize: isTouched ? 10 : 8,
            fontWeight: isTouched ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectList(List<ChainFocusProject> items, double totalTvl, {bool isOverall = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListHeader(isOverall: isOverall),
        const SizedBox(height: 12),
        ...List.generate(items.length.clamp(0, 15), (i) {
          final p = items[i];
          final color = _chartColors[i % _chartColors.length];

          return Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.03)),
              ),
            ),
            child: Row(
              children: [
                // Plain Rank/Index
                SizedBox(
                  width: 24,
                  child: Text(
                    '${i + 1}',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.jetBrainsMono(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              p.formattedTvl,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.jetBrainsMono(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Plain Percentage Text
                          SizedBox(
                            width: 44,
                            child: Text(
                              '${p.pct.toStringAsFixed(1)}%',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.jetBrainsMono(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Allocation bar
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Stack(
                              children: [
                                Container(
                                  height: 3,
                                  width: double.infinity,
                                  color: Colors.white.withOpacity(0.04),
                                ),
                                Container(
                                  height: 3,
                                  width: constraints.maxWidth * (p.pct / 100).clamp(0.0, 1.0),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildListHeader({bool isOverall = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 36),
          Expanded(
            flex: 5,
            child: Text(
              isOverall ? 'CHAIN' : 'PROTOCOL',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'TVL',
              textAlign: TextAlign.right,
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 52,
            child: Text(
              'ALLOC',
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
