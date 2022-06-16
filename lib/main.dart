import 'package:flutter/material.dart';
import 'package:notes_taker/notes_navigation.dart';

//! Test a particualar file.
void main() {
  runApp(const Noter());
}

class Noter extends StatelessWidget {
  const Noter({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Noter',
      home: NestNotes(),
    );
  }
}
