
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_theme.dart';
import '../../providers/heatmap_provider.dart';

class HeatmapScreen extends ConsumerStatefulWidget {
  const HeatmapScreen({super.key});

  @override
  ConsumerState<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends ConsumerState<HeatmapScreen> {
  final MapController _mapController = MapController();
  final _searchCtrl = TextEditingController();

  static const _defaultCenter = LatLng(14.5764, 121.0851); // Pasig City
  static const _defaultZoom = 13.0;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) await _goToUserLocation();
  }

  Future<void> _goToUserLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() => _userLocation = loc);
      _mapController.move(loc, _defaultZoom);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(heatmapZonesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── OpenStreetMap (free, no API key) ────────────────
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
              minZoom: 10,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.respiratrack.app',
              ),
              // Risk zone circles from MongoDB via backend API
              zonesAsync.when(
                data: (zones) => CircleLayer(circles: zones),
                loading: () => const CircleLayer(circles: []),
                error: (_, __) => const CircleLayer(circles: []),
              ),
              // User location dot + 500m geofence radius ring
              if (_userLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _userLocation!,
                      radius: 10,
                      color: AppColors.primaryBlue.withOpacity(0.4),
                      borderColor: AppColors.primaryBlue,
                      borderStrokeWidth: 2,
                    ),
                    CircleMarker(
                      point: _userLocation!,
                      radius: 500,
                      color: AppColors.primaryBlue.withOpacity(0.05),
                      borderColor: AppColors.primaryBlue.withOpacity(0.2),
                      borderStrokeWidth: 1,
                      useRadiusInMeter: true,
                    ),
                  ],
                ),
              // OSM attribution (required by license)
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          // ── Top Header ──────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: AppColors.primaryBlue,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Map',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'TB cases near you in Pasig City',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search barangay or area...',
                            hintStyle: AppTextStyles.caption,
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.textLight,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Risk Legend ──────────────────────────────────────
          Positioned(bottom: 180, right: 12, child: _RiskLegend()),

          // ── My Location FAB ──────────────────────────────────
          Positioned(
            bottom: 240,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'location_fab',
              backgroundColor: AppColors.white,
              onPressed: _goToUserLocation,
              child: const Icon(
                Icons.my_location_rounded,
                color: AppColors.primaryBlue,
              ),
            ),
          ),

          // ── Loading indicator ────────────────────────────────
          if (zonesAsync.isLoading)
            Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading risk zones...',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── About Map Card ───────────────────────────────────
          Positioned(bottom: 0, left: 0, right: 0, child: _AboutMapCard()),
        ],
      ),
    );
  }
}

class _RiskLegend extends StatelessWidget {
  const _RiskLegend();
  @override
  Widget build(BuildContext context) {
    const items = [
      ('Very High (31+ cases)', AppColors.riskHigh),
      ('Moderate (11–30 cases)', AppColors.riskModerate),
      ('Low (1–10 cases)', AppColors.riskLow),
      ('No Reported Cases', AppColors.riskNone),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TB Cases (Heat level)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.$2,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.$1,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutMapCard extends StatelessWidget {
  const _AboutMapCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.primaryBlue,
              ),
              SizedBox(width: 6),
              Text(
                'About this map',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'This heat map shows the density of reported TB cases in each '
            'barangay based on the latest data from health centers.',
            style: TextStyle(fontSize: 12, color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }
}
