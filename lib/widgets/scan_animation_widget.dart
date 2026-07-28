import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';

/// Widget animasi scanning yang menampilkan garis neon bergerak naik-turun
/// di atas gambar, dengan efek glow dan pulse border.
/// 
/// Digunakan saat menunggu response ML classification dari backend.
class ScanAnimationWidget extends StatefulWidget {
  /// Widget gambar yang akan di-scan (biasanya Image.file)
  final Widget imageWidget;

  /// Ukuran container
  final double width;
  final double height;

  /// Teks status yang ditampilkan di bawah animasi
  final String statusText;

  const ScanAnimationWidget({
    super.key,
    required this.imageWidget,
    this.width = 280,
    this.height = 320,
    this.statusText = 'Menganalisis pakaian...',
  });

  @override
  State<ScanAnimationWidget> createState() => _ScanAnimationWidgetState();
}

class _ScanAnimationWidgetState extends State<ScanAnimationWidget>
    with TickerProviderStateMixin {
  late final AnimationController _scanController;
  late final AnimationController _pulseController;
  late final Animation<double> _scanAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animasi garis scan: naik-turun terus-menerus
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
    _scanController.repeat(reverse: true);

    // Animasi pulse border: berkedip halus
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Container gambar + animasi scan
        AnimatedBuilder(
          animation: Listenable.merge([_scanAnimation, _pulseAnimation]),
          builder: (context, child) {
            return Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.neonBlue.withAlpha(
                    (255 * _pulseAnimation.value).toInt(),
                  ),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonBlue.withAlpha(
                      (40 * _pulseAnimation.value).toInt(),
                    ),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.5),
                child: Stack(
                  children: [
                    // Layer 1: Gambar asli
                    Positioned.fill(child: widget.imageWidget),

                    // Layer 2: Dark overlay untuk efek scanning
                    Positioned.fill(
                      child: Container(
                        color: AppTheme.primary.withAlpha(60),
                      ),
                    ),

                    // Layer 3: Garis scan neon
                    Positioned(
                      top: _scanAnimation.value *
                          (widget.height - 4), // -4 untuk border
                      left: 0,
                      right: 0,
                      child: _buildScanLine(),
                    ),

                    // Layer 4: Corner brackets (aesthetic)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ScanCornerPainter(
                          opacity: _pulseAnimation.value,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // Status text + loading dots
        _ScanStatusText(text: widget.statusText),
      ],
    );
  }

  /// Garis scan horizontal dengan efek glow
  Widget _buildScanLine() {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.neonBlue.withAlpha(100),
            AppTheme.neonBlue,
            AppTheme.neonBlue,
            AppTheme.neonBlue.withAlpha(100),
            Colors.transparent,
          ],
          stops: const [0.0, 0.15, 0.3, 0.7, 0.85, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonBlue.withAlpha(120),
            blurRadius: 12,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: AppTheme.neonBlue.withAlpha(40),
            blurRadius: 30,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }
}

/// Painter untuk sudut-sudut scan aesthetic
class _ScanCornerPainter extends CustomPainter {
  final double opacity;

  _ScanCornerPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppTheme.neonBlue.withAlpha((200 * opacity).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const double cornerLen = 24;
    const double margin = 8;

    // Top-left
    canvas.drawLine(
      const Offset(margin, margin + cornerLen),
      const Offset(margin, margin),
      paint,
    );
    canvas.drawLine(
      const Offset(margin, margin),
      const Offset(margin + cornerLen, margin),
      paint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - margin - cornerLen, margin),
      Offset(size.width - margin, margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin, margin + cornerLen),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(margin, size.height - margin - cornerLen),
      Offset(margin, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin + cornerLen, size.height - margin),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - margin - cornerLen, size.height - margin),
      Offset(size.width - margin, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin, size.height - margin - cornerLen),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ScanCornerPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

/// Teks status dengan animasi loading dots (...)
class _ScanStatusText extends StatefulWidget {
  final String text;

  const _ScanStatusText({required this.text});

  @override
  State<_ScanStatusText> createState() => _ScanStatusTextState();
}

class _ScanStatusTextState extends State<_ScanStatusText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        // Menghitung jumlah dots (0, 1, 2, 3) berdasarkan progress animasi
        final int dotCount = (_dotsController.value * 4).floor() % 4;
        final String dots = '.' * dotCount;
        final String spaces = ' ' * (3 - dotCount); // keep stable width

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon AI
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.neonBlue.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppTheme.neonBlue,
              ),
            ),
            const SizedBox(width: 10),
            // Teks dengan dots animasi
            Text(
              '${widget.text}$dots$spaces',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        );
      },
    );
  }
}
