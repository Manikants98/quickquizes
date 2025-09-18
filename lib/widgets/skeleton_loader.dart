import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                  Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                ],
                stops: [
                  0.0,
                  _animation.value,
                  1.0,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SkeletonText extends StatelessWidget {
  final double? width;
  final double height;
  final EdgeInsetsGeometry? margin;

  const SkeletonText({
    super.key,
    this.width,
    this.height = 16,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width,
      height: height,
      margin: margin,
      borderRadius: BorderRadius.circular(height / 2),
    );
  }
}

class SkeletonAvatar extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry? margin;

  const SkeletonAvatar({
    super.key,
    this.size = 40,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: size,
      height: size,
      margin: margin,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double? width;
  final double height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const SkeletonCard({
    super.key,
    this.width,
    this.height = 120,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon placeholder
          SkeletonLoader(
            width: 60,
            height: 60,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 16),
          // Content placeholder
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: double.infinity, height: 18),
                const SizedBox(height: 8),
                SkeletonText(width: 200, height: 14),
                const SizedBox(height: 4),
                SkeletonText(width: 150, height: 14),
                const Spacer(),
                SkeletonText(width: 120, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Arrow placeholder
          SkeletonLoader(
            width: 16,
            height: 16,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }
}

class SkeletonListView extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;

  const SkeletonListView({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 120,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return SkeletonCard(height: itemHeight);
      },
    );
  }
}

class SkeletonQuestionCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const SkeletonQuestionCard({
    super.key,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar skeleton
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonText(width: 120, height: 16),
                    SkeletonText(width: 80, height: 16),
                  ],
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: double.infinity,
                  height: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
          
          // Question card skeleton
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonText(width: double.infinity, height: 18),
                  const SizedBox(height: 8),
                  SkeletonText(width: 250, height: 18),
                  const SizedBox(height: 8),
                  SkeletonText(width: 180, height: 18),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Answer options skeleton
          ...List.generate(4, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SkeletonAvatar(size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SkeletonText(
                        width: double.infinity,
                        height: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
