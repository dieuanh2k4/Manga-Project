import 'dart:math';
import 'package:flutter/material.dart';
import 'package:web_admin/data/models/dashboard_dto.dart';

class DashboardLineChart extends StatefulWidget {
  final List<RevenuePointModel> data;

  const DashboardLineChart({super.key, required this.data});

  @override
  State<DashboardLineChart> createState() => _DashboardLineChartState();
}

class _DashboardLineChartState extends State<DashboardLineChart> {
  Offset? _hoverOffset;
  int _hoveredIndex = -1;

  void _onHover(PointerEvent event, BoxConstraints constraints) {
    if (widget.data.isEmpty) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localOffset = renderBox.globalToLocal(event.position);
    
    // Calculate the chart drawable area
    const double paddingLeft = 60.0;
    const double paddingRight = 20.0;
    final double drawWidth = constraints.maxWidth - paddingLeft - paddingRight;
    
    // Find nearest data point based on x coordinate
    final int pointsCount = widget.data.length;
    if (pointsCount < 2) return;
    
    final double stepX = drawWidth / (pointsCount - 1);
    
    double minDistance = double.infinity;
    int nearestIndex = -1;
    
    for (int i = 0; i < pointsCount; i++) {
      final double pX = paddingLeft + i * stepX;
      final double distance = (localOffset.dx - pX).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    if (nearestIndex != _hoveredIndex) {
      setState(() {
        _hoveredIndex = nearestIndex;
        _hoverOffset = localOffset;
      });
    }
  }

  void _onExit(PointerEvent event) {
    setState(() {
      _hoveredIndex = -1;
      _hoverOffset = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (e) => _onHover(e, constraints),
          onExit: _onExit,
          cursor: SystemMouseCursors.click,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: LineChartPainter(
                  data: widget.data,
                  hoveredIndex: _hoveredIndex,
                ),
              ),
              if (_hoveredIndex != -1 && _hoveredIndex < widget.data.length)
                _buildTooltip(constraints),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTooltip(BoxConstraints constraints) {
    final point = widget.data[_hoveredIndex];
    const double paddingLeft = 60.0;
    const double paddingRight = 20.0;
    final double drawWidth = constraints.maxWidth - paddingLeft - paddingRight;
    final double stepX = drawWidth / (widget.data.length - 1);
    final double pX = paddingLeft + _hoveredIndex * stepX;

    // Formatting revenue: e.g. "1.5M VND" or simple number representation
    final String formattedRevenue = point.revenue >= 1000000
        ? '${(point.revenue / 1000000).toStringAsFixed(1)}M'
        : '${(point.revenue / 1000).toStringAsFixed(0)}K';

    return Positioned(
      left: pX - 60,
      top: 10,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFF512F).withOpacity(0.4), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF512F).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ngày: ${point.date}',
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Doanh thu: $formattedRevenue đ',
                style: const TextStyle(color: Color(0xFFFF512F), fontSize: 11, fontWeight: FontWeight.w800),
              ),
              Text(
                'Đăng ký VIP: +${point.vipSignups}',
                style: const TextStyle(color: Color(0xFF00CDAC), fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<RevenuePointModel> data;
  final int hoveredIndex;

  LineChartPainter({required this.data, required this.hoveredIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double paddingTop = 20.0;
    const double paddingBottom = 30.0;
    const double paddingLeft = 60.0;
    const double paddingRight = 20.0;

    final double drawWidth = size.width - paddingLeft - paddingRight;
    final double drawHeight = size.height - paddingTop - paddingBottom;

    // Find max values
    double maxRevenue = data.map((p) => p.revenue).fold(1000.0, (prev, elem) => max(prev, elem));
    if (maxRevenue == 0) maxRevenue = 1000.0;
    
    // Format Y Axis helper
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw Y gridlines & labels (4 levels)
    const int yDivisions = 4;
    for (int i = 0; i <= yDivisions; i++) {
      final double y = paddingTop + drawHeight - (i * (drawHeight / yDivisions));
      final double value = (maxRevenue / yDivisions) * i;

      // Draw Gridline
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      // Draw Label
      String label = value >= 1000000
          ? '${(value / 1000000).toStringAsFixed(1)}M'
          : '${(value / 1000).toStringAsFixed(0)}K';
      if (i == 0) label = '0';

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 8, y - textPainter.height / 2));
    }

    final int pointsCount = data.length;
    if (pointsCount < 2) return;

    final double stepX = drawWidth / (pointsCount - 1);

    // Prepare paths for Revenue curve (cubic spline approximation)
    final Path curvePath = Path();
    final Path areaPath = Path();

    final List<Offset> points = [];
    for (int i = 0; i < pointsCount; i++) {
      final double x = paddingLeft + i * stepX;
      final double y = paddingTop + drawHeight - ((data[i].revenue / maxRevenue) * drawHeight);
      points.add(Offset(x, y));
    }

    // Cubic Bezier spline interpolation
    curvePath.moveTo(points[0].dx, points[0].dy);
    areaPath.moveTo(points[0].dx, paddingTop + drawHeight);
    areaPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final double cx1 = points[i].dx + (points[i + 1].dx - points[i].dx) / 2;
      final double cy1 = points[i].dy;
      final double cx2 = points[i].dx + (points[i + 1].dx - points[i].dx) / 2;
      final double cy2 = points[i + 1].dy;

      curvePath.cubicTo(cx1, cy1, cx2, cy2, points[i + 1].dx, points[i + 1].dy);
      areaPath.cubicTo(cx1, cy1, cx2, cy2, points[i + 1].dx, points[i + 1].dy);
    }

    areaPath.lineTo(points.last.dx, paddingTop + drawHeight);
    areaPath.close();

    // 1. Draw Area Gradient under the curve
    final Paint areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF512F).withOpacity(0.24),
          const Color(0xFFDD2476).withOpacity(0.00),
        ],
      ).createShader(Rect.fromLTRB(paddingLeft, paddingTop, size.width - paddingRight, paddingTop + drawHeight))
      ..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, areaPaint);

    // 2. Draw Glow Line (Shadow Effect)
    final Paint glowPaint = Paint()
      ..color = const Color(0xFFFF512F).withOpacity(0.4)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(curvePath, glowPaint);

    // 3. Draw Main Line
    final Paint linePaint = Paint()
      ..color = const Color(0xFFFF512F)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(curvePath, linePaint);

    // 4. Draw X axis dates (4 items spaced out)
    final int labelStep = (pointsCount / 4).ceil();
    for (int i = 0; i < pointsCount; i += labelStep) {
      final double x = paddingLeft + i * stepX;
      textPainter.text = TextSpan(
        text: data[i].date,
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, paddingTop + drawHeight + 8));
    }

    // 5. Draw interactive hover line & point
    if (hoveredIndex != -1 && hoveredIndex < points.length) {
      final Offset activePoint = points[hoveredIndex];

      // Draw Vertical Line
      final Paint hoverLinePaint = Paint()
        ..color = const Color(0xFFFF512F).withOpacity(0.25)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(activePoint.dx, paddingTop),
        Offset(activePoint.dx, paddingTop + drawHeight),
        hoverLinePaint,
      );

      // Draw Outer Glow Circle
      final Paint outerCirclePaint = Paint()
        ..color = const Color(0xFFFF512F).withOpacity(0.35)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(activePoint, 8, outerCirclePaint);

      // Draw Inner Point
      final Paint innerCirclePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(activePoint, 4, innerCirclePaint);

      final Paint borderCirclePaint = Paint()
        ..color = const Color(0xFFFF512F)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(activePoint, 4, borderCirclePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DashboardBarChart extends StatefulWidget {
  final List<GenreViewsModel> data;

  const DashboardBarChart({super.key, required this.data});

  @override
  State<DashboardBarChart> createState() => _DashboardBarChartState();
}

class _DashboardBarChartState extends State<DashboardBarChart> {
  int _hoveredIndex = -1;

  void _onHover(PointerEvent event, BoxConstraints constraints) {
    if (widget.data.isEmpty) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localOffset = renderBox.globalToLocal(event.position);

    const double paddingLeft = 45.0;
    const double paddingRight = 10.0;
    final double drawWidth = constraints.maxWidth - paddingLeft - paddingRight;

    final int barsCount = min(widget.data.length, 5); // Display top 5
    if (barsCount == 0) return;

    final double groupWidth = drawWidth / barsCount;
    final double barWidth = groupWidth * 0.45;

    int newHoveredIndex = -1;
    for (int i = 0; i < barsCount; i++) {
      final double groupCenterX = paddingLeft + (i * groupWidth) + (groupWidth / 2);
      final double barLeft = groupCenterX - (barWidth / 2);
      final double barRight = groupCenterX + (barWidth / 2);

      if (localOffset.dx >= barLeft && localOffset.dx <= barRight) {
        newHoveredIndex = i;
        break;
      }
    }

    if (newHoveredIndex != _hoveredIndex) {
      setState(() {
        _hoveredIndex = newHoveredIndex;
      });
    }
  }

  void _onExit(PointerEvent event) {
    setState(() {
      _hoveredIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (e) => _onHover(e, constraints),
          onExit: _onExit,
          cursor: SystemMouseCursors.click,
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: BarChartPainter(
              data: widget.data,
              hoveredIndex: _hoveredIndex,
            ),
          ),
        );
      },
    );
  }
}

class BarChartPainter extends CustomPainter {
  final List<GenreViewsModel> data;
  final int hoveredIndex;

  BarChartPainter({required this.data, required this.hoveredIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final int barsCount = min(data.length, 5); // Display top 5 genres
    if (barsCount == 0) return;

    const double paddingTop = 25.0;
    const double paddingBottom = 30.0;
    const double paddingLeft = 45.0;
    const double paddingRight = 10.0;

    final double drawWidth = size.width - paddingLeft - paddingRight;
    final double drawHeight = size.height - paddingTop - paddingBottom;

    // Find max views
    double maxViews = data.map((d) => d.viewsCount.toDouble()).fold(10.0, (prev, elem) => max(prev, elem));
    if (maxViews == 0) maxViews = 10.0;

    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw horizontal grid lines & labels (3 subdivisions)
    const int divisions = 3;
    for (int i = 0; i <= divisions; i++) {
      final double y = paddingTop + drawHeight - (i * (drawHeight / divisions));
      final double val = (maxViews / divisions) * i;

      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      // Label
      String label = val >= 1000
          ? '${(val / 1000).toStringAsFixed(1)}K'
          : '${val.toInt()}';
      if (i == 0) label = '0';

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 8, y - textPainter.height / 2));
    }

    final double groupWidth = drawWidth / barsCount;
    final double barWidth = groupWidth * 0.45;

    for (int i = 0; i < barsCount; i++) {
      final item = data[i];
      final double groupCenterX = paddingLeft + (i * groupWidth) + (groupWidth / 2);
      final double barLeft = groupCenterX - (barWidth / 2);

      final double barHeight = (item.viewsCount / maxViews) * drawHeight;
      final double barTop = paddingTop + drawHeight - barHeight;

      final bool isHovered = i == hoveredIndex;

      // Outer glow for hovered bar
      if (isHovered) {
        final Paint glowPaint = Paint()
          ..color = const Color(0xFF00CDAC).withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        final RRect glowRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(barLeft - 2, barTop - 2, barWidth + 4, barHeight + 2),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );
        canvas.drawRRect(glowRect, glowPaint);
      }

      // Draw rounded column bar
      final Paint barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isHovered
              ? [
                  const Color(0xFF02AAB0),
                  const Color(0xFF00CDAC),
                ]
              : [
                  const Color(0xFF00CDAC).withOpacity(0.85),
                  const Color(0xFF02AAB0).withOpacity(0.85),
                ],
        ).createShader(Rect.fromLTWH(barLeft, barTop, barWidth, barHeight));

      final RRect barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(barRect, barPaint);

      // Value text on top of bar
      textPainter.text = TextSpan(
        text: '${item.viewsCount}',
        style: TextStyle(
          color: isHovered ? Colors.white : Colors.white.withOpacity(0.6),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(groupCenterX - textPainter.width / 2, barTop - textPainter.height - 4));

      // Draw Genre Name Label under bar
      textPainter.text = TextSpan(
        text: item.genreName,
        style: TextStyle(
          color: isHovered ? Colors.white : Colors.white.withOpacity(0.4),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(groupCenterX - textPainter.width / 2, paddingTop + drawHeight + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
