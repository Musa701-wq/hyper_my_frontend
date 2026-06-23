import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/protocol_model.dart';
import '../../utils/app_colors.dart';

class TopChainsChart extends StatelessWidget {
  final List<ChainTvl> data;

  const TopChainsChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxTvl = data.first.tvl;

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
            'Top Chains by TVL',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Leading blockchain networks by total value locked',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 20),
          ...data.map((chain) => _buildChainRow(chain, maxTvl)),
        ],
      ),
    );
  }

  Widget _buildChainRow(ChainTvl chain, double maxTvl) {
    final ratio = maxTvl > 0 ? (chain.tvl / maxTvl) : 0.0;
    final color = _chainColor(chain.chain);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                chain.chain,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                chain.formattedTvl,
                style: GoogleFonts.jetBrainsMono(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 8,
              width: double.infinity,
              color: AppColors.surfaceBright.withValues(alpha: 0.2),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.7),
                        color,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _chainColor(String chain) {
    final lower = chain.toLowerCase();
    if (lower.contains('ethereum') || lower.contains('eth')) return const Color(0xFF627EEA);
    if (lower.contains('solana') || lower.contains('sol')) return const Color(0xFF9945FF);
    if (lower.contains('bsc') || lower.contains('binance')) return const Color(0xFFF0B90B);
    if (lower.contains('arbitrum') || lower.contains('arb')) return const Color(0xFF28A0F0);
    if (lower.contains('polygon') || lower.contains('matic')) return const Color(0xFF8247E5);
    if (lower.contains('avalanche') || lower.contains('avax')) return const Color(0xFFE84142);
    if (lower.contains('optimism') || lower.contains('op')) return const Color(0xFFFF0420);
    if (lower.contains('base')) return const Color(0xFF0052FF);
    if (lower.contains('sui')) return const Color(0xFF4DA2FF);
    if (lower.contains('aptos') || lower.contains('apt')) return const Color(0xFF00BFA5);
    if (lower.contains('ton')) return const Color(0xFF0098EA);
    if (lower.contains('tron') || lower.contains('trx')) return const Color(0xFFFF0606);
    if (lower.contains('hyperliquid') || lower.contains('hype')) return AppColors.brandAccent;
    return const Color(0xFF60A5FA);
  }
}
