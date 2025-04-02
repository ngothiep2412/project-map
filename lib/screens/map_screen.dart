import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  final List<Marker> _markers = [];
  int _currentDestinationIndex = 0;
  bool _isJourneyStarted = false;
  List<Location> _visitedLocations = [];

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _getCurrentLocation();
    _setupMarkers();
  }

  Future<void> _requestLocationPermission() async {
    await Geolocator.requestPermission();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });

      // Move the map camera to the current position
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        12.0,
      );
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  void _setupMarkers() {
    _markers.clear();
    for (int i = 0; i < destinations.length; i++) {
      var location = destinations[i];
      Color markerColor = Colors.red;

      // Change marker color based on journey status
      if (_visitedLocations.contains(location)) {
        markerColor = Colors.green; // Visited locations
      } else if (i == _currentDestinationIndex && _isJourneyStarted) {
        markerColor = Colors.blue; // Current destination
      }

      _markers.add(
        Marker(
          point: LatLng(location.latitude, location.longitude),
          width: 100,
          height: 100,
          child: Column(
            children: [
              Icon(
                Icons.location_pin,
                color: markerColor,
                size: 32,
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  location.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _startJourney() {
    setState(() {
      _isJourneyStarted = true;
      _currentDestinationIndex = 0;
      _visitedLocations = [];
    });
    _setupMarkers();
    _updateRoute();
  }

  void _resetJourney() {
    setState(() {
      _isJourneyStarted = false;
      _currentDestinationIndex = 0;
      _visitedLocations = [];
    });
    _setupMarkers();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hành trình đã được thiết lập lại'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _updateRoute() {
    if (_currentPosition == null || !_isJourneyStarted) return;

    Location nextDestination = destinations[_currentDestinationIndex];
    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      nextDestination.latitude,
      nextDestination.longitude,
    );

    // Check if the user has arrived at the destination
    if (distanceInMeters < 10000) {
      // 10000 meters threshold
      setState(() {
        _visitedLocations.add(nextDestination);
        _currentDestinationIndex++;

        if (_currentDestinationIndex < destinations.length) {
          // Move to the next destination
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Bạn đã đến ${nextDestination.name}! Tiếp tục đến ${destinations[_currentDestinationIndex].name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
          _setupMarkers();
        } else {
          // Notify that the user has reached the final destination
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chúc mừng! Bạn đã hoàn thành hành trình!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
          _isJourneyStarted = false;
        }
      });
    }
  }

  String _getNextDestinationInfo() {
    if (!_isJourneyStarted) {
      return 'Bắt đầu hành trình: HCM → Đồng Nai → Nha Trang → Đà Nẵng';
    }

    if (_currentDestinationIndex >= destinations.length) {
      return 'Hành trình đã hoàn thành!';
    }

    Location nextDestination = destinations[_currentDestinationIndex];
    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      nextDestination.latitude,
      nextDestination.longitude,
    );

    return 'Đang đến: ${nextDestination.name} (còn ${(distanceInMeters / 1000).toStringAsFixed(1)} km)';
  }

  String _getRemainingJourneyInfo() {
    if (_currentDestinationIndex >= destinations.length - 1) {
      return 'Đã đến điểm cuối cùng';
    }

    List<String> remainingDestinations = [];
    for (int i = _currentDestinationIndex + 1; i < destinations.length; i++) {
      remainingDestinations.add(destinations[i].name);
    }

    return 'Điểm tiếp theo: ${remainingDestinations.join(' → ')}';
  }

  // Calculate distance between two locations
  double _calculateDistance(Location loc1, Location loc2) {
    return Geolocator.distanceBetween(
          loc1.latitude,
          loc1.longitude,
          loc2.latitude,
          loc2.longitude,
        ) /
        1000; // Convert to km
  }

  Widget _buildJourneyProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(destinations.length, (index) {
          bool isVisited = _visitedLocations.contains(destinations[index]);
          bool isCurrent =
              index == _currentDestinationIndex && _isJourneyStarted;

          return Row(
            children: [
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: isVisited
                      ? Colors.green
                      : (isCurrent ? Colors.blue : Colors.grey),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (index + 1).toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (index < destinations.length - 1)
                Container(
                  width: 30,
                  height: 2,
                  color: _visitedLocations.contains(destinations[index])
                      ? Colors.green
                      : Colors.grey,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildJourneyDetails() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết hành trình',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < destinations.length - 1; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      backgroundColor:
                          _visitedLocations.contains(destinations[i])
                              ? Colors.green.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                      label: RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black, fontSize: 12),
                          children: [
                            TextSpan(
                              text:
                                  '${destinations[i].name} → ${destinations[i + 1].name}: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  '${_calculateDistance(destinations[i], destinations[i + 1]).toStringAsFixed(1)} km',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Theo dõi hành trình',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetJourney,
            tooltip: 'Đặt lại hành trình',
          ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải vị trí...'),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          initialZoom: 12,
                          onPositionChanged:
                              (MapPosition position, bool hasGesture) {
                            if (_isJourneyStarted) {
                              _updateRoute();
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                          MarkerLayer(markers: _markers),
                          // Current location marker
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                width: 50,
                                height: 50,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Controls overlay
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Column(
                          children: [
                            FloatingActionButton(
                              mini: true,
                              onPressed: () {
                                _mapController.move(
                                  LatLng(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                  ),
                                  12.0,
                                );
                              },
                              child: const Icon(Icons.my_location),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton(
                              mini: true,
                              onPressed: () {
                                _mapController.moveAndRotate(
                                  LatLng(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                  ),
                                  12.0,
                                  0,
                                );
                              },
                              child: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildJourneyProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        _getNextDestinationInfo(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isJourneyStarted ? Colors.blue : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_isJourneyStarted) ...[
                        const SizedBox(height: 8),
                        Text(
                          _getRemainingJourneyInfo(),
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildJourneyDetails(),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isJourneyStarted ? null : _startJourney,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isJourneyStarted
                              ? 'Hành trình đang diễn ra'
                              : 'Bắt đầu hành trình',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _isJourneyStarted
          ? FloatingActionButton.extended(
              onPressed: () {
                _getCurrentLocation();
                _updateRoute();
              },
              icon: Icon(Icons.navigation),
              label: Text('Cập nhật vị trí'),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }
}
