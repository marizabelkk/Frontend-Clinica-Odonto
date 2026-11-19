/// Região (elipse) de um dente na imagem `assets/images/odontograma.jpg`,
/// em pixels da imagem original (736×873).
class FormatoDente {
  const FormatoDente(this.cx, this.cy, this.rx, this.ry);

  final double cx;
  final double cy;
  final double rx;
  final double ry;
}

abstract final class MapaDentes {
  static const double imageWidth = 736;
  static const double imageHeight = 873;

  /// Numeração FDI: 11–48 permanentes, 51–85 decíduos.
  static const Map<int, FormatoDente> shapes = {
    11: FormatoDente(342, 76, 26, 27),
    12: FormatoDente(291, 85, 23, 24),
    13: FormatoDente(250, 104, 27, 25),
    14: FormatoDente(224, 145, 30, 26),
    15: FormatoDente(201, 185, 28, 23),
    16: FormatoDente(185, 238, 34, 37),
    17: FormatoDente(167, 296, 31, 30),
    18: FormatoDente(155, 348, 30, 29),
    21: FormatoDente(395, 76, 26, 27),
    22: FormatoDente(441, 90, 23, 24),
    23: FormatoDente(481, 112, 27, 25),
    24: FormatoDente(512, 150, 29, 26),
    25: FormatoDente(529, 193, 29, 25),
    26: FormatoDente(546, 246, 36, 36),
    27: FormatoDente(560, 305, 30, 31),
    28: FormatoDente(573, 358, 30, 26),
    31: FormatoDente(373, 811, 19, 19),
    32: FormatoDente(408, 813, 22, 16),
    33: FormatoDente(450, 803, 24, 22),
    34: FormatoDente(476, 770, 24, 22),
    35: FormatoDente(496, 733, 29, 26),
    36: FormatoDente(518, 678, 33, 36),
    37: FormatoDente(541, 618, 34, 35),
    38: FormatoDente(558, 560, 31, 31),
    41: FormatoDente(336, 811, 19, 19),
    42: FormatoDente(306, 815, 25, 15),
    43: FormatoDente(262, 794, 25, 22),
    44: FormatoDente(228, 776, 24, 22),
    45: FormatoDente(211, 730, 29, 26),
    46: FormatoDente(191, 672, 31, 35),
    47: FormatoDente(165, 613, 26, 32),
    48: FormatoDente(153, 550, 26, 29),
    51: FormatoDente(343, 227, 22, 17),
    52: FormatoDente(304, 233, 17, 15),
    53: FormatoDente(275, 258, 20, 20),
    54: FormatoDente(255, 298, 22, 24),
    55: FormatoDente(244, 346, 28, 25),
    61: FormatoDente(393, 227, 22, 17),
    62: FormatoDente(427, 235, 17, 15),
    63: FormatoDente(452, 262, 21, 22),
    64: FormatoDente(468, 300, 22, 24),
    65: FormatoDente(482, 350, 30, 29),
    71: FormatoDente(368, 666, 12, 12),
    72: FormatoDente(402, 660, 16, 13),
    73: FormatoDente(424, 645, 17, 17),
    74: FormatoDente(450, 616, 24, 24),
    75: FormatoDente(464, 557, 31, 33),
    81: FormatoDente(343, 666, 12, 12),
    82: FormatoDente(316, 660, 16, 13),
    83: FormatoDente(290, 643, 17, 17),
    84: FormatoDente(262, 611, 24, 24),
    85: FormatoDente(246, 557, 31, 33),
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
