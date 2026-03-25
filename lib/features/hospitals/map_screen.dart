import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng currentLocation = const LatLng(17.3850, 78.4867);
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> getLocation() async {
    try {
      // Request permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        // Use default location (Hyderabad) if permission denied
        setState(() => isLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        isLoading = false;
      });
    } catch (e) {
      // Fall back to default location on any error
      debugPrint('Location error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Hospitals"), backgroundColor: Colors.teal),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(initialCenter: currentLocation, initialZoom: 15),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.ai_health_guardian',
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                      textStyle: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // Your location
                    Marker(
                      point: currentLocation,
                      child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 40),
                    ),
                    // Tirupati Hospitals (demo markers)
                    Marker(point: const LatLng(13.6280, 79.4190), child: const Icon(Icons.local_hospital, color: Colors.blue, size: 35)),
                    Marker(point: const LatLng(13.6500, 79.4300), child: const Icon(Icons.local_hospital, color: Colors.blue, size: 35)),
                  ],
                ),
              ],
            ),
    );
  }
}