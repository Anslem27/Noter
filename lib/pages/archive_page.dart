// ignore_for_file: avoid_print, unused_local_variable

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
//import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/helpers/globals.dart' as globals;

import '../helpers/adaptive.dart';
import '../helpers/database_helper.dart';
import '../models/note_list_model.dart';
import '../models/notes_model.dart';
import '../notes_navigation.dart';
import '../widgets/grid_note.dart';
import '../widgets/list_note.dart';
import 'note_preview.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({Key? key}) : super(key: key);

  @override
  _ArchivePageState createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  late SharedPreferences sharedPreferences;
  List<Notes> notesList = [];
  bool isLoading = false;
  bool hasData = false;
  late ViewType _viewType;

  final TextEditingController _searchController = TextEditingController();
  final dbHelper = DatabaseHelper.instance;

  int selectedPageColor = 1;

  bool isDesktop = false;

  loadArchiveNotes() async {
    setState(() {
      isLoading = true;
    });

    await dbHelper.getNotesArchived(_searchController.text).then((value) {
      setState(() {
        print(value.length);
        isLoading = false;
        hasData = value.isNotEmpty;
        notesList = value;
      });
    });
  }

  getPref() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      bool isTile = sharedPreferences.getBool("is_tile") ?? false;
      _viewType = isTile ? ViewType.Tile : ViewType.Grid;
    });
  }

  @override
  void initState() {
    getPref();
    loadArchiveNotes();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool darkModeOn = (globals.themeMode == ThemeMode.dark ||
        (brightness == Brightness.dark &&
            globals.themeMode == ThemeMode.system));
    isDesktop = isDisplayDesktop(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            archiveTopBar(context, darkModeOn),
            SizedBox(
              height: 600,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Expanded(
                      child: isLoading
                          ? const Center(
                              child:  CircularProgressIndicator(),
                            )
                          : (hasData
                              ? (_viewType == ViewType.Grid
                                  ? archiveStaggeredGrid()
                                  : archiveListView())
                              : emptyArchive(context)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

//archive list _viewType
  archiveListView() {
    return ListView.builder(
      itemCount: notesList.length,
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemBuilder: (context, index) {
        var note = notesList[index];
        List<NoteListItem> _noteList = [];
        if (note.noteList.contains('{')) {
          final parsed =
              json.decode(note.noteText).cast<Map<String, dynamic>>();
          _noteList = parsed
              .map<NoteListItem>((json) => NoteListItem.fromJson(json))
              .toList();
        }
        return NoteCardList(
          note: note,
          onTap: () {
            setState(() {
              selectedPageColor = note.noteColor;
            });
            _showNoteReader(context, note);
          },
        );
      },
    );
  }

//archive staggered grid_note view
  archiveStaggeredGrid() {
    return StaggeredGridView.countBuilder(
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      // shrinkWrap: true,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: notesList.length,
      staggeredTileBuilder: (index) {
        return StaggeredTile.count(1, index.isOdd ? 0.9 : 1.02);
      },
      itemBuilder: (context, index) {
        var note = notesList[index];
        List<NoteListItem> _noteList = [];
        if (note.noteList.contains('{')) {
          final parsed =
              json.decode(note.noteText).cast<Map<String, dynamic>>();
          _noteList = parsed
              .map<NoteListItem>((json) => NoteListItem.fromJson(json))
              .toList();
        }
        return NoteCardGrid(
          note: note,
          onTap: () {
            setState(() {
              selectedPageColor = note.noteColor;
            });
            _showNoteReader(context, note);
          },
        );
      },
    );
  }

  archiveTopBar(BuildContext context, darkModeOn) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 25.0, left: 5, bottom: 25.0, right: 25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: "Back",
                //?remeber adaptive back button for full native experience.
                icon: Icon(Icons.adaptive.arrow_back),
                splashRadius: 24,
              ),
              Text(
                "My Archives",
                style: GoogleFonts.roboto(
                  color: Colors.black,
                  letterSpacing: 0.5,
                  fontSize: 33,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  offset: const Offset(12, 26),
                  blurRadius: 50,
                  spreadRadius: 0,
                  color: Colors.grey.withOpacity(.25),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: darkModeOn ? Colors.grey.shade800 : Colors.white,
              child: const Icon(
                Iconsax.archive,
                size: 25,
                color: Color(0xff53E88B),
              ),
            ),
          )
        ],
      ),
    );
  }

//an emty archive
  emptyArchive(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 80,
          ),
          Image.asset(
            "assets/illustrations/empty_test.png",
            alignment: Alignment.centerRight,
          ),
          SizedBox(height: MediaQuery.of(context).size.height / 18),
          const Text(
            'your archive is empty!',
            style: TextStyle(
              fontWeight: FontWeight.w300,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  String getDateString() {
    var formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    DateTime dt = DateTime.now();
    return formatter.format(dt);
  }

  void _showNoteReader(BuildContext context, Notes _note) async {
    isDesktop = isDisplayDesktop(context);
    if (isDesktop) {
      bool res = await showDialog(
          context: context,
          builder: (context) {
            return SizedBox(
              child: Dialog(
                child: SizedBox(
                  width: isDesktop ? 800 : MediaQuery.of(context).size.width,
                  child: NoteReaderPage(
                    note: _note,
                  ),
                ),
              ),
            );
          });
      if (res) loadArchiveNotes();
    } else {
      bool res = await Navigator.of(context).push(CupertinoPageRoute(
          builder: (BuildContext context) => NoteReaderPage(
                note: _note,
              )));
      if (res) loadArchiveNotes();
    }
  }
}
