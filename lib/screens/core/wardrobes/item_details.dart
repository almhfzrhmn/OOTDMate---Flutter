import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';
import 'package:ootdmate_frontend/models/wardrobe_item_model.dart';

class ItemDetailsScreen extends StatelessWidget {
  final WardrobeItemModel item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // Menilai apakah nilai AI Confidence tinggi (> 80%) atau sedang/rendah
    final isHighConfidence = (item.categoryConfidence ?? 0.0) >= 0.8;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      // ──────────────────────────────────────────────────────────────────────
      // 1. FIXED BOTTOM ACTION BAR (Seperti tombol 'Beli' di E-Commerce)
      // ──────────────────────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.secondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Tombol Edit/Delete (Opsi sekunder)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.lightGrey.withAlpha(40)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.textPrimary),
                  tooltip: "Edit Metadata",
                  onPressed: () {
                    // TODO: Akan dihubungkan ke fitur Edit/Delete pada step berikutnya
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Fitur Edit akan segera aktif!")),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Tombol Utama: AI Recommendations (OOTD Matcher)
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.acidGreen,
                    foregroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    // TODO: Pemicu untuk modul AI Recommendation (F-03.2 PRD)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.acidGreen,
                        content: Text(
                          "Mencari paduan pakaian untuk ${item.name ?? item.category}...",
                          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  label: const Text(
                    "CARI PASANGAN BAJU",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // ──────────────────────────────────────────────────────────────────────
      // 2. CUSTOM SCROLL VIEW & SLIVER (Efek Foto Besar Melayang)
      // ──────────────────────────────────────────────────────────────────────
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // SLIVER APP BAR — Bagian Header Gambar
          SliverAppBar(
            expandedHeight: 460.0,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.primary,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: AppTheme.primary.withAlpha(180),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0, top: 8.0, bottom: 8.0),
                child: CircleAvatar(
                  backgroundColor: AppTheme.primary.withAlpha(180),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined, color: AppTheme.textPrimary, size: 20),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // HERO ANIMATION: Transisi mulus saat foto ditarik dari grid
                  Hero(
                    tag: item.id,
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppTheme.surface,
                        child: const Icon(Icons.broken_image, size: 64, color: AppTheme.error),
                      ),
                    ),
                  ),
                  // GRADIENT OVERLAY agar teks kembali & shadow terlihat elegan
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(100),
                          Colors.transparent,
                          AppTheme.primary.withAlpha(200),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ──────────────────────────────────────────────────────────────────────
          // 3. SLIVER TO BOX ADAPTER — Konten Spesifikasi / Detail Pakaian
          // ──────────────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -28), // Mengapit sedikit ke atas foto
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border(
                    top: BorderSide(color: AppTheme.textSecondary.withAlpha(30), width: 1),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION 1: JUDUL & BADGE KATEGORI ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name?.toUpperCase() ?? item.category.toUpperCase(),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.brand != null && item.brand!.isNotEmpty
                                    ? "By ${item.brand!}"
                                    : "Personal Collection",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.neonBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // BADGE KATEGORI
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.neonBlue.withAlpha(100)),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // --- SECTION 2: AI CONFIDENCE SCORE BOX (HIGH TECH BADGE) ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isHighConfidence ? AppTheme.acidGreen : AppTheme.electricAmber,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (isHighConfidence ? AppTheme.acidGreen : AppTheme.electricAmber)
                                  .withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.psychology_alt,
                              color: isHighConfidence ? AppTheme.acidGreen : AppTheme.electricAmber,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "AI CLASSIFICATION ACCURACY",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      item.confidencePercent,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isHighConfidence ? "(Very High Match)" : "(Good Match)",
                                      style: TextStyle(
                                        color: isHighConfidence ? AppTheme.success : AppTheme.electricAmber,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // --- SECTION 3: SPESIFIKASI BARANG (SPECIFICATIONS GRID) ---
                    Text(
                      "ITEM SPECIFICATIONS",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSpecCard(
                            context,
                            icon: Icons.palette_outlined,
                            title: "Color",
                            value: item.color != null && item.color!.isNotEmpty ? item.color! : "Unspecified",
                            accent: AppTheme.glitchMagenta,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSpecCard(
                            context,
                            icon: Icons.sell_outlined,
                            title: "Brand",
                            value: item.brand != null && item.brand!.isNotEmpty ? item.brand! : "Unbranded",
                            accent: AppTheme.deepTeal,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // --- SECTION 4: PERSONAL NOTES (DESKRIPSI) ---
                    Text(
                      "PERSONAL NOTES",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withAlpha(120),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        item.notes != null && item.notes!.isNotEmpty
                            ? item.notes!
                            : "No notes added for this clothing item yet. Tap the edit icon below to add style reminders!",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: (item.notes != null && item.notes!.isNotEmpty)
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget untuk membuat Kartu Spesifikasi
  Widget _buildSpecCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}