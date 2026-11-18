/// Região (elipse) de um dente na imagem `assets/images/odontograma.jpg`,
/// em pixels da imagem original (736×873).
class ToothShape {
  const ToothShape(this.cx, this.cy, this.rx, this.ry);

  final double cx;
  final double cy;
  final double rx;
  final double ry;
}

abstract final class ToothMap {
  static const double imageWidth = 736;
  static const double imageHeight = 873;

  /// Numeração FDI: 11–48 permanentes, 51–85 decíduos.
  static const Map<int, ToothShape> shapes = {
    11: ToothShape(342, 76, 26, 27),
    12: ToothShape(291, 85, 23, 24),
    13: ToothShape(250, 104, 27, 25),
    14: ToothShape(224, 145, 30, 26),
    15: ToothShape(201, 185, 28, 23),
    16: ToothShape(185, 238, 34, 37),
    17: ToothShape(167, 296, 31, 30),
    18: ToothShape(155, 348, 30, 29),
    21: ToothShape(395, 76, 26, 27),
    22: ToothShape(441, 90, 23, 24),
    23: ToothShape(481, 112, 27, 25),
    24: ToothShape(512, 150, 29, 26),
    25: ToothShape(529, 193, 29, 25),
    26: ToothShape(546, 246, 36, 36),
    27: ToothShape(560, 305, 30, 31),
    28: ToothShape(573, 358, 30, 26),
    31: ToothShape(373, 811, 19, 19),
    32: ToothShape(408, 813, 22, 16),
    33: ToothShape(450, 803, 24, 22),
    34: ToothShape(476, 770, 24, 22),
    35: ToothShape(496, 733, 29, 26),
    36: ToothShape(518, 678, 33, 36),
    37: ToothShape(541, 618, 34, 35),
    38: ToothShape(558, 560, 31, 31),
    41: ToothShape(336, 811, 19, 19),
    42: ToothShape(306, 815, 25, 15),
    43: ToothShape(262, 794, 25, 22),
    44: ToothShape(228, 776, 24, 22),
    45: ToothShape(211, 730, 29, 26),
    46: ToothShape(191, 672, 31, 35),
    47: ToothShape(165, 613, 26, 32),
    48: ToothShape(153, 550, 26, 29),
    51: ToothShape(343, 227, 22, 17),
    52: ToothShape(304, 233, 17, 15),
    53: ToothShape(275, 258, 20, 20),
    54: ToothShape(255, 298, 22, 24),
    55: ToothShape(244, 346, 28, 25),
    61: ToothShape(393, 227, 22, 17),
    62: ToothShape(427, 235, 17, 15),
    63: ToothShape(452, 262, 21, 22),
    64: ToothShape(468, 300, 22, 24),
    65: ToothShape(482, 350, 30, 29),
    71: ToothShape(368, 666, 12, 12),
    72: ToothShape(402, 660, 16, 13),
    73: ToothShape(424, 645, 17, 17),
    74: ToothShape(450, 616, 24, 24),
    75: ToothShape(464, 557, 31, 33),
    81: ToothShape(343, 666, 12, 12),
    82: ToothShape(316, 660, 16, 13),
    83: ToothShape(290, 643, 17, 17),
    84: ToothShape(262, 611, 24, 24),
    85: ToothShape(246, 557, 31, 33),
  };

  static bool isDeciduous(int tooth) => tooth >= 51;

  static String describe(int tooth) =>
      'Dente $tooth · ${isDeciduous(tooth) ? 'decíduo' : 'permanente'}';

  /// Dente sob o ponto (em pixels da imagem) ou null. Usa a elipse mais próxima,
  /// com uma pequena tolerância para facilitar o toque em telas pequenas.
  static int? toothAt(double x, double y) {
    int? best;
    var bestDistance = 1.5;
    shapes.forEach((tooth, s) {
      final dx = (x - s.cx) / s.rx;
      final dy = (y - s.cy) / s.ry;
      final distance = dx * dx + dy * dy;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = tooth;
      }
    });
    return best;
  }
}
