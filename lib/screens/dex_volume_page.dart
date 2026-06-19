import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/dex_volume_model.dart';
import '../viewmodels/dex_volume_viewmodel.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/dex_volume/metric_card.dart';
import '../widgets/dex_volume/volume_chart.dart';
import '../widgets/dex_volume/growth_banner.dart';
import '../widgets/dex_volume/adoption_card.dart';
import '../widgets/dex_volume/trend_chart.dart';
import '../widgets/dex_volume/monthly_table.dart';
import '../widgets/error_state_widget.dart';

class DexVolumePage extends StatefulWidget {
  const DexVolumePage({super.key});

  @override
  State<DexVolumePage> createState() => _DexVolumePageState();
}

class _DexVolumePageState extends State<DexVolumePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DexVolumeViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    final vm = context.watch<DexVolumeViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Hyperliquid DEX Volume',
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.brandAccent,
            fontSize: res.fontSize(16),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandAccent))
          : vm.errorMessage.isNotEmpty
              ? ErrorStateWidget(
                  errorMessage: vm.errorMessage,
                  onRetry: () => vm.fetchAllData(),
                )
              : RefreshIndicator(
                  onRefresh: () => vm.fetchAllData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        // Section 1: Metric Cards
                        if (vm.metrics != null) ...[
                          _buildMetricCards(vm.metrics!),
                          const SizedBox(height: 16),
                        ],

                        // Section 1.5: External Toggles (Moved from Chart Container)
                        _buildExternalToggles(vm),
                        const SizedBox(height: 12),

                        // Section 2: Main Chart
                        VolumeChartWidget(
                          data: vm.chartData,
                          selectedScope: vm.selectedScope,
                          selectedTimeRange: vm.selectedTimeRange,
                          selectedChartType: vm.selectedChartType,
                          onChartTypeChanged: (type) => vm.setChartType(type),
                        ),
                        const SizedBox(height: 16),

                        // Section 3: Growth Signal Banners
                        if (vm.adoption != null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: GrowthBanner(
                                  title: 'MoM Growth',
                                  growth: vm.adoption!.monthOverMonthGrowth ?? 0,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GrowthBanner(
                                  title: 'QoQ Growth',
                                  growth: vm.adoption!.quarterOverQuarterGrowth ?? 0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Section 4: Adoption Snapshot
                        if (vm.adoption != null) ...[
                          _buildAdoptionCards(vm.adoption!),
                          const SizedBox(height: 16),
                        ],

                        // Section 5: Trend Charts
                        if (vm.adoption != null) ...[
                          TrendChartWidget(
                            title: 'Monthly Volume Trend',
                            subtitle: 'Historical performance',
                            trend: vm.adoption!.monthlyTrend,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(height: 12),
                          TrendChartWidget(
                            title: 'Quarterly Volume Trend',
                            subtitle: 'Strategic growth',
                            trend: vm.adoption!.quarterlyTrend,
                            color: const Color(0xFF8B5CF6),
                            filterCurrent: true,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Section 6: Monthly Table
                        if (vm.adoption != null) ...[
                          MonthlyVolumeTable(
                            monthlyTrend: vm.adoption!.monthlyTrend,
                            sixMonthAvg: vm.adoption!.sixMonthAverageVolume,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildMetricCards(DexVolumeMetrics metrics) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: MetricCard(title: '24h Volume', value: metrics.total24h, change: metrics.change1d)),
            const SizedBox(width: 12),
            Expanded(child: MetricCard(title: '7d Volume', value: metrics.total7d, change: metrics.change7d)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: MetricCard(title: '30d Volume', value: metrics.total30d, change: metrics.change1m)),
            const SizedBox(width: 12),
            Expanded(child: MetricCard(title: 'Cumulative', value: metrics.totalAllTime, isCumulative: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildAdoptionCards(AdoptionMetrics adoption) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AdoptionCard(
                title: 'Current Month',
                subtitle: DateFormat('yyyy-MM').format(DateTime.now()),
                value: adoption.currentMonthVolume,
                growth: adoption.monthOverMonthGrowth,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdoptionCard(
                title: 'Previous Month',
                subtitle: DateFormat('yyyy-MM').format(DateTime.now().subtract(const Duration(days: 30))),
                value: adoption.previousMonthVolume,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AdoptionCard(
                title: '6-Month Average',
                subtitle: 'per month',
                value: adoption.sixMonthAverageVolume ?? 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdoptionCard(
                title: 'ATH Month',
                subtitle: adoption.isNewMonthlyATH ? 'NEW ATH' : 'Historical',
                value: adoption.allTimeHighMonthlyVolume,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExternalToggles(DexVolumeViewModel vm) {
    return Column(
      children: [
        _buildToggleGroup(
          [
            _ToggleItem(label: 'All', value: 'all'),
            _ToggleItem(label: 'Perps', value: 'perps'),
            _ToggleItem(label: 'Spot', value: 'spot'),
          ],
          vm.selectedScope,
          (val) => vm.setScope(val),
        ),
        const SizedBox(height: 8),
        _buildToggleGroup(
          [
            _ToggleItem(label: 'All', value: 'All'),
            _ToggleItem(label: 'D', value: 'D'),
            _ToggleItem(label: 'W', value: 'W'),
            _ToggleItem(label: 'M', value: 'M'),
            _ToggleItem(label: 'Y', value: 'Y'),
          ],
          vm.selectedTimeRange,
          (val) => vm.setTimeRange(val),
        ),
      ],
    );
  }

  Widget _buildToggleGroup(List<_ToggleItem> items, String currentValue, Function(String) onChanged) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: items.map((item) {
                final bool isActive = currentValue == item.value;
                return GestureDetector(
                  onTap: () => onChanged(item.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF10B981) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.label,
                      style: GoogleFonts.jetBrainsMono(
                        color: isActive ? Colors.black : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleItem {
  final String label;
  final String value;
  _ToggleItem({required this.label, required this.value});
}
