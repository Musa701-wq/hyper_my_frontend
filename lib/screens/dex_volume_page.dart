import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../models/dex_volume_model.dart';
import '../utils/common_widgets.dart';
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

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.brandAccent, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Hyperliquid DEX Volume',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Consumer<DexVolumeViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return _buildLoading(res);
            }
            if (viewModel.errorMessage.isNotEmpty) {
              return ErrorStateWidget(
                errorMessage: viewModel.errorMessage,
                onRetry: () => viewModel.fetchAllData(),
              );
            }
            if (viewModel.metrics == null) {
              return const Center(child: Text('No data available'));
            }
            return RefreshIndicator(
              onRefresh: () => viewModel.fetchAllData(),
              color: AppColors.brandAccent,
              backgroundColor: AppColors.background,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(res.spacing(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetricCards(viewModel.metrics!),
                      const SizedBox(height: 24),
                      VolumeChartWidget(
                        data: viewModel.chartData,
                        selectedScope: 'All',
                        selectedTimeRange: viewModel.selectedTimeRange,
                        selectedChartType: viewModel.selectedChartType,
                        onChartTypeChanged: (type) => viewModel.setChartType(type),
                        onTimeRangeChanged: (range) => viewModel.setTimeRange(range),
                      ),
                      const SizedBox(height: 24),
                      if (viewModel.adoption != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: GrowthBanner(
                                title: 'MoM Growth',
                                growth: viewModel.adoption!.monthOverMonthGrowth ?? 0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GrowthBanner(
                                title: 'QoQ Growth',
                                growth: viewModel.adoption!.quarterOverQuarterGrowth ?? 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildAdoptionCards(viewModel.adoption!),
                        const SizedBox(height: 16),
                        TrendChartWidget(
                          title: 'Monthly Volume Trend',
                          subtitle: 'Historical performance',
                          trend: viewModel.adoption!.monthlyTrend,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(height: 16),
                        TrendChartWidget(
                          title: 'Quarterly Volume Trend',
                          subtitle: 'Strategic growth',
                          trend: viewModel.adoption!.quarterlyTrend,
                          color: const Color(0xFF8B5CF6),
                          filterCurrent: true,
                        ),
                        const SizedBox(height: 16),
                        MonthlyVolumeTable(
                          monthlyTrend: viewModel.adoption!.monthlyTrend,
                          sixMonthAvg: viewModel.adoption!.sixMonthAverageVolume,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricCards(DexVolumeMetrics metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        if (isWide) {
          return Row(
            children: [
              Expanded(child: MetricCard(title: '24h Volume', value: metrics.total24h, change: metrics.change1d)),
              const SizedBox(width: 12),
              Expanded(child: MetricCard(title: '7d Volume', value: metrics.total7d, change: metrics.change7d)),
              const SizedBox(width: 12),
              Expanded(child: MetricCard(title: '30d Volume', value: metrics.total30d, change: metrics.change1m)),
              const SizedBox(width: 12),
              Expanded(child: MetricCard(title: 'Cumulative', value: metrics.totalAllTime, isCumulative: true)),
            ],
          );
        }
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
      },
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

}

  Widget _buildLoading(Responsive res) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2C2F3A),
      highlightColor: const Color(0xFF3F4452),
      period: const Duration(milliseconds: 1400),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(res.spacing(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: _sh(res, 85, 0)),
                const SizedBox(width: 12),
                Expanded(child: _sh(res, 85, 0)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _sh(res, 85, 0)),
                const SizedBox(width: 12),
                Expanded(child: _sh(res, 85, 0)),
              ]),
              const SizedBox(height: 24),
              _sh(res, 40, 0, radius: 10), // Toggles
              const SizedBox(height: 16),
              _sh(res, 280, 0, radius: 16), // Chart
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _sh(res, 70, 0, radius: 12)),
                const SizedBox(width: 12),
                Expanded(child: _sh(res, 70, 0, radius: 12)),
              ]),
              const SizedBox(height: 16),
              _sh(res, 120, 0, radius: 16), // Adoption card
              const SizedBox(height: 16),
              _sh(res, 180, 0, radius: 16), // Trend chart
            ],
          ),
        ),
      ),
    );
  }

  Widget _sh(Responsive res, double h, double inset, {double radius = 12}) => Container(
    height: h,
    margin: EdgeInsets.symmetric(
      vertical: 3,
      horizontal: inset > 0 ? res.spacing(inset) : 0,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(radius),
    ),
  );

