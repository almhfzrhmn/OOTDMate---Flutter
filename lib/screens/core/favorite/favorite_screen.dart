import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';
import 'package:ootdmate_frontend/models/saved_outfit_model.dart';
import 'package:ootdmate_frontend/services/api-services/recommendation_service.dart';

// ─────────────────────────────────────────────
// FAVORITE SCREEN — Saved OOTD Outfits
//
// Layar untuk mengelola kombinasi OOTD yang disimpan pengguna.
// Fitur:
// - List outfit tersimpan dari GET /api/v1/outfits
// - Pull-to-refresh untuk memperbarui daftar
// - Hapus outfit dengan dialog konfirmasi via DELETE /api/v1/outfits/{id}
// - Empty state interaktif jika belum ada outfit
// ─────────────────────────────────────────────

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final RecommendationService _recommendationService = RecommendationService();

  List<SavedOutfitModel> _savedOutfits = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedOutfits();
  }

  /// Ambil daftar outfit tersimpan dari backend
  Future<void> _loadSavedOutfits() async {
    try {
      final outfits = await _recommendationService.getSavedOutfits();
      if (!mounted) return;
      setState(() {
        _savedOutfits = outfits;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// Hapus outfit dengan konfirmasi dialog
  Future<void> _confirmAndDeleteOutfit(SavedOutfitModel outfit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Outfit?"),
        content: const Text(
          "Kombinasi OOTD ini akan dihapus dari daftar favorit Anda.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Batal",
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _recommendationService.deleteSavedOutfit(outfit.id);
      if (!mounted) return;

      setState(() {
        _savedOutfits.removeWhere((o) => o.id == outfit.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Outfit berhasil dihapus ✨")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menghapus: $e"),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Outfits"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadSavedOutfits();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // ── Loading ──
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.glitchMagenta),
      );
    }

    // ── Error ──
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 48, color: AppTheme.error.withAlpha(150)),
            const SizedBox(height: 12),
            Text("Gagal memuat outfit tersimpan", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadSavedOutfits();
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Coba Lagi"),
            ),
          ],
        ),
      );
    }

    // ── Empty State ──
    if (_savedOutfits.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadSavedOutfits,
        color: AppTheme.glitchMagenta,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.glitchMagenta.withAlpha(20),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.glitchMagenta.withAlpha(60),
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 56,
                      color: AppTheme.glitchMagenta,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Belum Ada Outfit Tersimpan",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Simpan kombinasi OOTD favorit Anda dari fitur AI Matcher agar muncul di sini.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── List Outfits ──
    return RefreshIndicator(
      onRefresh: _loadSavedOutfits,
      color: AppTheme.glitchMagenta,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        itemCount: _savedOutfits.length,
        itemBuilder: (context, index) {
          final outfit = _savedOutfits[index];
          return _SavedOutfitCard(
            outfit: outfit,
            onDelete: () => _confirmAndDeleteOutfit(outfit),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET: Saved Outfit Card
// Kartu untuk menampilkan 1 kombinasi outfit tersimpan.
// ─────────────────────────────────────────────

class _SavedOutfitCard extends StatelessWidget {
  final SavedOutfitModel outfit;
  final VoidCallback onDelete;

  const _SavedOutfitCard({
    required this.outfit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.neonBlue.withAlpha(30),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Bar (Tanggal + Delete Button) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge Tanggal
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppTheme.neonBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      outfit.formattedDate.isNotEmpty
                          ? outfit.formattedDate
                          : "Saved Outfit",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.neonBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                // Tombol Hapus
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppTheme.error.withAlpha(200),
                  ),
                  onPressed: onDelete,
                  tooltip: "Hapus Outfit",
                ),
              ],
            ),
          ),

          // ── Catatan / Notes (jika ada) ──
          if (outfit.notes?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                outfit.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // ── Horizontal List dari Item Pakaian dalam Outfit ──
          SizedBox(
            height: 150,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              scrollDirection: Axis.horizontal,
              itemCount: outfit.items.length,
              itemBuilder: (context, index) {
                final item = outfit.items[index];
                return _OutfitItemTile(item: item);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET: Outfit Item Tile
// Miniature card untuk 1 pakaian di dalam Saved Outfit.
// ─────────────────────────────────────────────

class _OutfitItemTile extends StatelessWidget {
  final SavedOutfitItemModel item;

  const _OutfitItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withAlpha(10),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gambar
          Expanded(
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppTheme.secondary,
                      child: const Icon(Icons.broken_image, size: 24),
                    ),
                  )
                : Container(
                    color: AppTheme.secondary,
                    child: const Icon(Icons.checkroom, size: 28),
                  ),
          ),

          // Label Kategori
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            color: AppTheme.secondary,
            child: Text(
              item.category,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}