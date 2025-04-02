class Location {
  final String name;
  final double latitude;
  final double longitude;

  Location({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

// Define the journey locations: HCM -> Đồng Nai -> Nha Trang -> Đà Nẵng
final List<Location> destinations = [
  Location(name: 'HCM', latitude: 10.8231, longitude: 106.6297),
  Location(name: 'Đồng Nai', latitude: 10.9778, longitude: 106.8451),
  Location(name: 'Nha Trang', latitude: 12.2388, longitude: 109.1967),
  Location(name: 'Đà Nẵng', latitude: 16.0544, longitude: 108.2022),
];
