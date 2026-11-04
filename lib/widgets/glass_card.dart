import 'dart:ui';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Apple-grade Frosted Liquid Glass Card inspired by WhatsApp for iOS & macOS.
/// Uses genuine hardware-accelerated BackdropFilter with specular gradient borders.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double blur;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 14,
    this.blur = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Translucent Liquid Glass backdrops
    final defaultBg = isLight
        ? (backgroundColor ?? Colors.white).withValues(alpha: 0.78)
        : (backgroundColor ?? const Color(0xFF0F172A)).withValues(alpha: 0.62);

    // Specular hairline borders
    final defaultBorder = borderColor ??
        (isLight
            ? Colors.black.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.12));

    final defaultTextColor = isLight ? AppColors.lightTextPrimary : AppColors.textPrimary;
    final defaultIconColor = isLight ? AppColors.lightTextPrimary : AppColors.textPrimary;
    final shadowColor = isLight
        ? Colors.black.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.22);

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: defaultBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: defaultBorder,
          width: 0.6,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: defaultTextColor),
        child: IconTheme.merge(
          data: IconThemeData(color: defaultIconColor),
          child: child,
        ),
      ),
    );

    // Hardware-accelerated frosted blur
    Widget glass = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: isLight ? 10 : 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: (isLight ? Colors.black : Colors.white).withValues(alpha: 0.05),
          highlightColor: (isLight ? Colors.black : Colors.white).withValues(alpha: 0.02),
          child: glass,
        ),
      );
    }

    return glass;
  }
}
