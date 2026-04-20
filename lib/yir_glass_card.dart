library yir_glass_card;

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:yir_glass_card/paints/card_paint.dart';

// ─────────────────────────────────────────────
//  YirGlassStyle  (unchanged API)
// ─────────────────────────────────────────────
class YirGlassStyle {
  final Color color;
  const YirGlassStyle({required this.color});
}

// ─────────────────────────────────────────────
//  YirGlassCard  – now a StatefulWidget
// ─────────────────────────────────────────────
class YirGlassCard extends StatefulWidget {
  final double width;
  final double height;
  final Widget? child;
  final Color color;
  final double blur;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  // ── Animation toggles ──────────────────────
  /// Shimmering border sweep that loops forever.
  final bool enableShimmer;

  /// Floating / breathing idle animation.
  final bool enableFloat;

  /// Soft glow pulse on the border.
  final bool enableGlowPulse;

  /// Tap → ripple + scale-bounce.
  final bool enableTapEffect;

  /// Speed multiplier (1.0 = default).
  final double animationSpeed;

  const YirGlassCard({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    this.child,
    this.blur = 10,
    this.boxShadow,
    this.gradient,
    // animation defaults – all ON for "premium out-of-the-box" feel
    this.enableShimmer = true,
    this.enableFloat = true,
    this.enableGlowPulse = true,
    this.enableTapEffect = true,
    this.animationSpeed = 1.0,
  });

  @override
  State<YirGlassCard> createState() => _YirGlassCardState();
}

class _YirGlassCardState extends State<YirGlassCard>
    with TickerProviderStateMixin {
  // ── Controllers ───────────────────────────
  late final AnimationController _shimmerCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _tapCtrl;

  // ── Animations ────────────────────────────
  late final Animation<double> _shimmerAnim;
  late final Animation<double> _floatAnim;
  late final Animation<double> _glowAnim;
  late final Animation<double> _tapScaleAnim;
  late final Animation<double> _tapRippleAnim;
  late final Animation<double> _tapRippleOpacity;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    final s = widget.animationSpeed;

    // 1. Shimmer – sweeps a bright line around the border path
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2800 / s).round()),
    )..repeat();
    _shimmerAnim = CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear);

    // 2. Float – subtle Y-axis breathing
    _floatCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (3200 / s).round()),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // 3. Glow pulse – border opacity breathes
    _glowCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2000 / s).round()),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.15, end: 0.65).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // 4. Tap – scale bounce + ripple
    _tapCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (420 / s).round()),
    );
    _tapScaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.94), weight: 30),
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: 1.04)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_tapCtrl);
    _tapRippleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut),
    );
    _tapRippleOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enableTapEffect) return;
    setState(() => _isPressed = true);
    _tapCtrl.forward(from: 0);
  }

  void _onTapUp(TapUpDetails _) => setState(() => _isPressed = false);
  void _onTapCancel() => setState(() => _isPressed = false);

  @override
  Widget build(BuildContext context) {
    Widget card = SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          // ── Layer 1 : backdrop blur + fill ──────
          ClipPath(
            clipper: CardPaintContainer(),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.blur,
                sigmaY: widget.blur,
              ),
              child: Container(
                decoration: BoxDecoration(color: widget.color),
              ),
            ),
          ),

          // ── Layer 2 : glow-pulsing border ───────
          if (widget.enableGlowPulse)
            AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => CustomPaint(
                size: Size(widget.width, widget.height),
                painter: CardBorderPainter(opacity: _glowAnim.value),
              ),
            )
          else
            CustomPaint(
              size: Size(widget.width, widget.height),
              painter: CardBorderPainter(opacity: 0.3),
            ),

          // ── Layer 3 : shimmer sweep ──────────────
          if (widget.enableShimmer)
            AnimatedBuilder(
              animation: _shimmerAnim,
              builder: (_, __) => CustomPaint(
                size: Size(widget.width, widget.height),
                painter: _ShimmerBorderPainter(progress: _shimmerAnim.value),
              ),
            ),

          // ── Layer 4 : tap ripple ─────────────────
          if (widget.enableTapEffect)
            AnimatedBuilder(
              animation: _tapCtrl,
              builder: (_, __) {
                if (_tapRippleAnim.value == 0) return const SizedBox();
                return Opacity(
                  opacity: _tapRippleOpacity.value,
                  child: CustomPaint(
                    size: Size(widget.width, widget.height),
                    painter: _RipplePainter(
                      progress: _tapRippleAnim.value,
                      color: widget.color,
                    ),
                  ),
                );
              },
            ),

          // ── Layer 5 : child ──────────────────────
          if (widget.child != null) Center(child: widget.child!),
        ],
      ),
    );

    // Wrap with float animation
    if (widget.enableFloat) {
      card = AnimatedBuilder(
        animation: _floatAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: child,
        ),
        child: card,
      );
    }

    // Wrap with tap scale animation
    if (widget.enableTapEffect) {
      card = GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _tapScaleAnim,
          builder: (_, child) => Transform.scale(
            scale: _tapScaleAnim.value,
            child: child,
          ),
          child: card,
        ),
      );
    }

    return card;
  }
}

// ─────────────────────────────────────────────
//  Shimmer Painter  – bright arc sweeps the border
// ─────────────────────────────────────────────
class _ShimmerBorderPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0

  _ShimmerBorderPainter({required this.progress});

  // Build the same octagon path used by the card
  Path _buildPath(Size size) {
    return Path()
      ..moveTo(size.width * 0.1434769, size.height * 0.9999155)
      ..lineTo(size.width * 0.8565231, size.height * 0.9999155)
      ..lineTo(size.width, size.height * 0.8565237)
      ..lineTo(size.width, size.height * 0.1434763)
      ..lineTo(size.width * 0.8565231, 0)
      ..lineTo(size.width * 0.1434769, 0)
      ..lineTo(0, size.height * 0.1434763)
      ..lineTo(0, size.height * 0.8565237)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    // Measure total perimeter
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);

    // Head position
    const arcLength = 80.0; // px – length of shimmer arc
    final headPos = total * progress;

    // Draw a soft glowing arc along the path
    for (final metric in metrics) {
      final start = metric.length * (headPos / total) - arcLength / 2;
      final extractStart = start.clamp(0.0, metric.length);
      final extractEnd =
          (start + arcLength).clamp(0.0, metric.length).toDouble();
      if (extractEnd <= extractStart) continue;

      final arcPath = metric.extractPath(extractStart, extractEnd);

      // Outer glow
      canvas.drawPath(
        arcPath,
        Paint()
          ..color = Colors.white.withOpacity(0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Bright core
      canvas.drawPath(
        arcPath,
        Paint()
          ..color = Colors.white.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_ShimmerBorderPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────
//  Ripple Painter  – clipped inside card shape
// ─────────────────────────────────────────────
class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;

    canvas.drawCircle(
      center,
      maxRadius * progress,
      Paint()
        ..color = Colors.white.withOpacity(0.15 * (1 - progress))
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.progress != progress;
}