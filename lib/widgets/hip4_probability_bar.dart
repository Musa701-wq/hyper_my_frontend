import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hip4_model.dart';
import '../utils/app_colors.dart';

class Hip4ProbabilityBar extends StatelessWidget {
  final List<Hip4Outcome> outcomes;
  final double height;

  const Hip4ProbabilityBar({
    super.key,
    required this.outcomes,
    this.height = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    if (outcomes.isEmpty) return const SizedBox();

    // Sort outcomes by probability descending to ensure consistent color mapping
    final sortedOutcomes = List<Hip4Outcome>.from(outcomes)
      ..sort((a, b) => b.probability.compareTo(a.probability));

    final bool isBinary = outcomes.length == 2 && 
        outcomes.any((o) => o.label.toLowerCase() == 'yes') &&
        outcomes.any((o) => o.label.toLowerCase() == 'no');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The Segmented Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Row(
              children: outcomes.map((outcome) {
                return Expanded(
                  flex: (outcome.probability * 100).round().clamp(1, 10000),
                  child: Container(color: _getColor(outcome, outcomes)),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Labels
        if (isBinary)
          _buildBinaryLabels(outcomes)
        else
          _buildMultiLabels(outcomes),
      ],
    );
  }

  Widget _buildBinaryLabels(List<Hip4Outcome> outcomes) {
    final yes = outcomes.firstWhere((o) => o.label.toLowerCase() == 'yes');
    final no = outcomes.firstWhere((o) => o.label.toLowerCase() == 'no');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDotLabel(yes.label, yes.probability, const Color(0xFF10B981)),
        _buildDotLabel(no.label, no.probability, const Color(0xFFF43F5E), reverse: true),
      ],
    );
  }

  Widget _buildMultiLabels(List<Hip4Outcome> outcomes) {
    // Only show top 4 to avoid crowding
    final toShow = outcomes.take(4).toList();
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: toShow.map((o) => _buildDotLabel(o.label, o.probability, _getColor(o, outcomes))).toList(),
    );
  }

  Widget _buildDotLabel(String label, double probability, Color color, {bool reverse = false}) {
    final content = [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        reverse ? '${probability.toStringAsFixed(1)}% $label' : '$label ${probability.toStringAsFixed(1)}%',
        style: GoogleFonts.jetBrainsMono(
          color: AppColors.textSecondary,
          fontSize: 8,
          fontWeight: FontWeight.w500,
        ),
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: reverse ? content.reversed.toList() : content,
    );
  }

  Color _getColor(Hip4Outcome outcome, List<Hip4Outcome> all) {
    final label = outcome.label.toLowerCase();
    if (label == 'yes') return const Color(0xFF10B981);
    if (label == 'no') return const Color(0xFFF43F5E);
    
    // For others, use indexed palette
    final index = all.indexOf(outcome);
    final palette = [
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFF43F5E), // Red
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
    ];
    return palette[index % palette.length];
  }
}
