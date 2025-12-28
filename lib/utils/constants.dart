import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static TextStyle bigTemp = GoogleFonts.inter(
    fontSize: 90,
    fontWeight: FontWeight.w200, // Thin aesthetic like iOS
    color: Colors.white,
  );

  static TextStyle city = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static TextStyle desc = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
  );

  static TextStyle hl = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
  
  // iOS Weather gradients
  static const LinearGradient sunnyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF29B2DD), Color(0xFF33AADD)],
  );

  static const LinearGradient rainyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1F1F1F), Color(0xFF2C3E50)], // Darker for rain
  );
}
