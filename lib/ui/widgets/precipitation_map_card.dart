import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_1/ui/screens/precipitation_full_screen.dart';

class PrecipitationMapCard extends StatefulWidget {
  final double latitude;
  final double longitude;
  final int currentTemp;
  final String cityName;

  const PrecipitationMapCard({
    super.key, 
    required this.latitude, 
    required this.longitude,
    this.currentTemp = 0,
    this.cityName = "Vị trí",
  });

  // ... (rest of class)

  @override
  State<PrecipitationMapCard> createState() => _PrecipitationMapCardState();
}

class _PrecipitationMapCardState extends State<PrecipitationMapCard> {
  String? _tileUrl;

  @override
  void initState() {
    super.initState();
    _fetchRadarLayer();
  }
  
  // ... (fetchRadarLayer remains same)
  Future<void> _fetchRadarLayer() async {
     try {
       final response = await http.get(Uri.parse('https://api.rainviewer.com/public/weather-maps.json'));
       if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         if (data['radar'] != null && data['radar']['past'] != null) {
            final past = data['radar']['past'] as List;
            if (past.isNotEmpty) {
               final lastFrame = past.last;
               final ts = lastFrame['time'];
               // Use 2 (Blue) or 4 (Universal) for color scheme
               setState(() {
                  _tileUrl = 'https://tilecache.rainviewer.com/v2/radar/$ts/256/{z}/{x}/{y}/2/1_1.png';
               });
            }
         }
       }
     } catch (e) {
       print("Error fetching RainViewer config: $e");
     }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
         Navigator.push(
            context,
            MaterialPageRoute(
               builder: (_) => PrecipitationFullScreen(
                 latitude: widget.latitude,
                 longitude: widget.longitude,
                 cityName: widget.cityName,
                 currentTemp: widget.currentTemp,
               )
            ),
         );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 350,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                 padding: const EdgeInsets.all(12),
                 child: Row(
                   children: [
                      const Icon(Icons.umbrella, color: Colors.white54, size: 16),
                      const SizedBox(width: 8),
                      const Text("LƯỢNG MƯA", style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
                   ],
                 ),
              ),
              
              // Map
              Expanded(
                child: AbsorbPointer( // Disable map interaction on the card so playing works
                  absorbing: true,
                  child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(widget.latitude, widget.longitude),
                    initialZoom: 6,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.example.flutter_weather_app',
                    ),
                    
                    if (_tileUrl != null)
                      TileLayer(
                        urlTemplate: _tileUrl!,
                        userAgentPackageName: 'com.example.flutter_weather_app',
                        maxNativeZoom: 7,
                      ),
                    
                    // Marker
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(widget.latitude, widget.longitude),
                          width: 60,
                          height: 80,
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
                               Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                     color: Colors.black45,
                                     borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                     widget.cityName, 
                                     style: const TextStyle(color: Colors.white, fontSize: 10),
                                     overflow: TextOverflow.ellipsis,
                                  ),
                               )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
