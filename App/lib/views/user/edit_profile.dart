import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../helpers/media_helper.dart';
import '../../utils/text/person_name_formatter.dart';
import '../../ui/themes/colors.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../widgets/user/email_change_dialog.dart';
import '../../helpers/error_message_helper.dart';
import '../../components/utils.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class EditProfile extends StatefulWidget {
  final bool forced;

  const EditProfile({super.key, this.forced = false});

  @override
  State<EditProfile> createState() => _EditInlineProfileScreenState();
}

class _EditInlineProfileScreenState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  UserModel? _user;
  bool _loading = true;
  File? _compressedImage;
  LatLng? _selectedLatLng;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController addressController;
  late TextEditingController phoneController;
  late TextEditingController idCardController;

  @override
  void initState() {
    super.initState();
    _loadUser().then((_) => _getCurrentLocation());
  }

  Future<void> _getCurrentLocation() async {
    if (_selectedLatLng != null) return;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final current = LatLng(position.latitude, position.longitude);

      await _selectLocation(current, showAddressError: false);
      if (!mounted) return;

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(current, 15),
      );
    } catch (_) {
      // El usuario todavía puede elegir manualmente un punto en el mapa.
    }
  }

  Future<void> _loadUser() async {
    final userProvider = context.read<UserProvider>();
    final authService = userProvider.authService;

    final user = await authService.getCurrentUser();

    if (user != null) {
      _user = user;
      usernameController = TextEditingController(text: user.username);
      emailController = TextEditingController(text: user.email);
      firstNameController = TextEditingController(
        text: normalizePersonName(user.firstName ?? ''),
      );
      lastNameController = TextEditingController(
        text: normalizePersonName(user.lastName ?? ''),
      );
      addressController = TextEditingController(text: user.address);
      phoneController = TextEditingController(text: user.phone);
      idCardController = TextEditingController(text: user.ci);

      if (user.latitude != null && user.longitude != null) {
        _selectedLatLng = LatLng(user.latitude!, user.longitude!);
        _markers = {
          Marker(
            markerId: const MarkerId('selected'),
            position: _selectedLatLng!,
          )
        };
      }
    }

    setState(() => _loading = false);
  }

  Future<void> _saveChanges() async {
    if (_selectedLatLng == null) {
      showSnackbar('Selecciona tu ubicación en el mapa');
      return;
    }

    if (!_formKey.currentState!.validate() || _user == null) return;

    final userProvider = context.read<UserProvider>();
    final authService = userProvider.authService;
    final navigator = Navigator.of(context);

    final userService = UserService(authService);

    final firstName = normalizePersonName(firstNameController.text);
    final lastName = normalizePersonName(lastNameController.text);
    firstNameController.text = firstName;
    lastNameController.text = lastName;

    final updates = <String, dynamic>{
      'username': usernameController.text.trim(),
      'email': emailController.text.trim(),
      'first_name': firstName,
      'last_name': lastName,
      'address': addressController.text.trim(),
      'phone': phoneController.text.trim(),
      'ci': idCardController.text.trim(),
      'location': {
        'latitude': _selectedLatLng!.latitude,
        'longitude': _selectedLatLng!.longitude,
      },
    };

    try {
      // 🔥 1. Subir imagen si hay (pero usando MEDIA)
      final newEmail = emailController.text.trim().toLowerCase();
      if (newEmail != _user!.email.toLowerCase()) {
        final verified = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) =>
                EmailChangeDialog(auth: authService, email: newEmail));
        if (verified != true || !mounted) return;
      }
      if (_compressedImage != null) {
        await userService.uploadProfilePicture(_compressedImage!);
      }

      // 🔥 2. Actualizar usuario
      await userService.updateMe(updates);

      // 🔥 3. Refrescar usuario correctamente (SIN token manual)
      final refreshedUser = await authService.getCurrentUser();
      if (refreshedUser == null) return;

      if (!mounted) return;

      // 🔥 4. Actualizar provider
      userProvider.updateLocally(refreshedUser);

      showSnackbar('Datos actualizados');

      if (widget.forced) {
        navigator.pushReplacementNamed('/home');
      } else {
        navigator.pop(refreshedUser);
      }
    } catch (e) {
      if (!mounted) return;

      showSnackbar(userFacingError(e));
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null && _user != null) {
      try {
        File original = File(picked.path);
        File compressed = await compressImage(original);
        setState(() {
          _compressedImage = compressed;
        });
      } catch (e) {
        showSnackbar('Error al procesar la imagen');
      }
    }
  }

  Future<void> _selectLocation(
    LatLng latLng, {
    bool showAddressError = true,
  }) async {
    if (!mounted) return;

    setState(() {
      _selectedLatLng = latLng;
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: latLng,
        )
      };
    });

    try {
      final placemarks =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final addressParts = <String?>[
          place.street,
          place.locality,
          place.administrativeArea,
          place.country,
        ]
            .whereType<String>()
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toSet()
            .toList();

        if (!mounted) return;
        setState(() {
          addressController.text = addressParts.isNotEmpty
              ? addressParts.join(', ')
              : '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
        });
      } else if (mounted) {
        _setCoordinateAddress(latLng);
      }
    } catch (_) {
      if (mounted) {
        _setCoordinateAddress(latLng);
      }
      if (showAddressError) {
        showSnackbar('No se pudo obtener la dirección');
      }
    }
  }

  void _setCoordinateAddress(LatLng latLng) {
    setState(() {
      addressController.text =
          '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
    });
  }

  ImageProvider<Object> getProfileImage() {
    if (_compressedImage != null) {
      return FileImage(_compressedImage!);
    }

    final imageUrl = MediaHelper.getPrimaryUrl(_user?.media ?? []);

    if (imageUrl != null) {
      return NetworkImage(imageUrl);
    }

    return const AssetImage('assets/icons/defaultUser.jpg');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: const CustomAppBar(title: 'Editar Perfil'),
      body: _loading
          ? const AppLoader(message: 'Cargando perfil...')
          : Container(
              color: AppColors.pureWhite,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 10),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 30, horizontal: 20),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.grey.shade300, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundImage: getProfileImage(),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 4,
                                    child: InkWell(
                                      onTap: _pickAndUploadImage,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.darkBlue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                        padding: const EdgeInsets.all(6),
                                        child: const Icon(Icons.edit,
                                            size: 18, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '${_user!.firstName ?? ''} ${_user!.lastName ?? ''}'
                                      .trim()
                                      .isEmpty
                                  ? _user!.username
                                  : '${_user!.firstName} ${_user!.lastName}',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _user?.email ?? '',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 25),
                            _editableField(
                              Icons.person_outline,
                              'Usuario',
                              usernameController,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Campo obligatorio'
                                  : null,
                            ),
                            _divider(),
                            _editableField(
                              Icons.email,
                              'Email',
                              emailController,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Campo obligatorio';
                                }
                                final emailRegex =
                                    RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                if (!emailRegex.hasMatch(v.trim())) {
                                  return 'Email inválido';
                                }
                                return null;
                              },
                            ),
                            _divider(),
                            _editableField(
                              Icons.badge,
                              'Nombre',
                              firstNameController,
                              textCapitalization: TextCapitalization.words,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Campo obligatorio'
                                  : null,
                            ),
                            _divider(),
                            _editableField(
                              Icons.family_restroom,
                              'Apellido',
                              lastNameController,
                              textCapitalization: TextCapitalization.words,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Campo obligatorio'
                                  : null,
                            ),
                            _divider(),
                            _editableField(
                              Icons.location_on_outlined,
                              'Dirección',
                              addressController,
                              readOnly: true,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Selecciona la ubicación en el mapa'
                                  : null,
                            ),
                            SizedBox(
                              height: 250,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: _selectedLatLng ??
                                          const LatLng(-17.391203011521863,
                                              -66.17961807095989),
                                      zoom: 12,
                                    ),
                                    onMapCreated: (controller) async {
                                      _mapController = controller;
                                      if (_selectedLatLng != null) {
                                        _mapController!.animateCamera(
                                          CameraUpdate.newLatLngZoom(
                                            _selectedLatLng!,
                                            15,
                                          ),
                                        );
                                      } else {
                                        await _getCurrentLocation();
                                      }
                                    },
                                    onTap: _selectLocation,
                                    markers: _markers,
                                    myLocationEnabled: true,
                                    myLocationButtonEnabled: true,
                                    zoomControlsEnabled: true,
                                    scrollGesturesEnabled: true,
                                    zoomGesturesEnabled: true,
                                    rotateGesturesEnabled: true,
                                    tiltGesturesEnabled: true,
                                    gestureRecognizers: <Factory<
                                        OneSequenceGestureRecognizer>>{
                                      Factory<OneSequenceGestureRecognizer>(
                                        () => EagerGestureRecognizer(),
                                      ),
                                    }),
                              ),
                            ),
                            _divider(),
                            _editableField(
                              Icons.phone,
                              'Teléfono',
                              phoneController,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Campo obligatorio'
                                  : null,
                            ),
                            _divider(),
                            _editableField(
                              Icons.credit_card,
                              'DNI / ID',
                              idCardController,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Campo obligatorio'
                                  : null,
                            ),
                            const SizedBox(height: 30),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _saveChanges,
                                    icon: const Icon(Icons.save,
                                        color: AppColors.pureWhite),
                                    label: const Text('Guardar',
                                        style: TextStyle(
                                            color: AppColors.pureWhite)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.darkBlue,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.cancel,
                                        color: AppColors.darkBlue),
                                    label: const Text('Cancelar',
                                        style: TextStyle(
                                            color: AppColors.darkBlue)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
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

  Widget _editableField(
    IconData icon,
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueGrey),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            textCapitalization: textCapitalization,
            validator: validator,
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, color: Colors.grey),
    );
  }
}
