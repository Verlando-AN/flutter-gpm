import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants/app_colors.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceDark,
      highlightColor: Colors.white12,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class TicketShimmerCard extends StatelessWidget {
  const TicketShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerLoading(width: 60, height: 24, borderRadius: 8),
              const ShimmerLoading(width: 80, height: 16),
            ],
          ),
          const SizedBox(height: 16),
          const ShimmerLoading(width: 200, height: 24),
          const SizedBox(height: 8),
          const ShimmerLoading(width: 150, height: 16),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 16),
          Row(
            children: [
              const ShimmerLoading(width: 16, height: 16, borderRadius: 8),
              const SizedBox(width: 8),
              const ShimmerLoading(width: 120, height: 16),
              const Spacer(),
              const ShimmerLoading(width: 80, height: 36, borderRadius: 10),
            ],
          ),
        ],
      ),
    );
  }
}

class TicketListShimmer extends StatelessWidget {
  const TicketListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: 4,
      itemBuilder: (context, index) => const TicketShimmerCard(),
    );
  }
}
