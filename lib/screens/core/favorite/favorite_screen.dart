import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';
import 'package:ootdmate_frontend/models/saved_outfit_model.dart';
import 'package:ootdmate_frontend/services/api-services/recommendation_service.dart';

// ─────────────────────────────────────────────
// FAVORITE SCREEN — Saved OOTD Outfits (Redesigned)
//
// Layar premium untuk mengelola kombinasi OOTD tersimpan.
// Fitur:
// - List outfit tersimpan dari GET /api/v1/outfits
// - Pull-to-refresh untuk memperbarui daftar
// - Hapus outfit dengan dialog konfirmasi via DELETE /api/v1/outfits/{id}
// - Compatibility score + notes display
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20), 
            ),
            const SizedBox(width: 12),
            Text(
              "Hapus Outfit?",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          "Kombinasi OOTD ini akan dihapus dari daftar favorit Anda secara permanen.",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Batal",
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Hapus",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
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
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 10),
              Text(
                'Outfit berhasil dihapus',
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
        title: Text(
          "Saved Outfits",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_savedOutfits.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.neonBlue.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_savedOutfits.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.neonBlue,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: () {
              setState(() => _isLoading = true);
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
      return _buildLoadingShimmer();
    }

    // ── Error ──
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.error.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wifi_off_rounded, size: 40, color: AppTheme.error.withAlpha(180)),
              ),
              const SizedBox(height: 20),
              Text(
                "Gagal memuat outfit",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Periksa koneksi internet Anda dan coba lagi.",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadSavedOutfits();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  "Coba Lagi",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonBlue,
                  foregroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated icon area
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.glitchMagenta.withAlpha(20),
                          AppTheme.neonBlue.withAlpha(20),
                        ],
                      ),
                      border: Border.all(
                        color: AppTheme.glitchMagenta.withAlpha(40),
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      size: 44,
                      color: AppTheme.glitchMagenta,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    "No Saved Outfits Yet",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Head over to the OOTD Matcher and save your\nfavorite outfit combinations here.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.6,
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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

  /// Shimmer loading placeholder
  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.secondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.glitchMagenta,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET: Saved Outfit Card (Redesigned)
// Premium card untuk menampilkan 1 outfit tersimpan.
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withAlpha(8),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Date + Score + Delete ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              children: [
                // Date badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.neonBlue.withAlpha(12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppTheme.neonBlue,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        outfit.formattedDate.isNotEmpty
                            ? outfit.formattedDate
                            : "Saved",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.neonBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Compatibility score badge
                if (outfit.overallCompatibilityScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.acidGreen.withAlpha(12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 12,
                          color: AppTheme.acidGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(outfit.overallCompatibilityScore! * 100).toStringAsFixed(0)}% match',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.acidGreen,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Delete button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppTheme.error.withAlpha(180),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Notes (if any) ──
          if (outfit.notes?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withAlpha(60),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 14,
                      color: AppTheme.textSecondary.withAlpha(150),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        outfit.notes!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Horizontal List dari Item Pakaian ──
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 140,
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
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET: Outfit Item Tile (Redesigned)
// Premium miniature card untuk 1 pakaian di Saved Outfit.
// ─────────────────────────────────────────────

class _OutfitItemTile extends StatelessWidget {
  final SavedOutfitItemModel item;

  const _OutfitItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withAlpha(6),
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
                      child: const Icon(
                        Icons.broken_image_rounded,
                        size: 22,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  )
                : Container(
                    color: AppTheme.secondary,
                    child: const Icon(
                      Icons.checkroom_rounded,
                      size: 26,
                      color: AppTheme.textSecondary,
                    ),
                  ),
          ),

          // Label Kategori
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            color: AppTheme.secondary,
            child: Text(
              item.category,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.3,
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