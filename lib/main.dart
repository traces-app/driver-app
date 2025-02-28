import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  final LatLng _center = const LatLng(7.821603639133135, 80.406256487888);

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;

    // Load JSON from assets
    String styleJson = await rootBundle.loadString('assets/map/styles.json');

    // Apply styles to the Google Map
    mapController.setMapStyle(styleJson);
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
                target: _center,
                zoom: 15.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
