import 'package:flutter/material.dart';

class AppColors {
  // Cores Principais Obrigatórias
  static const Color black = Color(0xFF111827);       // Fundo dark, texto nobre, appBar
  static const Color blue = Color(0xFF2563EB);        // Cor de destaque, botões, rotas
  static const Color green = Color(0xFF16A34A);       // Online, Pix, sucesso, avaliações

  // Tons Secundários e Suporte
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);

  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color cardLight = Colors.white;
  static const Color surfaceLight = Color(0xFFF3F4F6);
  static const Color borderLight = Color(0xFFE5E7EB);

  // Acentos de Estado
  static const Color red = Color(0xFFDC2626);         // Offline, cancelar, erros
  static const Color yellow = Color(0xFFEAB308);      // Estrelas de avaliação, alertas
  static const Color grey = Color(0xFF6B7280);        // Textos secundários
  static const Color greyLight = Color(0xFF9CA3AF);   // Placeholders
}
