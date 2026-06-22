import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../viewmodels/wallet_viewmodel.dart';
import '../viewmodels/portfolio_viewmodel.dart';

class AccountManagementSheet extends StatelessWidget {
  final VoidCallback onAddAccount;

  const AccountManagementSheet({super.key, required this.onAddAccount});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletViewModel>();
    final accounts = wallet.accounts;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF16191E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Accounts',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (accounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No accounts added yet.',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: accounts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final acc = accounts[index];
                  final isSelected = wallet.address == acc.address;

                  return GestureDetector(
                    onTap: () {
                      wallet.selectAccount(acc.address);
                      context.read<PortfolioViewModel>().initializePortfolio(acc.address);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandAccent.withOpacity(0.1)
                            : AppColors.surfaceBright.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandAccent
                              : AppColors.surfaceBright.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.brandAccent
                                  : AppColors.textSecondary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              size: 18,
                              color: isSelected ? Colors.black : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  acc.name,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  acc.shortAddress,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: AppColors.brandAccent, size: 20),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.trendRed, size: 20),
                            onPressed: () {
                              _showDeleteConfirmation(context, wallet, acc);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onAddAccount();
              },
              icon: const Icon(Icons.add, color: Colors.black),
              label: Text(
                'ADD ACCOUNT',
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WalletViewModel wallet, SavedAccount account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16191E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.surfaceBright.withOpacity(0.5)),
        ),
        title: Text('Remove Account',
            style: GoogleFonts.jetBrainsMono(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account:',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceBright.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name, style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(account.address, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 9)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Remove this account from your list?',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await wallet.removeAccount(account.address);
            },
            child: Text('Remove',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.trendRed,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
