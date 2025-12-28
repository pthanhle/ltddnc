import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_1/ui/widgets/details/average_models.dart';

class AverageChartPainter extends CustomPainter {
    final List<double> todayData;
    final List<RangeValue> normalRange;
    final bool isCelsius;
    
    AverageChartPainter({required this.todayData, required this.normalRange, required this.isCelsius});

    @override
    void paint(Canvas canvas, Size size) {
        final double padLeft = 40;
        final double padRight = 10;
        final double padTop = 30;
        final double padBot = 30; // X Axis
        
        final w = size.width - padLeft - padRight;
        final h = size.height - padTop - padBot;
        
        // Dynamic Bounds
        double minT = 100;
        double maxT = -100;
        
        // Find min/max from all data
        for(var d in todayData) {
            double v = isCelsius ? d : (d * 9/5 + 32);
            if(v < minT) minT = v;
            if(v > maxT) maxT = v;
        }
        for(var r in normalRange) {
             double maxV = isCelsius ? r.max : (r.max * 9/5 + 32);
             double minV = isCelsius ? r.min : (r.min * 9/5 + 32);
             if(minV < minT) minT = minV;
             if(maxV > maxT) maxT = maxV;
        }
        
        // Add padding
        minT -= 3;
        maxT += 3;
        
        // Nice steps
        double range = maxT - minT;
        // e.g. 15 to 40 -> 25 range. step 5.
        // e.g. 21 to 32 -> 11 range. step 3.
        double stepY = 3; 
        if (range > 15) stepY = 5;
        if (range > 30) stepY = 10;
        
        minT = (minT / stepY).floor() * stepY;
        maxT = (maxT / stepY).ceil() * stepY;
        
        // Scale functions
        double getY(double t) {
            double v = isCelsius ? t : (t * 9/5 + 32);
            return padTop + h - ((v - minT) / (maxT - minT)) * h;
        }
        
        double stepX = w / 24.0;
        
        Paint gridPaint = Paint()..color = Colors.white.withOpacity(0.2)..strokeWidth = 1..style=PaintingStyle.stroke;
        Paint dashedGridPaint = Paint()..color = Colors.white.withOpacity(0.15)..strokeWidth = 1..style=PaintingStyle.stroke;
        Paint rangePaint = Paint()..color = Colors.orange.withOpacity(0.3)..style=PaintingStyle.fill;
        Paint linePaint = Paint()..color = Colors.orange..style=PaintingStyle.stroke..strokeWidth=4..strokeCap=StrokeCap.round;

        // Draw Horizontal Grid & Labels
        for(double v = minT; v <= maxT; v += stepY) {
            double y = padTop + h - ((v - minT) / (maxT - minT)) * h;
            canvas.drawLine(Offset(padLeft, y), Offset(size.width - padRight, y), gridPaint);
            
            TextSpan span = TextSpan(style: const TextStyle(color: Colors.grey, fontSize: 12), text: "${v.round()}°");
            TextPainter tp = TextPainter(text: span, textAlign: TextAlign.right, textDirection: ui.TextDirection.ltr);
            tp.layout();
            tp.paint(canvas, Offset(size.width - padRight + 5, y - 6)); // Right side labels
        }
        
        // Draw Vertical Dashed Grid (every 6 hours) & Labels
        // 0, 6, 12, 18
        for(int i=0; i<=24; i+=6) {
             double x = padLeft + i * stepX;
             
             // Draw Dashed Line
             double dy = padTop;
             while (dy < padTop + h) {
                canvas.drawLine(Offset(x, dy), Offset(x, dy+4), dashedGridPaint);
                dy += 8;
             }
             
             // Label
             TextSpan span = TextSpan(style: const TextStyle(color: Colors.grey, fontSize: 12), text: "${i.toString().padLeft(2,'0')} giờ");
             TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: ui.TextDirection.ltr);
             tp.layout();
             tp.paint(canvas, Offset(x - tp.width/2, padTop + h + 8));
        }

        // Clip chart area
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(padLeft, padTop, w, h));

        // Draw Range Area (Smooth)
        Path rangePath = Path();
        if (normalRange.isNotEmpty) {
            // Top Spline
            rangePath.moveTo(padLeft + stepX/2, getY(normalRange[0].max));
            for(int i=0; i<normalRange.length; i++) {
                double x = padLeft + i * stepX + stepX/2;
                double y = getY(normalRange[i].max);
                if (i==0) rangePath.lineTo(x, y);
                else {
                     double prevX = padLeft + (i-1) * stepX + stepX/2;
                     double prevY = getY(normalRange[i-1].max);
                     double cx = (prevX + x)/2;
                     rangePath.cubicTo(cx, prevY, cx, y, x, y);
                }
            }
            
            // Bottom Spline (Reverse)
            for(int i=normalRange.length-1; i>=0; i--) {
                double x = padLeft + i * stepX + stepX/2;
                double y = getY(normalRange[i].min);
                if (i == normalRange.length-1) rangePath.lineTo(x, y);
                else {
                     double prevX = padLeft + (i+1) * stepX + stepX/2;
                     double prevY = getY(normalRange[i+1].min);
                     double cx = (prevX + x)/2;
                     rangePath.cubicTo(cx, prevY, cx, y, x, y);
                }
            }
            rangePath.close();
            canvas.drawPath(rangePath, rangePaint);
        }
        
        // Draw Today Line (Smooth)
        Path linePath = Path();
        for(int i=0; i<todayData.length && i<24; i++) {
             double x = padLeft + i * stepX + stepX/2;
             double y = getY(todayData[i]);
             if(i==0) linePath.moveTo(x, y);
             else {
                 // Spline
                 double prevX = padLeft + (i-1)*stepX + stepX/2;
                 double prevY = getY(todayData[i-1]);
                 double cx = (prevX + x)/2;
                 linePath.cubicTo(cx, prevY, cx, y, x, y);
             }
        }
        canvas.drawPath(linePath, linePaint);
        
        canvas.restore();

        // Current Dot (Outside clip if needed, but points are inside)
        DateTime now = DateTime.now();
        int hr = now.hour;
        if (hr < todayData.length) {
            double x = padLeft + hr * stepX + stepX/2; 
            double y = getY(todayData[hr]);
            canvas.drawCircle(Offset(x,y), 6, Paint()..color = Colors.black);
            canvas.drawCircle(Offset(x,y), 4, Paint()..color = Colors.orange);
        }
    }
    
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RainChartPainter extends CustomPainter {
    final List<double> recentData;
    final List<double> normalData;
    final String unit;
    
    RainChartPainter({required this.recentData, required this.normalData, required this.unit});

    double _toDateVal(double val) {
         if (unit == "cm") return val / 10.0;
         if (unit == "in") return val / 25.4;
         return val;
    }

    @override
    void paint(Canvas canvas, Size size) {
        final double padBot = 0; 
        final w = size.width;
        final h = size.height - padBot;
        
        // Find max Y
        double maxVal = 0;
        for(var v in recentData) if(_toDateVal(v) > maxVal) maxVal = _toDateVal(v);
        for(var v in normalData) if(_toDateVal(v) > maxVal) maxVal = _toDateVal(v);
        if(maxVal == 0) maxVal = 10;
        maxVal *= 1.2; // Padding top
        
        // Steps Y (0, 25, 50, 75, 100...)
        double stepY = maxVal / 4;
        
        Paint gridPaint = Paint()..color = Colors.white.withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 1;
        Paint blueLine = Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round;
        Paint greyDashed = Paint()..color = Colors.grey..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
        
        // Horizontal Grid
        for(int i=0; i<=4; i++) {
             double val = stepY * i;
             double y = h - (val / maxVal) * h;
             canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
             
             // Label right side
             if (i > 0) {
                 TextSpan span = TextSpan(style: const TextStyle(color: Colors.grey, fontSize: 12), text: val.round().toString());
                 TextPainter tp = TextPainter(text: span, textAlign: TextAlign.right, textDirection: ui.TextDirection.ltr);
                 tp.layout();
                 tp.paint(canvas, Offset(w - tp.width, y - 14));
             }
        }
        
        // Vertical Grid (Dashed)
        // 3 lines: 0 (start), 15 (mid), 30 (end)
        for(int i=0; i<=2; i++) {
            double x = (w / 2) * i;
            double dy = 0;
            while(dy < h) {
                canvas.drawLine(Offset(x, dy), Offset(x, dy+4), gridPaint);
                dy += 8;
            }
        }
        
        // Draw Lines
        void drawLine(List<double> data, Paint p, bool isDashed) {
             if (data.isEmpty) return;
             Path path = Path();
             double stepX = w / (data.length - 1);
             
             path.moveTo(0, h - (_toDateVal(data[0]) / maxVal) * h);
             
             for(int i=1; i<data.length; i++) {
                 double x = i * stepX;
                 double y = h - (_toDateVal(data[i]) / maxVal) * h;
                 path.lineTo(x, y);
             }
             
             if (isDashed) {
                 // Manual dash
                 Path dashedPath = Path();
                 for (ui.PathMetric pathMetric in path.computeMetrics()) {
                      double distance = 0.0;
                      while (distance < pathMetric.length) {
                          dashedPath.addPath(
                              pathMetric.extractPath(distance, distance + 5),
                              Offset.zero,
                          );
                          distance += 10;
                      }
                  }
                  canvas.drawPath(dashedPath, p);
                  
                  // Dot at end
                  double endX = (data.length-1) * stepX;
                  double endY = h - (_toDateVal(data.last) / maxVal) * h;
                   canvas.drawCircle(Offset(endX, endY), 5, Paint()..color = Colors.grey);
             } else {
                 canvas.drawPath(path, p);
                 // Dot at end
                  double endX = (data.length-1) * stepX;
                  double endY = h - (_toDateVal(data.last) / maxVal) * h;
                  canvas.drawCircle(Offset(endX, endY), 6, Paint()..color = Colors.black);
                  canvas.drawCircle(Offset(endX, endY), 4, Paint()..color = Colors.white);
             }
        }
        
        drawLine(normalData, greyDashed, true);
        drawLine(recentData, blueLine, false);
    }
    
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BarPainter extends CustomPainter {
    final double min;
    final double max;
    final double scaleMin;
    final double scaleMax;
    final bool isCurrent;
    
    BarPainter({required this.min, required this.max, required this.scaleMin, required this.scaleMax, required this.isCurrent});

    @override
    void paint(Canvas canvas, Size size) {
        // Dark track background
        Paint trackPaint = Paint()..color = Colors.white.withOpacity(0.08)..style = PaintingStyle.fill..strokeCap = StrokeCap.round;
        
        // Gradient Bar
        Paint barPaint = Paint()..style = PaintingStyle.fill..strokeCap = StrokeCap.round;
        // Simple gradient for bar: Orange to lighter orange/yellow
        barPaint.shader = ui.Gradient.linear(
            Offset(0, 0),
            Offset(size.width, 0),
            [Colors.orange, Colors.orangeAccent],
        );

        // Track (Full width)
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(3)), trackPaint);
        
        // Bar
        double range = scaleMax - scaleMin;
        double startPct = (min - scaleMin) / range;
        double endPct = (max - scaleMin) / range;
        
        if(startPct < 0) startPct = 0;
        if(endPct > 1) endPct = 1;
        if(endPct < startPct) endPct = startPct;
        
        double x1 = size.width * startPct;
        double x2 = size.width * endPct;
        double w = x2 - x1;
        if(w < 4) w = 4; // Min width
        
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x1, 0, w, size.height), const Radius.circular(3)), barPaint);
    }
    
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
