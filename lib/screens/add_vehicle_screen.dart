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
    final pickedFile = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Fotoğraf Seçin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  )),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppTheme.accentBlue),
                ),
                title: const Text('Kamera',
                    style: TextStyle(color: AppTheme.textPrimary)),
                subtitle: const Text('Fotoğraf çek',
                    style: TextStyle(color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppTheme.accentGreen),
                ),
                title: const Text('Galeri',
                    style: TextStyle(color: AppTheme.textPrimary)),
                subtitle: const Text('Galeriden seç',
                    style: TextStyle(color: AppTheme.textSecondary)),
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
      if (_image != null) {
        imagePath = await _saveImage(_image!);
      }

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
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.accentGreen, size: 20),
                const SizedBox(width: 8),
                Text('${vehicle.name} başarıyla eklendi!'),
              ],
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Yeni Araç Ekle',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
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
                            height: 200,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceOverlay,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.dividerColor.withOpacity(0.5),
                              ),
                              image: _image != null
                                  ? DecorationImage(
                                      image: FileImage(_image!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _image == null
                                ? Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.accentBlue
                                              .withValues(alpha: 0.1),
                                        ),
                                        child: const Icon(
                                          Icons.add_a_photo_rounded,
                                          size: 36,
                                          color: AppTheme.accentBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Araç Fotoğrafı Ekle',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
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
                        // Vehicle Name
                        TextFormField(
                          controller: _nameController,
                          style:
                              const TextStyle(color: AppTheme.textPrimary),
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
                        const SizedBox(height: 16),
                        // Current KM
                        TextFormField(
                          controller: _kmController,
                          style:
                              const TextStyle(color: AppTheme.textPrimary),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Mevcut Kilometre',
                            prefixIcon: Icon(Icons.speed_rounded,
                                color: AppTheme.textHint),
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
                        const SizedBox(height: 16),
                        // Fuel Type Selector
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                'Yakıt Türü',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Row(
                              children: _fuelTypes.map((type) {
                                final isSelected = _fuelType == type;
                                final color =
                                    AppTheme.getFuelTypeColor(type);
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _fuelType = type),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? color.withValues(alpha: 0.2)
                                              : AppTheme.surfaceOverlay,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? color
                                                : AppTheme.dividerColor
                                                    .withValues(alpha: 0.5),
                                            width:
                                                isSelected ? 1.5 : 0.5,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              AppTheme.getFuelTypeIcon(
                                                  type),
                                              color: isSelected
                                                  ? color
                                                  : AppTheme.textHint,
                                              size: 22,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              type,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? color
                                                    : AppTheme
                                                        .textSecondary,
                                                fontSize: 11,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
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
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Tank Capacity
                        TextFormField(
                          controller: _tankController,
                          style:
                              const TextStyle(color: AppTheme.textPrimary),
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
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppTheme.primaryDark,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_rounded, size: 22),
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
      ),
    );
  }
}
