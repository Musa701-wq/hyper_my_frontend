import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class ComingSoonDialog extends StatelessWidget {
  final String featureName;

  const ComingSoonDialog({super.key, this.featureName = 'This feature'});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.surfaceBright),
      ),
      title: Text(
        'Coming Soon',
        style: GoogleFonts.jetBrainsMono(
          color: AppColors.brandAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        '$featureName is currently under development and will be available soon.',
        style: GoogleFonts.jetBrainsMono(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'CLOSE',
            style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent),
          ),
        ),
      ],
    );
  }
}
