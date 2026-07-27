import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/fee_intelligence_model.dart';
import '../services/fee_intelligence_service.dart';
import '../utils/app_colors.dart';
import '../utils/common_widgets.dart';
import '../utils/responsive.dart';
import 'defi_volume_detail_screen.dart';
import '../widgets/error_state_widget.dart';
import 'package:shimmer/shimmer.dart';

class DefiVolumeChainDetailScreen extends StatefulWidget {
  final String chain;
  const DefiVolumeChainDetailScreen({super.key, required this.chain});

  @override
  State<DefiVolumeChainDetailScreen> createState() => _DefiVolumeChainDetailScreenState();
}

class _DefiVolumeChainDetailScreenState extends State<DefiVolumeChainDetailScreen> {
  final _service = FeeIntelligenceService();
  bool _isLoading = true;
  String _error = '';
  DexChainDetailResponse? _chainData;

  @override
  void initState() {
    super.initState();
    _loadChainData();
  }

  Future<void> _loadChainData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final data = await _service.fetchProtocolsByChain(widget.chain);
      setState(() {
        _chainData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
            '${widget.chain} Volume',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: res.fontSize(15),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        body: _isLoading
            ? _buildShimmerLoading(res)
            : _error.isNotEmpty
                ? _buildErrorView()
                : _buildContent(res),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: ErrorStateWidget(
        errorMessage: _error,
        onRetry: _loadChainData,
      ),
    );
  }

  Widget _buildShimmerLoading(Responsive res) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E222D),
      highlightColor: const Color(0xFF3A3F4E),
      period: const Duration(milliseconds: 1500),
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: res.spacing(14), vertical: res.spacing(10)),
        children: [
          Container(height: 70, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 15),
          Container(height: 400, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
        ],
      ),
    );
  }

  Widget _buildContent(Responsive res) {
    final data = _chainData;
    if (data == null) return const SizedBox.shrink();

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: res.spacing(14), vertical: res.spacing(10)),
      children: [
        // Stats Banner
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Volume (24H)',
                _fmtMoney(data.totalVolume24h),
                res,
              ),
              Container(
                width: 1,
                height: 30,
                color: AppColors.surfaceBright.withOpacity(0.2),
              ),
              _buildStatItem(
                'Active Protocols',
                data.totalProtocols.toString(),
                res,
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),

        // Protocols Leaderboard Title
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'PROTOCOLS LEADERBOARD',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: res.fontSize(9.5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Table
        _buildProtocolsTable(data.protocols, res),
      ],
    );
  }

  Widget _buildStatItem(String title, String val, Responsive res) {
    return Column(
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: res.fontSize(8.5),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          val,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.brandAccent,
            fontSize: res.fontSize(14),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProtocolsTable(List<FeeTopProtocol> protocols, Responsive res) {
    if (protocols.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No protocols found on this chain',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
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
              width: res.columnWidth(650.0),
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
                            width: res.columnWidth(160.0),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
                              ),
                            ),
                            child: Text(
                              'NAME',
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.textSecondary,
                                fontSize: res.fontSize(8.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildHeaderCell('24H VOLUME', res, width: res.columnWidth(110.0)),
                          _buildHeaderCell('1D CHANGE', res, width: res.columnWidth(90.0)),
                          _buildHeaderCell('7D CHANGE', res, width: res.columnWidth(90.0)),
                          _buildHeaderCell('CATEGORY', res, width: res.columnWidth(100.0)),
                          _buildHeaderCell('CHAINS COUNT', res, width: res.columnWidth(100.0)),
                        ],
                      ),
                    ),
                    Divider(color: Colors.white.withOpacity(0.04), height: 1),
                    // Rows
                    ...protocols.asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value;
                      final rank = i + 1;

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
                                width: res.columnWidth(160.0),
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
                              _buildValueCell(_fmtMoney(p.fees24h), res, width: res.columnWidth(110.0)),
                              _buildPercentageCell(p.change1d, res, width: res.columnWidth(90.0)),
                              _buildPercentageCell(p.change7d, res, width: res.columnWidth(90.0)),
                              _buildCategoryCell(p.category, res, width: res.columnWidth(100.0)),
                              _buildValueCell(p.chains.length.toString(), res, width: res.columnWidth(100.0)),
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

  Widget _buildHeaderCell(String label, Responsive res, {required double width}) {
    return Container(
      width: width,
      height: 36,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 10),
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

  Widget _buildValueCell(String text, Responsive res, {required double width}) {
    return Container(
      width: width,
      height: 56,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 10),
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

  Widget _buildPercentageCell(double change, Responsive res, {required double width}) {
    final isPos = change >= 0;
    final color = isPos ? const Color(0xFF00E676) : const Color(0xFFFF5252);
    final sign = isPos ? '+' : '';
    return Container(
      width: width,
      height: 56,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
        ),
      ),
      child: Text(
        '$sign${change.toStringAsFixed(2)}%',
        style: GoogleFonts.jetBrainsMono(
          color: color,
          fontSize: res.fontSize(10),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategoryCell(String category, Responsive res, {required double width}) {
    return Container(
      width: width,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.surfaceBright.withOpacity(0.15), width: 0.5),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: _getCategoryColor(category).withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          category.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.jetBrainsMono(
            color: _getCategoryColor(category),
            fontSize: res.fontSize(7.5),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String c) {
    switch (c.toLowerCase().trim()) {
      case 'stablecoin issuer': return const Color(0xFF2563EB);
      case 'dexs': return const Color(0xFF00E5FF);
      case 'chain': return const Color(0xFF38E54D);
      case 'derivatives': return const Color(0xFFF97316);
      case 'liquid staking': return const Color(0xFF9D4EDD);
      case 'staking pool': return const Color(0xFF06B6D4);
      case 'lending': return const Color(0xFFFFB300);
      case 'rwa': return const Color(0xFF10B981);
      case 'bridge': return const Color(0xFFEF4444);
      case 'yield': return const Color(0xFF14B8A6);
      default: return const Color(0xFF8E9AA6);
    }
  }

  Widget _fallbackLogo(String name, Responsive res) {
    return Container(
      width: 18,
      height: 18,
      color: AppColors.surfaceBright.withOpacity(0.12),
      child: const Icon(Icons.token_outlined, color: AppColors.brandAccent, size: 8),
    );
  }
}
