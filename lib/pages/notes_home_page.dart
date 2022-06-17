// ignore_for_file: avoid_print, unused_local_variable, unused_element

import 'dart:convert';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:universal_platform/universal_platform.dart';
import '../widgets/fancy_toasts.dart';
import '/helpers/globals.dart' as globals;
import '../helpers/adaptive.dart';
import '../helpers/database_helper.dart';
import '../helpers/note_color.dart';
// import '../helpers/storage.dart';
import '../helpers/utility.dart';
import '../models/labels_model.dart';
import '../models/note_list_model.dart';
import '../models/notes_model.dart';
import '../notes_navigation.dart';
import '../widgets/color_palette_button.dart';
import '../widgets/grid_note.dart';
import '../widgets/list_note.dart';
import 'archive_page.dart';
import 'edit_note_page.dart';
import 'labels_page.dart';
import 'note_preview.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key, required this.title})
      : super(key: HomePage.staticGlobalKey);
  final String title;

  static final GlobalKey<_HomePageState> staticGlobalKey =
      GlobalKey<_HomePageState>();

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late SharedPreferences sharedPreferences;
  late ViewType _viewType;
  ViewType viewType = ViewType.Tile;
  ScrollController scrollController = ScrollController();
  List<Notes> notesListAll = [];
  List<Notes> notesList = [];
  List<Labels> labelList = [];
  bool isLoading = false;
  bool hasData = false;

  bool isAndroid = UniversalPlatform.isAndroid;
  bool isIOS = UniversalPlatform.isIOS;
  bool isWeb = UniversalPlatform.isWeb;
  bool isDesktop = false;
  String currentLabel = "";
  bool labelChecked = false;

  final dbHelper = DatabaseHelper.instance;
  var uuid = const Uuid();
  final TextEditingController _noteTitleController = TextEditingController();
  final TextEditingController _noteTextController = TextEditingController();
  String currentEditingNoteId = "";
  final TextEditingController _searchController = TextEditingController();

  int selectedPageColor = 1;

  getPref() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      bool isTile = sharedPreferences.getBool("is_tile") ?? false;
      _viewType = isTile ? ViewType.Tile : ViewType.Grid;
      viewType = isTile ? ViewType.Tile : ViewType.Grid;
    });
  }

  loadNotes() async {
    setState(() {
      isLoading = true;
    });

    if (isAndroid || isIOS) {
      await dbHelper.getNotesAll(_searchController.text).then((value) {
        setState(() {
          isLoading = false;
          hasData = value.isNotEmpty;
          notesList = value;
          notesListAll = value;
        });
      });
    }
  }

  loadLabels() async {
    await dbHelper.getLabelsAll().then((value) => setState(() {
          labelList = value;
          print(labelList.length);
        }));
  }

  void toggleView(ViewType viewType) {
    setState(() {
      _viewType = viewType;
      sharedPreferences.setBool("is_tile", _viewType == ViewType.Tile);
    });
  }

  void _updateColor(String noteId, int noteColor) async {
    print(noteColor);
    await dbHelper.updateNoteColor(noteId, noteColor).then((value) {
      loadNotes();
      setState(() {
        selectedPageColor = noteColor;
      });
    });
  }

  void _archiveNote(int archive) async {
    await dbHelper.archiveNote(currentEditingNoteId, archive).then((value) {
      loadNotes();
    });
  }

  void _deleteNote() async {
    await dbHelper.deleteNotes(currentEditingNoteId).then((value) {
      loadNotes();
    });
  }

  void _filterNotes() {
    setState(() {
      notesList = notesListAll.where((element) {
        return element.noteLabel.contains(currentLabel);
      }).toList();
    });
  }

  void _clearFilterNotes() {
    setState(() {
      notesList = notesListAll;
    });
  }

  @override
  void initState() {
    getPref();
    loadNotes();
    loadLabels();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool darkModeOn = (globals.themeMode == ThemeMode.dark ||
        (brightness == Brightness.dark &&
            globals.themeMode == ThemeMode.system));
    print(globals.themeMode);
    isDesktop = isDisplayDesktop(context);
    bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(
                  top: 15.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Noter",
                          textAlign: TextAlign.start,
                          style: GoogleFonts.roboto(
                            letterSpacing: 0.5,
                            fontSize: 40,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: IconButton(
                            splashRadius: 24,
                            onPressed: () {},
                            icon: const Icon(Iconsax.menu),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    actionsRow(darkModeOn, context),
                  ],
                ),
              ),
              SizedBox(
                height: 600,
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : (hasData
                        ? (_viewType == ViewType.Grid
                            ? staggeredNotes(isPortrait)
                            : listedNotes())
                        //! Case for empty notes
                        : emptyNotes()),
              ),
            ],
          ),
        ),
      ),
      endDrawer: labelsDrawer(darkModeOn, context),
      floatingActionButton: addNoteFAB(context, darkModeOn),
    );
  }

  actionsRow(bool darkModeOn, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 20),
        Visibility(
          visible: viewType == ViewType.Tile,
          child: CircleAvatar(
            radius: 25,
            backgroundColor: darkModeOn ? Colors.grey.shade800 : Colors.white,
            child: IconButton(
              splashRadius: 24,
              icon: SvgPicture.asset(
                "assets/svg/apps-delete.svg",
                color: Colors.greenAccent,
                height: 23,
              ),
              onPressed: () {
                setState(() {
                  viewType = ViewType.Grid;
                  HomePage.staticGlobalKey.currentState!.toggleView(viewType);
                });
              },
            ),
          ),
        ),
        Visibility(
          visible: viewType == ViewType.Grid,
          child: CircleAvatar(
            radius: 25,
            backgroundColor: darkModeOn ? Colors.grey.shade800 : Colors.white,
            child: IconButton(
              splashRadius: 23,
              icon: SvgPicture.asset(
                "assets/svg/apps-sort.svg",
                color: Colors.greenAccent,
                height: 25,
              ),
              onPressed: () {
                setState(() {
                  viewType = ViewType.Tile;
                  HomePage.staticGlobalKey.currentState!.toggleView(viewType);
                });
              },
            ),
          ),
        ),
        CircleAvatar(
          radius: 25,
          backgroundColor: darkModeOn ? Colors.grey.shade800 : Colors.white,
          child: IconButton(
            splashRadius: 24,
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => const SearchPage(),
                ),
              );
            },
            icon: const Icon(Iconsax.search_normal,
                size: 25, color: Colors.greenAccent),
          ),
        ),
        //labels
        CircleAvatar(
          radius: 25,
          backgroundColor: darkModeOn ? Colors.grey.shade800 : Colors.white,
          child: IconButton(
            splashRadius: 24,
            onPressed: () {
              openLabelEditor();
            },
            icon: const Icon(
              Iconsax.tag,
              size: 25,
              color: Colors.greenAccent,
            ),
          ),
        ),
        CircleAvatar(
          radius: 25,
          backgroundColor: darkModeOn ? Colors.grey.shade800 : Colors.white,
          child: IconButton(
            splashRadius: 24,
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => const ArchivePage(),
                ),
              );
            },
            icon: const Icon(
              Iconsax.archive,
              size: 25,
              color: Colors.greenAccent,
            ),
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  addNoteFAB(BuildContext context, darkModeOn) {
    return FloatingActionButton(
      backgroundColor: darkModeOn ? Colors.grey.shade800 : Colors.white,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      onPressed: () {
        setState(() {
          _noteTextController.text = '';
          _noteTitleController.text = '';
          currentEditingNoteId = "";
        });
        _showEdit(context, Notes('', '', '', '', '', 0, 0, ''));
      },
      child: SvgPicture.asset(
        "assets/svg/add-document.svg",
        color: Colors.greenAccent,
      ),
    );
  }

  Drawer labelsDrawer(bool darkModeOn, BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: darkModeOn
                  ? const Color.fromARGB(255, 123, 17, 142).withOpacity(0.5)
                  : const Color.fromARGB(255, 123, 17, 142).withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.only(left: 15, top: 56, bottom: 20),
            alignment: Alignment.center,
            child: Row(
              children: [
                const SizedBox(
                  width: 32,
                ),
                Text(
                  'My Labels',
                  style: GoogleFonts.roboto(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Iconsax.tag),
                    splashRadius: 24,
                    color: Colors.greenAccent,
                    onPressed: () {
                      Navigator.pop(context);
                      openLabelEditor();
                    },
                  ),
                ),
                const SizedBox(width: 5)
              ],
            ),
          ),
          if (labelList.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Iconsax.tag,
                      size: 80,
                      color: Color.fromARGB(255, 123, 17, 142),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "You havn't created\nany label",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
                    ),
                    TextButton(
                      onPressed: () {
                        openLabelEditor();
                      },
                      child: const Text(
                        'Create a label',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (labelList.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemBuilder: (context, index) {
                  Labels label = labelList[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      onTap: (() {
                        setState(() {
                          currentLabel = label.labelName;
                          _filterNotes();
                        });
                      }),
                      leading: const Icon(Iconsax.tag),
                      trailing: (currentLabel.isEmpty ||
                              currentLabel != label.labelName)
                          ? const Icon(
                              Icons.clear,
                              color: Colors.transparent,
                            )
                          : const Icon(
                              Icons.check_outlined,
                              color: FlexColor.jungleDarkPrimary,
                            ),
                      title: Text(label.labelName),
                    ),
                  );
                },
                itemCount: labelList.length,
              ),
            ),
          if (labelList.isNotEmpty)
            SafeArea(
              child: Column(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        // tileColor: constantAqua,
                        trailing: const Icon(Iconsax.close_square),
                        title: const Text(
                          'Clear Filter',
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 17,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            currentLabel = "";
                            _filterNotes();
                          });
                          Navigator.pop(context);
                        },
                        dense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

//for list type noted
  listedNotes() {
    return Container(
      alignment: Alignment.center,
      margin: isDesktop
          ? const EdgeInsets.symmetric(horizontal: 200)
          : const EdgeInsets.all(0),
      child: ListView.builder(
        itemCount: notesList.length,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
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
            onLongPress: () {
              _showOptionsSheet(context, note);
            },
          );
        },
      ),
    );
  }

//staggerded grid notes
  staggeredNotes(bool isPortrait) {
    return Container(
      margin: isPortrait
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 200),
      child: StaggeredGridView.countBuilder(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 0,
        physics: const BouncingScrollPhysics(),
        itemCount: notesList.length,
        staggeredTileBuilder: (index) {
          return StaggeredTile.count(1, index.isOdd ? 0.9 : 1.02);
        },
        itemBuilder: (context, index) {
          var note = notesList[index];
          List<NoteListItem> _noteList = [];
          if (note.noteList.contains('{')) {
            try {
              final parsed =
                  json.decode(note.noteText).cast<Map<String, dynamic>>();
              _noteList = parsed
                  .map<NoteListItem>((json) => NoteListItem.fromJson(json))
                  .toList();
              // ignore: empty_catches
            } on Exception {}
          }
          return NoteCardGrid(
            note: note,
            onTap: () {
              setState(() {
                selectedPageColor = note.noteColor;
              });
              _showNoteReader(context, note);
            },
            onLongPress: () {
              _showOptionsSheet(context, note);
            },
          );
        },
      ),
    );
  }

//illustration for empty notes
  emptyNotes() {
    return Container(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 150,
          ),
          //TODO: Edit image colors to match across app
          Image.asset("assets/illustrations/pixeltrue-vision-1.png"),
          const SizedBox(
            height: 20,
          ),
          Text(
            'Tap the add button\nto add a note!',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.roboto(fontWeight: FontWeight.w300, fontSize: 22),
          ),
        ],
      ),
    );
  }

  void openLabelEditor() async {
    var res = await Navigator.of(context).push(CupertinoPageRoute(
        builder: (BuildContext context) => const LabelsPage(
              noteid: '',
              notelabel: '',
            )));
    loadLabels();
  }

  openDialog(Widget page) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool darkModeOn = (globals.themeMode == ThemeMode.dark ||
        (brightness == Brightness.dark &&
            globals.themeMode == ThemeMode.system));
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: darkModeOn ? Colors.black : Colors.white,
            shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: darkModeOn ? Colors.white24 : Colors.black12,
                ),
                borderRadius: BorderRadius.circular(10)),
            child: Container(
              decoration: BoxDecoration(
                color: darkModeOn ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                  maxWidth: 600, minWidth: 400, minHeight: 600, maxHeight: 600),
              padding: const EdgeInsets.all(8),
              child: page,
            ),
          );
        });
  }

//! Bottom sheet onhold
  void _showOptionsSheet(BuildContext context, Notes _note) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool darkModeOn = brightness == Brightness.dark;
    isDesktop = isDisplayDesktop(context);
    showModalBottomSheet(
        context: context,
        isDismissible: true,
        isScrollControlled: true,
        constraints: isDesktop
            ? const BoxConstraints(maxWidth: 450, minWidth: 400)
            : const BoxConstraints(),
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return SizedBox(
                height: 480,
                child: SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      // mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            Navigator.of(context).pop();
                            setState(() {
                              _noteTextController.text =
                                  Utility.stripTags(_note.noteText);
                              _noteTitleController.text = _note.noteTitle;
                              currentEditingNoteId = _note.noteId;
                            });
                            _showEdit(context, _note);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: const <Widget>[
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Iconsax.edit_2),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Edit'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: const <Widget>[
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Iconsax.color_swatch),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Color Tone'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 60,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              shrinkWrap: true,
                              children: [
                                ColorPaletteButton(
                                  color: NoteColor.getColor(0, darkModeOn),
                                  onTap: () {
                                    _updateColor(_note.noteId, 0);
                                    Navigator.pop(context);
                                  },
                                  isSelected: _note.noteColor == 0,
                                ),
                                ColorPaletteButton(
                                  color: NoteColor.getColor(1, darkModeOn),
                                  onTap: () {
                                    _updateColor(_note.noteId, 1);
                                    Navigator.pop(context);
                                  },
                                  isSelected: _note.noteColor == 1,
                                ),
                                ColorPaletteButton(
                                  color: NoteColor.getColor(2, darkModeOn),
                                  onTap: () {
                                    _updateColor(_note.noteId, 2);
                                    Navigator.pop(context);
                                  },
                                  isSelected: _note.noteColor == 2,
                                ),
                                ColorPaletteButton(
                                  color: NoteColor.getColor(3, darkModeOn),
                                  onTap: () {
                                    _updateColor(_note.noteId, 3);
                                    Navigator.pop(context);
                                  },
                                  isSelected: _note.noteColor == 3,
                                ),
                                ColorPaletteButton(
                                  color: NoteColor.getColor(4, darkModeOn),
                                  onTap: () {
                                    _updateColor(_note.noteId, 4);
                                    Navigator.pop(context);
                                  },
                                  isSelected: _note.noteColor == 4,
                                ),
                                ColorPaletteButton(
                                  color: NoteColor.getColor(5, darkModeOn),
                                  onTap: () {
                                    _updateColor(_note.noteId, 5);
                                    Navigator.pop(context);
                                  },
                                  isSelected: _note.noteColor == 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            Navigator.pop(context);
                            _assignLabel(_note);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: const <Widget>[
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Iconsax.tag),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Assign a label'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Visibility(
                          visible: _note.noteArchived == 0,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: () {
                              Navigator.of(context).pop();
                              setState(() {
                                currentEditingNoteId = _note.noteId;
                              });
                              _archiveNote(1);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: const <Widget>[
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(Iconsax.archive_add),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Archive'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: _note.noteArchived == 1,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: () {
                              Navigator.of(context).pop();
                              setState(() {
                                currentEditingNoteId = _note.noteId;
                              });
                              _archiveNote(0);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: const <Widget>[
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(Iconsax.archive_minus),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Unarchive'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            Navigator.of(context).pop();
                            setState(() {
                              currentEditingNoteId = _note.noteId;
                            });
                            _confirmDelete();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: const <Widget>[
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Iconsax.trash),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: const <Widget>[
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Iconsax.close_circle),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Cancel'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        });
  }

  void _showNoteReader(BuildContext context, Notes _note) async {
    isDesktop = isDisplayDesktop(context);
    if (isDesktop) {
      bool res = await showDialog(
          context: context,
          builder: (context) {
            // ignore: avoid_unnecessary_containers
            return Container(
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
      if (res) loadNotes();
    } else {
      bool res = await Navigator.of(context).push(CupertinoPageRoute(
          builder: (BuildContext context) => NoteReaderPage(
                note: _note,
              )));
      if (res) loadNotes();
    }
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
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12))),
            margin: const EdgeInsets.only(bottom: 10.0),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                height: 160,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    // mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          'Confirm',
                          style: GoogleFonts.roboto(
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
                                style: OutlinedButton.styleFrom(
                                    primary: const Color.fromARGB(
                                        255, 204, 118, 112),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15))),
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('No'),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    primary: const Color.fromARGB(
                                        255, 204, 118, 112),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15))),
                                onPressed: () {
                                  _deleteNote();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      content: InfoToast(
                                        body: "You have deleted a note",
                                        title: "Deleted",
                                        widget: Icon(
                                          Iconsax.trash,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                  Navigator.pop(context, true);
                                },
                                child: const Text('Yes'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  void _assignLabel(Notes note) async {
    var res = await Navigator.of(context).push(CupertinoPageRoute(
        builder: (BuildContext context) => LabelsPage(
              noteid: note.noteId,
              notelabel: note.noteLabel,
            )));
    if (res != null) loadNotes();
  }

  void _showEdit(BuildContext context, Notes _note) async {
    if (!UniversalPlatform.isDesktop) {
      final res = await Navigator.of(context).push(CupertinoPageRoute(
          builder: (BuildContext context) => EditNotePage(
                note: _note,
              )));

      if (res is Notes) loadNotes();
    } else {
      openDialog(EditNotePage(
        note: _note,
      ));
    }
  }

  // Future<bool> _onBackPressed() async {
  //   if (!(_noteTitleController.text.isEmpty ||
  //       _noteTextController.text.isEmpty)) {
  //     _saveNote();
  //   }
  //   return true;
  // }

  String getDateString() {
    var formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    DateTime dt = DateTime.now();
    return formatter.format(dt);
  }
}
