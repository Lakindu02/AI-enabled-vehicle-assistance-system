import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardian_link/screens/auth/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/hospital_model.dart';
import '../../models/police_model.dart';
import '../../utils/app_colors.dart';
import 'home_screen_app_drawer.dart';

class HomeScreen extends StatefulWidget {
  final UserModel userModel;

  const HomeScreen({super.key, required this.userModel});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  Set<Marker> _markers = {};
  List<HospitalModel> _hospitals = [];
  List<PoliceModel> _policeStations = [];
  bool _showHospitals = true;
  bool _showPolice = true;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      await _loadLocations();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadLocations() async {
    try {
      final hospitals = await _databaseService.getAllHospitals();
      final police = await _databaseService.getAllPoliceStations();

      print(hospitals);

      if (mounted) {
        setState(() {
          _hospitals = hospitals;
          _policeStations = police;
        });
        _updateMarkers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading locations: $e')));
      }
    }
  }

  void _openGoogleMaps(double latitude, double longitude, String label) async {
    final String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

    try {
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Google Maps')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening Google Maps: $e')),
        );
      }
    }
  }

  void _updateMarkers() {
    Set<Marker> markers = {};

    if (_showHospitals) {
      for (var hospital in _hospitals) {
        markers.add(
          Marker(
            markerId: MarkerId('hospital_${hospital.id}'),
            position: LatLng(hospital.latitude, hospital.longitude),
            infoWindow: InfoWindow(
              title: hospital.name,
              snippet: hospital.address,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            onTap: () => _openGoogleMaps(
              hospital.latitude,
              hospital.longitude,
              hospital.name,
            ),
          ),
        );
      }
    }

    if (_showPolice) {
      for (var police in _policeStations) {
        markers.add(
          Marker(
            markerId: MarkerId('police_${police.id}'),
            position: LatLng(police.latitude, police.longitude),
            infoWindow: InfoWindow(title: police.name, snippet: police.address),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            onTap: () =>
                _openGoogleMaps(police.latitude, police.longitude, police.name),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen()),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authService.logout();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GuardianLink'), elevation: 0),
      drawer: HomeScreenAppDrawer(
        userModel: widget.userModel,
        onLogout: _handleLogout,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _initializeScreen,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _buildGoogleMaps(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return Padding(
      padding: const EdgeInsetsGeometry.only(bottom: 50.0),
      child: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: _showHospitals,
                    onChanged: (value) {
                      setState(() => _showHospitals = value ?? true);
                      _updateMarkers();
                      Navigator.pop(context);
                    },
                    title: const Text('Show Hospitals'),
                    secondary: Icon(
                      Icons.local_hospital,
                      color: AppColors.error,
                    ),
                  ),
                  CheckboxListTile(
                    value: _showPolice,
                    onChanged: (value) {
                      setState(() => _showPolice = value ?? true);
                      _updateMarkers();
                      Navigator.pop(context);
                    },
                    title: const Text('Show Police Stations'),
                    secondary: Icon(Icons.local_police, color: AppColors.info),
                  ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.layers),
      ),
    );
  }

  _buildGoogleMaps() {
    return GoogleMap(
      onMapCreated: (controller) {
        _controller.complete(controller);
      },
      initialCameraPosition: const CameraPosition(
        target: LatLng(6.872916, 79.8899),
        zoom: 12,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.satellite,
      zoomControlsEnabled: false,
      compassEnabled: true,
    );
  }
}
