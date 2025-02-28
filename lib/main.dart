import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: AuthCheckScreen(), // Check authentication before showing the map
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  @override
  _AuthCheckScreenState createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  bool isAuthenticated = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _signIn();
  }

  Future<void> _signIn() async {
    try {
      // TODO: handle authentication properly for different user entered accounts
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: "testuser@example.com",
            password: "testpassword",
          );

      setState(() {
        isAuthenticated = true;
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        setState(() {
          errorMessage = 'No user found for that email.';
        });
      } else if (e.code == 'wrong-password') {
        setState(() {
          errorMessage = 'Wrong password provided for that user.';
        });
      } else {
        setState(() {
          errorMessage = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isAuthenticated) {
      return const MyHomePage(title: 'Map View');
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text("Logging In...")),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child:
                errorMessage == null
                    ? const CircularProgressIndicator()
                    : Text("Error: $errorMessage"),
          ),
        ),
      );
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late GoogleMapController mapController;

  LatLng? _currentPosition;
  Marker? _locationMarker;
  StreamSubscription<Position>? _positionStream;

  final LatLng _center = const LatLng(7.821603639133135, 80.406256487888);

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;

    // Load JSON from assets
    String styleJson = await rootBundle.loadString('assets/map/styles.json');

    // Apply styles to the Google Map
    mapController.setMapStyle(styleJson);
  }

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("⚠️ Location services are disabled.");
      return;
    }

    // Check and request permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("❌ Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("❌ Location permissions are permanently denied.");
      return;
    }

    // Get initial location
    Position position = await Geolocator.getCurrentPosition();
    _updateLocation(position);

    // Listen for location changes
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position newPosition) {
      _updateLocation(newPosition);
    });
  }

  void _updateLocation(Position position) {
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _locationMarker = Marker(
        markerId: const MarkerId("userLocation"),
        position: _currentPosition!,
      );

      // Move camera to the new position
      mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        backgroundColor: Colors.black,
        title: Text(widget.title, style: TextStyle(color: Colors.white)),
        elevation: 2,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? _center,
                zoom: 15.0,
              ),
              // markers: _locationMarker != null ? {_locationMarker!} : {},
              myLocationEnabled: true, // Show blue dot
              myLocationButtonEnabled: true, // Enable built-in location button
            ),
          ),
        ],
      ),
    );
  }
}
