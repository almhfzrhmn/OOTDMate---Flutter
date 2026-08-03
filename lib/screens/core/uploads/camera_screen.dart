import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';
import 'package:ootdmate_frontend/models/wardrobe_item_model.dart';
import 'package:ootdmate_frontend/services/api-services/wardrobe_item_service.dart';
import 'package:ootdmate_frontend/widgets/ui/clothing_guide_overlay.dart';
import 'package:ootdmate_frontend/widgets/ui/color_picker_field.dart';
import 'package:ootdmate_frontend/widgets/ui/glass_text_field.dart';
import 'package:ootdmate_frontend/widgets/ui/scan_animation_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Step-based upload flow:
/// 1. pickImage   — User memilih sumber gambar (kamera / galeri)
/// 2. reviewGuide — Preview gambar + panduan posisi pakaian
/// 3. scanning    — Animasi scanning + upload ke backend (POST)
/// 4. result      — Tampilkan hasil klasifikasi ML + form metadata + simpan (PUT)
enum UploadStep { pickImage, reviewGuide, scanning, result }

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // ─────────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────────
  UploadStep _currentStep = UploadStep.pickImage;
  File? _image;
  WardrobeItemModel? _classificationResult;
  bool _isSavingMetadata = false;
  String? _errorMessage;

  // Form metadata controllers
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedColor;

  // Services
  final ImagePicker _imagePicker = ImagePicker();
  final WardrobeItemService _wardrobeService = WardrobeItemService();

  // Minimum scan animation duration (2 detik)
  static const Duration _minScanDuration = Duration(seconds: 2);

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // IMAGE PICKING
  // ─────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _currentStep = UploadStep.reviewGuide;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error picking image: $e");
      }
      _showSnackBar('Gagal mengambil gambar', isError: true);
    }
  }

  // ─────────────────────────────────────────────
  // UPLOAD & ML CLASSIFICATION (Step 3)
  // ─────────────────────────────────────────────
  Future<void> _uploadAndClassify() async {
    if (_image == null) return;

    setState(() {
      _currentStep = UploadStep.scanning;
      _errorMessage = null;
    });

    try {
      // Jalankan upload dan timer minimum secara paralel
      final results = await Future.wait([
        _wardrobeService.uploadWardrobeItems(imageFile: _image!),
        Future.delayed(_minScanDuration),
      ]);

      final WardrobeItemModel result = results[0] as WardrobeItemModel;

      if (mounted) {
        setState(() {
          _classificationResult = result;
          _currentStep = UploadStep.result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _currentStep = UploadStep.reviewGuide; // Kembali ke review
        });
        _showSnackBar('Gagal menganalisis: $_errorMessage', isError: true);
      }
    }
  }

  // ─────────────────────────────────────────────
  // SAVE METADATA (Step 4)
  // ─────────────────────────────────────────────
  Future<void> _saveMetadata() async {
    if (_classificationResult == null) return;

    setState(() => _isSavingMetadata = true);

    try {
      final String name = _nameController.text.trim();
      final String brand = _brandController.text.trim();
      final String notes = _notesController.text.trim();

      // Hanya panggil PUT jika ada metadata yang diisi
      if (name.isNotEmpty ||
          brand.isNotEmpty ||
          _selectedColor != null ||
          notes.isNotEmpty) {
        await _wardrobeService.updateWardrobeItem(
          itemId: _classificationResult!.id,
          name: name.isNotEmpty ? name : null,
          brand: brand.isNotEmpty ? brand : null,
          color: _selectedColor,
          notes: notes.isNotEmpty ? notes : null,
        );
      }

      if (mounted) {
        _showSnackBar(
          'Berhasil disimpan! Kategori: ${_classificationResult!.category}',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Gagal menyimpan: ${e.toString().replaceAll("Exception: ", "")}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingMetadata = false);
      }
    }
  }

  // ─────────────────────────────────────────────
  // NAVIGATION HELPERS
  // ─────────────────────────────────────────────
  void _goBack() {
    setState(() {
      switch (_currentStep) {
        case UploadStep.reviewGuide:
          _image = null;
          _currentStep = UploadStep.pickImage;
          break;
        case UploadStep.result:
          // Dari result, kembali ke pick (karena item sudah tersimpan di backend)
          _resetAll();
          break;
        default:
          break;
      }
    });
  }

  void _resetAll() {
    _image = null;
    _classificationResult = null;
    _errorMessage = null;
    _nameController.clear();
    _brandController.clear();
    _notesController.clear();
    _selectedColor = null;
    _currentStep = UploadStep.pickImage;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? AppTheme.textPrimary : AppTheme.primary,
          ),
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.acidGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: _currentStep != UploadStep.scanning
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: _currentStep != UploadStep.pickImage
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20),
                      onPressed: _goBack,
                    )
                  : null,
              title: Text(
                _appBarTitle,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: false,
            )
          : null,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  String get _appBarTitle {
    switch (_currentStep) {
      case UploadStep.pickImage:
        return 'Add Items';
      case UploadStep.reviewGuide:
        return 'Review';
      case UploadStep.scanning:
        return '';
      case UploadStep.result:
        return 'Analyze Result';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case UploadStep.pickImage:
        return _buildPickImageStep();
      case UploadStep.reviewGuide:
        return _buildReviewGuideStep();
      case UploadStep.scanning:
        return _buildScanningStep();
      case UploadStep.result:
        return _buildResultStep();
    }
  }

  // ─────────────────────────────────────────────
  // STEP 1: PICK IMAGE
  // ─────────────────────────────────────────────
  Widget _buildPickImageStep() {
    return Center(
      key: const ValueKey('pickImage'),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: AppTheme.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: AppTheme.textPrimary,
                              shape: BoxShape.circle
                            ),
                            child: Icon(Icons.upload, color: AppTheme.surface, size: 34),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Upload Image",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0
                            ),
                          ),
                          Text(
                            "Max. file size : 10MB",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.camera_enhance,
                            label: "Camera",
                            color: AppTheme.acidGreen,
                            onTap: () => _pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.folder,
                            label: "Gallery",
                            color: AppTheme.cyberPurple,
                            onTap: () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(
                        minHeight: 200,
                        maxHeight: 260,
                      ),
                      alignment: Alignment.bottomCenter,
                      child: SvgPicture.asset(
                        'assets/images/bro.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface.withAlpha(50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withAlpha(40),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STEP 2: REVIEW + GUIDE OVERLAY
  // ─────────────────────────────────────────────
  Widget _buildReviewGuideStep() {
    return Center(
      key: const ValueKey('reviewGuide'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview dengan guide overlay
            Container(
              width: 280,
              height: 340,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.mediumGrey.withAlpha(60),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gambar
                    Image.file(
                      _image!,
                      fit: BoxFit.cover,
                    ),
                    // Guide overlay di atas gambar
                    const ClothingGuideOverlay(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info text
            Text(
              'Make sure the clothing is clearly visible within the area.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Ganti Foto
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _goBack,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Change Picture'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide(
                    color: AppTheme.mediumGrey.withAlpha(80),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Tombol Analisis
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploadAndClassify,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  'Analyze with AI',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.primary
                  )
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.acidGreen,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STEP 3: SCANNING ANIMATION
  // ─────────────────────────────────────────────
  Widget _buildScanningStep() {
    return Center(
      key: const ValueKey('scanning'),
      child: ScanAnimationWidget(
        imageWidget: Image.file(
          _image!,
          fit: BoxFit.cover,
        ),
        width: 280,
        height: 340,
        statusText: 'Menganalisis pakaian',
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STEP 4: RESULT + METADATA FORM
  // ─────────────────────────────────────────────
  Widget _buildResultStep() {
    final result = _classificationResult!;

    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── CLASSIFICATION RESULT CARD ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.acidGreen.withAlpha(40),
              ),
            ),
            child: Column(
              children: [
                // Image thumbnail kecil
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _image!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),

                // Success indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.success.withAlpha(30),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Analisis Selesai!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.glitchMagenta.withAlpha(30),
                        AppTheme.neonBlue.withAlpha(30),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppTheme.glitchMagenta.withAlpha(60),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _categoryIcon(result.category),
                        color: AppTheme.glitchMagenta,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        result.category,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Confidence bar
                _buildConfidenceBar(result.categoryConfidence ?? 0),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── METADATA FORM ──
          Text(
            'Detail Pakaian',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lengkapi informasi pakaian kamu (opsional)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Nama item
          GlassTextField(
            hintText: 'Nama Pakaian (cth: Jaket Denim)',
            prefixIcon: Icons.label_outline_rounded,
            controller: _nameController,
          ),
          const SizedBox(height: 12),

          // Brand
          GlassTextField(
            hintText: 'Brand (cth: Uniqlo, H&M)',
            prefixIcon: Icons.storefront_rounded,
            controller: _brandController,
          ),
          const SizedBox(height: 12),

          // Color picker
          ColorPickerField(
            selectedColor: _selectedColor,
            onColorSelected: (color) {
              setState(() => _selectedColor = color);
            },
          ),
          const SizedBox(height: 12),

          // Notes
          GlassTextField(
            hintText: 'Catatan (cth: Cocok untuk casual)',
            prefixIcon: Icons.notes_rounded,
            controller: _notesController,
          ),
          const SizedBox(height: 28),

          // ── SAVE BUTTON ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSavingMetadata ? null : _saveMetadata,
              icon: _isSavingMetadata
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 20),
              label: Text(
                _isSavingMetadata
                    ? 'Menyimpan...'
                    : 'Simpan ke Lemari',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.acidGreen,
                foregroundColor: AppTheme.primary,
                fixedSize: null,
                padding: const EdgeInsets.all(5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: AppTheme.acidGreen.withAlpha(100),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Skip metadata button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isSavingMetadata
                  ? null
                  : () {
                      _showSnackBar(
                        'Berhasil disimpan! Kategori: ${result.category}',
                      );
                      Navigator.pop(context, true);
                    },
              child: Text(
                'Lewati, simpan tanpa detail',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPER WIDGETS
  // ─────────────────────────────────────────────

  /// Confidence progress bar dengan gradient
  Widget _buildConfidenceBar(double confidence) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tingkat Keyakinan AI:  ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${(confidence * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: confidence >= 0.8
                    ? AppTheme.success
                    : confidence >= 0.5
                        ? AppTheme.acidGreen
                        : AppTheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: confidence,
            minHeight: 6,
            backgroundColor: AppTheme.mediumGrey.withAlpha(60),
            valueColor: AlwaysStoppedAnimation<Color>(
              confidence >= 0.8
                  ? AppTheme.success
                  : confidence >= 0.5
                      ? AppTheme.acidGreen
                      : AppTheme.error,
            ),
          ),
        ),
      ],
    );
  }

  /// Icon berdasarkan kategori ML
  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'topwear':
        return Icons.dry_cleaning_rounded;
      case 'bottomwear':
        return Icons.straighten_rounded;
      case 'footwear':
        return Icons.ice_skating_rounded;
      default:
        return Icons.checkroom_rounded;
    }
  }
}