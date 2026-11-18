import 'package:flutter/material.dart';

/// Fundo institucional compartilhado por todas as rotas do aplicativo.
class BrandBackground extends StatelessWidget {
  const BrandBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset('assets/images/brand_background.png', fit: BoxFit.cover),
      child,
    ],
  );
}
