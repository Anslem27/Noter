import 'package:flutter/material.dart';
//import 'package:notes_taker/theme/app_theme.dart';

import 'screens/note_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'NoteKeeper',
      /*  theme: NoterTheme.lightTheme,
      darkTheme: NoterTheme.darkTheme, */
      debugShowCheckedModeBanner: false,
      home: NoteList(),
    );
  }
}
