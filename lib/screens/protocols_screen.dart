import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../viewmodels/protocol_viewmodel.dart';
import '../models/protocol_model.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/error_state_widget.dart';
import 'protocol_detail_screen.dart';

class ProtocolsScreen extends StatefulWidget {
  const ProtocolsScreen({super.key});

  @override
  State<ProtocolsScreen> createState() => _ProtocolsScreenState();
}

class _ProtocolsScreenState extends State<ProtocolsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProtocolViewModel>().fetchProtocols();
    });
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    final vm = context.watch<ProtocolViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(res),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterBar(vm, res),
          Expanded(
            child: _buildBody(vm, res),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Responsive res) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Protocol TVL Analytics',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: res.fontSize(18),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Explore Total Value Locked across the ecosystem',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: res.fontSize(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ProtocolViewModel vm, Responsive res) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: res.spacing(16), vertical: res.spacing(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildDropdownPill<int>(
              value: vm.limit,
              icon: Icons.list_alt_rounded,
              prefix: 'Top',
              options: [20, 50, 100],
              onChanged: (val) => vm.setLimit(val ?? 20),
              res: res,
            ),
            SizedBox(width: res.spacing(10)),
            _buildFilterPill(
              label: 'Highest TVL',
              icon: Icons.swap_vert_rounded,
              res: res,
              onTap: () {}, // Default sort is already highest TVL
            ),
            SizedBox(width: res.spacing(10)),
            _buildDropdownPill<String>(
              value: vm.selectedCategory,
              icon: Icons.filter_alt_outlined,
              options: vm.categories,
              onChanged: (val) => vm.setCategory(val ?? 'All Categories'),
              res: res,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownPill<T>({
    required T value,
    required IconData icon,
    String? prefix,
    required List<T> options,
    required ValueChanged<T?> onChanged,
    required Responsive res,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBright.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brandAccent),
          const SizedBox(width: 8),
          DropdownButton<T>(
            value: value,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textSecondary),
            dropdownColor: AppColors.surfaceBright,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white, 
              fontSize: 11, 
              fontWeight: FontWeight.bold
            ),
            items: options.map((opt) {
              return DropdownMenuItem<T>(
                value: opt,
                child: Text(prefix != null ? '$prefix $opt' : opt.toString()),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required IconData icon,
    required Responsive res,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceBright.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceBright.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.brandAccent),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ProtocolViewModel vm, Responsive res) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brandAccent));
    }

    if (vm.errorMessage.isNotEmpty) {
      return ErrorStateWidget(
        errorMessage: vm.errorMessage,
        onRetry: () => vm.fetchProtocols(),
      );
    }

    if (vm.protocols.isEmpty) {
      return Center(
        child: Text(
          'No protocols found',
          style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 4 : screenWidth > 800 ? 3 : 2;

    return GridView.builder(
      padding: EdgeInsets.all(res.spacing(16)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: res.spacing(16),
        mainAxisSpacing: res.spacing(16),
        childAspectRatio: 1.1,
      ),
      itemCount: vm.protocols.length,
      itemBuilder: (context, index) {
        final p = vm.protocols[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProtocolDetailScreen(
                  slug: p.slug,
                  name: p.name,
                  logo: p.logo,
                ),
              ),
            );
          },
          child: _ProtocolCard(protocol: p),
        );
      },
    );
  }
}

class _ProtocolCard extends StatelessWidget {
  final Protocol protocol;

  const _ProtocolCard({required this.protocol});

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);

    return Container(
      padding: EdgeInsets.all(res.spacing(14)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBright.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.03),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  protocol.logo,
                  width: 32,
                  height: 32,
                  errorBuilder: (_, __, ___) => Container(
                    width: 32,
                    height: 32,
                    color: AppColors.surfaceBright,
                    child: const Icon(Icons.token, size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      protocol.name,
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: res.fontSize(12),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.brandAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        protocol.category,
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.brandAccent,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (protocol.type == 'core')
                const Icon(Icons.verified, size: 16, color: AppColors.brandAccent),
            ],
          ),
          const Spacer(),
          Text(
            'TOTAL VALUE LOCKED',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: 8,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            protocol.fullTvl,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: res.fontSize(16),
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rank #${protocol.rank}',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                ),
              ),
              Text(
                'Details →',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.brandAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
