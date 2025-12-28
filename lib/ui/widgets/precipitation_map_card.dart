import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class PrecipitationMapCard extends StatefulWidget {
  final double latitude;
  final double longitude;

  const PrecipitationMapCard({super.key, required this.latitude, required this.longitude});

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
                  _tileUrl = 'https://tile.rainviewer.com/v2/radar/$ts/256/{z}/{x}/{y}/2/1_1.png';
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
    return ClipRRect(
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
                    Text("LƯỢNG MƯA", style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
                 ],
               ),
            ),
            
            // Map
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(widget.latitude, widget.longitude),
                  initialZoom: 6,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.flutter_weather_app',
                    tileBuilder: (context, widget, tile) {
                         return ColorFiltered(
                            colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.dstATop),
                            child: ColorFiltered(
                               colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                               child: widget
                            ),
                         );
                    },
                  ),
                  
                  if (_tileUrl != null)
                    TileLayer(
                      urlTemplate: _tileUrl!,
                      userAgentPackageName: 'com.example.flutter_weather_app',
                    ),
                  
                  // Marker
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(widget.latitude, widget.longitude),
                        width: 40,
                        height: 40,
                        child: Container(
                            decoration: BoxDecoration(
                               color: Colors.white,
                               shape: BoxShape.circle,
                               boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]
                            ),
                            child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
