import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';

// ─────────────────────────────────────────────
// WARDROBE DONUT CHART
// Widget kustom yang menggambar donut chart (grafik cincin)
// untuk menampilkan komposisi kategori pakaian.
//
// Cara pakai:
//   WardrobeDonutChart(
//     categories: {"T-shirt": 5, "Pants": 4, "Jacket": 3},
//     totalItems: 12,
//   )
// ─────────────────────────────────────────────

class WardrobeDonutChart extends StatelessWidget {
  final Map<String, int> categories;
  final int totalItems;

  const WardrobeDonutChart({
    super.key,
    required this.categories,
    required this.totalItems,
  });

  // Daftar warna untuk tiap segmen chart (mengikuti palette AppTheme)
  static const List<Color> segmentColors = [
    AppTheme.acidGreen,
    AppTheme.neonBlue,
    AppTheme.glitchMagenta,
    AppTheme.electricAmber,
    AppTheme.deepTeal,
    AppTheme.cyberPurple,
  ];

  @override
  Widget build(BuildContext context) {
    // Jika wardrobe kosong, tampilkan pesan ajakan
    if (totalItems == 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checkroom, size: 48, color: AppTheme.textSecondary.withAlpha(80)),
            const SizedBox(height: 12),
            Text(
              "Your wardrobe is empty",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Upload your first clothing item!",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary.withAlpha(120),
              ),
            ),
          ],
        ),
      );
    }

    // Urutkan kategori dari jumlah terbanyak ke tersedikit
    final sortedEntries = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        // ── DONUT CHART ──
        SizedBox(
          height: 200,
          width: 200,
          child: CustomPaint(
            painter: _DonutChartPainter(
              entries: sortedEntries,
              total: totalItems,
              colors: segmentColors,
            ),
            // Angka total di tengah donut
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$totalItems",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    "items",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── LEGEND (Keterangan warna per kategori) ──
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(sortedEntries.length, (index) {
            final entry = sortedEntries[index];
            final color = segmentColors[index % segmentColors.length];

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Titik warna kecil
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(100),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Label: "T-shirt (5)"
                Text(
                  "${entry.key} (${entry.value})",
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// CUSTOM PAINTER: Mesin Gambar Donut Chart
//
// CustomPainter adalah cara Flutter menggambar grafik custom.
// Kita menggambar lingkaran (arc) per kategori, lalu
// menambahkan efek cahaya neon (glow) di tiap segmen.
// ─────────────────────────────────────────────

class _DonutChartPainter extends CustomPainter {
  final List<MapEntry<String, int>> entries;
  final int total;
  final List<Color> colors;

  _DonutChartPainter({
    required this.entries,
    required this.total,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Ketebalan cincin donut
    const strokeWidth = 24.0;

    // Mulai menggambar dari posisi jam 12 (atas)
    // -pi/2 dalam radian = 12 o'clock
    double startAngle = -pi / 2;

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final color = colors[i % colors.length];

      // Hitung sudut segmen berdasarkan persentase
      // Contoh: 5/12 item = 5/12 * 360 derajat
      final sweepAngle = (entry.value / total) * 2 * pi;

      // Jarak kecil antar segmen agar terlihat terpisah
      const gapAngle = 0.04;
      final adjustedSweep = sweepAngle > gapAngle ? sweepAngle - gapAngle : sweepAngle;

      // ── Layer 1: Efek glow (cahaya neon di belakang) ──
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8
        ..color = color.withAlpha(50)
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle + gapAngle / 2,
        adjustedSweep,
        false,
        glowPaint,
      );

      // ── Layer 2: Segmen utama (warna solid) ──
      final segmentPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = color
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle + gapAngle / 2,
        adjustedSweep,
        false,
        segmentPaint,
      );

      // Geser posisi awal untuk segmen berikutnya
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    // Gambar ulang hanya jika data berubah
    return oldDelegate.total != total || oldDelegate.entries != entries;
  }
}
