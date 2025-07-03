import 'package:flutter/material.dart';

enum ButtonType { primary, secondary, outlined, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool fullWidth;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
    this.padding,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget buttonContent = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(text),
            ],
          );

    switch (type) {
      case ButtonType.primary:
        return SizedBox(
          width: fullWidth ? double.infinity : width,
          height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: padding != null
                ? ElevatedButton.styleFrom(padding: padding)
                : null,
            child: buttonContent,
          ),
        );
      case ButtonType.secondary:
        return SizedBox(
          width: fullWidth ? double.infinity : width,
          height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              padding: padding,
            ),
            child: buttonContent,
          ),
        );
      case ButtonType.outlined:
        return SizedBox(
          width: fullWidth ? double.infinity : width,
          height: height,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: padding != null
                ? OutlinedButton.styleFrom(padding: padding)
                : null,
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(text),
                    ],
                  ),
          ),
        );
      case ButtonType.text:
        return SizedBox(
          width: fullWidth ? double.infinity : width,
          height: height,
          child: TextButton(
            onPressed: isLoading ? null : onPressed,
            style: padding != null
                ? TextButton.styleFrom(padding: padding)
                : null,
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(text),
                    ],
                  ),
          ),
        );
    }
  }
}
