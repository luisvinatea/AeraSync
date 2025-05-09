import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A consistent AeraSync icon widget that can be used across the application
/// to ensure visual cohesion and brand identity.
class AeraSyncIcon extends StatelessWidget {
  /// Creates an AeraSync icon widget.
  ///
  /// The [size] parameter sets both width and height of the icon.
  /// The [color] parameter allows for optional tinting of the icon.
  const AeraSyncIcon({
    super.key, 
    this.size = 48.0,
    this.color,
  });

  /// Size of the icon (width and height will be the same).
  final double size;
  
  /// Optional color tint for the icon.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/aerasync_icon.svg',
      width: size,
      height: size,
      colorFilter: color != null 
          ? ColorFilter.mode(color!, BlendMode.srcIn) 
          : null,
    );
  }
}