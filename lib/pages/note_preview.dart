// ignore_for_file: avoid_print, unused_field, deprecated_member_use

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '/helpers/globals.dart' as globals;

import '../helpers/adaptive.dart';
import '../helpers/database_helper.dart';
import '../helpers/note_color.dart';
import '../helpers/utility.dart';
import '../models/note_list_model.dart';
import '../models/notes_model.dart';
import '../widgets/color_palette_button.dart';
import 'edit_note_page.dart';
import 'labels_page.dart';

class NoteReaderPage extends StatefulWidget {
  final Notes note;
  const NoteReaderPage({Key? key, required this.note}) : super(key: key);

  @override
  _NoteReaderPageState createState() => _NoteReaderPageState();
}

class _NoteReaderPageState extends State<NoteReaderPage> {
  late Notes note;
  final dbHelper = DatabaseHelper.instance;
  ScrollController scrollController = ScrollController();
  String currentEditingNoteId = "";
  List<String> _checkList = [];
  List<NoteListItem> _noteList = [];
  bool isDesktop = false;

  int selectedPageColor = 0;

  void _updateColor(String noteId, int noteColor) async {
    print(noteColor);
    await dbHelper.updateNoteColor(noteId, noteColor).then((value) {
      setState(() {
        selectedPageColor = noteColor;
      });
    });
  }

  void _deleteNote() async {
    await dbHelper.deleteNotes(currentEditingNoteId).then((value) {
      _onBackPressed();
    });
  }

  void _archiveNote(int archive) async {
    await dbHelper.archiveNote(currentEditingNoteId, archive).then((value) {
      _onBackPressed();
    });
  }

  void _noteToList() {
    if (note.noteText.contains('{')) {
      _checkList = note.noteText.replaceAll('[CHECKBOX]\n', '').split('\n');
      final parsed = json.decode(note.noteText).cast<Map<String, dynamic>>();
      _noteList = parsed
          .map<NoteListItem>((json) => NoteListItem.fromJson(json))
          .toList();
    }
  }

  @override
  void initState() {
    selectedPageColor = widget.note.noteColor;
    note = widget.note;
    _noteToList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool darkModeOn = (globals.themeMode == ThemeMode.dark ||
        (brightness == Brightness.dark &&
            globals.themeMode == ThemeMode.system));
    print(note.toJson());
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        backgroundColor: NoteColor.getColor(selectedPageColor, darkModeOn),
        appBar: AppBar(
          elevation: 0.2,
          backgroundColor: NoteColor.getColor(selectedPageColor, darkModeOn)
              .withOpacity(0.6),
          leading: Container(
            margin: const EdgeInsets.all(8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.pop(context, true);
              },
              child: const Icon(
                Iconsax.arrow_left_2,
                size: 15,
                color: Colors.black,
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: "Edit Note",
              onPressed: () {
                _showEdit(context, note);
              },
              color: Colors.black,
              icon: const Icon(Iconsax.edit_2),
            ),
            IconButton(
              tooltip: "Note color swatch",
              onPressed: () {
                _showColorPalette(context, note);
              },
              color: Colors.black,
              icon: const Icon(Iconsax.color_swatch),
            ),
            IconButton(
              onPressed: () {
                _assignLabel(note);
              },
              color: Colors.black,
              icon: const Icon(Iconsax.tag),
            ),
            // Archive
            Visibility(
              visible: note.noteArchived == 0,
              child: IconButton(
                tooltip: 'Archive',
                onPressed: () {
                  setState(() {
                    currentEditingNoteId = note.noteId;
                  });
                  _archiveNote(1);
                },
                color: Colors.black,
                icon: const Icon(Iconsax.archive_add),
              ),
            ),
            Visibility(
              visible: note.noteArchived == 1,
              child: IconButton(
                tooltip: 'Unarchive',
                onPressed: () {
                  setState(() {
                    currentEditingNoteId = note.noteId;
                  });
                  _archiveNote(0);
                },
                color: Colors.black,
                icon: const Icon(Iconsax.archive_minus),
              ),
            ),
            IconButton(
              tooltip: "Delete note",
              onPressed: () {
                setState(() {
                  currentEditingNoteId = note.noteId;
                });
                _confirmDelete();
              },
              color: Colors.black,
              icon: const Icon(Iconsax.trash),
            )
          ],
        ),
        body: note.noteText.contains('{')
            ? Column(
                children: [
                  Expanded(
                      child: ListView.builder(
                    itemBuilder: (context, index) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Visibility(
                            visible: note.noteTitle.isNotEmpty && index == 0,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(left: 8, top: 10),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                note.noteTitle,
                                style: GoogleFonts.roboto(
                                  color: Colors.black,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Checkbox(
                                value: _noteList[index].checked == 'true',
                                onChanged: (checked) {
                                  setState(() {
                                    if (_noteList[index].checked == 'true') {
                                      _noteList[index].checked = 'false';
                                    } else {
                                      _noteList[index].checked = 'true';
                                    }

                                    _saveNote();
                                  });
                                },
                                checkColor: darkModeOn && selectedPageColor == 0
                                    ? Colors.black
                                    : Colors.white,
                                activeColor:
                                    darkModeOn && selectedPageColor == 0
                                        ? Colors.white
                                        : Colors.black,
                                fillColor: MaterialStateProperty.all(
                                  darkModeOn && selectedPageColor == 0
                                      ? Colors.white
                                      : Colors.black,
                                )),
                            title: Text(
                              _noteList[index].value,
                              style: TextStyle(
                                fontSize: 17,
                                color: darkModeOn && selectedPageColor == 0
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    itemCount: _noteList.length,
                  )),
                ],
              )
            : SingleChildScrollView(
                controller: scrollController,
                child: SizedBox(
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10.0,
                      ),
                      Visibility(
                        visible: note.noteTitle.isNotEmpty,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(left: 8),
                          alignment: Alignment.centerLeft,
                          //! Note title
                          child: Text(
                            note.noteTitle,
                            style: GoogleFonts.roboto(
                                color: Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: !note.noteText.contains('('),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(left: 8),
                          alignment: Alignment.centerLeft,
                          child: MarkdownBody(
                            styleSheet: MarkdownStyleSheet(
                              a: const TextStyle(
                                color: Colors.blueAccent,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                              p: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            selectable: true,
                            shrinkWrap: true,
                            onTapLink: (text, href, title) {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      actionsPadding: const EdgeInsets.all(10),
                                      title: const Text('Attention!'),
                                      content: const Text(
                                          'Do you want to open the link?'),
                                      actions: [
                                        OutlinedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('No'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            if (await canLaunch(href!)) {
                                              await launch(
                                                href,
                                                forceSafariVC: false,
                                                forceWebView: false,
                                              );
                                              Navigator.pop(context);
                                            } else {
                                              throw 'Could not launch';
                                            }
                                          },
                                          child: const Text('Yes'),
                                        ),
                                      ],
                                    );
                                  });
                            },
                            data: note.noteText,
                            softLineBreak: true,
                            fitContent: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: BottomAppBar(
          //color: Colors.transparent.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    note.noteLabel.replaceAll(",", ", "),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      color: Colors.black,
                    ),
                  ),
                ),
                Text(
                  "Last Edited: ${Utility.formatDateTime(note.noteDate)}",
                  style: GoogleFonts.roboto(
                    fontSize: 23,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveNote() async {
    var _noteJson = jsonEncode(_noteList.map((e) => e.toJson()).toList());
    Notes _note = Notes(note.noteId, note.noteDate, note.noteTitle, _noteJson,
        note.noteLabel, note.noteArchived, note.noteColor, note.noteList);
    await dbHelper.updateNotes(_note).then((value) {});
    print(_noteJson);
  }

  void _showEdit(BuildContext context, Notes _note) async {
    final res = await Navigator.of(context).push(CupertinoPageRoute(
        builder: (BuildContext context) => EditNotePage(
              note: _note,
            )));
    setState(() {
      note = res;
      _noteToList();
    });
  }

  void _showColorPalette(BuildContext context, Notes _note) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool darkModeOn = (globals.themeMode == ThemeMode.dark ||
        (brightness == Brightness.dark &&
            globals.themeMode == ThemeMode.system));
    isDesktop = isDisplayDesktop(context);
    showModalBottomSheet(
        context: context,
        isDismissible: true,
        constraints: isDesktop
            ? const BoxConstraints(maxWidth: 450, minWidth: 400)
            : const BoxConstraints(),
        builder: (context) {
          return Container(
            margin: const EdgeInsets.only(bottom: 30),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ColorPaletteButton(
                      color: NoteColor.getColor(0, darkModeOn),
                      onTap: () {
                        _updateColor(_note.noteId, 0);
                        Navigator.pop(context);
                      },
                      isSelected: selectedPageColor == 0,
                    ),
                    ColorPaletteButton(
                      color: NoteColor.getColor(1, darkModeOn),
                      onTap: () {
                        _updateColor(_note.noteId, 1);
                        Navigator.pop(context);
                      },
                      isSelected: selectedPageColor == 1,
                    ),
                    ColorPaletteButton(
                      color: NoteColor.getColor(2, darkModeOn),
                      onTap: () {
                        _updateColor(_note.noteId, 2);
                        Navigator.pop(context);
                      },
                      isSelected: selectedPageColor == 2,
                    ),
                    ColorPaletteButton(
                      color: NoteColor.getColor(3, darkModeOn),
                      onTap: () {
                        _updateColor(_note.noteId, 3);
                        Navigator.pop(context);
                      },
                      isSelected: selectedPageColor == 3,
                    ),
                    ColorPaletteButton(
                      color: NoteColor.getColor(4, darkModeOn),
                      onTap: () {
                        _updateColor(_note.noteId, 4);
                        Navigator.pop(context);
                      },
                      isSelected: selectedPageColor == 4,
                    ),
                    ColorPaletteButton(
                      color: NoteColor.getColor(5, darkModeOn),
                      onTap: () {
                        _updateColor(_note.noteId, 5);
                        Navigator.pop(context);
                      },
                      isSelected: selectedPageColor == 5,
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  void _confirmDelete() async {
    isDesktop = isDisplayDesktop(context);
    showModalBottomSheet(
        context: context,
        isDismissible: true,
        constraints: isDesktop
            ? const BoxConstraints(maxWidth: 450, minWidth: 400)
            : const BoxConstraints(),
        builder: (context) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10.0),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                height: 160,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'Confirm',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(10),
                        child: Text('Are you sure you want to delete?'),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('No'),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: ElevatedButton(
                                onPressed: () {
                                  _deleteNote();
                                  Navigator.pop(context, true);
                                },
                                child: const Text('Yes'),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  void _assignLabel(Notes _note) async {
    var res = await Navigator.of(context).push(CupertinoPageRoute(
        builder: (BuildContext context) => LabelsPage(
              noteid: _note.noteId,
              notelabel: _note.noteLabel,
            )));
    if (res != null) {
      setState(() {
        note.noteLabel = res;
      });
    }
  }

  Future<bool> _onBackPressed() async {
    Navigator.pop(context, true);
    return false;
  }
}
