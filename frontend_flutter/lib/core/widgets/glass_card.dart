import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double blur;
  final VoidCallback? onTap;
  final bool hasGlow;
  final Color? glowColor;

  const GlassCard({
    Key? key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.blur = 16.0,
    this.onTap,
    this.hasGlow = false,
    this.glowColor,
  }) : super(key: key);

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final defaultBg = widget.color ?? AppColors.cardBg;
    final hoverBg = widget.color != null 
        ? widget.color!.withOpacity(widget.color!.opacity + 0.05) 
        : AppColors.cardBgHover;
    
    final currentBg = _isHovered && widget.onTap != null ? hoverBg : defaultBg;
    final currentBorderColor = _isHovered && widget.onTap != null
        ? (widget.borderColor ?? AppColors.primary.withOpacity(0.4))
        : (widget.borderColor ?? AppColors.cardBorder);

    Widget cardContent = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: currentBg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: currentBorderColor,
          width: 1.0,
        ),
        boxShadow: widget.hasGlow || (_isHovered && widget.onTap != null)
            ? [
                BoxShadow(
                  color: widget.glowColor ?? AppColors.primaryGlow.withOpacity(0.15),
                  blurRadius: _isHovered ? 24.0 : 16.0,
                  spreadRadius: _isHovered ? 2.0 : 0.0,
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(16.0),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      cardContent = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
