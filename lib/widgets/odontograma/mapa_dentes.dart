import 'dart:ui';

import '../../models/odontograma_model.dart';

/// Centro e alcance de toque do dente em pixels do asset do odontograma.
class FormatoDente {
  const FormatoDente(this.cx, this.cy, this.rx, this.ry);

  final double cx;
  final double cy;
  final double rx;
  final double ry;
}

abstract final class MapaDentes {
  static const double imageWidth = 996;
  static const double imageHeight = 701;

  /// Coordenadas calibradas para o odontograma em grade (numera\u00e7\u00e3o FDI).
  static const Map<int, FormatoDente> shapes = {
    // Denticao permanente superior.
    18: FormatoDente(72, 199, 25, 24),
    17: FormatoDente(127, 199, 25, 24),
    16: FormatoDente(183, 199, 25, 24),
    15: FormatoDente(238, 199, 25, 24),
    14: FormatoDente(294, 199, 25, 24),
    13: FormatoDente(350, 199, 25, 24),
    12: FormatoDente(406, 199, 25, 24),
    11: FormatoDente(462, 199, 25, 24),
    21: FormatoDente(538, 199, 25, 24),
    22: FormatoDente(594, 199, 25, 24),
    23: FormatoDente(650, 199, 25, 24),
    24: FormatoDente(705, 199, 25, 24),
    25: FormatoDente(761, 199, 25, 24),
    26: FormatoDente(817, 199, 25, 24),
    27: FormatoDente(873, 199, 25, 24),
    28: FormatoDente(929, 199, 25, 24),

    // Denticao permanente inferior.
    48: FormatoDente(72, 272, 25, 24),
    47: FormatoDente(127, 272, 25, 24),
    46: FormatoDente(183, 272, 25, 24),
    45: FormatoDente(238, 272, 25, 24),
    44: FormatoDente(294, 272, 25, 24),
    43: FormatoDente(350, 272, 25, 24),
    42: FormatoDente(406, 272, 25, 24),
    41: FormatoDente(462, 272, 25, 24),
    31: FormatoDente(538, 272, 25, 24),
    32: FormatoDente(594, 272, 25, 24),
    33: FormatoDente(650, 272, 25, 24),
    34: FormatoDente(705, 272, 25, 24),
    35: FormatoDente(761, 272, 25, 24),
    36: FormatoDente(817, 272, 25, 24),
    37: FormatoDente(873, 272, 25, 24),
    38: FormatoDente(929, 272, 25, 24),

    // Denticao decidua superior.
    55: FormatoDente(239, 427, 25, 24),
    54: FormatoDente(295, 427, 25, 24),
    53: FormatoDente(351, 427, 25, 24),
    52: FormatoDente(407, 427, 25, 24),
    51: FormatoDente(463, 427, 25, 24),
    61: FormatoDente(538, 427, 25, 24),
    62: FormatoDente(594, 427, 25, 24),
    63: FormatoDente(650, 427, 25, 24),
    64: FormatoDente(706, 427, 25, 24),
    65: FormatoDente(762, 427, 25, 24),

    // Denticao decidua inferior.
    85: FormatoDente(239, 499, 25, 24),
    84: FormatoDente(295, 499, 25, 24),
    83: FormatoDente(351, 499, 25, 24),
    82: FormatoDente(407, 499, 25, 24),
    81: FormatoDente(463, 499, 25, 24),
    71: FormatoDente(538, 499, 25, 24),
    72: FormatoDente(594, 499, 25, 24),
    73: FormatoDente(650, 499, 25, 24),
    74: FormatoDente(706, 499, 25, 24),
    75: FormatoDente(762, 499, 25, 24),
  };

  static bool isDeciduous(int tooth) => tooth >= 51;

  static String describe(int tooth) =>
      'Dente $tooth \u00b7 ${isDeciduous(tooth) ? 'dec\u00edduo' : 'permanente'}';

  /// Faces aceitas pela arcada e pelo grupo anat\u00f4mico do dente.
  static List<FaceDente> facesForTooth(int tooth) {
    final quadrant = tooth ~/ 10;
    final upperArch = quadrant == 1 || quadrant == 2 ||
        quadrant == 5 || quadrant == 6;
    final centerFace = tooth % 10 <= 3
        ? FaceDente.incisal
        : FaceDente.oclusal;

    return [
      upperArch ? FaceDente.vestibular : FaceDente.lingual,
      upperArch ? FaceDente.palatina : FaceDente.vestibular,
      FaceDente.mesial,
      FaceDente.distal,
      centerFace,
      FaceDente.denteInteiro,
    ];
  }

  /// Centro do segmento desenhado para uma face, no mesmo sistema do asset.
  static Offset faceCenter(int tooth, FaceDente face) {
    final shape = shapes[tooth]!;
    final quadrant = tooth ~/ 10;
    final mesialGoesRight = quadrant == 1 || quadrant == 4 ||
        quadrant == 5 || quadrant == 8;
    final side = mesialGoesRight ? 1.0 : -1.0;

    final upperArch = quadrant == 1 || quadrant == 2 ||
        quadrant == 5 || quadrant == 6;
    final topY = shape.cy - shape.ry * .68;
    final bottomY = shape.cy + shape.ry * .68;

    return switch (face) {
      FaceDente.vestibular => Offset(shape.cx, upperArch ? topY : bottomY),
      FaceDente.lingual => Offset(shape.cx, upperArch ? bottomY : topY),
      FaceDente.palatina => Offset(shape.cx, upperArch ? bottomY : topY),
      FaceDente.mesial => Offset(shape.cx + shape.rx * .68 * side, shape.cy),
      FaceDente.distal => Offset(shape.cx - shape.rx * .68 * side, shape.cy),
      FaceDente.oclusal => Offset(shape.cx, shape.cy),
      FaceDente.incisal => Offset(shape.cx, shape.cy),
      FaceDente.denteInteiro => Offset(shape.cx, shape.cy),
    };
  }

  /// Dente sob o ponto, limitado aos centros medidos da imagem nova.
  static int? toothAt(double x, double y) {
    int? best;
    var bestDistance = 4.0;
    shapes.forEach((tooth, shape) {
      final dx = (x - shape.cx) / shape.rx;
      final dy = (y - shape.cy) / shape.ry;
      final distance = dx * dx + dy * dy;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = tooth;
      }
    });
    return best;
  }
}
