import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';
import 'package:ootdmate_frontend/models/recommendation_history_model.dart';
import 'package:ootdmate_frontend/services/api-services/history_service.dart';

// ─────────────────────────────────────────────
// HISTORY SCREEN — Recommendation Interaction Log
//
// Menampilkan riwayat interaksi pengguna dengan outfit recommendation.
// Fitur:
// - List history dari GET /api/v1/histories
// - Pull-to-refresh
// - Swipe-to-delete
// - Badge interaksi (Saved, Viewed, Applied, dll.)
// ─────────────────────────────────────────────

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();

  List<RecommendationHistoryModel> _histories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistories();
  }

  Future<void> _loadHistories() async {
    try {
      final histories = await _historyService.getHistories();
      if (!mounted) return;
      setState(() {
        _histories = histories;
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

  Future<void> _deleteHistory(RecommendationHistoryModel history) async {
    try {
      await _historyService.deleteHistory(history.id);
      if (!mounted) return;
      setState(() {
        _histories.removeWhere((h) => h.id == history.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Riwayat dihapus',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.primary),
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
          content: Text('Gagal menghapus: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.surface.withAlpha(80),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppTheme.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Outfit History",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  // Badge jumlah
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.neonBlue.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.neonBlue.withAlpha(50),
                      ),
                    ),
                    child: Text(
                      "${_histories.length}",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.neonBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.acidGreen,
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _histories.isEmpty
                          ? _buildEmptyState()
                          : _buildHistoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppTheme.error.withAlpha(180),
          ),
          const SizedBox(height: 16),
          Text(
            "Gagal memuat riwayat",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _loadHistories();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(
              "Coba Lagi",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.acidGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.neonBlue.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 40,
                color: AppTheme.neonBlue.withAlpha(180),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Belum Ada Riwayat",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Riwayat interaksi Anda dengan rekomendasi outfit akan muncul di sini.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
      color: AppTheme.acidGreen,
      backgroundColor: AppTheme.secondary,
      onRefresh: _loadHistories,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _histories.length,
        itemBuilder: (context, index) {
          final history = _histories[index];
          return Dismissible(
            key: Key(history.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.error,
              ),
            ),
            onDismissed: (_) => _deleteHistory(history),
            child: _HistoryCard(history: history),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET: History Card
// ─────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final RecommendationHistoryModel history;

  const _HistoryCard({required this.history});

  /// Warna badge berdasarkan tipe interaksi
  Color _badgeColor() {
    switch (history.interactionType) {
      case 'saved':
        return AppTheme.acidGreen;
      case 'viewed':
        return AppTheme.neonBlue;
      case 'applied':
        return AppTheme.success;
      case 'favorited':
        return AppTheme.glitchMagenta;
      case 'ignored':
        return AppTheme.textSecondary;
      default:
        return AppTheme.surface;
    }
  }

  /// Icon badge berdasarkan tipe interaksi
  IconData _badgeIcon() {
    switch (history.interactionType) {
      case 'saved':
        return Icons.bookmark_rounded;
      case 'viewed':
        return Icons.visibility_rounded;
      case 'applied':
        return Icons.checkroom_rounded;
      case 'favorited':
        return Icons.favorite_rounded;
      case 'ignored':
        return Icons.swipe_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _badgeColor();
    final items = history.outfit?.items ?? [];
    final score = history.outfit?.overallCompatibilityScore;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.surface.withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Badge + Tanggal ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                // Badge interaksi
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: badgeColor.withAlpha(60),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_badgeIcon(), size: 14, color: badgeColor),
                      const SizedBox(width: 6),
                      Text(
                        history.interactionLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Skor kompatibilitas
                if (score != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.acidGreen.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${(score * 100).toStringAsFixed(0)}%",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.acidGreen,
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                // Timestamp
                Text(
                  "${history.formattedDate} • ${history.formattedTime}",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Outfit Item Thumbnails ──
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      width: 64,
                      height: 64,
                      margin: EdgeInsets.only(
                        right: index < items.length - 1 ? 10 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withAlpha(80),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.surface.withAlpha(60),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: item.imageUrl.isNotEmpty
                            ? Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 24,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.checkroom,
                                    color: AppTheme.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.category,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 8,
                                      color: AppTheme.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Text(
                "Data outfit tidak tersedia",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textSecondary.withAlpha(120),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
