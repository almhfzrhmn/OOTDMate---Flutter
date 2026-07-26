import "dart:io";
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ootdmate_frontend/services/api-services/wardrobe_item_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _image;
  bool _isUploading = false;

  final ImagePicker _imagePicker = ImagePicker();
  final WardrobeItemService _wardrobeService = WardrobeItemService();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error while trying to pick images : $e");
      }
    }
  }

  // FUNGSI UNTUK UPLOAD KE BACKEND OOTDMATE
  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final result = await _wardrobeService.uploadWardrobeItems(
        imageFile: _image!,
        
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil menyimpan ke lemari! Kategori: ${result.category}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitur Kamera & Galeri'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Menampilkan Gambar yang dipilih
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Text('Belum ada gambar yang dipilih'),
                      ),
              ),
              const SizedBox(height: 30),

              // Jika sedang upload, tampilkan Loading
              if (_isUploading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Sedang menganalisis pakaian dengan ML...'),
                  ],
                )
              else ...[
                // Tombol Buka Kamera
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Buka Kamera'),
                ),
                const SizedBox(height: 10),

                // Tombol Buka Galeri
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Buka Galeri'),
                ),
                const SizedBox(height: 25),

                // Tombol UPLOAD munucl jika gambar sudah dipilih
                if (_image != null)
                  ElevatedButton.icon(
                    onPressed: _uploadImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text(
                      'Simpan & Analisis Pakaian',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}