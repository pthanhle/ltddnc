import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/logic/providers/weather_provider.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final BehaviorSubject<String> _querySubject = BehaviorSubject<String>();
  List<City> _results = [];
  bool _loading = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    // Debounce search input by 500ms
    _subscription = _querySubject
        .debounceTime(const Duration(milliseconds: 500))
        .distinct()
        .listen((query) {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _results = [];
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _querySubject.close();
    super.dispose();
  }

  void _performSearch(String query) async {
    setState(() => _loading = true);
    final results = await context.read<WeatherProvider>().searchCities(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        title: const Text("Tìm kiếm"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                hintText: "Tìm thành phố, sân bay...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _controller.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                           _controller.clear();
                           _querySubject.add("");
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => _querySubject.add(val),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final city = _results[index];
                      return ListTile(
                        title: Text(city.name,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(city.country,
                            style: const TextStyle(color: Colors.grey)),
                        onTap: () {
                          context.read<WeatherProvider>().addCity(city);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
