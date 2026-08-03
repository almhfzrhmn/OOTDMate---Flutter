import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';

/// Daftar warna pakaian umum yang bisa dipilih user
class ClothingColor {
  final String name;
  final Color color;

  const ClothingColor(this.name, this.color);
}

/// Preset warna pakaian yang umum digunakan
const List<ClothingColor> clothingColors = [
  ClothingColor('Black', Color(0xFF1A1A1A)),
  ClothingColor('White', Color(0xFFF5F5F5)),
  ClothingColor('Gray', Color(0xFF808080)),
  ClothingColor('Navy', Color(0xFF1B2A4A)),
  ClothingColor('Blue', Color(0xFF2196F3)),
  ClothingColor('Light Blue', Color(0xFF81D4FA)),
  ClothingColor('Red', Color(0xFFD32F2F)),
  ClothingColor('Maroon', Color(0xFF6D1A1A)),
  ClothingColor('Pink', Color(0xFFF48FB1)),
  ClothingColor('Green', Color(0xFF388E3C)),
  ClothingColor('Olive', Color(0xFF6B6B3D)),
  ClothingColor('Khaki', Color(0xFFC3B091)),
  ClothingColor('Brown', Color(0xFF5D4037)),
  ClothingColor('Beige', Color(0xFFD4C5A9)),
  ClothingColor('Cream', Color(0xFFFFF8E1)),
  ClothingColor('Yellow', Color(0xFFFDD835)),
  ClothingColor('Orange', Color(0xFFFF9800)),
  ClothingColor('Purple', Color(0xFF7B1FA2)),
  ClothingColor('Denim', Color(0xFF4A6FA5)),
  ClothingColor('Charcoal', Color(0xFF36454F)),
];

/// Widget color picker berbentuk grid warna yang bisa dipilih.
/// Menampilkan nama warna yang terpilih dan memungkinkan input manual.
class ColorPickerField extends StatefulWidget {
  /// Warna yang saat ini terpilih (nama warna)
  final String? selectedColor;

  /// Callback saat warna dipilih
  final ValueChanged<String> onColorSelected;

  const ColorPickerField({
    super.key,
    this.selectedColor,
    required this.onColorSelected,
  });

  @override
  State<ColorPickerField> createState() => _ColorPickerFieldState();
}

class _ColorPickerFieldState extends State<ColorPickerField> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Find matching ClothingColor for current selection
    final ClothingColor? currentColor = widget.selectedColor != null
        ? clothingColors.cast<ClothingColor?>().firstWhere(
              (c) => c!.name.toLowerCase() == widget.selectedColor!.toLowerCase(),
              orElse: () => null,
            )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + selected color display
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface.withAlpha(180),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isExpanded
                    ? AppTheme.neonBlue.withAlpha(100)
                    : AppTheme.mediumGrey.withAlpha(80),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Color circle preview
                if (currentColor != null) ...[
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: currentColor.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.textSecondary.withAlpha(80),
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else ...[
                  Icon(
                    Icons.palette_outlined,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 12),
                ],
                // Label text
                Expanded(
                  child: Text(
                    widget.selectedColor ?? 'Pilih Warna',
                    style: TextStyle(
                      color: widget.selectedColor != null
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Expand/collapse icon
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),

        // Color grid (expandable)
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState:
              _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withAlpha(200),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.mediumGrey.withAlpha(40),
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: clothingColors.map((clothingColor) {
                final bool isSelected = widget.selectedColor?.toLowerCase() ==
                    clothingColor.name.toLowerCase();

                return GestureDetector(
                  onTap: () {
                    widget.onColorSelected(clothingColor.name);
                    setState(() => _isExpanded = false);
                  },
                  child: Tooltip(
                    message: clothingColor.name,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: clothingColor.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.neonBlue
                              : AppTheme.textSecondary.withAlpha(40),
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.neonBlue.withAlpha(60),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: _contrastColor(clothingColor.color),
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Menentukan warna kontras untuk ikon check (hitam atau putih)
  Color _contrastColor(Color bgColor) {
    final double luminance = bgColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}
