import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hip4_model.dart';
import '../utils/app_colors.dart';

const _palette = [
  Color(0xFF10B981), // Green
  Color(0xFFF59E0B), // Amber
  Color(0xFF3B82F6), // Blue
  Color(0xFF8B5CF6), // Purple — used for "Others"
];

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

    final bool isBinary = outcomes.length == 2 &&
        outcomes.any((o) => o.label.toLowerCase() == 'yes') &&
        outcomes.any((o) => o.label.toLowerCase() == 'no');

    // Sort descending by probability
    final sorted = List<Hip4Outcome>.from(outcomes)
      ..sort((a, b) => b.probability.compareTo(a.probability));

    // Build display list: top 3 + optional "Others"
    final List<_DisplayOutcome> display = _buildDisplay(sorted, isBinary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Bar ──────────────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Row(
              children: display.map((d) {
                return Expanded(
                  flex: (d.probability * 100).round().clamp(1, 10000),
                  child: Container(color: d.color),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // ── Labels ───────────────────────────────────────────────────
        _buildLabels(display, isBinary),
      ],
    );
  }

  List<_DisplayOutcome> _buildDisplay(
      List<Hip4Outcome> sorted, bool isBinary) {
    if (isBinary) {
      // Yes/No — keep both, assign fixed colors
      return sorted.asMap().entries.map((e) {
        final label = e.value.label.toLowerCase();
        final color = label == 'yes'
            ? const Color(0xFF10B981)
            : const Color(0xFFF43F5E);
        return _DisplayOutcome(e.value.label, e.value.probability, color);
      }).toList();
    }

    if (sorted.length <= 3) {
      return sorted.asMap().entries
          .map((e) => _DisplayOutcome(
              e.value.label, e.value.probability, _palette[e.key % _palette.length]))
          .toList();
    }

    // More than 3: show top 3, merge rest into "Others"
    final top3 = sorted.take(3).toList();
    final rest = sorted.skip(3).toList();
    final othersProb = rest.fold(0.0, (sum, o) => sum + o.probability);
    final othersCount = rest.length;

    final result = top3.asMap().entries
        .map((e) => _DisplayOutcome(
            e.value.label, e.value.probability, _palette[e.key]))
        .toList();

    result.add(_DisplayOutcome(
      'Others ($othersCount)',
      othersProb,
      _palette[3], // Purple for others
    ));

    return result;
  }

  Widget _buildLabels(List<_DisplayOutcome> display, bool isBinary) {
    if (isBinary) {
      return Row(
        children: [
          Expanded(child: _dotLabel(display[0])),
          if (display.length > 1) Expanded(child: _dotLabel(display[1])),
        ],
      );
    }

    // 2 per row
    final List<Widget> rows = [];
    for (int i = 0; i < display.length; i += 2) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          children: [
            Expanded(child: _dotLabel(display[i])),
            if (i + 1 < display.length)
              Expanded(child: _dotLabel(display[i + 1])),
          ],
        ),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Widget _dotLabel(_DisplayOutcome d) {
    // Font size proportional to probability: 9–12px
    final fs = (9.0 + d.probability * 0.05).clamp(9.0, 12.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: d.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${d.label} ${d.probability.toStringAsFixed(1)}%',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: fs,
              fontWeight: d.probability >= 30 ? FontWeight.w600 : FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DisplayOutcome {
  final String label;
  final double probability;
  final Color color;
  _DisplayOutcome(this.label, this.probability, this.color);
}
