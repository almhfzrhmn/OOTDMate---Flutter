import 'package:flutter/material.dart';
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
      _shuffleIndex = 0;
    });
  }

  /// Shuffle: Ganti ke kombinasi Top-K berikutnya (INSTAN, tanpa API call)
  void _shuffle() {
    setState(() {
      _shuffleIndex++;
    });
  }

  /// Simpan outfit saat ini ke backend
  Future<void> _saveOutfit() async {
    if (_result == null || _selectedAnchor == null) return;

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
      await _recommendService.saveOutfit(itemIds: itemIds);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Outfit saved! ✨")),
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
                child: Image.network(
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
                onPressed: _saveOutfit,
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

  const _OutfitItemCard({
    required this.imageUrl,
    required this.category,
    this.name,
    this.similarityScore,
    required this.isAnchor,
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
          // Gambar
          Expanded(
            child: Image.network(
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