import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _kmController = TextEditingController();
  final _tankController = TextEditingController();
  String _fuelType = 'Benzin';
  File? _image;
  bool _saving = false;

  final List<String> _fuelTypes = ['Benzin', 'Dizel', 'LPG', 'Elektrik'];

  @override
  void dispose() {
    _nameController.dispose();
    _kmController.dispose();
    _tankController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Fotoğraf Seçin',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _optionTile(
                icon: Icons.camera_alt_rounded,
                title: 'Kamera',
                subtitle: 'Fotoğraf çek',
                color: AppTheme.accent,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              _optionTile(
                icon: Icons.photo_library_rounded,
                title: 'Galeri',
                subtitle: 'Galeriden seç',
                color: AppTheme.maintColor,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF292524) : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
                Text(subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _saveImage(File image) async {
    final dir = await getApplicationDocumentsDirectory();
    final vehicleImagesDir = Directory('${dir.path}/vehicle_images');
    if (!await vehicleImagesDir.exists()) {
      await vehicleImagesDir.create(recursive: true);
    }
    final fileName =
        'vehicle_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
    final savedImage = await image.copy('${vehicleImagesDir.path}/$fileName');
    return savedImage.path;
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      String? imagePath;
      if (_image != null) imagePath = await _saveImage(_image!);

      final vehicle = Vehicle(
        name: _nameController.text.trim(),
        currentKm: double.parse(_kmController.text.trim()),
        fuelType: _fuelType,
        tankCapacity: double.parse(_tankController.text.trim()),
        imagePath: imagePath,
      );

      await DatabaseHelper.instance.insertVehicle(vehicle);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${vehicle.name} başarıyla eklendi!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata oluştu: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded,
                        color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Yeni Araç Ekle',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image picker
                      GestureDetector(
                        onTap: _showImagePicker,
                        child: Container(
                          height: 190,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF292524) : AppTheme.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Theme.of(context).dividerColor, width: 1),
                            image: _image != null
                                ? DecorationImage(
                                    image: FileImage(_image!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _image == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentLight,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.add_a_photo_rounded,
                                        size: 28,
                                        color: AppTheme.accent,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Araç Fotoğrafı Ekle',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Kamera veya galeriden seçin',
                                      style: TextStyle(
                                        color: AppTheme.textHint,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section label
                      _sectionLabel('Araç Bilgileri'),
                      const SizedBox(height: 12),

                      // Vehicle Name
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        decoration: const InputDecoration(
                          labelText: 'Araç Adı',
                          prefixIcon: Icon(Icons.directions_car_rounded,
                              color: AppTheme.textHint),
                          hintText: 'Örn: Şahsi Arabam',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Araç adı gerekli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Current KM
                      TextFormField(
                        controller: _kmController,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Mevcut Kilometre',
                          prefixIcon:
                              Icon(Icons.speed_rounded, color: AppTheme.textHint),
                          suffixText: 'km',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Kilometre gerekli';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return 'Geçerli bir sayı girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Fuel Type
                      _sectionLabel('Yakıt Türü'),
                      const SizedBox(height: 12),
                      Row(
                        children: _fuelTypes.map((type) {
                          final isSelected = _fuelType == type;
                          final color = AppTheme.getFuelTypeColor(type);
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _fuelType = type),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 180),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withValues(alpha: 0.1)
                                        : AppTheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : AppTheme.borderSubtle,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        AppTheme.getFuelTypeIcon(type),
                                        color: isSelected
                                            ? color
                                            : AppTheme.textHint,
                                        size: 20,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        type,
                                        style: TextStyle(
                                          color: isSelected
                                              ? color
                                              : AppTheme.textSecondary,
                                          fontSize: 10,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Tank Capacity
                      _sectionLabel('Depo Kapasitesi'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tankController,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Depo Kapasitesi',
                          prefixIcon: const Icon(
                              Icons.local_gas_station_rounded,
                              color: AppTheme.textHint),
                          suffixText:
                              _fuelType == 'Elektrik' ? 'kWh' : 'L',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Depo kapasitesi gerekli';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return 'Geçerli bir sayı girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveVehicle,
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text('Aracı Kaydet'),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );
  }
}
