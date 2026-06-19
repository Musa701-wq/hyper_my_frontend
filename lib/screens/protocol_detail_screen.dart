import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/protocol_model.dart';
import '../services/protocol_service.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';

class ProtocolDetailScreen extends StatefulWidget {
  final String slug;
  final String? name;
  final String? logo;

  const ProtocolDetailScreen({
    super.key,
    required this.slug,
    this.name,
    this.logo,
  });

  @override
  State<ProtocolDetailScreen> createState() => _ProtocolDetailScreenState();
}

class _ProtocolDetailScreenState extends State<ProtocolDetailScreen> {
  final ProtocolService _service = ProtocolService();
  ProtocolDetail? _detail;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      final detail = await _service.getProjectDetail(widget.slug);
      if (mounted) setState(() { _detail = detail; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '< TVL Dashboard',
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: res.fontSize(13),
          ),
        ),
        titleSpacing: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandAccent))
          : _error.isNotEmpty
              ? _buildError(res)
              : _buildContent(res),
    );
  }

  Widget _buildError(Responsive res) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AppColors.trendRed, size: 48),
          const SizedBox(height: 12),
          Text(_error, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchDetail,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandAccent),
            child: Text('Retry', style: GoogleFonts.jetBrainsMono(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Responsive res) {
    final d = _detail!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(res.spacing(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(d, res),
          SizedBox(height: res.spacing(20)),
          _buildTvlHero(d, res),
          SizedBox(height: res.spacing(20)),
          _buildStatsSection(d, res),
          SizedBox(height: res.spacing(20)),
          _buildChainTvls(d, res),
          SizedBox(height: res.spacing(20)),
          _buildAboutSection(d, res),
          SizedBox(height: res.spacing(32)),
          _buildFooter(res),
          SizedBox(height: res.spacing(16)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER — Logo, name, category badges, links
  // ═══════════════════════════════════════════════════════════
  Widget _buildHeader(ProtocolDetail d, Responsive res) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBright.withValues(alpha: 0.3)),
            color: AppColors.surfaceBright.withValues(alpha: 0.1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              d.logo,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.token, color: AppColors.textSecondary, size: 28),
            ),
          ),
        ),
        SizedBox(width: res.spacing(16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.name,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: res.fontSize(22),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _badge(d.category, AppColors.brandAccent),
                  _badge(d.type.toUpperCase(), d.type == 'core' ? AppColors.brandAccent : AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (d.url.isNotEmpty) _linkChip(Icons.language, 'Website', d.url),
                  if (d.twitter != null) ...[
                    const SizedBox(width: 8),
                    _linkChip(Icons.alternate_email, '@${d.twitter}', 'https://x.com/${d.twitter}'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _linkChip(IconData icon, String label, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceBright.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceBright.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.brandAccent),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TVL HERO — Big number + change badges
  // ═══════════════════════════════════════════════════════════
  Widget _buildTvlHero(ProtocolDetail d, Responsive res) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(res.spacing(20)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandAccent.withValues(alpha: 0.08),
            AppColors.brandAccent.withValues(alpha: 0.02),
            AppColors.background,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(color: AppColors.brandAccent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 14, color: AppColors.brandAccent.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                'TOTAL VALUE LOCKED',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              d.fullTvl,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: res.fontSize(32),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _changeBadge('1H CHANGE', d.change1h),
              const SizedBox(width: 10),
              _changeBadge('1D CHANGE', d.change1d),
              const SizedBox(width: 10),
              _changeBadge('7D CHANGE', d.change7d),
            ],
          ),
        ],
      ),
    );
  }

  Widget _changeBadge(String label, double value) {
    final isPositive = value >= 0;
    final color = isPositive ? AppColors.trendGreen : AppColors.trendRed;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 7, letterSpacing: 0.5),
            ),
            const SizedBox(height: 3),
            Text(
              '${isPositive ? "+" : ""}${value.toStringAsFixed(2)}%',
              style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PROTOCOL STATS — Market Cap, Mcap/TVL
  // ═══════════════════════════════════════════════════════════
  Widget _buildStatsSection(ProtocolDetail d, Responsive res) {
    return Container(
      padding: EdgeInsets.all(res.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBright.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 14, color: AppColors.brandAccent),
              const SizedBox(width: 8),
              Text(
                'Protocol Stats',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _statRow('Market Cap', d.mcap != null ? _fmtLargeNum(d.mcap!) : 'N/A'),
          const Divider(color: AppColors.surfaceBright, height: 20),
          _statRow('Mcap/TVL Ratio', d.mcapTvlRatio != null ? d.mcapTvlRatio!.toStringAsFixed(2) : 'N/A'),
          const Divider(color: AppColors.surfaceBright, height: 20),
          _statRow('Chains', d.chains.length.toString()),
          const Divider(color: AppColors.surfaceBright, height: 20),
          _statRow('Type', d.type.toUpperCase()),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11)),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TVL BY CHAIN — sorted list with percentage bars
  // ═══════════════════════════════════════════════════════════
  Widget _buildChainTvls(ProtocolDetail d, Responsive res) {
    if (d.chainTvls.isEmpty) return const SizedBox.shrink();

    // Sort by TVL descending
    final sorted = d.chainTvls.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final totalChainTvl = sorted.fold<double>(0, (sum, e) => sum + e.value);

    return Container(
      padding: EdgeInsets.all(res.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBright.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_rounded, size: 14, color: AppColors.brandAccent),
              const SizedBox(width: 8),
              Text(
                'TVL by Chain',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sorted.map((entry) {
            final pct = totalChainTvl > 0 ? (entry.value / totalChainTvl * 100) : 0.0;
            return _chainRow(entry.key, entry.value, pct, res);
          }),
        ],
      ),
    );
  }

  Widget _chainRow(String chain, double tvl, double pct, Responsive res) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chain, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      _fmtLargeNum(tvl),
                      style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.brandAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: AppColors.surfaceBright.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandAccent.withValues(alpha: 0.6)),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ABOUT SECTION — description
  // ═══════════════════════════════════════════════════════════
  Widget _buildAboutSection(ProtocolDetail d, Responsive res) {
    if (d.description.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(res.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBright.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: AppColors.brandAccent),
              const SizedBox(width: 8),
              Text(
                'About ${d.name}',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            d.description,
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════════════════════
  Widget _buildFooter(Responsive res) {
    return Center(
      child: Text(
        'Data powered by DefiLlama & Hyperliquid API',
        style: GoogleFonts.jetBrainsMono(
          color: AppColors.textSecondary.withValues(alpha: 0.4),
          fontSize: 9,
        ),
      ),
    );
  }

  String _fmtLargeNum(double val) {
    if (val >= 1e9) return '\$${(val / 1e9).toStringAsFixed(2)}B';
    if (val >= 1e6) return '\$${(val / 1e6).toStringAsFixed(2)}M';
    if (val >= 1e3) return '\$${(val / 1e3).toStringAsFixed(0)}K';
    return '\$${val.toStringAsFixed(0)}';
  }
}
