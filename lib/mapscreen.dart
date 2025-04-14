import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Map',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.red,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController mapController;
  late Position _currentPosition;
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _firIdController = TextEditingController();
  bool _isLoading = false;
  bool _canMarkUnsafeLocation = false;
  String _selectedRouteType = "fastest";

  @override
  void initState() {
    super.initState();
    mapController = MapController.withUserPosition(
      trackUserLocation: UserTrackingOption(
        enableTracking: true,
        unFollowUser: false,
      ),
    );
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          throw Exception('Location permissions are denied');
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      await mapController.goToLocation(
        GeoPoint(
          latitude: _currentPosition.latitude,
          longitude: _currentPosition.longitude,
        ),
      );

      await mapController.addMarker(
        GeoPoint(
          latitude: _currentPosition.latitude,
          longitude: _currentPosition.longitude,
        ),
        markerIcon: MarkerIcon(
          icon: Icon(Icons.my_location, color: Colors.blue),
        ),
      );

      List<GeoPoint> unsafeAreas = [
        GeoPoint(latitude: 19.0728, longitude: 72.8767),
        GeoPoint(latitude: 19.0730, longitude: 72.8770),
        GeoPoint(latitude: 19.0740, longitude: 72.8780),
      ];

      for (var area in unsafeAreas) {
        await mapController.drawCircle(
          CircleOSM(
            key: "circleKey_${area.latitude}_${area.longitude}",
            centerPoint: area,
            radius: 20,
            color: Colors.red.withOpacity(0.5),
            strokeWidth: 2,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showDirections() async {
    GeoPoint currentLocation = GeoPoint(
        latitude: _currentPosition.latitude,
        longitude: _currentPosition.longitude);

    if (_destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a destination location.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<Location> locations =
          await locationFromAddress(_destinationController.text);

      if (locations.isEmpty) throw Exception('Place not found!');

      GeoPoint destinationLocation = GeoPoint(
          latitude: locations.first.latitude,
          longitude: locations.first.longitude);

      RoadInfo roadInfo = await mapController.drawRoad(
        currentLocation,
        destinationLocation,
        roadOption: RoadOption(
          roadColor:
              _selectedRouteType == "safest" ? Colors.blue : Colors.green,
          roadWidth: 20.0,
          zoomInto: true,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Distance: ${roadInfo.distance} km, Duration: ${roadInfo.duration} sec')));

      await mapController.addMarker(destinationLocation,
          markerIcon:
              MarkerIcon(icon: Icon(Icons.location_on, color: Colors.red)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error retrieving location: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _markUnsafeLocation(Offset globalPosition) async {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localOffset = renderBox.globalToLocal(globalPosition);

    GeoPoint tappedPoint = await convertOffsetToGeoPoint(localOffset);

    await mapController.drawCircle(CircleOSM(
      key: "unsafeCircle_${tappedPoint.latitude}_${tappedPoint.longitude}",
      centerPoint: tappedPoint,
      radius: 20,
      color: Colors.red.withOpacity(0.5),
      strokeWidth: 2,
    ));

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Unsafe location marked!')));
  }

  Future<GeoPoint> convertOffsetToGeoPoint(Offset offset) async {
    final mapCenter = await mapController.centerMap;
    final bounds = await mapController.bounds;

    final mapWidth = context.size!.width;
    final mapHeight = context.size!.height;

    final degreesPerPixelX = (bounds.east - bounds.west) / mapWidth;
    final degreesPerPixelY = (bounds.north - bounds.south) / mapHeight;

    final newLongitude =
        mapCenter.longitude + (offset.dx - mapWidth / 2) * degreesPerPixelX;
    final newLatitude =
        mapCenter.latitude - (offset.dy - mapHeight / 2) * degreesPerPixelY;

    return GeoPoint(latitude: newLatitude, longitude: newLongitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Safe Map'),
        backgroundColor: Color.fromARGB(255, 182, 68, 60),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 24, 24, 24),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _firIdController,
                            maxLength: 5,
                            decoration: InputDecoration(
                              labelText: 'Enter FIR ID',
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                            style: TextStyle(color: Colors.white),
                            onChanged: (value) {
                              if (value.length == 5) {
                                setState(() {
                                  _canMarkUnsafeLocation = true;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'You can now mark an unsafe location on the map!',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.black,
                                  ),
                                );
                              }
                            },
                          ),
                          SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _selectedRouteType,
                            dropdownColor: Colors.black,
                            decoration: InputDecoration(
                              labelText: 'Select Route Type',
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: "fastest",
                                child: Text(
                                  "Fastest Route",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              DropdownMenuItem(
                                value: "safest",
                                child: Text(
                                  "Safest Route",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedRouteType = value!;
                              });
                            },
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: _destinationController,
                            decoration: InputDecoration(
                              labelText: 'Destination Location',
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _showDirections,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 182, 68, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Show Directions',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTapDown: (details) {
                if (_canMarkUnsafeLocation) {
                  _markUnsafeLocation(details.globalPosition);
                }
              },
              child: OSMFlutter(
                controller: mapController,
                osmOption: OSMOption(
                  userTrackingOption: UserTrackingOption(
                    enableTracking: true,
                    unFollowUser: false,
                  ),
                  zoomOption: ZoomOption(
                    initZoom: 14.0,
                    minZoomLevel: 3.0,
                    maxZoomLevel: 19.0,
                  ),
                  userLocationMarker: UserLocationMaker(
                    personMarker: MarkerIcon(
                      icon: Icon(
                        Icons.location_history_rounded,
                        color: Colors.blue,
                        size: 48,
                      ),
                    ),
                    directionArrowMarker: MarkerIcon(
                      icon: Icon(Icons.double_arrow, size: 48),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
