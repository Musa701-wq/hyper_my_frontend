import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import '../utils/app_colors.dart';
import '../viewmodels/subscription_viewmodel.dart';
import '../utils/responsive.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchExternalLink(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<SubscriptionViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isPro) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
               if (context.mounted) Navigator.pop(context);
            });
          }

          return Stack(
            children: [
              // Dynamic Background Glow
              _buildBackgroundGlow(res),
              
              // Custom Background Lines
              _buildBackgroundLines(res),

              CustomScrollView(
                slivers: [
                  _buildSliverAppBar(context),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: res.horizontalPadding(24.0),
                        vertical: 24.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildHeader(res),
                          const SizedBox(height: 24),
                          
                          if (viewModel.errorMessage != null)
                            _buildErrorState(viewModel, res),
                          
                          if (viewModel.products.isEmpty && !viewModel.isProcessing && viewModel.errorMessage == null)
                            _buildEmptyState(res),

                          ...viewModel.products.map((product) => _buildPlanCard(context, viewModel, product, res)),
                          
                          const SizedBox(height: 16),
                          _buildFeatureSection(res),
                          
                          const SizedBox(height: 32),
                          _buildFAQSection(res),
                          
                          const SizedBox(height: 16),
                          _buildFooter(viewModel, res),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (viewModel.isProcessing)
                _buildProcessingOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackgroundGlow(Responsive res) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -res.height * 0.15 + (40 * _controller.value),
              right: -res.width * 0.15 + (40 * (1 - _controller.value)),
              child: Container(
                width: res.width * 0.7,
                height: res.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.brandAccent.withValues(alpha: 0.08),
                      AppColors.brandAccent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBackgroundLines(Responsive res) {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.03,
        child: CustomPaint(
          painter: _GridPainter(),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      pinned: true,
      expandedHeight: 0,
    );
  }

  Widget _buildHeader(Responsive res) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF161A22),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.brandAccent.withValues(alpha: 0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandAccent.withValues(alpha: 0.2),
                blurRadius: 30,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/buy.gif',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'HYPERSCREENER PRO',
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: res.fontSize(32),
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 2,
          width: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.brandAccent.withValues(alpha: 0),
                AppColors.brandAccent,
                AppColors.brandAccent.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'The ultimate trading ammunition for serious players.',
          textAlign: TextAlign.center,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: res.fontSize(14),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionViewModel viewModel, ProductDetails product, Responsive res) {
    final bool isMonthly = product.id.contains('premiummonthly');

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF161A22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMonthly ? AppColors.brandAccent : const Color(0xFF2E323D),
          width: isMonthly ? 2 : 1,
        ),
        boxShadow: isMonthly ? [
          BoxShadow(
            color: AppColors.brandAccent.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          )
        ] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => viewModel.subscribe(product),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMonthly)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.brandAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'MOST POPULAR',
                              style: GoogleFonts.jetBrainsMono(
                                color: Colors.black,
                                fontSize: res.fontSize(9),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        Text(
                          product.title.split('(').first.trim().toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white,
                            fontSize: res.fontSize(20),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            fontSize: res.fontSize(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.price,
                        style: GoogleFonts.jetBrainsMono(
                          color: isMonthly ? AppColors.brandAccent : Colors.white,
                          fontSize: res.fontSize(24),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        isMonthly ? 'BILL YEARLY' : 'BILL WEEKLY',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                          fontSize: res.fontSize(10),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureSection(Responsive res) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF161A22).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2E323D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UNLOCKED ASSETS',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.brandAccent.withValues(alpha: 0.6),
                  fontSize: res.fontSize(11),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              _FeatureItem(res: res, text: 'Giga-Depth Orderbook Visuals'),
              _FeatureItem(res: res, text: 'Institutional-Grade Heatmaps'),
              _FeatureItem(res: res, text: 'Real-time Whale Inflow Alerts'),
              _FeatureItem(res: res, text: 'Cumulative Volume Delta (CVD)'),
              _FeatureItem(res: res, text: 'Priority Node Access'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection(Responsive res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 20),
          child: Text(
            'FREQUENTLY ASKED QUESTIONS',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textPrimary,
              fontSize: res.fontSize(14),
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        _buildFAQItem(
          res,
          question: 'What is HyperView Pro?',
          answer: 'HyperView Pro provides institutional-grade trading tools, including giga-depth orderbook visuals, real-time whale inflow alerts, and advanced CVD analytics.',
        ),
        _buildFAQItem(
          res,
          question: 'How accurate is the data?',
          answer: 'Our data is synchronized directly with exchange nodes, ensuring sub-millisecond precision for leaderboard rankings and live trade matching.',
        ),
        _buildFAQItem(
          res,
          question: 'Can I cancel my subscription?',
          answer: 'Yes, subscriptions are managed through your official App Store or Play Store account and can be terminated at any time.',
        ),
        _buildFAQItem(
          res,
          question: 'Are future features included?',
          answer: 'Absolutely. Your Pro subscription includes all upcoming releases, including HIP-3 asset support and priority node access.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(Responsive res, {required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161A22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E323D)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          childrenPadding: EdgeInsets.zero,
          iconColor: AppColors.brandAccent,
          collapsedIconColor: AppColors.textSecondary,
          title: Text(
            question,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: res.fontSize(12),
              fontWeight: FontWeight.bold,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary,
                  fontSize: res.fontSize(11),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(SubscriptionViewModel viewModel, Responsive res) {
    return Column(
      children: [
        _buildRestoreButton(viewModel, res),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                fontSize: 10,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: "By continuing, you agree to our "),
                TextSpan(
                  text: "Terms of Use",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandAccent,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _launchExternalLink('https://vectorlabzlimited.com/terms-of-use/'),
                ),
                const TextSpan(text: " and "),
                TextSpan(
                  text: "Privacy Policy",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandAccent,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _launchExternalLink('https://vectorlabzlimited.com/privacy-policy/'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Protected by Hyper Protocol. All transactions are encrypted. Subscriptions auto-renew unless terminated 24h prior to expiration.',
          textAlign: TextAlign.center,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            fontSize: res.fontSize(9),
            height: 1.8,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          color: AppColors.textSecondary.withValues(alpha: 0.6),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildRestoreButton(SubscriptionViewModel viewModel, Responsive res) {
    return InkWell(
      onTap: () => viewModel.restorePurchases(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'RESTORE PREVIOUS ACCESS',
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: res.fontSize(11),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.brandAccent),
            const SizedBox(height: 24),
            Text(
              'ENCRYPTING TRANSACTION...',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.brandAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(SubscriptionViewModel viewModel, Responsive res) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.trendRed.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.trendRed.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.trendRed, size: 32),
          const SizedBox(height: 16),
          Text(
            viewModel.errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.trendRed,
              fontSize: res.fontSize(12),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => viewModel.loadProducts(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.trendRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('RETRY UPLINK', style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(Responsive res) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF2A2E39))),
          const SizedBox(height: 32),
          Text(
            'SYNCHRONIZING SECURE TUNNEL...',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              fontSize: res.fontSize(12),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _FeatureItem extends StatelessWidget {
  final Responsive res;
  final String text;

  const _FeatureItem({required this.res, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.brandAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.add_task_rounded, color: AppColors.brandAccent, size: 14),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: res.fontSize(13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
