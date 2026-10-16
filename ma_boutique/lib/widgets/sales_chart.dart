import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/stats.dart';
import '../core/theme.dart';

/// Courbe des ventes reproduisant le SVG du composant SalesChart React.
class SalesChart extends StatefulWidget {
  final List<PointSerie> points;
  final bool accent;
  final String monnaie;
  final double hauteur;

  const SalesChart({
    super.key,
    required this.points,
    this.accent = false,
    this.monnaie = 'FCFA',
    this.hauteur = 132,
  });

  @override
  State<SalesChart> createState() => _SalesChartState();
}

class _SalesChartState extends State<SalesChart> {
  static const double _l = 8;
  static const double _r = 8;

  int? _actif;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final points = widget.points;
    final trait = widget.accent ? c.accent : c.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final largeur = constraints.maxWidth;
        final max = points.isEmpty
            ? 1.0
            : points.map((p) => p.valeur).fold(1.0, math.max);
        final pasX = (largeur - _l - _r) / math.max(points.length - 1, 1);
        double y(double v) => widget.hauteur - 18 - v / max * (widget.hauteur - 34);
        final coords = [
          for (var i = 0; i < points.length; i++)
            (x: _l + i * pasX, y: y(points[i].valeur), i: i),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: widget.hauteur,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) => _pointer(d.localPosition.dx, pasX, largeur),
                      onPanDown: (d) => _pointer(d.localPosition.dx, pasX, largeur),
                      onTapUp: (_) => setState(() => _actif = null),
                      child: CustomPaint(
                        painter: _CourbePainter(
                          coords: coords,
                          hauteur: widget.hauteur,
                          largeur: largeur,
                          l: _l,
                          r: _r,
                          max: max,
                          actif: _actif,
                          trait: trait,
                          line: c.line,
                          surface: c.surface,
                        ),
                      ),
                    ),
                  ),
                  if (_actif != null && _actif! < coords.length)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Align(
                        alignment: Alignment(_alignement(coords[_actif!].x, largeur), -1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: c.line),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            '${points[_actif!].label} · ${formatMontant(points[_actif!].valeur, widget.monnaie)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Text(
                      'max ${formatCompact(max)}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _label(points.isNotEmpty ? points.first.label : ''),
                _label(points.isNotEmpty ? points[points.length ~/ 2].label : ''),
                _label(points.isNotEmpty ? points.last.label : ''),
              ],
            ),
          ],
        );
      },
    );
  }

  double _alignement(double x, double largeur) {
    if (x < largeur * 0.3) return -1;
    if (x > largeur * 0.7) return 1;
    return 0;
  }

  void _pointer(double dx, double pasX, double largeur) {
    if (widget.points.isEmpty) return;
    final i = ((dx - _l) / pasX).round().clamp(0, widget.points.length - 1);
    setState(() => _actif = i);
  }

  Widget _label(String texte) {
    return Text(
      texte,
      style: TextStyle(fontSize: 12, color: context.colors.muted),
    );
  }
}

class _CourbePainter extends CustomPainter {
  final List<({double x, double y, int i})> coords;
  final double hauteur;
  final double largeur;
  final double l;
  final double r;
  final double max;
  final int? actif;
  final Color trait;
  final Color line;
  final Color surface;

  _CourbePainter({
    required this.coords,
    required this.hauteur,
    required this.largeur,
    required this.l,
    required this.r,
    required this.max,
    required this.actif,
    required this.trait,
    required this.line,
    required this.surface,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double y(double v) => hauteur - 18 - v / max * (hauteur - 34);

    // Lignes de grille : 0, 0.5, 1 × max
    for (final f in [0.0, 0.5, 1.0]) {
      final yy = y(max * f);
      final paintLigne = Paint()
        ..color = line
        ..strokeWidth = 1;
      if (f != 0) {
        const dash = 3.0;
        const espace = 4.0;
        final path = Path();
        var x = l;
        while (x < largeur - r) {
          path.moveTo(x, yy);
          path.lineTo(math.min(x + dash, largeur - r), yy);
          x += dash + espace;
        }
        canvas.drawPath(path, paintLigne);
      } else {
        canvas.drawLine(Offset(l, yy), Offset(largeur - r, yy), paintLigne);
      }
    }

    if (coords.isEmpty) return;

    final chemin = Path();
    for (var i = 0; i < coords.length; i++) {
      if (i == 0) {
        chemin.moveTo(coords[i].x, coords[i].y);
      } else {
        chemin.lineTo(coords[i].x, coords[i].y);
      }
    }

    // Aire sous la courbe
    final aire = Path()
      ..moveTo(l, hauteur - 18)
      ..addPath(chemin, Offset.zero)
      ..lineTo(coords.isEmpty ? l : coords.last.x, hauteur - 18)
      ..close();
    canvas.drawPath(
      aire,
      Paint()..color = trait.withValues(alpha: 0.12),
    );

    // Ligne principale
    canvas.drawPath(
      chemin,
      Paint()
        ..color = trait
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    if (actif != null && actif! < coords.length) {
      final c = coords[actif!];
      // Ligne verticale
      canvas.drawLine(
        Offset(c.x, 12),
        Offset(c.x, hauteur - 18),
        Paint()
          ..color = trait.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
      // Point actif (centre couleur surface, contour trait)
      canvas.drawCircle(
        Offset(c.x, c.y),
        4.5,
        Paint()..color = surface,
      );
      canvas.drawCircle(
        Offset(c.x, c.y),
        4.5,
        Paint()
          ..color = trait
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    } else if (coords.isNotEmpty) {
      // Dernier point
      canvas.drawCircle(Offset(coords.last.x, coords.last.y), 4, Paint()..color = trait);
    }
  }

  @override
  bool shouldRepaint(_CourbePainter oldDelegate) {
    return oldDelegate.coords != coords ||
        oldDelegate.actif != actif ||
        oldDelegate.trait != trait ||
        oldDelegate.line != line ||
        oldDelegate.surface != surface ||
        oldDelegate.hauteur != hauteur ||
        oldDelegate.largeur != largeur;
  }
}