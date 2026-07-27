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
import '../widgets/dex_volume/volume_chart.dart';
import '../widgets/dex_volume/growth_banner.dart';
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
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.brandAccent, size: res.fontSize(20)),
          ),
          title: Text(
            'Hyperliquid DEX Volume',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: res.fontSize(16),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
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
                      SizedBox(height: res.spacing(16)),
                      VolumeChartWidget(
                        data: viewModel.chartData,
                        selectedScope: 'All',
                        selectedTimeRange: viewModel.selectedTimeRange,
                        selectedChartType: viewModel.selectedChartType,
                        onChartTypeChanged: (type) => viewModel.setChartType(type),
                        onTimeRangeChanged: (range) => viewModel.setTimeRange(range),
                      ),
                      SizedBox(height: res.spacing(16)),
                      if (viewModel.adoption != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: GrowthBanner(
                                title: 'MoM Growth',
                                growth: viewModel.adoption!.monthOverMonthGrowth ?? 0,
                              ),
                            ),
                            SizedBox(width: res.spacing(10)),
                            Expanded(
                              child: GrowthBanner(
                                title: 'QoQ Growth',
                                growth: viewModel.adoption!.quarterOverQuarterGrowth ?? 0,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: res.spacing(12)),
                        _buildAdoptionCards(viewModel.adoption!),
                        SizedBox(height: res.spacing(12)),
                        TrendChartWidget(
                          title: 'Monthly Volume Trend',
                          subtitle: 'Historical performance',
                          trend: viewModel.adoption!.monthlyTrend,
                          color: const Color(0xFF10B981),
                        ),
                        SizedBox(height: res.spacing(12)),
                        TrendChartWidget(
                          title: 'Quarterly Volume Trend',
                          subtitle: 'Strategic growth',
                          trend: viewModel.adoption!.quarterlyTrend,
                          color: const Color(0xFF8B5CF6),
                          filterCurrent: true,
                        ),
                        SizedBox(height: res.spacing(12)),
                        MonthlyVolumeTable(
                          monthlyTrend: viewModel.adoption!.monthlyTrend,
                          sixMonthAvg: viewModel.adoption!.sixMonthAverageVolume,
                        ),
                        SizedBox(height: res.spacing(24)),
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

  String _fmtVol(double val) {
    if (val >= 1e9) {
      return '\$${(val / 1e9).toStringAsFixed(2)}B';
    } else if (val >= 1e6) {
      return '\$${(val / 1e6).toStringAsFixed(2)}M';
    } else {
      return '\$${val.toStringAsFixed(2)}';
    }
  }

  Widget _buildMetricCards(DexVolumeMetrics metrics) {
    final res = Responsive(context);

    final isUp1d = metrics.change1d >= 0;
    final isUp7d = (metrics.change7d ?? 0) >= 0;
    final isUp1m = (metrics.change1m ?? 0) >= 0;

    final item1 = _kpiItem(
      title: '24h Volume',
      value: _fmtVol(metrics.total24h),
      badgeWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp1d ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: isUp1d ? AppColors.trendGreen : AppColors.trendRed,
            size: res.fontSize(14),
          ),
          Text(
            '${isUp1d ? '+' : ''}${metrics.change1d.toStringAsFixed(2)}%',
            style: GoogleFonts.inter(
              color: isUp1d ? AppColors.trendGreen : AppColors.trendRed,
              fontSize: res.fontSize(9.5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      icon: isUp1d ? Icons.trending_up : Icons.trending_down,
      iconColor: isUp1d ? AppColors.trendGreen : AppColors.trendRed,
      res: res,
    );

    final item2 = _kpiItem(
      title: '7d Volume',
      value: _fmtVol(metrics.total7d),
      badgeWidget: metrics.change7d == null
          ? const SizedBox.shrink()
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUp7d ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: isUp7d ? AppColors.trendGreen : AppColors.trendRed,
                  size: res.fontSize(14),
                ),
                Text(
                  '${isUp7d ? '+' : ''}${metrics.change7d!.toStringAsFixed(2)}%',
                  style: GoogleFonts.inter(
                    color: isUp7d ? AppColors.trendGreen : AppColors.trendRed,
                    fontSize: res.fontSize(9.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
      icon: isUp7d ? Icons.trending_up : Icons.trending_down,
      iconColor: isUp7d ? AppColors.trendGreen : AppColors.trendRed,
      res: res,
    );

    final item3 = _kpiItem(
      title: '30d Volume',
      value: _fmtVol(metrics.total30d),
      badgeWidget: metrics.change1m == null
          ? const SizedBox.shrink()
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUp1m ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: isUp1m ? AppColors.trendGreen : AppColors.trendRed,
                  size: res.fontSize(14),
                ),
                Text(
                  '${isUp1m ? '+' : ''}${metrics.change1m!.toStringAsFixed(2)}%',
                  style: GoogleFonts.inter(
                    color: isUp1m ? AppColors.trendGreen : AppColors.trendRed,
                    fontSize: res.fontSize(9.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
      icon: isUp1m ? Icons.trending_up : Icons.trending_down,
      iconColor: isUp1m ? AppColors.trendGreen : AppColors.trendRed,
      res: res,
    );

    final item4 = _kpiItem(
      title: 'Cumulative',
      value: _fmtVol(metrics.totalAllTime),
      badgeWidget: const SizedBox.shrink(),
      icon: Icons.bar_chart_rounded,
      res: res,
    );

    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: res.spacing(16),
        vertical: res.spacing(14),
      ),
      child: res.isMobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: item1),
                    Container(
                      width: 1,
                      height: res.spacing(55),
                      margin: EdgeInsets.symmetric(horizontal: res.spacing(14)),
                      color: Colors.white.withOpacity(0.06),
                    ),
                    Expanded(child: item2),
                  ],
                ),
                Divider(
                  color: Colors.white.withOpacity(0.06),
                  height: res.spacing(24),
                  thickness: 1,
                ),
                Row(
                  children: [
                    Expanded(child: item3),
                    Container(
                      width: 1,
                      height: res.spacing(55),
                      margin: EdgeInsets.symmetric(horizontal: res.spacing(14)),
                      color: Colors.white.withOpacity(0.06),
                    ),
                    Expanded(child: item4),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: item1),
                Container(
                  width: 1,
                  height: res.spacing(60),
                  margin: EdgeInsets.symmetric(horizontal: res.spacing(16)),
                  color: Colors.white.withOpacity(0.06),
                ),
                Expanded(child: item2),
                Container(
                  width: 1,
                  height: res.spacing(60),
                  margin: EdgeInsets.symmetric(horizontal: res.spacing(16)),
                  color: Colors.white.withOpacity(0.06),
                ),
                Expanded(child: item3),
                Container(
                  width: 1,
                  height: res.spacing(60),
                  margin: EdgeInsets.symmetric(horizontal: res.spacing(16)),
                  color: Colors.white.withOpacity(0.06),
                ),
                Expanded(child: item4),
              ],
            ),
    );
  }

  Widget _buildAdoptionCards(AdoptionMetrics adoption) {
    final res = Responsive(context);

    final isGrowthUp = (adoption.monthOverMonthGrowth ?? 0) >= 0;

    final item1 = _kpiItem(
      title: 'Current Month',
      value: _fmtVol(adoption.currentMonthVolume),
      badgeWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('yyyy-MM').format(DateTime.now()),
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: res.fontSize(9.5),
            ),
          ),
          if (adoption.monthOverMonthGrowth != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isGrowthUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: isGrowthUp ? AppColors.trendGreen : AppColors.trendRed,
                  size: res.fontSize(14),
                ),
                Text(
                  '${isGrowthUp ? '+' : ''}${adoption.monthOverMonthGrowth!.toStringAsFixed(2)}%',
                  style: GoogleFonts.inter(
                    color: isGrowthUp ? AppColors.trendGreen : AppColors.trendRed,
                    fontSize: res.fontSize(9.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      icon: Icons.calendar_today_rounded,
      res: res,
    );

    final item2 = _kpiItem(
      title: 'Previous Month',
      value: _fmtVol(adoption.previousMonthVolume),
      badgeWidget: Text(
        DateFormat('yyyy-MM').format(DateTime.now().subtract(const Duration(days: 30))),
        style: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: res.fontSize(9.5),
        ),
      ),
      icon: Icons.history_rounded,
      res: res,
    );

    final item3 = _kpiItem(
      title: '6-Month Average',
      value: _fmtVol(adoption.sixMonthAverageVolume ?? 0),
      badgeWidget: Text(
        'per month',
        style: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: res.fontSize(9.5),
        ),
      ),
      icon: Icons.analytics_rounded,
      res: res,
    );

    final item4 = _kpiItem(
      title: 'ATH Month',
      value: _fmtVol(adoption.allTimeHighMonthlyVolume),
      badgeWidget: Text(
        adoption.isNewMonthlyATH ? 'NEW ATH' : 'Historical',
        style: GoogleFonts.inter(
          color: adoption.isNewMonthlyATH ? AppColors.trendGreen : AppColors.textSecondary,
          fontSize: res.fontSize(9.5),
          fontWeight: adoption.isNewMonthlyATH ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      icon: Icons.emoji_events_rounded,
      res: res,
    );

    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: res.spacing(16),
        vertical: res.spacing(14),
      ),
      child: res.isMobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: item1),
                    Container(
                      width: 1,
                      height: res.spacing(70),
                      margin: EdgeInsets.symmetric(horizontal: res.spacing(14)),
                      color: Colors.white.withOpacity(0.06),
                    ),
                    Expanded(child: item2),
                  ],
                ),
                Divider(
                  color: Colors.white.withOpacity(0.06),
                  height: res.spacing(24),
                  thickness: 1,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: item3),
                    Container(
                      width: 1,
                      height: res.spacing(70),
                      margin: EdgeInsets.symmetric(horizontal: res.spacing(14)),
                      color: Colors.white.withOpacity(0.06),
                    ),
                    Expanded(child: item4),
                  ],
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: item1),
                Container(
                  width: 1,
                  height: res.spacing(75),
                  margin: EdgeInsets.symmetric(horizontal: res.spacing(16)),
                  color: Colors.white.withOpacity(0.06),
                ),
                Expanded(child: item2),
                Container(
                  width: 1,
                  height: res.spacing(75),
                  margin: EdgeInsets.symmetric(horizontal: res.spacing(16)),
                  color: Colors.white.withOpacity(0.06),
                ),
                Expanded(child: item3),
                Container(
                  width: 1,
                  height: res.spacing(75),
                  margin: EdgeInsets.symmetric(horizontal: res.spacing(16)),
                  color: Colors.white.withOpacity(0.06),
                ),
                Expanded(child: item4),
              ],
            ),
    );
  }

  Widget _kpiItem({
    required String title,
    required String value,
    required Widget badgeWidget,
    required IconData icon,
    Color? iconColor,
    required Responsive res,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: res.fontSize(8.5),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  color: valueColor ?? AppColors.textPrimary,
                  fontSize: res.fontSize(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              badgeWidget,
            ],
          ),
        ),
        Container(
          width: res.spacing(24),
          height: res.spacing(24),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.brandAccent).withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: res.fontSize(12),
            color: iconColor ?? AppColors.brandAccent,
          ),
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

