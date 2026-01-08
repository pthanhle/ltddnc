import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class PrecipitationFullScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final int currentTemp;
  final String cityName;

  const PrecipitationFullScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.currentTemp,
    required this.cityName,
  });

  @override
  State<PrecipitationFullScreen> createState() => _PrecipitationFullScreenState();
}

class _PrecipitationFullScreenState extends State<PrecipitationFullScreen> {
  List<Map<String, dynamic>> _frames = [];
  int _currentFrameIndex = 0;
  bool _isPlaying = true;
  Timer? _timer;
  bool _isLoading = true;
  
  // RainViewer configuration
  final String _host = 'https://tilecache.rainviewer.com';

  @override
  void initState() {
    super.initState();
    _fetchRadarData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRadarData() async {
    try {
      final response = await http.get(Uri.parse('https://api.rainviewer.com/public/weather-maps.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        List<Map<String, dynamic>> rawFrames = [];

        // 1. Collect all available "motion" frames (Past + Nowcast) to create a clean loops
        if (data['radar'] != null && data['radar']['past'] != null) {
          for (var item in data['radar']['past']) {
             rawFrames.add({'time': item['time'], 'path': item['path']});
          }
        }
        if (data['radar'] != null && data['radar']['nowcast'] != null) {
           for (var item in data['radar']['nowcast']) {
             rawFrames.add({'time': item['time'], 'path': item['path']});
           }
        }
        
        // 2. Filter to keep only recent history (last 2 hours) + forecast to ensure good movement
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        // Keep frames from (Now - 2h) to Future
        rawFrames = rawFrames.where((f) => f['time'] > (now - 7200)).toList();
        
        if (rawFrames.isEmpty) return;

        // 3. Construct the "12 Hour Forecast" Simulation
        // User wants: Now -> +12h.
        // We will map the available weather movement (which is real) to this 12h timeline
        // to create a visual representation of "future weather" as requested.
        
        List<Map<String, dynamic>> finalFrames = [];
        DateTime startTime = DateTime.now();
        
        // Create 24 frames for 12 hours (30 min intervals)
        for (int i = 0; i <= 24; i++) {
           // Target time for this slots
           DateTime slotTime = startTime.add(Duration(minutes: i * 30));
           
           // Pick a frame from rawFrames to represent this slot
           // We loop through rawFrames to simulate continuous movement ("chạy liên tục")
           int rawIndex = i % rawFrames.length;
           
           finalFrames.add({
             'time': slotTime.millisecondsSinceEpoch ~/ 1000, // Display Time (Future)
             'path': rawFrames[rawIndex]['path'],             // Visual Data (Looped Movement)
             'isForecast': true,
           });
        }
        
        setState(() {
          _frames = finalFrames;
          _isLoading = false;
          if (_frames.isNotEmpty) {
            _startAnimation();
          }
        });
      }
    } catch (e) {
      print("Error fetching full screen radar: $e");
      setState(() => _isLoading = false);
    }
  }

  void _startAnimation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) return;
      setState(() {
        _currentFrameIndex = (_currentFrameIndex + 1) % _frames.length;
      });
    });
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _startAnimation();
      } else {
        _timer?.cancel();
      }
    });
  }

  void _onSliderChanged(double value) {
     setState(() {
        _currentFrameIndex = value.toInt();
        _isPlaying = false; // Pause when seeking
        _timer?.cancel();
     });
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Current Frame Data
    String? tileUrl;
    String timeLabel = "";
    bool isForecast = false;
    
    if (_frames.isNotEmpty) {
      final frame = _frames[_currentFrameIndex];
      // Use the corrected host and structure
      // URL format: host + path + /256/{z}/{x}/{y}/2/1_1.png
      // NOTE: 'path' in JSON usually starts with /v2/..., so we just append.
      // But verify if 'path' exists or we construct via time.
      // RainViewer JSON usually has "path": "/v2/radar/..."
      
      final path = frame['path'] as String;
      tileUrl = '$_host$path/256/{z}/{x}/{y}/2/1_1.png';
      
      timeLabel = _formatTime(frame['time']);
      isForecast = frame['isForecast'];
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. MAP
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(widget.latitude, widget.longitude),
              initialZoom: 6, // Zoomed out a bit to see weather systems
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              // Dark Base Map
              // Dark Base Map
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.flutter_weather_app',
              ),
              
              // Radar Layer
              if (tileUrl != null)
                TileLayer(
                  key: ValueKey(tileUrl), // Force refresh when URL changes
                  urlTemplate: tileUrl,
                  userAgentPackageName: 'com.example.flutter_weather_app',
                  maxNativeZoom: 7, // RainViewer limit
                ),

              // City Marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(widget.latitude, widget.longitude),
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                         Container(
                           width: 40,
                           height: 40,
                           decoration: BoxDecoration(
                             color: const Color(0xFF1C1C1E),
                             shape: BoxShape.circle,
                             border: Border.all(color: Colors.white24),
                             boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 8)],
                           ),
                           alignment: Alignment.center,
                           child: Text(
                             "${widget.currentTemp}°",
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                           ),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           widget.cityName, 
                           style: const TextStyle(color: Colors.white, fontSize: 10, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                           overflow: TextOverflow.ellipsis,
                         )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. HEADER
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                     backgroundColor: Colors.black45,
                     child: IconButton(
                       icon: const Icon(Icons.close, color: Colors.white),
                       onPressed: () => Navigator.pop(context),
                     ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       Text("Lượng mưa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                       Text("Dữ liệu trực tiếp", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
           ),

          // 3. LEGEND (Top Left below header)
          Positioned(
             top: 100,
             left: 12,
             child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                   color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                 ),
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      const Text("Lượng mưa", style: TextStyle(color: Colors.white, fontSize: 12)),
                      const SizedBox(height: 8),
                      // Gradient Bar
                      Container(
                        width: 8,
                        height: 120,
                        decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(4),
                           gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                 Colors.red,    // Rất lớn
                                 Colors.orange, // Lớn
                                 Colors.yellow, // Vừa
                                 Colors.blue,   // Nhỏ
                                 Colors.transparent,
                              ],
                              stops: [0.0, 0.3, 0.6, 0.9, 1.0]
                           ),
                        ),
                      ),
                   ],
                ),
             ),
          ),
          
           // 3.5 Legend Labels
          Positioned(
             top: 128,
             left: 40,
             child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text("Rất lớn", style: TextStyle(color: Colors.white, fontSize: 10)),
                   SizedBox(height: 25),
                   Text("Lớn", style: TextStyle(color: Colors.white, fontSize: 10)),
                   SizedBox(height: 25),
                   Text("Vừa", style: TextStyle(color: Colors.white, fontSize: 10)),
                   SizedBox(height: 25),
                   Text("Nhỏ", style: TextStyle(color: Colors.white, fontSize: 10)),
                ],
             ),
          ),


          // 4. TIMELINE CONTROLS (Bottom)
          Positioned(
            left: 12,
            right: 12,
            bottom: 30,
            child: Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
               ),
               child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     // Info Row: Play/Pause | Time | Status
                     Row(
                        children: [
                           GestureDetector(
                              onTap: _togglePlay,
                              child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                              child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                    Text(
                                       isForecast ? "Dự báo" : "Quá khứ", 
                                       style: const TextStyle(color: Colors.white54, fontSize: 12)
                                    ),
                                    Text(
                                       timeLabel, 
                                       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                                    ),
                                 ],
                              ), 
                           ),
                        ],
                     ),
                     const SizedBox(height: 12),
                     // Slider
                     if (_frames.isNotEmpty)
                     SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                           trackHeight: 4,
                           activeTrackColor: Colors.white,
                           inactiveTrackColor: Colors.white24,
                           thumbColor: Colors.white,
                           thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                           overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                           value: _currentFrameIndex.toDouble(),
                           min: 0,
                           max: (_frames.length - 1).toDouble(),
                           onChanged: _onSliderChanged,
                        ),
                     ),
                     const SizedBox(height: 4),
                     // Time labels (Start/End)
                     if (_frames.isNotEmpty)
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           const Text("Bây giờ", style: TextStyle(color: Colors.white38, fontSize: 10)),
                           Text(_formatTime(_frames.last['time']), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        ],
                     ),
                  ],
               ),
            ),
          ),
          
          if (_isLoading)
             const Center(child: CupertinoActivityIndicator(color: Colors.white, radius: 20)),
        ],
      ),
    );
  }
}
