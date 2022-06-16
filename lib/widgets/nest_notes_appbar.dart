// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '/helpers/globals.dart' as globals;

class SAppBar extends StatefulWidget {
  final String title;
  final List<Widget>? action;
  final bool? centerTitle;
  final Color? backgroundColor;
  final double? elevation;
  final Function? onTap;
  const SAppBar(
      {Key? key,
      required this.title,
      this.action,
      this.centerTitle,
      this.backgroundColor,
      this.elevation,
      this.onTap})
      : super(key: key);

  @override
  _SAppBarState createState() => _SAppBarState();
}

class _SAppBarState extends State<SAppBar> {
  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool darkModeOn = (globals.themeMode == ThemeMode.dark ||
        (brightness == Brightness.dark &&
            globals.themeMode == ThemeMode.system));
    return AppBar(
      leading: Container(
        margin: const EdgeInsets.all(8.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (widget.onTap == null) {
              Navigator.pop(context);
            } else {
              widget.onTap!();
            }
          },
          child: const Icon(
            Iconsax.arrow_left_2,
            size: 15,
          ),
        ),
      ),
      centerTitle: widget.centerTitle ?? true,
      backgroundColor: widget.backgroundColor,
      elevation: widget.elevation,
      title: Text(
        widget.title,
        style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      ),
      actions: widget.action,
    );
  }
}
