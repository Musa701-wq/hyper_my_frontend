import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class PaywallWidget extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onUpgrade;

  const PaywallWidget({
    super.key,
    required this.title,
    required this.description,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Content Blur
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
            ),
          ),
        ),
        
        // Premium HUD Overlay
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLockIcon(),
                const SizedBox(height: 24),
                Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: AppColors.brandAccent.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 200,
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildUpgradeButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.brandAccent.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.brandAccent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandAccent.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Image.asset(
          'assets/shield.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildUpgradeButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandAccent.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onUpgrade,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandAccent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'ACTIVATE PRO ACCESS',
          style: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
