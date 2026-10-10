import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_animations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class WingmanButton extends StatefulWidget {
  const WingmanButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.expand = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expand;
  final IconData? icon;

  @override
  State<WingmanButton> createState() => _WingmanButtonState();
}

class _WingmanButtonState extends State<WingmanButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: AppAnimations.fast,
      child: SizedBox(
        width: widget.expand ? double.infinity : null,
        height: AppSpacing.buttonHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: enabled ? AppColors.accentGradient : null,
            color: enabled ? null : AppColors.surfaceHighlight,
            borderRadius: AppRadius.button,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppRadius.button,
              onTap: enabled
                  ? () {
                      HapticFeedback.lightImpact();
                      widget.onPressed?.call();
                    }
                  : null,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.champagne,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: enabled
                                  ? AppColors.champagne
                                  : AppColors.textTertiary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: enabled
                                      ? AppColors.champagne
                                      : AppColors.textTertiary,
                                  letterSpacing: 0.4,
                                ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WingmanSecondaryButton extends StatelessWidget {
  const WingmanSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : null,
      height: AppSpacing.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blush,
          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.45)),
          shape: const StadiumBorder(),
          textStyle: Theme.of(context).textTheme.labelLarge,
        ),
        child: Text(label),
      ),
    );
  }
}

class WingmanIconButton extends StatelessWidget {
  const WingmanIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: AppColors.surfaceElevated,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.borderSubtle),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class WingmanTextButton extends StatelessWidget {
  const WingmanTextButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentSoft,
        minimumSize: const Size(44, 44),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
      child: Text(label),
    );
  }
}
