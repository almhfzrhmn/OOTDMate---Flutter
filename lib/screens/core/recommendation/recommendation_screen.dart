import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';
import 'package:ootdmate_frontend/models/wardrobe_item_model.dart';
import 'package:ootdmate_frontend/models/recommendation_model.dart';
import 'package:ootdmate_frontend/services/api-services/wardrobe_item_service.dart';
import 'package:ootdmate_frontend/services/api-services/recommendation_service.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

// Enum untuk melacak state layar saat ini
enum _ScreenState { selectAnchor, loading, result }

class _RecommendationScreenState extends State<RecommendationScreen>
    with SingleTickerProviderStateMixin {
  // ── Services ──
  final WardrobeItemService _wardrobeService = WardrobeItemService();
  final RecommendationService _recommendService = RecommendationService();
  final ImagePicker _imagePicker = ImagePicker();

  // ── State ──
  _ScreenState _screenState = _ScreenState.selectAnchor;

  // State 1: Wardrobe items untuk dipilih
  List<WardrobeItemModel> _wardrobeItems = [];
  bool _isLoadingWardrobe = true;
  bool _isFetchingMoreWardrobe = false;
  String? _wardrobeError;
  int _currentPage = 1;
  final int _limit = 20;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  // State 3: Hasil rekomendasi
  RecommendationResponseModel? _result;
  WardrobeItemModel? _selectedAnchor; // Item yang dipilih user
  String? _resultError;

  // Upload-based recommendation state
  File? _uploadedImage;     // File gambar yang diupload (bukan dari wardrobe)
  bool _isFromUpload = false; // Apakah rekomendasi dari upload?

  // Shuffle: Index untuk cycling melalui Top-K
  // Saat shuffle, kita ganti item yang ditampilkan per kategori
  int _shuffleIndex = 0;

  // Animasi untuk loading state
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Setup animasi pulse untuk loading
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true); // Loop maju-mundur

    _scrollController.addListener(_onScroll);
    _loadWardrobeItems(refresh: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoadingWardrobe && !_isFetchingMoreWardrobe) {
        _loadWardrobeItems();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // DATA FETCHING
  // ─────────────────────────────────────────────

  /// Ambil semua item wardrobe user (untuk State 1: pilih anchor)
  Future<void> _loadWardrobeItems({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    setState(() {
      if (refresh) {
        _isLoadingWardrobe = true;
      } else {
        _isFetchingMoreWardrobe = true;
      }
      _wardrobeError = null;
    });

    try {
      final items = await _wardrobeService.getWardrobeItems(
        page: _currentPage,
        limit: _limit,
      );
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _wardrobeItems = items;
        } else {
          _wardrobeItems.addAll(items);
        }
        
        if (items.length < _limit) {
          _hasMore = false;
        } else {
          _currentPage++;
        }
        
        _isLoadingWardrobe = false;
        _isFetchingMoreWardrobe = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _isLoadingWardrobe = false;
          _wardrobeError = e.toString();
        } else {
          _isFetchingMoreWardrobe = false;
        }
      });
    }
  }

  /// Kirim item terpilih ke AI dan minta rekomendasi (State 1 → State 2 → State 3)
  Future<void> _requestRecommendation(WardrobeItemModel anchor) async {
    setState(() {
      _selectedAnchor = anchor;
      _screenState = _ScreenState.loading;
      _resultError = null;
      _shuffleIndex = 0;
    });

    try {
      final result = await _recommendService.getRecommendations(
        itemId: anchor.id,
        topK: 5, // Ambil 5 rekomendasi per kategori untuk Shuffle
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _screenState = _ScreenState.result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resultError = e.toString();
        _screenState = _ScreenState.result;
      });
    }
  }

  /// Kembali ke State 1 (pilih anchor baru)
  void _resetToSelection() {
    setState(() {
      _screenState = _ScreenState.selectAnchor;
      _result = null;
      _selectedAnchor = null;
      _uploadedImage = null;
      _isFromUpload = false;
      _shuffleIndex = 0;
    });
  }

  /// Shuffle: Ganti ke kombinasi Top-K berikutnya (INSTAN, tanpa API call)
  void _shuffle() {
    setState(() {
      _shuffleIndex++;
    });
  }

  // ─────────────────────────────────────────────
  // UPLOAD-BASED RECOMMENDATION
  // ─────────────────────────────────────────────

  /// Buka kamera/galeri lalu langsung minta rekomendasi dari foto baru.
  Future<void> _pickAndRecommend(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
        maxHeight: 1080,
      );
      if (pickedFile == null) return;

      final imageFile = File(pickedFile.path);
      await _requestRecommendationFromUpload(imageFile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil gambar: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  /// Kirim foto baru ke AI endpoint /recommend/from-upload.
  Future<void> _requestRecommendationFromUpload(File imageFile) async {
    setState(() {
      _uploadedImage = imageFile;
      _isFromUpload = true;
      _selectedAnchor = null; // Tidak ada anchor dari wardrobe
      _screenState = _ScreenState.loading;
      _resultError = null;
      _shuffleIndex = 0;
    });

    try {
      final result = await _recommendService.getRecommendationsFromUpload(
        imageFile: imageFile,
        topK: 5,
        saveToWardrobe: false,
      );
      if (!mounted) return;

      // Buat WardrobeItemModel sementara dari query_item response
      // agar UI card bisa render data anchor.
      final queryItem = result.queryItem;
      _selectedAnchor = WardrobeItemModel(
        id: queryItem.id ?? '',
        imageUrl: queryItem.imageUrl,
        category: queryItem.category,
        categoryConfidence: queryItem.confidence,
      );

      setState(() {
        _result = result;
        _screenState = _ScreenState.result;
      });

      // Tampilkan modal popup: "Simpan foto ini ke wardrobe?"
      _showSaveToWardrobeDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resultError = e.toString();
        _screenState = _ScreenState.result;
      });
    }
  }

  /// Modal popup yang menanyakan apakah user ingin menyimpan
  /// foto yang baru difoto ke wardrobe atau tidak.
  void _showSaveToWardrobeDialog() {
    if (!mounted || _uploadedImage == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.acidGreen.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.checkroom_rounded,
                color: AppTheme.acidGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Simpan ke Lemari?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview gambar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _uploadedImage!,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pakaian ini belum disimpan di lemari digital kamu. '
              'Ingin menyimpannya agar bisa dipakai untuk rekomendasi lain nanti?',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          // Tombol "Tidak"
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tidak, Lewati',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Tombol "Simpan"
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveUploadedItemToWardrobe();
            },
            icon: const Icon(Icons.save_rounded, size: 18),
            label: Text(
              'Simpan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.acidGreen,
              foregroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Simpan foto yang sudah diupload ke wardrobe via endpoint yang sama.
  /// Menggunakan WardrobeItemService.uploadWardrobeItems.
  Future<void> _saveUploadedItemToWardrobe() async {
    if (_uploadedImage == null) return;

    try {
      final savedItem = await _wardrobeService.uploadWardrobeItems(
        imageFile: _uploadedImage!,
      );
      if (!mounted) return;

      // Update anchor ID agar Save Outfit bisa menyertakan item ini
      setState(() {
        _selectedAnchor = WardrobeItemModel(
          id: savedItem.id,
          imageUrl: savedItem.imageUrl,
          category: savedItem.category,
          categoryConfidence: savedItem.categoryConfidence,
        );
        _isFromUpload = false; // Sudah ada di wardrobe sekarang
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tersimpan! Kategori: ${savedItem.category}',
            style: const TextStyle(color: AppTheme.primary),
          ),
          backgroundColor: AppTheme.acidGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  /// Hitung rata-rata compatibility score dari item rekomendasi yang ditampilkan
  double _calculateCompatibilityScore() {
    if (_result == null) return 0.0;
    double totalScore = 0;
    int count = 0;
    for (final category in _result!.categoryNames) {
      final items = _result!.recommendations[category]!;
      if (items.isNotEmpty) {
        final currentItem = items[_shuffleIndex % items.length];
        totalScore += currentItem.similarityScore;
        count++;
      }
    }
    return count > 0 ? totalScore / count : 0.0;
  }

  /// Tampilkan modal bottom sheet untuk memberi metadata sebelum menyimpan
  void _showSaveOutfitModal() {
    if (_result == null || _selectedAnchor == null) return;

    final compatibilityScore = _calculateCompatibilityScore();
    int personalRating = 0;
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.secondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    'Save This Outfit',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── System Compatibility Score ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withAlpha(80),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.acidGreen.withAlpha(30),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.acidGreen.withAlpha(20),
                            border: Border.all(
                              color: AppTheme.acidGreen.withAlpha(60),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${(compatibilityScore * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.acidGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Compatibility Score',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Based on style similarity analysis',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Personal Star Rating ──
                  Text(
                    'Your personal rating',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      final isSelected = starIndex <= personalRating;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            personalRating = starIndex;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AnimatedScale(
                            scale: isSelected ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: isSelected ? AppTheme.electricAmber : AppTheme.surface,
                              size: 36,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // ── Notes Field ──
                  Text(
                    'Notes (optional)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g., Perfect for weekend hangout...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.textSecondary.withAlpha(100),
                      ),
                      filled: true,
                      fillColor: AppTheme.surface.withAlpha(80),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Action Buttons ──
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: BorderSide(color: AppTheme.surface.withAlpha(150)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final notesText = notesController.text.trim();
                            Navigator.pop(ctx);
                            _performSaveOutfit(
                              notes: notesText.isNotEmpty ? notesText : null,
                              overallScore: compatibilityScore,
                            );
                          },
                          icon: const Icon(Icons.favorite_rounded, size: 18),
                          label: Text(
                            'Save Outfit',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.acidGreen,
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Simpan outfit saat ini ke backend (dipanggil dari modal)
  Future<void> _performSaveOutfit({
    String? notes,
    double? overallScore,
  }) async {
    if (_result == null || _selectedAnchor == null) return;

    // Jika anchor dari upload dan belum disimpan, simpan dulu
    if (_isFromUpload && _uploadedImage != null) {
      await _saveUploadedItemToWardrobe();
      // Jika masih _isFromUpload (gagal simpan), batalkan
      if (_isFromUpload) return;
    }

    // Kumpulkan ID semua item yang sedang ditampilkan
    final itemIds = <String>[];

    // Tambahkan anchor item
    if (_selectedAnchor!.id.isNotEmpty) {
      itemIds.add(_selectedAnchor!.id);
    }

    // Tambahkan item rekomendasi yang sedang ditampilkan (sesuai shuffle index)
    for (final category in _result!.categoryNames) {
      final items = _result!.recommendations[category]!;
      if (items.isNotEmpty) {
        final currentItem = items[_shuffleIndex % items.length];
        itemIds.add(currentItem.id);
      }
    }

    try {
      await _recommendService.saveOutfit(
        itemIds: itemIds,
        notes: notes,
        overallCompatibilityScore: overallScore,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                'Outfit saved to Favorites!',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.acidGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save: $e"),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  // BUILD (Router ke 3 state)
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _screenState == _ScreenState.result
              ? "AI Recommendation"
              : "OOTD Matcher",
        ),
        leading: _screenState != _ScreenState.selectAnchor
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _resetToSelection,
              )
            : null,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentState(),
        ),
      ),
    );
  }

  /// Pilih widget mana yang ditampilkan berdasarkan state
  Widget _buildCurrentState() {
    switch (_screenState) {
      case _ScreenState.selectAnchor:
        return _buildAnchorSelection();
      case _ScreenState.loading:
        return _buildLoadingState();
      case _ScreenState.result:
        return _buildResultState();
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // STATE 1: PILIH PAKAIAN ACUAN (ANCHOR)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildAnchorSelection() {
    // Loading
    if (_isLoadingWardrobe) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.glitchMagenta),
      );
    }

    // Error
    if (_wardrobeError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 48, color: AppTheme.error.withAlpha(150)),
            const SizedBox(height: 12),
            Text("Failed to load wardrobe", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                _loadWardrobeItems(refresh: true);
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    // Wardrobe kosong
    if (_wardrobeItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checkroom, size: 64, color: AppTheme.glitchMagenta.withAlpha(130)),
            const SizedBox(height: 12),
            Text("Your wardrobe is empty", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              "Add at least 2 items from different categories\nto get outfit recommendations.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            // Tetap tampilkan tombol scan meskipun wardrobe kosong
            _buildScanNewItemButton(),
          ],
        ),
      );
    }

    // Grid item wardrobe
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instruksi untuk user
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text(
            "Pick an item you want to wear today",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            "AI will find the best matching pieces from your wardrobe",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),

        // ── Tombol Scan New Item ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _buildScanNewItemButton(),
        ),

        Expanded(
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: _wardrobeItems.length,
                  itemBuilder: (context, index) {
                    final item = _wardrobeItems[index];
                    return _AnchorItemCard(
                      item: item,
                      onTap: () => _requestRecommendation(item),
                    );
                  },
                ),
              ),
              if (_isFetchingMoreWardrobe)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.glitchMagenta),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tombol "Scan New Item" — buka kamera/galeri untuk rekomendasi instan.
  Widget _buildScanNewItemButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.glitchMagenta.withAlpha(15),
            AppTheme.neonBlue.withAlpha(15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.glitchMagenta.withAlpha(40),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showImageSourceDialog(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.glitchMagenta.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: AppTheme.glitchMagenta,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan New Item',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Take a photo and get instant outfit recommendation',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dialog pilihan sumber gambar: Kamera atau Galeri.
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Sumber Gambar',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.acidGreen.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppTheme.acidGreen),
                ),
                title: Text('Kamera', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                subtitle: Text('Ambil foto langsung', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndRecommend(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.neonBlue.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppTheme.neonBlue),
                ),
                title: Text('Galeri', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                subtitle: Text('Pilih dari galeri', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndRecommend(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // STATE 2: LOADING (AI sedang bekerja)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gambar anchor item dengan efek pulse
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              // Scale: bergerak antara 0.95 dan 1.05
              final scale = 0.95 + (_pulseController.value * 0.1);
              // Opacity glow: bergerak antara 0.3 dan 0.8
              final glowOpacity = 0.3 + (_pulseController.value * 0.5);

              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonBlue.withAlpha((glowOpacity * 255).toInt()),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 160,
                height: 160,
                child: _isFromUpload && _uploadedImage != null
                    ? Image.file(
                        _uploadedImage!,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        _selectedAnchor?.imageUrl ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppTheme.surface,
                          child: const Icon(Icons.image, size: 48),
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Teks loading
          Text(
            "Scanning your wardrobe...",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.neonBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Finding the best match",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // STATE 3: HASIL REKOMENDASI (Outfit Grid)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildResultState() {
    // Error handling
    if (_resultError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.error.withAlpha(150)),
            const SizedBox(height: 12),
            Text("AI couldn't generate outfit", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _resultError!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _resetToSelection,
              icon: const Icon(Icons.arrow_back),
              label: const Text("Try Another"),
            ),
          ],
        ),
      );
    }

    if (_result == null || _result!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppTheme.textSecondary.withAlpha(100)),
            const SizedBox(height: 12),
            Text("No matching items found", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              "Try adding more items to your wardrobe\nfrom different categories.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _resetToSelection,
              icon: const Icon(Icons.arrow_back),
              label: const Text("Pick Another"),
            ),
          ],
        ),
      );
    }

    // ── Hitung rata-rata skor kecocokan dari item yang sedang ditampilkan ──
    double totalScore = 0;
    int count = 0;
    for (final category in _result!.categoryNames) {
      final items = _result!.recommendations[category]!;
      if (items.isNotEmpty) {
        final currentItem = items[_shuffleIndex % items.length];
        totalScore += currentItem.similarityScore;
        count++;
      }
    }
    final avgScore = count > 0 ? totalScore / count : 0.0;
    final scorePercent = (avgScore * 100).toStringAsFixed(0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // ── Compatibility Score Badge ──
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.acidGreen.withAlpha(20),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppTheme.acidGreen.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.acidGreen, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Tingkat Keserasian: $scorePercent%",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.acidGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Anchor Item (Pakaian Acuan) ──
        Text(
          "Your Pick",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: _OutfitItemCard(
            imageUrl: _selectedAnchor?.imageUrl ?? '',
            category: _selectedAnchor?.category ?? '',
            name: _selectedAnchor?.name,
            isAnchor: true, // Style berbeda untuk anchor
            localImageFile: _isFromUpload ? _uploadedImage : null,
          ),
        ),

        const SizedBox(height: 24),

        // ── Recommended Items ──
        Text(
          "AI RECOMMENDATION",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),

        // Grid rekomendasi (2 kolom jika ada 2+ kategori)
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _result!.categoryNames.map((category) {
            final items = _result!.recommendations[category]!;
            if (items.isEmpty) return const SizedBox.shrink();

            // Pilih item berdasarkan shuffle index (cycling)
            final currentItem = items[_shuffleIndex % items.length];

            return _OutfitItemCard(
              imageUrl: currentItem.imageUrl,
              category: currentItem.category,
              name: currentItem.name,
              similarityScore: currentItem.similarityScore,
              isAnchor: false,
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // ── Action Buttons ──
        Row(
          children: [
            // Shuffle Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shuffle,
                icon: const Icon(Icons.shuffle, size: 18),
                label: const Text("Shuffle"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.neonBlue,
                  side: BorderSide(color: AppTheme.neonBlue.withAlpha(80)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Save Outfit Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showSaveOutfitModal,
                icon: const Icon(Icons.favorite_border, size: 18),
                label: const Text("Save Outfit"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.acidGreen,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Try Another Button
        Center(
          child: TextButton.icon(
            onPressed: _resetToSelection,
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: const Text("Pick Another Item"),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET: Anchor Item Card (untuk State 1)
// Kartu item di grid pemilihan anchor.
// Saat di-tap, akan memulai proses rekomendasi AI.
// ─────────────────────────────────────────────

class _AnchorItemCard extends StatelessWidget {
  final WardrobeItemModel item;
  final VoidCallback onTap;

  const _AnchorItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gambar item
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Icon(Icons.broken_image, size: 40, color: AppTheme.error),
                      ),
                    ),
                  ),
                  // Overlay nama item di bawah gambar
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black45],
                        ),
                      ),
                      child: Text(
                        item.name?.isNotEmpty == true ? item.name! : 'Unnamed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Label kategori di bawah
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                item.category,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutfitItemCard extends StatelessWidget {
  final String imageUrl;
  final String category;
  final String? name;
  final double? similarityScore;
  final bool isAnchor;
  final File? localImageFile; // Untuk gambar dari upload lokal

  const _OutfitItemCard({
    required this.imageUrl,
    required this.category,
    this.name,
    this.similarityScore,
    required this.isAnchor,
    this.localImageFile,
  });

  @override
  Widget build(BuildContext context) {
    // Warna aksen berbeda untuk anchor vs rekomendasi
    final accentColor = isAnchor ? AppTheme.acidGreen : AppTheme.neonBlue;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withAlpha(isAnchor ? 60 : 30),
          width: isAnchor ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gambar (lokal atau network)
          Expanded(
            child: localImageFile != null
                ? Image.file(
                    localImageFile!,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppTheme.surface,
                      child: const Center(child: Icon(Icons.image, size: 40)),
                    ),
                  ),
          ),

          // Info bar di bawah gambar
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama item
                Text(
                  name?.isNotEmpty == true ? name! : category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Label kategori
                    Text(
                      category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    // Skor kecocokan (hanya untuk rekomendasi, bukan anchor)
                    if (!isAnchor && similarityScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${(similarityScore! * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}