import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/odontograma_model.dart';
import 'mapa_dentes.dart';

/// Imagem do odontograma (numeração FDI) clicável: toque em um dente para
/// selecioná-lo. Faces com condições registradas ficam marcadas.
class GraficoOdontograma extends StatelessWidget {
  const GraficoOdontograma({
    required this.registrosPorDente,
    required this.selectedTooth,
    required this.onToothTap,
    this.conditionCodes = const {},
    super.key,
  });

  final Map<int, List<OdontogramaRegistroModel>> registrosPorDente;
  final int? selectedTooth;
  final ValueChanged<int?> onToothTap;
  final Map<int, String> conditionCodes;

  static const _semanticColors = <String, Color>{
    'HIGIDO': Color(0xFF607D8B),
    'CARIE': Color(0xFFD32F2F),
    'RESTAURACAO': Color(0xFF1565C0),
    'AUSENTE': Color(0xFF455A64),
    'EXTRACAO_INDICADA': Color(0xFFF57C00),
    'COROA': Color(0xFF7B1FA2),
    'IMPLANTE': Color(0xFF00897B),
    'ENDODONTIA': Color(0xFF3949AB),
    'FRATURA': Color(0xFFC2185B),
    'SELANTE': Color(0xFF2E7D32),
    'RAIZ_RESIDUAL': Color(0xFF6D4C41),
    'NAO_ERUPCIONADO': Color(0xFF00838F),
    'PROTESE': Color(0xFFF9A825),
    'MANCHA_BRANCA': Color(0xFFAFB42B),
  };
  static const _seedCodesById = <int, String>{
    1: 'HIGIDO',
    2: 'CARIE',
    3: 'RESTAURACAO',
    4: 'AUSENTE',
    5: 'EXTRACAO_INDICADA',
    6: 'COROA',
    7: 'IMPLANTE',
    8: 'ENDODONTIA',
    9: 'FRATURA',
    10: 'SELANTE',
    11: 'RAIZ_RESIDUAL',
    12: 'NAO_ERUPCIONADO',
    13: 'PROTESE',
    14: 'MANCHA_BRANCA',
  };

  /// Cores sem repeticao entre as condicoes do catalogo.
  static Color colorForCondicao(int condicaoId, {String? codigo}) {
    final normalizedCode =
        (codigo ?? _seedCodesById[condicaoId])?.toUpperCase();
    final semanticColor = _semanticColors[normalizedCode];
    if (semanticColor != null) return semanticColor;
    return HSVColor.fromAHSV(
      1,
      (condicaoId * 137.508) % 360,
      .78,
      .86,
    ).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark
        ? AppTheme.gold
        : Theme.of(context).colorScheme.primary;
    final marked = registrosPorDente;

    // O desenho é um JPG de fundo branco: mantém o "papel" branco também no modo escuro.
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: Colors.white,
        child: AspectRatio(
          aspectRatio: MapaDentes.imageWidth / MapaDentes.imageHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              return GestureDetector(
                key: const Key('odontograma-chart'),
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => onToothTap(
                  MapaDentes.toothAt(
                    details.localPosition.dx / size.width * MapaDentes.imageWidth,
                    details.localPosition.dy /
                        size.height *
                        MapaDentes.imageHeight,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/odontograma.jpg',
                      fit: BoxFit.contain,
                      semanticLabel: 'Odontograma FDI',
                    ),
                    CustomPaint(
                      painter: _ToothPainter(
                        marked: marked,
                        conditionCodes: conditionCodes,
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
    required this.conditionCodes,
    required this.selected,
    required this.accent,
  });

  final Map<int, List<OdontogramaRegistroModel>> marked;
  final Map<int, String> conditionCodes;
  final int? selected;
  final Color accent;

  Rect _rectOf(FormatoDente shape, Size size) {
    final sx = size.width / MapaDentes.imageWidth;
    final sy = size.height / MapaDentes.imageHeight;
    return Rect.fromCenter(
      center: Offset(shape.cx * sx, shape.cy * sy),
      width: shape.rx * 2 * sx,
      height: shape.ry * 2 * sy,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / MapaDentes.imageWidth;
    final sy = size.height / MapaDentes.imageHeight;
    final scale = sx < sy ? sx : sy;
    final recordsByFace = <int, List<OdontogramaRegistroModel>>{};

    marked.forEach((tooth, records) {
      final shape = MapaDentes.shapes[tooth];
      if (shape == null || records.isEmpty) return;
      final wholeToothRecords = records
          .where((record) => record.face == FaceDente.denteInteiro)
          .toList();
      if (wholeToothRecords.isNotEmpty) {
        _paintWholeTooth(canvas, _rectOf(shape, size), wholeToothRecords, scale);
      }
      recordsByFace[tooth] = records
          .where((record) => record.face != FaceDente.denteInteiro)
          .toList();
    });

    final selectedShape = selected == null ? null : MapaDentes.shapes[selected];
    final selectedRect = selectedShape == null
        ? null
        : _rectOf(selectedShape, size).inflate(2 * scale);
    if (selectedRect != null) {
      final selectedRRect = RRect.fromRectAndRadius(
        selectedRect,
        Radius.circular(5 * scale),
      );
      canvas
        ..drawRRect(
          selectedRRect,
          Paint()..color = accent.withValues(alpha: .20),
        )
        ..drawRRect(
          selectedRRect,
          Paint()
            ..color = accent.withValues(alpha: .85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 * scale,
        );
    }

    recordsByFace.forEach((tooth, records) {
      final shape = MapaDentes.shapes[tooth];
      if (shape == null || records.isEmpty) return;
      final grouped = <Offset, List<OdontogramaRegistroModel>>{};
      for (final record in records) {
        final base = MapaDentes.faceCenter(tooth, record.face);
        grouped.putIfAbsent(base, () => []).add(record);
      }

      for (final entry in grouped.entries) {
        final base = entry.key;
        final faceRecords = entry.value;
        final isSideFace = (base.dx - shape.cx).abs() >
            (base.dy - shape.cy).abs();
        for (var i = 0; i < faceRecords.length; i++) {
          final record = faceRecords[i];
          final distribution = (i - (faceRecords.length - 1) / 2) * 16.0;
          final offset = isSideFace
              ? Offset(0, distribution)
              : Offset(distribution, 0);
          final center = Offset(
            (base.dx + offset.dx) * sx,
            (base.dy + offset.dy) * sy,
          );
          final color = GraficoOdontograma.colorForCondicao(
            record.condicaoId,
            codigo: conditionCodes[record.condicaoId],
          );
          final radius = 6 * scale;
          canvas
            ..drawCircle(
              center,
              radius,
              Paint()..color = color.withValues(alpha: .82),
            )
            ..drawCircle(
              center,
              radius,
              Paint()
                ..color = color
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.8 * scale,
            );
        }
      }
    });

    if (selectedRect != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(selectedRect, Radius.circular(5 * scale)),
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * scale,
      );
    }
  }

  void _paintWholeTooth(
    Canvas canvas,
    Rect rect,
    List<OdontogramaRegistroModel> records,
    double scale,
  ) {
    final bounds = RRect.fromRectAndRadius(
      rect,
      Radius.circular(4 * scale),
    );
    canvas.save();
    canvas.clipRRect(bounds);
    final stripeWidth = rect.width / records.length;
    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      final color = GraficoOdontograma.colorForCondicao(
        record.condicaoId,
        codigo: conditionCodes[record.condicaoId],
      );
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left + stripeWidth * i,
          rect.top,
          stripeWidth + .5 * scale,
          rect.height,
        ),
        Paint()..color = color.withValues(alpha: .32),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ToothPainter oldDelegate) =>
      oldDelegate.selected != selected ||
      oldDelegate.accent != accent ||
      !_sameCodes(oldDelegate.conditionCodes, conditionCodes) ||
      !_sameMarks(oldDelegate.marked, marked);

  static bool _sameCodes(Map<int, String> a, Map<int, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static bool _sameMarks(
    Map<int, List<OdontogramaRegistroModel>> a,
    Map<int, List<OdontogramaRegistroModel>> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null || other.length != entry.value.length) return false;
      for (var i = 0; i < entry.value.length; i++) {
        final first = entry.value[i];
        final second = other[i];
        if (first.id != second.id ||
            first.face != second.face ||
            first.condicaoId != second.condicaoId) {
          return false;
        }
      }
    }
    return true;
  }
}
