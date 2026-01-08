import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

enum WeatherEffectType { sun, clouds, rain, storm, snow, none }

class WeatherEffectLayer extends StatefulWidget {
  final int weatherCode;
  final bool isDay;

  const WeatherEffectLayer({
    super.key,
    required this.weatherCode,
    required this.isDay,
  });

  @override
  State<WeatherEffectLayer> createState() => _WeatherEffectLayerState();
}


class _WeatherEffectLayerState extends State<WeatherEffectLayer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Ensure non-null initialization for fields that might be reset during hot reload
  List<RainDrop> _rainDrops = [];
  List<SnowFlake> _snowFlakes = [];
  List<CloudPuff> _clouds = [];
  List<SunRay> _sunRays = [];
  List<LensFlare> _lensFlares = [];

  LightningBolt? _activeBolt;
  
  final Random _random = Random();
  
  // Lightning State
  double _flashOpacity = 0.0;
  int _lightningTimer = 0;
  double _sunIntensity = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
    _initParticles();
  }

  @override
  void didUpdateWidget(covariant WeatherEffectLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherCode != widget.weatherCode || oldWidget.isDay != widget.isDay) {
       _initParticles();
    }
  }
  
  void _initParticles() {
    // Safety re-init
    _rainDrops = [];
    _clouds = [];
    _sunRays = [];
    _snowFlakes = [];
    _lensFlares = [];

    int code = widget.weatherCode;
    bool isDay = widget.isDay;
    _sunIntensity = (code == 2) ? 0.6 : 1.0;

    // --- 1. DETERMINE DENSITY BASED ON DATA ---
    int cloudCount = 0;
    int rainCount = 0;
    int snowCount = 0;
    double cloudOpacityBase = 0.8;
    bool darkClouds = false;

    // Clear (0)
    if (code == 0) {
       cloudCount = 0;
    }
    // Mainly Clear (1)
    else if (code == 1) {
       cloudCount = 3; // Small amount, very wispy
       cloudOpacityBase = 0.5;
    }
    // Partly Cloudy (2)
    else if (code == 2) {
       cloudCount = 8; // Distinctly more clouds
       cloudOpacityBase = 0.85;
    }
    // Overcast (3)
    else if (code == 3) {
       cloudCount = 20; // Full coverage, dense
       cloudOpacityBase = 0.85; // Slight transparency for contrast
       darkClouds = true; // Use grey clouds
    }
    // Fog (45, 48)
    else if (code == 45 || code == 48) {
       cloudCount = 25; 
       cloudOpacityBase = 0.5; 
    }
    // Drizzle (51, 53, 55)
    else if (code >= 51 && code <= 55) {
       cloudCount = 15;
       rainCount = 30;
       darkClouds = true;
    }
    // Rain (61, 63, 65)
    else if (code >= 61 && code <= 65) {
       cloudCount = 20;
       rainCount = 80;
       darkClouds = true;
    }
    // Heavy Rain / Showers (80, 81, 82)
    else if (code >= 80 && code <= 82) {
       cloudCount = 25;
       rainCount = 150; 
       darkClouds = true;
    }
    // Snow (71-77, 85-86)
    else if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
       cloudCount = 15;
       snowCount = 60;
       darkClouds = true;
    }
    // Thunderstorm (95, 96, 99)
    else if (code >= 95) {
       cloudCount = 25;
       rainCount = 120;
       darkClouds = true;
    }

    // --- 2. GENERATE CLOUDS ---
    for(int i=0; i<cloudCount; i++) {
        // Overcast/Rain clouds cover more Y-area (top 0.5 height)
        // Clear/Partly clouds stick to top 0.25
        // Code 2 (Partly) -> 0.3
        double yMax = (code >= 3) ? 0.50 : (code == 2 ? 0.30 : 0.15); 
        
        _clouds.add(CloudPuff(
          x: _random.nextDouble(), 
          y: -0.1 + _random.nextDouble() * yMax, 
          size: 0.25 + _random.nextDouble() * 0.25, 
          speed: 0.00002 + _random.nextDouble() * 0.00004, 
          density: ((cloudOpacityBase - 0.1) + _random.nextDouble() * 0.2).clamp(0.0, 1.0), 
          isDark: darkClouds
        )..generateShape(_random, code));
    }

    // --- 3. GENERATE RAIN ---
    for(int i=0; i<rainCount; i++) {
       int layer = _random.nextInt(3); 
       double depth = (layer + 1) / 3; 
       _rainDrops.add(RainDrop(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          speed: 0.015 + (depth * 0.02), 
          length: 0.01 + (depth * 0.02), 
          opacity: (0.15 + (depth * 0.2)).clamp(0.0, 1.0), 
          width: depth * 1.0, 
       ));
    }

    // --- 4. GENERATE SNOW ---
    for(int i=0; i<snowCount; i++) {
       double depth = 0.5 + _random.nextDouble() * 0.5;
       _snowFlakes.add(SnowFlake(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          speed: 0.001 * depth,
          size: (1 + _random.nextDouble() * 2) * depth,
          opacity: (0.4 * depth + 0.2).clamp(0.0, 1.0)
       ));
    }

    // --- 5. GENERATE SUN (Only if Day and Not Overcast/Heavy Rain) ---
    // Show sun for codes 0, 1, 2. Hide for 3+.
    if (isDay && (code <= 2)) {
       // Reduce ray intensity/count for Partly Cloudy (2)
       bool isPartlyCloudy = (code == 2);
       int rayCount = isPartlyCloudy ? 8 : 12; 
       
       for(int i=0; i<rayCount; i++) {
          _sunRays.add(SunRay(
             angle: (i * (2 * pi / rayCount)) + (_random.nextDouble() * 0.1), 
             length: (0.4 + _random.nextDouble() * 0.4) * (isPartlyCloudy ? 0.7 : 1.0), 
             width: (2.0 + _random.nextDouble() * 3.0) * (isPartlyCloudy ? 0.8 : 1.0)
          ));
       }
       // Lens Flares - lighter if partly cloudy
       double flareOpacityMod = isPartlyCloudy ? 0.5 : 1.0;
       
       _lensFlares.add(LensFlare(active: true, offset: 0.2, radius: 10, opacity: 0.1 * flareOpacityMod, color: Colors.blue.shade200));
       _lensFlares.add(LensFlare(active: true, offset: 0.4, radius: 5, opacity: 0.05 * flareOpacityMod, color: Colors.yellow.shade100));
       _lensFlares.add(LensFlare(active: true, offset: 0.5, radius: 20, opacity: 0.03 * flareOpacityMod, color: Colors.purple.shade100));
    }
  }

  WeatherEffectType _getType() {
    // We now just determine "Dominant" renderer, but the initParticles logic handles the composition.
    // If we have rain drops, we render rain.
    if (_rainDrops.isNotEmpty) return WeatherEffectType.rain; // Covers storm too
    if (_snowFlakes.isNotEmpty) return WeatherEffectType.snow;
    if (_clouds.isNotEmpty) return WeatherEffectType.clouds; // Includes overcast
    if (widget.isDay) return WeatherEffectType.sun;
    return WeatherEffectType.none;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            
            // Safety check for hot reload nulls
            if (_rainDrops == null) _initParticles();

            // Always update system
            _updateSystem(size);
            
            // For drawing, we stack them. 
            // Sun is furthest back. Clouds mid. Rain front.
            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Sun Layer (Only if exists)
                  if (_sunRays.isNotEmpty)
                     CustomPaint(painter: RealisticSunPainter(rays: _sunRays, flares: _lensFlares, time: _controller.value, intensity: _sunIntensity)),

                  // 2. Cloud Layer (Always render if clouds exist)
                  if (_clouds.isNotEmpty)
                     CustomPaint(painter: RealisticCloudPainter(clouds: _clouds)),
                  
                  // 3. Precip Layer
                  if (_rainDrops.isNotEmpty)
                     _buildRainAndStorm(_rainDrops.length > 80), // Storm if heavy
                     
                  if (_snowFlakes.isNotEmpty)
                     CustomPaint(painter: RealisticSnowPainter(flakes: _snowFlakes)),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  void _updateSystem(Size size) {
     if (widget.weatherCode >= 95) { // Storm logic
        _updateLightning();
     }
  }
  
  void _updateLightning() {
     if (_flashOpacity > 0) {
        _flashOpacity -= 0.05; 
        if (_flashOpacity < 0) _flashOpacity = 0.0;
     }

     if (_activeBolt != null) {
        if (_activeBolt!.life > 0) {
           _activeBolt!.life--;
        } else {
           _activeBolt = null; 
        }
     } else {
        if (_random.nextInt(300) == 0) { 
           _flashOpacity = 0.8; 
           _activeBolt = LightningBolt.generate();
        }
     }
  }

  Widget _buildRainAndStorm(bool isStorm) {
    return Stack(
      children: [
        if (isStorm && _flashOpacity > 0.0)
          Container(color: Colors.white.withOpacity(_flashOpacity * 0.1)), 
          
        CustomPaint(
          painter: RealisticRainPainter(drops: _rainDrops, isStorm: isStorm),
          size: Size.infinite,
        ),
        
        if (isStorm && _activeBolt != null)
           CustomPaint(painter: LightningPainter(bolt: _activeBolt!)),
      ],
    );
  }
}

// --- LOGIC & PAINTERS ---

// 1. SUN & FLARES
class SunRay {
   double angle; // in radians
   double length; // 0.0 to 1.0 (relative to diag)
   double width; 
   SunRay({required this.angle, required this.length, required this.width});
}

class LensFlare {
  bool active;
  double offset; // distance from sun center
  double radius;
  double opacity;
  Color color;
  LensFlare({required this.active, required this.offset, required this.radius, required this.opacity, required this.color});
}

class RealisticSunPainter extends CustomPainter {
  final List<SunRay> rays;
  final List<LensFlare> flares;
  final double time;
  final double intensity;
  
  RealisticSunPainter({required this.rays, required this.flares, required this.time, this.intensity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.85, size.height * 0.15); // Moved down slightly
    
    // A. Main Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
           Colors.white.withOpacity(0.8 * intensity), 
           Colors.yellow.shade100.withOpacity(0.3 * intensity),
           Colors.transparent,
        ],
        stops: const [0.05, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.8));
    
    canvas.drawCircle(center, size.width * 0.8, glowPaint);
    
    // B. Rays
    final rayPaint = Paint()
      ..color = Colors.white.withOpacity(0.15 * intensity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2); 

    for (var ray in rays) {
       double rAngle = ray.angle + (time * 2 * pi * 0.05); 
       double rLen = ray.length * size.width * 0.6;
       
       canvas.save();
       canvas.translate(center.dx, center.dy);
       canvas.rotate(rAngle);
       
       Path rayPath = Path();
       rayPath.moveTo(0, 0);
       rayPath.lineTo(rLen, 0);
       rayPaint.strokeWidth = ray.width;
       canvas.drawPath(rayPath, rayPaint);
       
       canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 2. CLOUDS
class CloudPuff {
  double x, y, size, speed, density;
  bool isDark;
  List<Offset> puffOffsets = [];
  List<double> puffSizes = [];
  
  CloudPuff({required this.x, required this.y, required this.size, required this.speed, required this.density, this.isDark = false});
  
  void generateShape(Random r, int code) {
     puffOffsets.clear();
     puffSizes.clear();
     bool isFlat = (code >= 3 && code != 51); 
     
     int count = 10 + r.nextInt(8);
     for(int i=0; i<count; i++) {
        double wScale = isFlat ? 3.0 : 1.5;
        double hScale = isFlat ? 0.6 : 1.0;
        
        double dx = (r.nextDouble() - 0.5) * wScale; 
        double dy = (r.nextDouble() - 0.5) * hScale;
        puffOffsets.add(Offset(dx, dy));
        puffSizes.add(0.3 + r.nextDouble() * 0.7);
     }
  }
}

class RealisticCloudPainter extends CustomPainter {
  final List<CloudPuff> clouds;
  RealisticCloudPainter({required this.clouds});

  @override
  void paint(Canvas canvas, Size size) {
    for (var cloud in clouds) {
       final paint = Paint()
         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45); 

       Color cColor = cloud.isDark ? const Color(0xFF90A4AE) : Colors.white;
       paint.color = cColor.withOpacity(cloud.density);
       
       double cx = cloud.x * size.width;
       double cy = cloud.y * size.height;
       double baseRadius = cloud.size * (size.width * 0.20); 

       for(int i=0; i<cloud.puffOffsets.length; i++) {
          Offset off = cloud.puffOffsets[i];
          double puffR = baseRadius * cloud.puffSizes[i];
          canvas.drawCircle(Offset(cx + (off.dx * baseRadius * 0.5), cy + (off.dy * baseRadius * 0.5)), puffR, paint);
       }
       
       cloud.x += cloud.speed;
       if (cloud.x > 1.4) cloud.x = -0.4;
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 3. RAIN
class RainDrop {
  double x, y, speed, length, opacity, width;
  RainDrop({required this.x, required this.y, required this.speed, required this.length, required this.opacity, required this.width});
}

class RealisticRainPainter extends CustomPainter {
  final List<RainDrop> drops;
  final bool isStorm;
  RealisticRainPainter({required this.drops, required this.isStorm});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    double windX = isStorm ? -0.008 : -0.002; 
    
    for (var drop in drops) {
      paint.color = Colors.white.withOpacity(drop.opacity);
      paint.strokeWidth = drop.width;

      double startX = drop.x * size.width;
      double startY = drop.y * size.height;
      double endX = startX + (windX * size.width); 
      double endY = startY + (drop.length * size.height);
      
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);

      drop.y += drop.speed;
      drop.x += windX;
      if (drop.y > 1.05) { drop.y = -0.1; drop.x = Random().nextDouble(); }
      if (drop.x < -0.1) drop.x = 1.1; 
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 4. SNOW
class SnowFlake {
  double x, y, speed, size, opacity;
  SnowFlake({required this.x, required this.y, required this.speed, required this.size, required this.opacity});
}

class RealisticSnowPainter extends CustomPainter {
   final List<SnowFlake> flakes;
   RealisticSnowPainter({required this.flakes});
   @override
  void paint(Canvas canvas, Size size) {
     final paint = Paint()..color = Colors.white;
     for (var flake in flakes) {
        paint.color = Colors.white.withOpacity(flake.opacity);
        canvas.drawCircle(Offset(flake.x * size.width, flake.y * size.height), flake.size, paint);
        flake.y += flake.speed;
        flake.x += sin(flake.y * 10) * 0.0005; 
        if (flake.y > 1.0) { flake.y = -0.05; flake.x = Random().nextDouble(); }
     }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 5. LIGHTNING
class LightningBolt {
  List<Offset> points;
  int life; 
  LightningBolt(this.points, this.life);
  static LightningBolt generate() {
     List<Offset> pts = [];
     Random r = Random();
     double x = 0.2 + r.nextDouble() * 0.6; 
     double y = 0.0;
     pts.add(Offset(x, y));
     while (y < 0.8) {
        y += 0.05 + r.nextDouble() * 0.05;
        x += (r.nextDouble() - 0.5) * 0.1; 
        pts.add(Offset(x, y));
     }
     return LightningBolt(pts, 10); 
  }
}

class LightningPainter extends CustomPainter {
   final LightningBolt bolt;
   LightningPainter({required this.bolt});
   @override
  void paint(Canvas canvas, Size size) {
      if (bolt.life <= 0) return;
      final paint = Paint()
         ..color = Colors.white.withOpacity((bolt.life / 10).clamp(0.0, 1.0))
         ..style = PaintingStyle.stroke
         ..strokeWidth = 2
         ..strokeJoin = StrokeJoin.round
         ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5); 
         
      Path path = Path();
      if (bolt.points.isNotEmpty) {
          path.moveTo(bolt.points[0].dx * size.width, bolt.points[0].dy * size.height);
          for(int i=1; i<bolt.points.length; i++) {
             path.lineTo(bolt.points[i].dx * size.width, bolt.points[i].dy * size.height);
          }
      }
      canvas.drawPath(path, paint);
      paint.strokeWidth = 6;
      paint.color = Colors.blueAccent.withOpacity(0.3 * (bolt.life/10));
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
