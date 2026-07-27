import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'responsive.dart';

class DotGridPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;

  DotGridPainter({required this.dotColor, this.spacing = 30.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PulseDot extends StatefulWidget {
  final Color color;
  const PulseDot({super.key, this.color = AppColors.trendGreen});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(_a.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_a.value * 0.5),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base colorful shadow/glow
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background, // Base solid background
              gradient: RadialGradient(
                center: const Alignment(0, 1.0), // Start from bottom center
                radius: 0.8, // Make it subtle and stay in the lower half
                colors: [
                  AppColors.brandAccent.withOpacity(0.1), // Greenish glow
                  AppColors.background.withOpacity(0.0), // Fade out
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
        // Dot Grid Pattern
        Positioned.fill(
          child: CustomPaint(
            painter: DotGridPainter(
              dotColor: AppColors.surfaceBright.withOpacity(0.5),
              spacing: 35.0,
            ),
          ),
        ),
        // The actual foreground content
        child,
      ],
    );
  }
}

// ─── Section label ─────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        color: AppColors.textSecondary.withOpacity(0.5),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.0,
      ),
    );
  }
}

// ─── Generic card container matching profile style ─────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.15),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: child,
    );
  }
}

// ─── Stat card matching Profile screen design ──────────────────
class StatCardWidget extends StatelessWidget {
  final String label;
  final String value;
  final String? badge;
  final bool badgeUp;
  final bool showBadge;
  final Color? accentColor;

  const StatCardWidget({
    super.key,
    required this.label,
    required this.value,
    this.badge,
    this.badgeUp = true,
    this.showBadge = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    final accent = accentColor ?? AppColors.brandAccent;

    return Container(
      padding: EdgeInsets.all(res.spacing(12)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              if (showBadge && badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeUp ? AppColors.brandAccent : AppColors.lossRed).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.jetBrainsMono(
                      color: badgeUp ? AppColors.brandAccent : AppColors.lossRed,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: res.fontSize(18),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 14,
                height: 2,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Pagination Bar matching Home Screen style ───────
class AppPaginationBar extends StatelessWidget {
  final int currentPage;
  final int itemsPerPage;
  final int totalItems;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onItemsPerPageChanged;
  final List<int> itemsPerPageOptions;

  const AppPaginationBar({
    super.key,
    required this.currentPage,
    required this.itemsPerPage,
    required this.totalItems,
    required this.onPageChanged,
    required this.onItemsPerPageChanged,
    this.itemsPerPageOptions = const [10, 20, 50, 100],
  });

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    final totalPages = (totalItems / itemsPerPage).ceil();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: res.spacing(16), vertical: res.spacing(10)),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Rows:',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary,
                fontSize: res.fontSize(12),
              ),
            ),
            const SizedBox(width: 8),
            Theme(
              data: Theme.of(context).copyWith(canvasColor: AppColors.background),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: AppColors.surfaceBright),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    dropdownColor: AppColors.background,
                    value: itemsPerPage,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 16),
                    style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: res.fontSize(12)),
                    borderRadius: BorderRadius.circular(8),
                    elevation: 8,
                    onChanged: (val) => val != null ? onItemsPerPageChanged(val) : null,
                    items: itemsPerPageOptions.map((v) => DropdownMenuItem(value: v, child: Text(v.toString()))).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            _buildPageButton(
              res,
              icon: Icons.chevron_left,
              isEnabled: currentPage > 1,
              isActive: false,
              onTap: () => onPageChanged(currentPage - 1),
            ),
            const SizedBox(width: 8),
            ...() {
              if (totalPages <= 1) {
                return [
                  _buildPageButton(
                    res,
                    text: '1',
                    isActive: true,
                    onTap: () {},
                  )
                ];
              }
              List<Widget> buttons = [];
              int start = (currentPage - 1).clamp(1, totalPages);
              int end = (start + 2).clamp(1, totalPages);
              if (end == totalPages && totalPages > 3) start = end - 2;
              for (int i = start; i <= end; i++) {
                buttons.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildPageButton(
                      res,
                      text: i.toString(),
                      isActive: i == currentPage,
                      onTap: () => onPageChanged(i),
                    ),
                  ),
                );
              }
              return buttons;
            }(),
            const SizedBox(width: 8),
            _buildPageButton(
              res,
              icon: Icons.chevron_right,
              isEnabled: (currentPage * itemsPerPage < totalItems),
              isActive: false,
              onTap: () => onPageChanged(currentPage + 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageButton(
    Responsive res, {
    String? text,
    IconData? icon,
    VoidCallback? onTap,
    required bool isActive,
    bool isEnabled = true,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: res.spacing(32),
        height: res.spacing(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandAccent : AppColors.background,
          border: Border.all(color: isActive ? AppColors.brandAccent : AppColors.surfaceBright),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.4,
          child: text != null
              ? Text(
                  text,
                  style: GoogleFonts.jetBrainsMono(
                    color: isActive ? Colors.black : AppColors.textPrimary,
                    fontSize: res.fontSize(12),
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                )
              : Icon(
                  icon,
                  size: res.fontSize(16),
                  color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                ),
        ),
      ),
    );
  }
}
