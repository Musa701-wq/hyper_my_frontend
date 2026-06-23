import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/ticker_model.dart';
import '../utils/app_colors.dart';
import '../utils/ticker_formatters.dart';
import 'funding_legend_dialog.dart';

class TickerInfoTab extends StatelessWidget {
  final TickerModel ticker;

  const TickerInfoTab({super.key, required this.ticker});

  bool get _isSpot => ticker.marketType == 'spot';
  bool get _isPerp => ticker.marketType == 'perp';

  @override
  Widget build(BuildContext context) {
    final changeColor = ticker.change24hPct >= 0 ? AppColors.trendGreen : AppColors.trendRed;
    final fundingColor = ticker.funding8hPct >= 0 ? AppColors.trendGreen : AppColors.trendRed;
    final premiumColor = ticker.premium >= 0 ? AppColors.trendGreen : AppColors.trendRed;
    final sentiment = fundingSentiment(ticker.funding8hPct);
    final formattedChange = '${ticker.change24hPct >= 0 ? '+' : ''}${ticker.change24hPct.toStringAsFixed(2)}%';
    final formattedFunding = '${ticker.funding8hPct >= 0 ? '+' : ''}${ticker.funding8hPct.toStringAsFixed(4)}%';
    final formattedPremium = '${ticker.premium >= 0 ? '+' : ''}${(ticker.premium * 100).toStringAsFixed(4)}%';
    final markPrice = ticker.markPx > 0 ? ticker.markPx : ticker.lastPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        Divider(height: 1, color: AppColors.surfaceBright.withOpacity(0.3)),
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
          Divider(height: 1, color: AppColors.surfaceBright.withOpacity(0.3)),
        ],
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
          if (_isSpot && ticker.totalSupply > 0) ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _Cell(label: 'TOTAL SUPPLY', value: fmtNum(ticker.totalSupply))),
              const SizedBox(width: 12),
              Expanded(child: _Cell(
                label: 'MAX SUPPLY',
                value: ticker.maxSupply > 0 ? fmtNum(ticker.maxSupply) : '∞',
              )),
            ]),
          ],
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
          if (_isPerp && ticker.maxLeverage > 0) ...[

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
        Divider(height: 1, color: AppColors.surfaceBright.withOpacity(0.3)),
        _sectionLabel('FUNDING & SENTIMENT'),
        _pad(Column(children: [
          Row(children: [
            Icon(Icons.schedule, size: 13, color: AppColors.textSecondary.withOpacity(0.8)),
            const SizedBox(width: 6),
            Text(
              'FUNDING RATE (8H)',
              style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 0.5),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => showDialog(context: context, builder: (context) => const FundingLegendDialog()),
              child: Icon(Icons.info_outline, size: 11, color: AppColors.textSecondary.withOpacity(0.8)),
            ),
            const Spacer(),
            Text(
              formattedFunding,
              style: GoogleFonts.jetBrainsMono(color: fundingColor, fontSize: 14, fontWeight: FontWeight.bold),
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
        ]), bottom: 16),
      ],
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary.withOpacity(0.6),
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
}

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
        Text(label,
            style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 9, letterSpacing: 0.8)),
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
            style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 9, letterSpacing: 0.8)),
        const SizedBox(height: 5),
        Row(children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(mode.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
      ],
    );
  }
}
