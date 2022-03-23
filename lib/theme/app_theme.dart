import 'package:flutter/material.dart';

//! Do not alter with these values.

class NoterTheme {
  //private contructor
  NoterTheme._();
  static final ThemeData lightTheme = ThemeData(
    focusColor: Colors.black,
    hoverColor: Colors.black,
    disabledColor: Colors.white,
    cardColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    brightness: Brightness.light,
    primarySwatch: diafconPrimaryColor,
    hintColor: const Color(0xff0F2576),
    primaryColor: const Color(0xFF0096FF),
  );
  static final ThemeData darkTheme = ThemeData(
    iconTheme: const IconThemeData(color: Colors.white),
    focusColor: Colors.white,
    disabledColor: const Color(0xFF0096FF),
    hoverColor: const Color(0xFF0096FF),
    appBarTheme: AppBarTheme(color: Colors.grey.shade900),
    cardColor: Colors.grey.shade900,
    scaffoldBackgroundColor: darkColor,
    primarySwatch: darkColor,
    primaryColor: Colors.grey.shade800,
    brightness: Brightness.dark,
    backgroundColor: Colors.grey.shade900,
    hintColor: darkColor,
  );
}

//custom Lighter dark blue material color
const MaterialColor diafconPrimaryColor = MaterialColor(
  0xff7fffd4,
  <int, Color>{
    //?no applied shades, maintained one constant
    50: Color(0xff7fffd4),
    100: Color(0xff7fffd4),
    200: Color(0xff7fffd4),
    300: Color(0xff7fffd4),
    400: Color(0xff7fffd4),
    500: Color(0xff7fffd4),
    600: Color(0xff7fffd4),
    700: Color(0xff7fffd4),
    800: Color(0xff7fffd4),
    900: Color(0xff7fffd4),
  },
);

//custom black material color
const MaterialColor darkColor = MaterialColor(
  0xff000000,
  <int, Color>{
    50: Color(0xff000000),
    100: Color(0xff000000),
    200: Color(0xff000000),
    300: Color(0xff000000),
    400: Color(0xff000000),
    500: Color(0xff000000),
    600: Color(0xff000000),
    700: Color(0xff000000),
    800: Color(0xff000000),
    900: Color(0xff000000),
  },
);
