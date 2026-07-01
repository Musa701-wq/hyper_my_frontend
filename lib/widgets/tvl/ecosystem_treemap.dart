import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/protocol_model.dart';
import '../../utils/app_colors.dart';

class EcosystemTreeMap extends StatelessWidget {
  final List<Protocol> protocols;
  final double height;

  const EcosystemTreeMap({
    super.key,
    required this.protocols,
    this.height = 400.0,
  });

  @override
  Widget build(BuildContext context) {
    if (protocols.isEmpty) return const SizedBox.shrink();

    // Take top 20 protocols for the treemap to keep it clean
    final displayProtocols = protocols.take(20).toList();
    final totalTvl = displayProtocols.fold(0.0, (sum, p) => sum + p.tvl);

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.1)),
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
                    'Ecosystem Overview',
                    style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                   Text(
                    'Relative size of top protocols by TVL.',
                    style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 9),
                  ),
                ],
              ),
              const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _buildTreeMap(displayProtocols, totalTvl, constraints.maxWidth, constraints.maxHeight);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeMap(List<Protocol> data, double total, double width, double height) {
    if (data.isEmpty) return const SizedBox.shrink();
    
    // Simplified TreeMap logic: Split recursively alternatively between H and V
    return _RecursiveSplit(
      data: data,
      total: total,
      width: width,
      height: height,
      vertical: width > height,
    );
  }
}

class _RecursiveSplit extends StatelessWidget {
  final List<Protocol> data;
  final double total;
  final double width;
  final double height;
  final bool vertical;

  const _RecursiveSplit({
    required this.data,
    required this.total,
    required this.width,
    required this.height,
    required this.vertical,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    if (data.length == 1) {
      return _TreeMapNode(protocol: data[0], width: width, height: height, percentage: (data[0].tvl / total) * 100);
    }

    // Find a split point
    int splitIndex = 1;
    double currentSum = 0;
    double halfTotal = total / 2;
    
    for (int i = 0; i < data.length; i++) {
        currentSum += data[i].tvl;
        if (currentSum >= halfTotal || i == data.length - 2) {
            splitIndex = i + 1;
            break;
        }
    }

    final firstPart = data.sublist(0, splitIndex);
    final secondPart = data.sublist(splitIndex);
    final firstTotal = firstPart.fold(0.0, (sum, p) => sum + p.tvl);
    final secondTotal = total - firstTotal;

    if (vertical) {
      final splitWidth = width * (firstTotal / total);
      return Row(
        children: [
          _RecursiveSplit(
            data: firstPart,
            total: firstTotal,
            width: splitWidth,
            height: height,
            vertical: !vertical,
          ),
          _RecursiveSplit(
            data: secondPart,
            total: secondTotal,
            width: width - splitWidth,
            height: height,
            vertical: !vertical,
          ),
        ],
      );
    } else {
      final splitHeight = height * (firstTotal / total);
      return Column(
        children: [
          _RecursiveSplit(
            data: firstPart,
            total: firstTotal,
            width: width,
            height: splitHeight,
            vertical: !vertical,
          ),
          _RecursiveSplit(
            data: secondPart,
            total: secondTotal,
            width: width,
            height: height - splitHeight,
            vertical: !vertical,
          ),
        ],
      );
    }
  }
}

class _TreeMapNode extends StatelessWidget {
  final Protocol protocol;
  final double width;
  final double height;
  final double percentage;

  const _TreeMapNode({
    required this.protocol,
    required this.width,
    required this.height,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(protocol.category);
    final isVisible = width > 50 && height > 40;
    final showSmall = width > 25 && height > 20;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        border: Border.all(color: Colors.black.withOpacity(0.3), width: 0.5),
      ),
      child: isVisible 
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circular Logo if enough space
                    if (height > 80)
                      Container(
                        width: (height * 0.2).clamp(16.0, 32.0),
                        height: (height * 0.2).clamp(16.0, 32.0),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            protocol.logo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.token, size: (height * 0.15).clamp(8, 16), color: Colors.white70),
                          ),
                        ),
                      ),
                    
                    Text(
                      protocol.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (height > 45) ...[
                      const SizedBox(height: 2),
                      Text(
                        protocol.fullTvl,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (height > 65)
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 8,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          )
        : (showSmall 
            ? Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    protocol.name[0],
                    style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ) 
            : const SizedBox.shrink()),
    );
  }

  Color _getCategoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('cex')) return const Color(0xFF6366F1); // Bybit Blue-ish
    if (lower.contains('bridge')) return const Color(0xFF3B82F6);
    if (lower.contains('lending')) return const Color(0xFF10B981);
    if (lower.contains('rwa')) return const Color(0xFFF43F5E);
    if (lower.contains('dex')) return const Color(0xFFD97706);
    if (lower.contains('liquid')) return const Color(0xFFEC4899);
    return const Color(0xFF64748B);
  }
}
