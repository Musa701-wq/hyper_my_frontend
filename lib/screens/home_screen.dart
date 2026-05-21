import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/common_widgets.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/coming_soon_dialog.dart';
import '../widgets/error_state_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.menu, color: AppColors.brandAccent),
        title: Text(
          'HYPERLIQUID',
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.brandAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          const Icon(Icons.sensors, color: AppColors.brandAccent),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => showDialog(context: context, builder: (context) => const ComingSoonDialog(featureName: 'Wallet Connection')),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.brandAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.brandAccent, width: 1),
              ),
              child: Center(
                child: Text(
                  'CONNECT',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.brandAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leaderboard',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border.all(color: AppColors.surfaceBright),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (val) => viewModel.setSearchQuery(val),
                            style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Search by wallet address or symbol...',
                              hintStyle: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tabs
                  Container(
                    height: 38,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surfaceBright),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTab(viewModel, 'HIP'),
                        _buildTab(viewModel, 'PERPS'),
                        _buildTab(viewModel, 'SPOT'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (viewModel.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(child: CircularProgressIndicator(color: AppColors.brandAccent)),
                    )
                  else if (viewModel.errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: ErrorStateWidget(
                        errorMessage: viewModel.errorMessage,
                        onRetry: () => viewModel.fetchTickers(),
                      ),
                    )
                  else ...[
                    // Filters Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            border: Border.all(color: AppColors.surfaceBright),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              dropdownColor: AppColors.background,
                              value: viewModel.selectedDex,
                            style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 12),
                            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 18),
                            onChanged: (String? newValue) {
                              if (newValue != null) viewModel.setSelectedDex(newValue);
                            },
                            items: viewModel.availableDexes.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value == 'All' ? 'ALL' : value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text('USDC', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => showDialog(context: context, builder: (context) => const ComingSoonDialog(featureName: 'TOTAL Filter')),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.brandAccent),
                            borderRadius: BorderRadius.circular(4),
                            color: AppColors.brandAccent.withValues(alpha: 0.1),
                          ),
                          child: Text('TOTAL', style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fixed Left Column (Symbol)
                      SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Symbol', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11))
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Data Rows
                            ...viewModel.paginatedTickers.map((ticker) {
                              return Container(
                                height: 56,
                                padding: const EdgeInsets.only(left: 8.0, right: 4.0, top: 12.0, bottom: 12.0),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_border, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            ticker.displayName.split(':').last,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AppColors.brandAccent.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                            child: Text(ticker.dex.toUpperCase(), style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: 8)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      // Scrollable Right Section
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                    SizedBox(width: 100, child: Align(alignment: Alignment.centerLeft, child: Text('Last Price', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11)))),
                                    SizedBox(width: 140, child: Align(alignment: Alignment.centerLeft, child: Text('24h Change', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11)))),
                                    SizedBox(width: 100, child: Align(alignment: Alignment.centerLeft, child: Text('8h Funding', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11)))),
                                    SizedBox(width: 120, child: Align(alignment: Alignment.centerLeft, child: Text('Volume', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11)))),
                                    SizedBox(width: 140, child: Align(alignment: Alignment.centerLeft, child: Text('Open Interest', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11)))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Data Rows
                              ...viewModel.paginatedTickers.map((ticker) {
                                final formattedVol = '\$${(ticker.volume24hUSD).toStringAsFixed(0)}'.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
                                final oldPrice = ticker.lastPrice / (1 + (ticker.change24hPct / 100));
                                final pointChange = ticker.lastPrice - oldPrice;
                                final pointChangeStr = pointChange >= 0 ? '+${pointChange.toStringAsFixed(3)}' : pointChange.toStringAsFixed(3);
                                final pctChangeStr = '${ticker.change24hPct >= 0 ? '+' : ''}${ticker.change24hPct.toStringAsFixed(2)}%';
                                final formattedChange = '$pointChangeStr / $pctChangeStr';
                                final formattedFunding = '${ticker.funding8hPct.toStringAsFixed(4)}%';
                                final formattedOI = '\$${(ticker.openInterestUSD).toStringAsFixed(0)}'.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
                                final changeColor = ticker.change24hPct >= 0 ? AppColors.brandAccent : AppColors.lossRed;

                                return Container(
                                  height: 56,
                                  width: 616, // Content (600) + Padding (16)
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                                  decoration: const BoxDecoration(
                                    border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 100, child: Text(ticker.lastPrice.toStringAsFixed(4), style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold))),
                                      SizedBox(width: 140, child: Text(formattedChange, style: GoogleFonts.jetBrainsMono(color: changeColor, fontSize: 11))),
                                      SizedBox(width: 100, child: Text(formattedFunding, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11))),
                                      SizedBox(width: 120, child: Text(formattedVol, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11))),
                                      SizedBox(width: 140, child: Text(formattedOI, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11))),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  // Pagination Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Rows per page:', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.surfaceBright),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            dropdownColor: AppColors.background,
                            value: viewModel.rowsPerPage,
                            icon: const Padding(
                              padding: EdgeInsets.only(left: 4.0),
                              child: Icon(Icons.keyboard_arrow_down, color: AppColors.textPrimary, size: 16),
                            ),
                            style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 12),
                            onChanged: (int? newValue) {
                              if (newValue != null) viewModel.setRowsPerPage(newValue);
                            },
                            items: [10, 20, 50].map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString()),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left, color: viewModel.currentPage > 1 ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.5)),
                        onPressed: viewModel.currentPage > 1 ? () => viewModel.previousPage() : null,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${viewModel.totalFilteredCount == 0 ? 0 : (viewModel.currentPage - 1) * viewModel.rowsPerPage + 1}-${(viewModel.currentPage * viewModel.rowsPerPage > viewModel.totalFilteredCount) ? viewModel.totalFilteredCount : viewModel.currentPage * viewModel.rowsPerPage} of ${viewModel.totalFilteredCount}', 
                        style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 14)
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(Icons.chevron_right, color: (viewModel.currentPage * viewModel.rowsPerPage < viewModel.totalFilteredCount) ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.5)),
                        onPressed: (viewModel.currentPage * viewModel.rowsPerPage < viewModel.totalFilteredCount) ? () => viewModel.nextPage() : null,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border: Border.all(color: AppColors.surfaceBright),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.brandAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('MAINNET ONLINE', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                    ],
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.surfaceBright, width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppColors.background.withValues(alpha: 0.85),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.brandAccent,
          unselectedItemColor: AppColors.textSecondary,
          unselectedLabelStyle: GoogleFonts.jetBrainsMono(fontSize: 10),
          selectedLabelStyle: GoogleFonts.jetBrainsMono(fontSize: 10),
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            if (index != 0) {
              showDialog(context: context, builder: (context) => const ComingSoonDialog(featureName: 'Navigation'));
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Markets'),
            BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Trade'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Portfolio'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    ));
  }

  Widget _buildTab(HomeViewModel viewModel, String title) {
    bool isActive = viewModel.selectedTab == title;
    return GestureDetector(
      onTap: () => viewModel.setTab(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceBright : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: GoogleFonts.jetBrainsMono(
            color: isActive ? AppColors.brandAccent : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
