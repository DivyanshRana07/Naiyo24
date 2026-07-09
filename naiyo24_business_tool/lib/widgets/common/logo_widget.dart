import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:naiyo24_business_tool/theme/theme.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({
    super.key,
    this.fontSize = 24,
    this.showTagline = false,
    this.textColor,
    this.secondaryTextColor,
  });

  final double fontSize;
  final bool showTagline;
  final Color? textColor;
  final Color? secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    final wordmarkColor =
        secondaryTextColor ?? (textColor ?? AppColors.textPrimary);
    final primaryPartColor = textColor ?? AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(fontSize * 0.25),
              child: Container(
                color: Colors.black,
                child: Image.asset(
                  'assets/images/naiyo24_official_logo.jpg',
                  width: fontSize * 1.2,
                  height: fontSize * 1.2,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Naiyo',
                    style: GoogleFonts.jaldi(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: primaryPartColor,
                    ),
                  ),
                  TextSpan(
                    text: '24',
                    style: GoogleFonts.jaldi(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: wordmarkColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'Business Tool',
            style: GoogleFonts.jaldi(
              fontSize: fontSize * 0.5,
              fontWeight: FontWeight.w400,
              color: textColor ?? AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}
