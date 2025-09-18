import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? backgroundColor;
  final Color? textColor;

  const AppLogo({
    super.key,
    this.size = 48,
    this.showText = true,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        final themeService = ThemeService();
        final primaryColor = themeService.primaryColor;
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: backgroundColor ?? primaryColor,
                borderRadius: BorderRadius.circular(size * 0.2),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Q',
                  style: TextStyle(
                    fontSize: size * 0.6,
                    fontWeight: FontWeight.bold,
                    color: textColor ?? Colors.white,
                  ),
                ),
              ),
            ),
            if (showText) ...[
              const SizedBox(width: 12),
              Text(
                'uickQuiz',
                style: TextStyle(
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class AppLogoIcon extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const AppLogoIcon({
    super.key,
    this.size = 32,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        final themeService = ThemeService();
        final primaryColor = themeService.primaryColor;
        
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? primaryColor,
            borderRadius: BorderRadius.circular(size * 0.2),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Q',
              style: TextStyle(
                fontSize: size * 0.6,
                fontWeight: FontWeight.bold,
                color: iconColor ?? Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
