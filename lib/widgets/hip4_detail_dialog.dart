import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/hip4_model.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';

class Hip4DetailDialog extends StatelessWidget {
  final Hip4Market market;
  const Hip4DetailDialog({super.key, required this.market});

  static const _bg     = Color(0xFF0E0E14);
  static const _card   = Color(0xFF16161F);
  static const _border = Color(0xFF252530);

  static const List<Color> _palette = [
    Color(0xFF00C9A7),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFFF43F5E),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF84CC16),
  ];

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    final sorted = List<Hip4Outcome>.from(market.outcomes)
      ..sort((a, b) => b.probability.compareTo(a.probability));

    final expiryStr = market.expiry != null
        ? DateFormat('dd MMM yyyy · HH:mm').format(market.expiry!.toLocal()) + ' UTC'
        : null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: res.isMobile ? 14 : 60,
        vertical: 40,
      ),
      child: Container(
        width: res.isMobile ? double.infinity : 580,
        constraints: BoxConstraints(maxHeight: res.height * 0.82),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(context, res, expiryStr),
            const Divider(color: _border, height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description (max 3 lines)
                    if (market.description.isNotEmpty)
                      Text(
                        market.description,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: res.fontSize(10),
                          height: 1.6,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 20),

                    // Outcomes count + sort hint
                    Row(
                      children: [
                        Text(
                          'OUTCOMES',
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: res.fontSize(9),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _border,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${market.outcomes.length}',
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white38,
                              fontSize: res.fontSize(8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'sorted by probability',
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: res.fontSize(8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Outcome rows
                    ...sorted.asMap().entries.map((e) => _outcomeRow(e.value, e.key, res)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Responsive res, String? expiryStr) {
    final classColor = _classColor(market.marketClass);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  market.name,
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: res.fontSize(14),
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(market.marketClass, classColor),
                    if (market.category.isNotEmpty)
                      _chip(market.category, Colors.white30),
                    if (expiryStr != null)
                      _chip('⏱ $expiryStr', Colors.white24),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white54, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          color: borderColor == Colors.white30 || borderColor == Colors.white24
              ? Colors.white38
              : borderColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _outcomeRow(Hip4Outcome outcome, int idx, Responsive res) {
    final color  = _outcomeColor(outcome, idx);
    final isTop  = idx == 0;
    final pct    = outcome.probability.clamp(0.0, 100.0);
    final barPct = pct / 100.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isTop ? color.withValues(alpha: 0.07) : _card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTop ? color.withValues(alpha: 0.4) : _border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Color dot
              Container(
                width: 7, height: 7,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              // Label
              Expanded(
                child: Text(
                  outcome.label,
                  style: GoogleFonts.jetBrainsMono(
                    color: isTop ? color : Colors.white70,
                    fontSize: res.fontSize(11),
                    fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Probability
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: GoogleFonts.jetBrainsMono(
                  color: color,
                  fontSize: res.fontSize(11),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              // Price
              Text(
                outcome.price.toStringAsFixed(4),
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: res.fontSize(11),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: barPct,
              minHeight: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.75)),
            ),
          ),
        ],
      ),
    );
  }

  Color _outcomeColor(Hip4Outcome o, int idx) {
    if (o.label.toLowerCase() == 'yes') return const Color(0xFF10B981);
    if (o.label.toLowerCase() == 'no')  return const Color(0xFFF43F5E);
    return _palette[idx % _palette.length];
  }

  Color _classColor(String cls) {
    switch (cls) {
      case 'priceBinary': return const Color(0xFF38B2AC);
      case 'priceBucket': return const Color(0xFF4299E1);
      case 'question':    return const Color(0xFFED8936);
      default:            return const Color(0xFF718096);
    }
  }
}
