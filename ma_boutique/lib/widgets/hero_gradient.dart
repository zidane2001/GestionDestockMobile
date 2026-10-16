import 'package:flutter/material.dart';

/// Professional welcome screen background using the hero image
class HeroGradient extends StatelessWidget {
  const HeroGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0F),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Hero image with subtle overlay
          Image.asset(
            'assets/images/hero_boutique.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: const Color(0xFF0A0A0F)),
          ),
          // Dark overlay for text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Subtle brand accent line at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE94560).withValues(alpha: 0.0),
                    const Color(0xFFE94560).withValues(alpha: 0.8),
                    const Color(0xFF4A90D9).withValues(alpha: 0.8),
                    const Color(0xFF4A90D9).withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated app logo for the welcome screen - uses the actual logo image
class AnimatedAppLogo extends StatefulWidget {
  final double size;
  const AnimatedAppLogo({super.key, this.size = 80});

  @override
  State<AnimatedAppLogo> createState() => _AnimatedAppLogoState();
}

class _AnimatedAppLogoState extends State<AnimatedAppLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _rotateAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _rotateAnim = Tween<double>(begin: -0.3, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Transform.rotate(
            angle: _rotateAnim.value,
            child: Opacity(
              opacity: _fadeAnim.value,
              child: child,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo_smart_stock.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(
              color: const Color(0xFF1A1A2E),
              child: const Icon(Icons.storefront_rounded, size: 40, color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}

/// Staggered animation for welcome screen content
class StaggeredContent extends StatefulWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration duration;

  const StaggeredContent({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<StaggeredContent> createState() => _StaggeredContentState();
}

class _StaggeredContentState extends State<StaggeredContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration + widget.delay * widget.children.length,
      vsync: this,
    );

    _animations = List.generate(widget.children.length, (index) {
      final start = (widget.delay.inMilliseconds * index) /
          (widget.duration.inMilliseconds + widget.delay.inMilliseconds * widget.children.length);
      final end = start +
          widget.duration.inMilliseconds /
              (widget.duration.inMilliseconds + widget.delay.inMilliseconds * widget.children.length);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(widget.children.length, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Opacity(
              opacity: _animations[index].value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - _animations[index].value)),
                child: child,
              ),
            );
          },
          child: widget.children[index],
        );
      }),
    );
  }
}
