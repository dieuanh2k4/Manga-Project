import 'package:flutter/material.dart';

ThemeData theme() {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(
      0xFFDFE3ED,
    ), // Backing background behind shell
    cardColor: Colors.white, // Shell card background
    canvasColor: const Color(0xFFF7F8FC), // Main content container background
    fontFamily: 'Muli',
    appBarTheme: appBarTheme(),
  );
}

ThemeData darkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(
      0xFF1A1D2E,
    ), // Backing background behind shell
    cardColor: const Color(0xFF0E1326), // Shell card background
    canvasColor: const Color(0xFF080C1B), // Main content container background
    fontFamily: 'Muli',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0E1326),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white70),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
    ),
  );
}

AppBarTheme appBarTheme() {
  return const AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: Color(0XFF8B8B8B)),
    titleTextStyle: TextStyle(color: Color(0XFF8B8B8B), fontSize: 18),
  );
}
