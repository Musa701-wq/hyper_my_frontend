import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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
        _buildSectionCard(
          title: 'PRICE',
          child: Column(children: [
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
          ]),
        ),
        if (ticker.impactBidPx > 0 || ticker.impactAskPx > 0)
          _buildSectionCard(
            title: 'ORDER BOOK IMPACT',
            child: Row(children: [
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
            ]),
          ),
        _buildSectionCard(
          title: 'MARKET',
          child: Column(children: [
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
            if (_isPerp && (ticker.openInterestUSD > 0 || ticker.openInterest > 0)) ...[
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
          ]),
        ),
        if (_isSpot)
          _buildSectionCard(
            title: 'TOKEN INFO',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _infoRow(
                  context,
                  label: 'Canonical',
                  valueWidget: _buildCanonicalBadge(ticker.isCanonical ?? false),
                ),
                if (ticker.tokenId.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _infoRow(
                    context,
                    label: 'Token ID',
                    value: ticker.tokenId,
                    isAddress: true,
                  ),
                ],
                if (ticker.szDecimals != null) ...[
                  const SizedBox(height: 10),
                  _infoRow(
                    context,
                    label: 'Size Decimals',
                    value: ticker.szDecimals.toString(),
                  ),
                ],
                if (ticker.weiDecimals != null) ...[
                  const SizedBox(height: 10),
                  _infoRow(
                    context,
                    label: 'Wei Decimals',
                    value: ticker.weiDecimals.toString(),
                  ),
                ],
                if (ticker.evmContract != null && ticker.evmContract!.address.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _infoRow(
                    context,
                    label: 'EVM Contract',
                    value: ticker.evmContract!.address,
                    isAddress: true,
                    url: 'https://arbiscan.io/token/${ticker.evmContract!.address}',
                  ),
                ],
                if (ticker.deployerTradingFeeShare != null && ticker.deployerTradingFeeShare!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _infoRow(
                    context,
                    label: 'Deployer Fee Share',
                    value: () {
                      final feeShare = double.tryParse(ticker.deployerTradingFeeShare!);
                      return feeShare != null
                          ? '${(feeShare * 100).toStringAsFixed(1)}%'
                          : ticker.deployerTradingFeeShare!;
                    }(),
                  ),
                ],
              ],
            ),
          ),
        if (_isPerp)
          _buildSectionCard(
            title: 'FUNDING & SENTIMENT',
            child: Column(children: [
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Long: ${sentiment.longPct.toStringAsFixed(1)}%',
                  style: GoogleFonts.jetBrainsMono(color: AppColors.trendGreen, fontSize: 11)),
              Text('Short: ${sentiment.shortPct.toStringAsFixed(1)}%',
                  style: GoogleFonts.jetBrainsMono(color: AppColors.trendRed, fontSize: 11)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF060708),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF161A22), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.brandAccent,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary.withOpacity(0.8),
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required String label,
    String? value,
    Widget? valueWidget,
    bool isAddress = false,
    String? url,
  }) {
    Widget displayWidget;

    if (valueWidget != null) {
      displayWidget = valueWidget;
    } else if (value != null) {
      if (isAddress) {
        final shortAddress = value.length > 20
            ? '${value.substring(0, 8)}…${value.substring(value.length - 6)}'
            : value;

        final textWidget = GestureDetector(
          onTap: url != null
              ? () async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              : null,
          child: Text(
            shortAddress,
            style: GoogleFonts.jetBrainsMono(
              color: url != null ? const Color(0xFF60A5FA) : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              decoration: url != null ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
        );

        displayWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: textWidget),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF161A22),
                    duration: const Duration(seconds: 2),
                    content: Text(
                      '$label copied to clipboard!',
                      style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12),
                    ),
                  ),
                );
              },
              child: const Icon(
                Icons.copy,
                size: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      } else {
        displayWidget = Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    } else {
      displayWidget = const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(child: displayWidget),
      ],
    );
  }

  Widget _buildCanonicalBadge(bool isCanonical) {
    if (isCanonical) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2D2A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF0D9488), width: 0.5),
        ),
        child: Text(
          'Official',
          style: GoogleFonts.jetBrainsMono(
            color: const Color(0xFF5EEAD4),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF2C1E0A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD97706), width: 0.5),
        ),
        child: Text(
          'Community',
          style: GoogleFonts.jetBrainsMono(
            color: const Color(0xFFFBBF24),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
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
