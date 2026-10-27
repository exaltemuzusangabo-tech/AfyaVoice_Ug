import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/theme.dart';
import '../models/health_facility.dart';
import '../services/clinic_routing_service.dart';

class ClinicMapScreen extends StatefulWidget {
  final String triageLevel;

  const ClinicMapScreen({super.key, this.triageLevel = 'HIGH'});

  @override
  State<ClinicMapScreen> createState() => _ClinicMapScreenState();
}

class _ClinicMapScreenState extends State<ClinicMapScreen> {
  GoogleMapController? _mapController;
  Position? _userPosition;
  List<HealthFacility> _rankedFacilities = [];
  bool _onlyCSectionReady = false;
  bool _isLoading = true;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    if (widget.triageLevel == 'CRITICAL') {
      _onlyCSectionReady = true;
    }
    _loadLocationAndFacilities();
  }

  Future<void> _loadLocationAndFacilities() async {
    setState(() => _isLoading = true);

    final pos = await ClinicRoutingService.getCurrentLocation();
    final facilities = ClinicRoutingService.getRankedFacilities(
      userPosition: pos,
      triageLevel: widget.triageLevel,
    );

    final Set<Marker> markers = {};

    // Add user marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(pos.latitude, pos.longitude),
        infoWindow: const InfoWindow(title: 'Patient Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      ),
    );

    // Add facility markers
    for (final f in facilities) {
      final hue = f.type == 'REFERRAL_HOSPITAL'
          ? BitmapDescriptor.hueRed
          : (f.cSectionReady ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueGreen);

      markers.add(
        Marker(
          markerId: MarkerId(f.id),
          position: LatLng(f.latitude, f.longitude),
          infoWindow: InfoWindow(
            title: f.name,
            snippet: '${f.distanceKm} km away | ${f.openStatus}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        ),
      );
    }

    setState(() {
      _userPosition = pos;
      _rankedFacilities = facilities;
      _markers.addAll(markers);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _onlyCSectionReady
        ? _rankedFacilities.where((f) => f.cSectionReady).toList()
        : _rankedFacilities;

    final initialTarget = _userPosition != null
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
        : const LatLng(0.3476, 32.5825); // Kampala CBD

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Clinic Routing'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('C-Section Ready Only', style: TextStyle(fontSize: 12)),
                  selected: _onlyCSectionReady,
                  selectedColor: AfyaTheme.primaryEmergency.withOpacity(0.3),
                  checkmarkColor: Colors.redAccent,
                  onSelected: (val) => setState(() => _onlyCSectionReady = val),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sorted for ${widget.triageLevel} urgency',
                    style: const TextStyle(fontSize: 11, color: AfyaTheme.subText),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Google Map View
                SizedBox(
                  height: 240,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialTarget,
                      zoom: 11.5,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: _markers,
                    onMapCreated: (ctrl) => _mapController = ctrl,
                  ),
                ),

                // Ranked List Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Facilities (${filtered.length} accessible)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Text(
                        'Distance & Capability Weighted',
                        style: TextStyle(fontSize: 11, color: AfyaTheme.subText),
                      ),
                    ],
                  ),
                ),

                // Facility Cards List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final f = filtered[index];
                      final isReferral = f.type == 'REFERRAL_HOSPITAL';

                      return Card(
                        color: AfyaTheme.surfaceCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isReferral ? AfyaTheme.primaryEmergency.withOpacity(0.5) : const Color(0xFF2C3847),
                            width: isReferral ? 1.5 : 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          f.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${f.level} • ${f.district}',
                                          style: const TextStyle(fontSize: 12, color: AfyaTheme.subText),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AfyaTheme.seedTeal.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AfyaTheme.seedTeal),
                                    ),
                                    child: Text(
                                      '${f.distanceKm ?? "--"} km',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF26A69A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Capability badges
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (f.cSectionReady)
                                    _buildBadge('C-Section Active', Colors.greenAccent),
                                  if (f.bloodBank)
                                    _buildBadge('Blood Bank', Colors.redAccent),
                                  if (f.nicAvailable)
                                    _buildBadge('NICU Nursery', Colors.blueAccent),
                                  if (f.twentyFourSeven)
                                    _buildBadge('24/7 Maternity', Colors.tealAccent),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Action Buttons: Navigate & Call
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => ClinicRoutingService.launchNavigation(f),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AfyaTheme.seedTeal,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      icon: const Icon(Icons.directions, size: 18),
                                      label: const Text('Directions', style: TextStyle(fontSize: 13)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (f.phone.isNotEmpty)
                                    IconButton.filled(
                                      onPressed: () => ClinicRoutingService.callFacility(f.phone),
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(0xFF2E3846),
                                        foregroundColor: Colors.greenAccent,
                                      ),
                                      icon: const Icon(Icons.call, size: 20),
                                      tooltip: 'Call Maternity Desk',
                                    ),
                                  if (f.emergencyAmbulance.isNotEmpty)
                                    IconButton.filled(
                                      onPressed: () => ClinicRoutingService.callFacility(f.emergencyAmbulance),
                                      style: IconButton.styleFrom(
                                        backgroundColor: AfyaTheme.primaryEmergency,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.emergency, size: 20),
                                      tooltip: 'Call Ambulance Dispatch',
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
