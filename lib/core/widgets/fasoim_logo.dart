import 'package:flutter/material.dart';

class FasoImLogo extends StatelessWidget {
  const FasoImLogo({
    super.key,
    this.compact = false,
    this.light = false,
    this.showSubtitle = true,
  });

  final bool compact;
  final bool light;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 46.0 : 92.0;

    return Container(
      decoration: BoxDecoration(
        color: light ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(compact ? 8 : 14),
      ),
      padding: light ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3) : EdgeInsets.zero,
      child: Image.asset(
        'assets/images/logo_fasoim.png',
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: showSubtitle ? 'Logo FasoIM Immersion patriotique' : 'Logo FasoIM',
      ),
    );
  }
}
