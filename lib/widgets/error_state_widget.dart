import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class ErrorStateWidget extends StatefulWidget {
  final String errorMessage;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.errorMessage,
    this.onRetry,
  });

  @override
  State<ErrorStateWidget> createState() => _ErrorStateWidgetState();
}

class _ErrorStateWidgetState extends State<ErrorStateWidget> {
  bool _showRawDetails = false;

  String _parseTitle(String raw) {
    if (raw.isEmpty) return 'CONNECTION FAILED';
    final lower = raw.toLowerCase();
    
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('handshakeexception') ||
        lower.contains('connection timed out') ||
        lower.contains('connection refused') ||
        lower.contains('clientexception') ||
        lower.contains('offline') ||
        lower.contains('no internet')) {
      return 'CONNECTION FAILED';
    }

    if (lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504') ||
        lower.contains('internal server error') ||
        lower.contains('bad gateway') ||
        lower.contains('service unavailable') ||
        lower.contains('gateway timeout') ||
        lower.contains('server error')) {
      return 'SERVER ERROR';
    }

    return 'LOAD ERROR';
  }

  IconData _parseIcon(String raw) {
    if (raw.isEmpty) return Icons.wifi_off_rounded;
    final lower = raw.toLowerCase();

    if (lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504') ||
        lower.contains('internal server error') ||
        lower.contains('bad gateway') ||
        lower.contains('service unavailable') ||
        lower.contains('gateway timeout') ||
        lower.contains('server error')) {
      return Icons.dns_rounded;
    }

    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('handshakeexception') ||
        lower.contains('connection timed out') ||
        lower.contains('connection refused') ||
        lower.contains('clientexception') ||
        lower.contains('offline') ||
        lower.contains('no internet')) {
      return Icons.wifi_off_rounded;
    }

    return Icons.error_outline_rounded;
  }

  String _parseError(String raw) {
    if (raw.isEmpty) {
      return 'We encountered a problem connecting to the server. Please check your internet connection or try again later.';
    }
    final lower = raw.toLowerCase();
    
    // 1. Connection / Internet Issues
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('handshakeexception') ||
        lower.contains('connection timed out') ||
        lower.contains('connection refused') ||
        lower.contains('clientexception') ||
        lower.contains('offline') ||
        lower.contains('no internet')) {
      return 'No Internet Connection. Please check your cellular data or Wi-Fi network and try again.';
    }

    // 2. Server Down / Resource issues
    if (lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504') ||
        lower.contains('internal server error') ||
        lower.contains('bad gateway') ||
        lower.contains('service unavailable') ||
        lower.contains('gateway timeout') ||
        lower.contains('server error')) {
      return 'Server is busy or undergoing maintenance. We are working to resolve this as quickly as possible. Please try again shortly.';
    }

    // 3. Resource Not Found / Formatting issues
    if (lower.contains('404') || 
        lower.contains('not found') ||
        lower.contains('formatexception')) {
      return 'Data loading error. The requested resource could not be found or processed correctly.';
    }

    // 4. Default user friendly fallback
    return 'We encountered an unexpected error while fetching data. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final title = _parseTitle(widget.errorMessage);
    final iconData = _parseIcon(widget.errorMessage);
    final userMessage = _parseError(widget.errorMessage);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.lossRed.withOpacity(0.15),
            width: 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lossRed.withOpacity(0.08),
              AppColors.background,
              AppColors.background,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              userMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: widget.onRetry,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBright,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.brandAccent.withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandAccent.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'RETRY CONNECTION',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.brandAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
