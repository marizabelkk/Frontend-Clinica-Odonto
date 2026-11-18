import 'package:flutter/material.dart';

import '../../data/models/odontograma_dto.dart';
import 'tooth_map.dart';

/// Imagem do odontograma (numeração FDI) clicável: toque em um dente para
/// selecioná-lo. Dentes com defeitos registrados ficam coloridos.
class OdontogramaChart extends StatelessWidget {
  const OdontogramaChart({
    required this.registrosPorDente,
    required this.selectedTooth,
    required this.onToothTap,
    super.key,
  });

  final Map<int, List<OdontogramaRegistroDto>> registrosPorDente;
  final int? selectedTooth;
  final ValueChanged<int?> onToothTap;

  static const _palette = <Color>[
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
    Color(0xFF1E88E5),
    Color(0xFF00897B),
    Color(0xFF6D4C41),
    Color(0xFFD81B60),
    Color(0xFF43A047),
  ];

  /// Cor estável de cada defeito do catálogo (usada no desenho e nas listas).
  static Color colorForCondicao(int condicaoId) =>
      _palette[condicaoId % _palette.length];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final marked = <int, Color>{
      for (final entry in registrosPorDente.entries)
        if (entry.value.isNotEmpty)
          entry.key: colorForCondicao(entry.value.last.condicaoId),
    };

    // O desenho é um JPG de fundo branco: mantém o "papel" branco também no modo escuro.
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: Colors.white,
        child: AspectRatio(
          aspectRatio: ToothMap.imageWidth / ToothMap.imageHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              return GestureDetector(
                key: const Key('odontograma-chart'),
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => onToothTap(
                  ToothMap.toothAt(
                    details.localPosition.dx / size.width * ToothMap.imageWidth,
                    details.localPosition.dy /
                        size.height *
                        ToothMap.imageHeight,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/odontograma.jpg',
                      fit: BoxFit.fill,
                      semanticLabel: 'Odontograma com numeração FDI',
                    ),
                    CustomPaint(
                      painter: _ToothPainter(
                        marked: marked,
                        selected: selectedTooth,
                        accent: accent,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ToothPainter extends CustomPainter {
  const _ToothPainter({
    required this.marked,
    required this.selected,
    required this.accent,
  });

  final Map<int, Color> marked;
  final int? selected;
  final Color accent;

  Rect _rectOf(ToothShape shape, Size size) {
    final sx = size.width / ToothMap.imageWidth;
    final sy = size.height / ToothMap.imageHeight;
    return Rect.fromCenter(
      center: Offset(shape.cx * sx, shape.cy * sy),
      width: shape.rx * 2 * sx,
      height: shape.ry * 2 * sy,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    marked.forEach((tooth, color) {
      final shape = ToothMap.shapes[tooth];
      if (shape == null) return;
      final rect = _rectOf(shape, size);
      canvas
        ..drawOval(rect, Paint()..color = color.withValues(alpha: 0.45))
        ..drawOval(
          rect,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
    });

    final shape = selected == null ? null : ToothMap.shapes[selected];
    if (shape != null) {
      final rect = _rectOf(shape, size).inflate(2);
      canvas
        ..drawOval(rect, Paint()..color = accent.withValues(alpha: 0.18))
        ..drawOval(
          rect,
          Paint()
            ..color = accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5,
        );
    }
  }

  @override
  bool shouldRepaint(_ToothPainter oldDelegate) =>
      oldDelegate.selected != selected ||
      oldDelegate.accent != accent ||
      !_sameMarks(oldDelegate.marked, marked);

  static bool _sameMarks(Map<int, Color> a, Map<int, Color> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
