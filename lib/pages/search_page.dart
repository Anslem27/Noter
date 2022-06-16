// ignore_for_file: avoid_print

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '/helpers/globals.dart' as globals;

import '../helpers/database_helper.dart';
import '../models/notes_model.dart';
import '../widgets/list_note.dart';
import 'note_preview.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Notes> notesList = [];
  int selectedPageColor = 1;
  final dbHelper = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  final FocusNode searchFocusNode = FocusNode();

  bool _showClearButton = false;

  loadNotes(searchText) async {
    if (searchText.toString().isEmpty) {
      notesList.clear();
    } else {
      await dbHelper.getNotesAll(searchText).then((value) {
        setState(() {
          print(value.length);
          notesList = value;
        });
      });
    }
  }

  @override
  void initState() {
    // loadNotes();
    _searchController.addListener(() {
      setState(() {
        _showClearButton = _searchController.text.isNotEmpty;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool darkModeOn = (globals.themeMode == ThemeMode.dark ||
        (brightness == Brightness.dark &&
            globals.themeMode == ThemeMode.system));
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: 25.0, left: 5, bottom: 25.0, right: 25.0),
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
                        "Search notes",
                        style: GoogleFonts.roboto(
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
                      backgroundColor: Theme.of(context).cardColor,
                      child: const Icon(
                        Iconsax.search_favorite,
                        size: 25,
                        color: Colors.greenAccent,
                      ),
                    ),
                  )
                ],
              ),
            ),
            Container(
              child: searchTextField(darkModeOn),
            ),
            emptySearchIllustration(context),
            searchedList()
          ],
        ),
      ),
    );
  }

  searchTextField(bool darkModeOn) {
    return Row(
      children: [
        const SizedBox(
          width: 20,
        ),
        Expanded(
          child: TextField(
            controller: _searchController,
            focusNode: searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: const Icon(Iconsax.search_favorite),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.purple),
              ),
            ),
            onChanged: (value) => loadNotes(value),
          ),
        ),
        const SizedBox(width: 10),
        Visibility(
          visible: _showClearButton,
          child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _searchController.clear();
                });
                notesList.clear();
              },
              child: const Icon(Iconsax.close_circle)),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

//search results
  searchedList() {
    return Visibility(
      visible: _searchController.text.isNotEmpty,
      child: Expanded(
          child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ListView.builder(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          itemBuilder: (context, index) {
            return NoteCardList(
              note: notesList[index],
              onTap: () {
                _showNoteReader(context, notesList[index]);
              },
            );
          },
          itemCount: notesList.length,
        ),
      )),
    );
  }

//simlple searching illustration
  emptySearchIllustration(BuildContext context) {
    return Visibility(
      visible: _searchController.text.isEmpty,
      child: Expanded(
        child: Container(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height / 19,
              ),
              Image.asset("assets/illustrations/fogg-searching-a-book.png"),
              const SizedBox(height: 20),
              const Text(
                'Browse your notes',
                style: TextStyle(fontWeight: FontWeight.w300, fontSize: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoteReader(BuildContext context, Notes _note) async {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (BuildContext context) => NoteReaderPage(
          note: _note,
        ),
      ),
    );
  }
}
