import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';
import 'package:ootdmate_frontend/models/user_model.dart';
import 'package:ootdmate_frontend/models/wardrobe_stats_model.dart';
import 'package:ootdmate_frontend/screens/core/recommendation/recommendation_screen.dart';
import 'package:ootdmate_frontend/screens/core/uploads/camera_screen.dart';
import 'package:ootdmate_frontend/services/api-services/wardrobe_item_service.dart';
import 'package:ootdmate_frontend/widgets/ui/app_header.dart';
import 'package:ootdmate_frontend/widgets/charts/wardrobe_donut_chart.dart';

class HomeScreen extends StatefulWidget {
  final UserModel? userProfile;
  final String? avatarUrl;
  final ValueChanged<UserModel>? onProfileUpdated;

  const HomeScreen({
    super.key,
    this.userProfile,
    this.avatarUrl,
    this.onProfileUpdated,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WardrobeItemService _wardrobeItemService = WardrobeItemService();

  // State untuk menyimpan data stats dari API
  WardrobeStatsModel? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  /// Ambil data statistik wardrobe dari backend
  Future<void> _loadStats() async {
    try {
      final stats = await _wardrobeItemService.getWardrobeStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
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

  @override
  Widget build(BuildContext context) {
    // Ambil data user dari parameter (bukan dari API lagi)
    final String name = widget.userProfile?.fullName ?? 'Guest';
    final String? avatarUrl = widget.avatarUrl ?? widget.userProfile?.avatarUrl;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          AppHeader(
            title: "Hi, ${name[0].toUpperCase() + name.substring(1)}",
            subTitle: "Let's create your stylish look for today",
            avatarUrl: avatarUrl,
            username: name,
            currentUser: widget.userProfile,
            onProfileUpdated: widget.onProfileUpdated,
          ),
        ],
        body: RefreshIndicator(
          color: AppTheme.acidGreen,
          onRefresh: _loadStats,
          child: _buildBody(context),
        ),
      ),
    );
  }

  /// Body utama — menangani 3 state: loading, error, dan data
  Widget _buildBody(BuildContext context) {
    // ── STATE 1: Loading ──
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.glitchMagenta),
      );
    }

    // ── STATE 2: Error ──
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 48, color: AppTheme.error.withAlpha(150)),
            const SizedBox(height: 12),
            Text(
              "Failed to load dashboard",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadStats();
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    // ── STATE 3: Data berhasil dimuat ──
    final stats = _stats ?? WardrobeStatsModel.empty();

    // Pakai ListView agar bisa pull-to-refresh dan scroll
    return Column(
      children: [
        // Container(
        //   height: 180,
        //   width : double.infinity,
        //   decoration: BoxDecoration(
        //     color : AppTheme.primarySecond,
        //     shape : BoxShape.circle,
        //   ),
        //   child: Center(child: Text(
        //     "Tes tambah kolom"
        //   ),
        //   ),
        // ),
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              // SECTION 1: WARDROBE OVERVIEW (Donut Chart)
              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              _buildSectionTitle(context, icon: Icons.pie_chart_outline, title: "WARDROBE OVERVIEW"),
              const SizedBox(height: 16),
          
              // Container dengan background gelap untuk donut chart
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.textSecondary.withAlpha(20)),
                ),
                child: WardrobeDonutChart(
                  categories: stats.categories,
                  totalItems: stats.totalItems,
                ),
              ),
          
              const SizedBox(height: 28),
          
              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              // SECTION 2: QUICK ACTIONS
              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              _buildSectionTitle(context, icon: Icons.bolt, title: "QUICK ACTIONS"),
              const SizedBox(height: 16),
          
              Row(
                children: [
                  // Kartu 1: Add Clothing
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.add_a_photo_outlined,
                      label: "Add Clothing",
                      description: "Upload & classify",
                      accentColor: AppTheme.acidGreen,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CameraScreen(),)
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Kartu 2: OOTD Generator
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.auto_awesome,
                      label: "OOTD Generator",
                      description: "AI outfit matcher",
                      accentColor: AppTheme.glitchMagenta,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RecommendationScreen() )
                        );
                      },
                    ),
                  ),
                ],
              ),
          
              const SizedBox(height: 28),
          
              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              // SECTION 3: CATEGORY BREAKDOWN (Progress Bars)
              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              _buildSectionTitle(context, icon: Icons.bar_chart, title: "CATEGORY BREAKDOWN"),
              const SizedBox(height: 16),
          
              if (stats.totalItems == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "No data yet. Start adding clothes!",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              else
                ..._buildCategoryBars(context, stats),
          
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // HELPER: Section Title (Label judul tiap bagian)
  // ─────────────────────────────────────────────
  Widget _buildSectionTitle(BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // HELPER: Category Breakdown Bars
  // Menampilkan bar horizontal per kategori
  // ─────────────────────────────────────────────
  List<Widget> _buildCategoryBars(BuildContext context, WardrobeStatsModel stats) {
    // Urutkan dari terbanyak
    final sorted = stats.categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Warna segmen, sama dengan donut chart
    const colors = WardrobeDonutChart.segmentColors;

    return List.generate(sorted.length, (index) {
      final entry = sorted[index];
      final percentage = stats.totalItems > 0
          ? entry.value / stats.totalItems
          : 0.0;
      final color = colors[index % colors.length];

      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris atas: Nama kategori + jumlah
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "${entry.value} pcs",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  // Background bar (abu-abu gelap)
                  Container(
                    height: 8,
                    width: double.infinity,
                    color: AppTheme.surface,
                  ),
                  // Foreground bar (warna kategori)
                  FractionallySizedBox(
                    widthFactor: percentage,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withAlpha(80),
                            blurRadius: 6,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
// WIDGET TERPISAH: Quick Action Card
//
// Kartu pintasan aksi (Add Clothing, OOTD Generator).
// Dipisah menjadi widget sendiri agar:
// 1. Mudah dibaca (kode tidak terlalu panjang)
// 2. Mudah di-maintain jika ingin menambah kartu baru
// 3. Reusable di tempat lain
// ─────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color accentColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.secondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon dalam lingkaran bercahaya
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(height: 14),
            // Label utama
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            // Deskripsi kecil
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
