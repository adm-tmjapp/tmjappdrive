import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../application/profile_providers.dart';
import '../../domain/profile_models.dart';

class ProfileEditAddressScreen extends ConsumerStatefulWidget {
  const ProfileEditAddressScreen({super.key});

  @override
  ConsumerState<ProfileEditAddressScreen> createState() =>
      _ProfileEditAddressScreenState();
}

class _ProfileEditAddressScreenState
    extends ConsumerState<ProfileEditAddressScreen> {
  static const Color _bg = Color(0xFF050B16);
  static const Color _card = Color(0xFF0D1529);
  static const Color _panel = Color(0xFF111B30);
  static const Color _border = Color(0xFF1F2C45);
  static const Color _muted = Color(0xFF9CA3AF);
  static const Color _primary = Color(0xFFD62D86);
  static const CameraPosition _spCamera = CameraPosition(
    target: LatLng(-23.55052, -46.633308),
    zoom: 12,
  );

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<DriverProfileAddress> _results = const [];
  List<DriverProfileAddress> _history = const [];
  DriverProfileAddress? _selectedAddress;
  LatLng? _selectedLatLng;
  final Completer<GoogleMapController> _mapController = Completer();
  bool _loadingLocation = false;
  bool _loadingSearch = false;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    final currentAddress = ref.read(profileControllerProvider).payload?.address;
    _selectedAddress = currentAddress;
    if (currentAddress?.latitude != null && currentAddress?.longitude != null) {
      _selectedLatLng = LatLng(
        currentAddress!.latitude!,
        currentAddress.longitude!,
      );
    }
    _loadHistory();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showInfo('Ative o GPS para usar sua localizacao.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showInfo('Permita acesso a localizacao para continuar.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _applySelectedLocation(
        LatLng(position.latitude, position.longitude),
        label: 'Localizacao atual',
      );
    } catch (_) {
      _showInfo('Nao foi possivel obter sua localizacao.');
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _applySelectedLocation(LatLng latLng, {String? label}) {
    setState(() {
      _selectedLatLng = latLng;
      _selectedAddress = DriverProfileAddress(
        formattedAddress:
            label ??
            'Selecionado no mapa (${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)})',
        latitude: latLng.latitude,
        longitude: latLng.longitude,
        street: null,
        number: null,
        district: null,
        city: null,
        state: null,
        zipCode: null,
        complement: null,
        label: label,
        id: _selectedAddress?.id,
      );
    });
    _animateMap(latLng);
  }

  Future<void> _animateMap(LatLng target) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    unawaited(
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 15),
        ),
      ),
    );
  }

  void _selectAddress(DriverProfileAddress item) {
    setState(() {
      _selectedAddress = item;
      if (item.latitude != null && item.longitude != null) {
        _selectedLatLng = LatLng(item.latitude!, item.longitude!);
      }
    });
    if (item.latitude != null && item.longitude != null) {
      _animateMap(LatLng(item.latitude!, item.longitude!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final currentAddress = state.payload?.address;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Alterar Endereço',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                children: [
                  _SearchField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                  ),
                  const SizedBox(height: 22),
                  _ActionTile(
                    icon: Icons.gps_fixed_rounded,
                    title: 'Usar localização atual',
                    subtitle:
                        currentAddress?.formattedAddress.isNotEmpty == true
                            ? currentAddress!.formattedAddress
                            : 'Ative o GPS para precisão',
                    isLoading: _loadingLocation,
                    onTap: _useCurrentLocation,
                  ),
                  const SizedBox(height: 16),
                  _MapCard(
                    address: _selectedAddress?.formattedAddress,
                    selected: _selectedLatLng,
                    camera:
                        _selectedLatLng != null
                            ? CameraPosition(target: _selectedLatLng!, zoom: 15)
                            : _spCamera,
                    onMapReady: (c) {
                      if (!_mapController.isCompleted) {
                        _mapController.complete(c);
                      }
                    },
                    onTap:
                        (point) => _applySelectedLocation(
                          point,
                          label: 'Selecionado no mapa',
                        ),
                  ),
                  if (_searchController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Text(
                      'Resultados da busca',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_loadingSearch)
                      const Center(child: CircularProgressIndicator())
                    else if (_results.isEmpty)
                      const Text(
                        'Nenhum endereço encontrado.',
                        style: TextStyle(color: Colors.white70),
                      )
                    else
                      ..._results.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _RecentAddressTile(
                            item: item,
                            selected: _isSameAddress(item, _selectedAddress),
                            onTap: () => _selectAddress(item),
                          ),
                        ),
                      ),
                  ] else ...[
                    const SizedBox(height: 28),
                    const Text(
                      'Endereços recentes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_loadingHistory)
                      const Center(child: CircularProgressIndicator())
                    else if (_history.isEmpty)
                      const Text(
                        'Nenhum endereço recente encontrado.',
                        style: TextStyle(color: Colors.white70),
                      )
                    else
                      ..._history.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _RecentAddressTile(
                            item: item,
                            selected: _isSameAddress(item, _selectedAddress),
                            onTap: () => _selectAddress(item),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton.icon(
                  onPressed: state.isUpdating ? null : _confirmAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 8,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  icon:
                      state.isUpdating
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.place_outlined),
                  label: const Text(
                    'Confirmar no Mapa',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadHistory() async {
    try {
      final history =
          await ref
              .read(profileControllerProvider.notifier)
              .getAddressHistory();
      if (!mounted) return;
      setState(() {
        _history = history;
        _loadingHistory = false;
        _selectedAddress ??= history.isNotEmpty ? history.first : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingHistory = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final query = value.trim();
      if (!mounted) return;
      if (query.length < 3) {
        setState(() {
          _results = const [];
          _loadingSearch = false;
        });
        return;
      }
      setState(() => _loadingSearch = true);
      try {
        final results = await ref
            .read(profileControllerProvider.notifier)
            .searchAddresses(query);
        if (!mounted) return;
        setState(() {
          _results = results;
          _loadingSearch = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _results = const [];
          _loadingSearch = false;
        });
      }
    });
  }

  Future<void> _confirmAddress() async {
    if (_selectedAddress == null) {
      _showInfo('Selecione um endereco antes de confirmar.');
      return;
    }
    final success = await ref
        .read(profileControllerProvider.notifier)
        .updateAddress(_selectedAddress!);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(_selectedAddress!.formattedAddress);
      return;
    }
    _showInfo(
      ref.read(profileControllerProvider).error ?? 'Falha ao salvar endereco.',
    );
  }

  bool _isSameAddress(DriverProfileAddress item, DriverProfileAddress? other) {
    if (other == null) return false;
    if (item.id != null && other.id != null) return item.id == other.id;
    return item.formattedAddress == other.formattedAddress;
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Buscar novo endereço...',
        hintStyle: const TextStyle(
          color: _ProfileEditAddressScreenState._muted,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: _ProfileEditAddressScreenState._primary,
          size: 30,
        ),
        filled: true,
        fillColor: _ProfileEditAddressScreenState._card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: _ProfileEditAddressScreenState._border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: _ProfileEditAddressScreenState._border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: _ProfileEditAddressScreenState._primary,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        isDense: true,
        alignLabelWithHint: true,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            height: 74,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF36162D), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _StaticMap(
                    camera: _ProfileEditAddressScreenState._spCamera,
                    darkOverlay: true,
                    marker: null,
                    onTap: null,
                    onMapReady: (_) {},
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xCC0D0C18), Color(0x990D0C18)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD62D86), Color(0xFFED5AA9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withValues(alpha: 0.36),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ProfileEditAddressScreenState._muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white70,
                          ),
                        )
                      else
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white70,
                          size: 26,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.onTap,
    this.address,
    required this.camera,
    required this.onMapReady,
    this.selected,
  });

  final ValueChanged<LatLng> onTap;
  final String? address;
  final CameraPosition camera;
  final void Function(GoogleMapController) onMapReady;
  final LatLng? selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        height: 126,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF36162D)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _StaticMap(
                  camera: camera,
                  marker: selected,
                  onTap: onTap,
                  onMapReady: onMapReady,
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: _MapPainter())),
              const Center(
                child: Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF0E9EAF),
                  size: 62,
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.map_outlined, color: Color(0xFFD62D86)),
                        SizedBox(width: 8),
                        Text(
                          'Selecionar no mapa',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (address != null && address!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        address!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentAddressTile extends StatelessWidget {
  const _RecentAddressTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final DriverProfileAddress item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon =
        item.label?.toLowerCase() == 'casa'
            ? Icons.home_filled
            : item.label?.toLowerCase() == 'trabalho'
            ? Icons.work_rounded
            : Icons.history_rounded;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: _ProfileEditAddressScreenState._panel,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _ProfileEditAddressScreenState._border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white70, size: 30),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: _ProfileEditAddressScreenState._muted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    selected
                        ? _ProfileEditAddressScreenState._primary
                        : Colors.white24,
                width: 2,
              ),
            ),
            child: Icon(
              selected ? Icons.add : Icons.star_border_rounded,
              color:
                  selected
                      ? _ProfileEditAddressScreenState._primary
                      : Colors.white54,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint =
        Paint()
          ..color = const Color(0x332C3B5B)
          ..strokeWidth = 3;
    final dashPaint =
        Paint()
          ..color = const Color(0x660E9EAF)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;

    final path1 =
        Path()
          ..moveTo(10, size.height * 0.15)
          ..lineTo(size.width * 0.35, size.height * 0.05)
          ..lineTo(size.width * 0.55, size.height * 0.22)
          ..lineTo(size.width * 0.92, size.height * 0.12);
    final path2 =
        Path()
          ..moveTo(0, size.height * 0.55)
          ..lineTo(size.width * 0.28, size.height * 0.42)
          ..lineTo(size.width * 0.52, size.height * 0.62)
          ..lineTo(size.width, size.height * 0.48);
    final path3 =
        Path()
          ..moveTo(size.width * 0.1, size.height)
          ..lineTo(size.width * 0.3, size.height * 0.78)
          ..lineTo(size.width * 0.56, size.height * 0.92)
          ..lineTo(size.width * 0.8, size.height * 0.7);

    canvas.drawPath(path1, linePaint);
    canvas.drawPath(path2, linePaint);
    canvas.drawPath(path3, linePaint);

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 58, dashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StaticMap extends StatelessWidget {
  const _StaticMap({
    required this.camera,
    this.darkOverlay = false,
    this.marker,
    this.onTap,
    required this.onMapReady,
  });

  final CameraPosition camera;
  final bool darkOverlay;
  final LatLng? marker;
  final ValueChanged<LatLng>? onTap;
  final void Function(GoogleMapController) onMapReady;

  @override
  Widget build(BuildContext context) {
    final interactive = onTap != null;
    final markers =
        marker != null
            ? {Marker(markerId: const MarkerId('selected'), position: marker!)}
            : <Marker>{};

    return Stack(
      fit: StackFit.expand,
      children: [
        GoogleMap(
          initialCameraPosition:
              marker != null
                  ? CameraPosition(target: marker!, zoom: camera.zoom)
                  : camera,
          markers: markers,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          compassEnabled: false,
          rotateGesturesEnabled: interactive,
          scrollGesturesEnabled: interactive,
          tiltGesturesEnabled: false,
          zoomGesturesEnabled: interactive,
          liteModeEnabled: !interactive,
          buildingsEnabled: false,
          onMapCreated: onMapReady,
          onTap: onTap,
        ),
        if (darkOverlay)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
