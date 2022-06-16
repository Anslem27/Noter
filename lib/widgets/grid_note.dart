import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/helpers/globals.dart' as globals;

import '../helpers/note_color.dart';
import '../helpers/utility.dart';
import '../models/notes_model.dart';

class NoteCardGrid extends StatefulWidget {
  final Notes? note;
  final Function onTap;
  final Function? onLongPress;
  const NoteCardGrid(
      {Key? key, this.note, required this.onTap, this.onLongPress})
      : super(key: key);

  @override
  _NoteCardGridState createState() => _NoteCardGridState();
}

class _NoteCardGridState extends State<NoteCardGrid> {
  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool darkModeOn = (globals.themeMode == ThemeMode.dark ||
        (brightness == Brightness.dark &&
            globals.themeMode == ThemeMode.system));
    return Container(
      margin: const EdgeInsets.only(
        top: 10,
      ),
      child: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(12),
          ),
        ),
        color: NoteColor.getColor(widget.note!.noteColor, darkModeOn),
        child: InkWell(
          borderRadius: BorderRadius.circular(15.0),
          onTap: () => widget.onTap(),
          onLongPress: () => widget.onLongPress!(),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Visibility(
                  visible: widget.note!.noteTitle.isNotEmpty,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      widget.note!.noteTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      widget.note!.noteText,
                      maxLines: 6,
                      overflow: TextOverflow.fade,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
                // NOTE WITH CHECK BOX
                // Visibility(
                //   visible: widget.note.noteList.contains('{'),
                //   child: Expanded(
                //     child: Padding(
                //       padding: const EdgeInsets.all(8.0),
                //       child: NotesListViewExt(
                //           noteListItems: _noteList, noteColor: widget.note.noteColor),
                //     ),
                //   ),
                // ),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(
                        widget.note!.noteLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12.0),
                      )),
                      Text(
                        Utility.formatDateTime(widget.note!.noteDate),
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
