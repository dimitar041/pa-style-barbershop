import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/pa_screen_shell.dart';

class SalonLocationScreen extends StatefulWidget {
  const SalonLocationScreen({super.key});

  @override
  State<SalonLocationScreen> createState() => _SalonLocationScreenState();
}

class _SalonLocationScreenState extends State<SalonLocationScreen> {
  static const String _salonName = 'PA Style Studio';
  static const String _address = 'ул. „Георги Сава Раковски" 128, София';
  static const String _phone = '+359 88 888 8888';
  static const String _workingHours = 'Пон – Нед: 08:00 – 21:00';

  static const LatLng _salonLocation = LatLng(42.6977, 23.3219);

  LatLng? _userLocation;
  bool _locationLoading = true;
  String? _locationError;
  double? _distanceKm;

  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _locationLoading = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationLoading = false;
          _locationError = 'Локацията на устройството е изключена.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationLoading = false;
            _locationError = 'Достъпът до локация е отказан.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationLoading = false;
          _locationError = 'Локацията е перманентно забранена. Разреши я от настройки.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final userLatLng = LatLng(position.latitude, position.longitude);
      final distance = _calculateDistanceKm(
        userLatLng.latitude,
        userLatLng.longitude,
        _salonLocation.latitude,
        _salonLocation.longitude,
      );

      if (!mounted) return;
      setState(() {
        _userLocation = userLatLng;
        _distanceKm = distance;
        _locationLoading = false;
      });

      _fitMapToBothPoints(userLatLng);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationLoading = false;
        _locationError = 'Неуспешно получаване на локация.';
      });
    }
  }

  void _fitMapToBothPoints(LatLng userPos) {
    final bounds = LatLngBounds.fromPoints([_salonLocation, userPos]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
      );
    });
  }

  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  Future<void> _openDirections() async {
    final query = _userLocation != null
        ? 'https://www.google.com/maps/dir/${_userLocation!.latitude},${_userLocation!.longitude}/${_salonLocation.latitude},${_salonLocation.longitude}'
        : 'https://www.google.com/maps/search/?api=1&query=${_salonLocation.latitude},${_salonLocation.longitude}';
    final uri = Uri.parse(query);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone() async {
    final uri = Uri.parse('tel:$_phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PaScreenShell(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              _salonName,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _address,
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _salonLocation,
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.pastyle.barbershop',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _salonLocation,
                            width: 50,
                            height: 50,
                            child: const _SalonMarker(),
                          ),
                          if (_userLocation != null)
                            Marker(
                              point: _userLocation!,
                              width: 40,
                              height: 40,
                              child: const _UserMarker(),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (_locationLoading)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                            ),
                            const SizedBox(width: 8),
                            Text('Търся локацията ти...', style: textTheme.labelMedium),
                          ],
                        ),
                      ),
                    ),
                  if (_distanceKm != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _distanceKm! < 1
                              ? '${(_distanceKm! * 1000).round()} м до салона'
                              : '${_distanceKm!.toStringAsFixed(1)} км до салона',
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  if (_locationError != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_off_rounded, size: 18, color: cs.onErrorContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _locationError!,
                                style: textTheme.labelMedium?.copyWith(color: cs.onErrorContainer),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              onPressed: _getUserLocation,
                              color: cs.onErrorContainer,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    icon: Icons.access_time_rounded,
                    label: _workingHours,
                    color: cs.tertiary,
                  ),
                ),
                const SizedBox(width: 10),
                _InfoChip(
                  icon: Icons.phone_rounded,
                  label: _phone,
                  color: cs.secondary,
                  onTap: _callPhone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FilledButton.icon(
              onPressed: _openDirections,
              icon: const Icon(Icons.directions_rounded),
              label: Text(_userLocation != null ? 'Навигация до салона' : 'Отвори в Google Maps'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SalonMarker extends StatelessWidget {
  const _SalonMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: const Icon(Icons.content_cut_rounded, color: Colors.white, size: 20),
        ),
        CustomPaint(
          size: const Size(12, 8),
          painter: _TrianglePainter(Theme.of(context).colorScheme.primary),
        ),
      ],
    );
  }
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: cs.tertiary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = ui.Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
