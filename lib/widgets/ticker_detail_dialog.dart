import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/ticker_model.dart';
import '../utils/app_colors.dart';

/// Sentiment meter from 8h funding rate.
({double longPct, double shortPct}) fundingSentiment(double funding8hPct) {
  const scalePerPercent = 50.0;
  final longPct = (50 + funding8hPct * scalePerPercent).clamp(0.0, 100.0);
  return (longPct: longPct, shortPct: 100.0 - longPct);
}

class TickerDetailDialog extends StatelessWidget {
  final TickerModel ticker;

  const TickerDetailDialog({super.key, required this.ticker});

  // ── Formatters ─────────────────────────────────────────────────────
  static String fmtUsd(double v) {
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(2)}K';
    return '\$${v.toStringAsFixed(2)}';
  }

  static String fmtNum(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(2)}K';
    return v.toStringAsFixed(4);
  }

  static String fmtPx(double v) {
    if (v <= 0) return '—';
    if (v >= 1000) return '\$${v.toStringAsFixed(2)}';
    if (v >= 1) return '\$${v.toStringAsFixed(4)}';
    return '\$${v.toStringAsFixed(6)}';
  }

  bool get _isSpot => ticker.marketType == 'spot';
  bool get _isPerp => ticker.marketType == 'perp';

  String get _subtitle {
    final name = ticker.displayName.isNotEmpty ? ticker.displayName : ticker.symbol;
    final afterColon = name.contains(':') ? name.split(':').last : name;
    return afterColon.split('-').first;
  }

  @override
  Widget build(BuildContext context) {
    final changeColor = ticker.change24hPct >= 0 ? AppColors.trendGreen : AppColors.trendRed;
    final fundingColor = ticker.funding8hPct >= 0 ? AppColors.trendGreen : AppColors.trendRed;
    final premiumColor = ticker.premium >= 0 ? AppColors.trendGreen : AppColors.trendRed;
    final sentiment = fundingSentiment(ticker.funding8hPct);
    final formattedChange = '${ticker.change24hPct >= 0 ? '+' : ''}${ticker.change24hPct.toStringAsFixed(2)}%';
    final formattedFunding = '${ticker.funding8hPct >= 0 ? '+' : ''}${ticker.funding8hPct.toStringAsFixed(4)}%';
    final formattedPremium = '${ticker.premium >= 0 ? '+' : ''}${(ticker.premium * 100).toStringAsFixed(4)}%';

    // Use markPx if available, else lastPrice
    final markPrice = ticker.markPx > 0 ? ticker.markPx : ticker.lastPrice;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF161A22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBright.withValues(alpha: 0.6)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ───────────────────────────────────────────
              _buildHeader(context),
              Divider(height: 1, color: AppColors.surfaceBright.withValues(alpha: 0.5)),

              // ── Section: PRICE ───────────────────────────────────
              _sectionLabel('PRICE'),
              _pad(Column(children: [
                Row(children: [
                  Expanded(child: _Cell(label: 'MARK PRICE', value: fmtPx(markPrice), valueColor: changeColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _Cell(label: 'MID PRICE', value: ticker.midPx > 0 ? fmtPx(ticker.midPx) : '—')),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _Cell(
                    label: 'ORACLE',
                    value: ticker.oraclePx > 0 ? fmtPx(ticker.oraclePx) : '—',
                    valueColor: const Color(0xFF7C83FD),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _Cell(
                    label: 'PREV DAY',
                    value: ticker.prevDayPx > 0 ? fmtPx(ticker.prevDayPx) : '—',
                    valueColor: AppColors.textSecondary,
                  )),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _Cell(label: '24H CHANGE', value: formattedChange, valueColor: changeColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _Cell(
                    label: 'PREMIUM',
                    value: ticker.premium != 0 ? formattedPremium : '—',
                    valueColor: premiumColor,
                  )),
                ]),
              ])),

              Divider(height: 1, color: AppColors.surfaceBright.withValues(alpha: 0.3)),

              // ── Section: ORDER BOOK (shown when data available) ──
              if (ticker.impactBidPx > 0 || ticker.impactAskPx > 0) ...[
                _sectionLabel('ORDER BOOK IMPACT'),
                _pad(Row(children: [
                  Expanded(child: _Cell(
                    label: 'IMPACT BID',
                    value: ticker.impactBidPx > 0 ? fmtPx(ticker.impactBidPx) : '—',
                    valueColor: AppColors.trendGreen,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _Cell(
                    label: 'IMPACT ASK',
                    value: ticker.impactAskPx > 0 ? fmtPx(ticker.impactAskPx) : '—',
                    valueColor: AppColors.trendRed,
                  )),
                ])),
                Divider(height: 1, color: AppColors.surfaceBright.withValues(alpha: 0.3)),
              ],

              // ── Section: MARKET ──────────────────────────────────
              _sectionLabel('MARKET'),
              _pad(Column(children: [
                Row(children: [
                  Expanded(child: _Cell(label: 'VOLUME 24H', value: fmtUsd(ticker.volume24hUSD))),
                  const SizedBox(width: 12),
                  Expanded(child: _Cell(
                    label: 'BASE VOLUME',
                    value: ticker.dayBaseVlm > 0 ? fmtNum(ticker.dayBaseVlm) : '—',
                  )),
                ]),

                // Market cap (spot / crypto)
                if (!_isPerp && ticker.marketCapUSD > 0) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _Cell(label: 'MARKET CAP', value: fmtUsd(ticker.marketCapUSD))),
                    const SizedBox(width: 12),
                    Expanded(child: _Cell(
                      label: 'CIRC. SUPPLY',
                      value: ticker.circulatingSupply > 0 ? fmtNum(ticker.circulatingSupply) : '—',
                    )),
                  ]),
                ],

                // Total & max supply (spot)
                if (_isSpot && ticker.totalSupply > 0) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _Cell(
                      label: 'TOTAL SUPPLY',
                      value: fmtNum(ticker.totalSupply),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _Cell(
                      label: 'MAX SUPPLY',
                      value: ticker.maxSupply > 0 ? fmtNum(ticker.maxSupply) : '∞',
                    )),
                  ]),
                ],

                // OI (perp / hip3)
                if (ticker.openInterestUSD > 0 || ticker.openInterest > 0) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _Cell(label: 'OPEN INTEREST', value: fmtUsd(ticker.openInterestUSD))),
                    const SizedBox(width: 12),
                    Expanded(child: _Cell(
                      label: 'OI (BASE)',
                      value: ticker.openInterest > 0 ? fmtNum(ticker.openInterest) : '—',
                    )),
                  ]),
                ],

                // Leverage & growth mode (perp)
                if (_isPerp || ticker.maxLeverage > 0) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _Cell(
                      label: 'MAX LEVERAGE',
                      value: ticker.maxLeverage > 0 ? '${ticker.maxLeverage}×' : '—',
                      valueColor: const Color(0xFFFFB74D),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ticker.growthMode.isNotEmpty
                          ? _GrowthModeBadge(mode: ticker.growthMode)
                          : const SizedBox.shrink(),
                    ),
                  ]),
                ],
              ])),



              Divider(height: 1, color: AppColors.surfaceBright.withValues(alpha: 0.3)),

              // ── Section: FUNDING & SENTIMENT ─────────────────────
              _sectionLabel('FUNDING & SENTIMENT'),
              _pad(Column(children: [
                Row(children: [
                  Icon(Icons.schedule, size: 13, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                  const SizedBox(width: 6),
                  Text(
                    'FUNDING RATE (8H)',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formattedFunding,
                    style: GoogleFonts.jetBrainsMono(
                      color: fundingColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 7,
                    child: Row(children: [
                      if (sentiment.longPct > 0)
                        Expanded(
                          flex: sentiment.longPct.round().clamp(1, 100),
                          child: Container(color: AppColors.trendGreen),
                        ),
                      if (sentiment.shortPct > 0)
                        Expanded(
                          flex: sentiment.shortPct.round().clamp(1, 100),
                          child: Container(color: AppColors.trendRed),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Long: ${sentiment.longPct.toStringAsFixed(1)}%',
                      style: GoogleFonts.jetBrainsMono(color: AppColors.trendGreen, fontSize: 11)),
                  Text('Short: ${sentiment.shortPct.toStringAsFixed(1)}%',
                      style: GoogleFonts.jetBrainsMono(color: AppColors.trendRed, fontSize: 11)),
                ]),
              ]), bottom: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary.withValues(alpha: 0.6),
            fontSize: 9,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _pad(Widget child, {double bottom = 12}) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
        child: child,
      );

  Widget _buildHeader(BuildContext context) {
    final title = ticker.displayName.isNotEmpty ? ticker.displayName : ticker.symbol;
    final typeLabel = ticker.marketType.toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 10, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIcon(40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (typeLabel.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _BadgeChip(
                      label: typeLabel,
                      color: typeLabel == 'SPOT'
                          ? const Color(0xFF7C83FD)
                          : typeLabel == 'PERP'
                              ? const Color(0xFFFFB74D)
                              : AppColors.textSecondary,
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Text(
                    _subtitle,
                    style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  if (ticker.isDelisted) ...[
                    const SizedBox(width: 6),
                    _BadgeChip(label: 'DELISTED', color: AppColors.trendRed),
                  ],
                ]),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(double size) {
    if (ticker.iconUrl.isEmpty) return _iconPlaceholder(size);
    final isSvg = ticker.iconUrl.toLowerCase().contains('.svg');
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.surfaceBright, shape: BoxShape.circle),
      child: ClipOval(
        child: isSvg
            ? SvgPicture.network(
                ticker.iconUrl,
                fit: BoxFit.cover,
                placeholderBuilder: (_) => _iconPlaceholder(size),
                errorBuilder: (_, __, e) => _iconPlaceholder(size),
              )
            : Image.network(
                ticker.iconUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, e) => _iconPlaceholder(size),
              ),
      ),
    );
  }

  Widget _iconPlaceholder(double size) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: AppColors.surfaceBright, shape: BoxShape.circle),
        child: Icon(Icons.image_outlined, size: size * 0.5, color: AppColors.textSecondary),
      );
}

// ── Sub-widgets ─────────────────────────────────────────────────────

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Cell({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: 9,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _GrowthModeBadge extends StatelessWidget {
  final String mode;
  const _GrowthModeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    final isEnabled = mode.toLowerCase() == 'enabled';
    final color = isEnabled ? const Color(0xFF7C83FD) : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GROWTH MODE',
            style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary, fontSize: 9, letterSpacing: 0.8)),
        const SizedBox(height: 5),
        Row(children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            mode.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(color: color, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ]),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;
  const _BadgeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(color: color, fontSize: 8, letterSpacing: 0.5),
      ),
    );
  }
}

class _TokenRow extends StatelessWidget {
  final String label;
  final String value;
  const _TokenRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary, fontSize: 9, letterSpacing: 0.8)),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textPrimary.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
