import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

class WaveBackground extends StatelessWidget {
  final double animation;

  const WaveBackground({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;

        return Stack(
          children: [
            // Background image
            Container(
              width: width,
              height: height,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/icons/background.webp'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Wave SVG with animation
            Positioned(
              bottom: -50 + 20 * math.sin(animation * math.pi * 2),
              left: 0,
              right: 0,
              child: SvgPicture.asset(
                'assets/static/wave.svg',
                width: width,
                fit: BoxFit.fitWidth,
              ),
            ),
          ],
        );
      },
    );
  }
}
