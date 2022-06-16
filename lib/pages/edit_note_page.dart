// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../helpers/database_helper.dart';
import '../models/note_list_model.dart';
import '../models/notes_model.dart';
import '../widgets/note_edit_list_textfield.dart';
import '../widgets/nest_notes_appbar.dart';

class EditNotePage extends StatefulWidget {
  final Notes note;

  const EditNotePage({Key? key, required this.note}) : super(key: key);

  @override
  _EditNotePageState createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  final FocusNode titleFocusNode = FocusNode();
  final FocusNode contentFocusNode = FocusNode();
  final TextEditingController _noteTitleController = TextEditingController();
  final TextEditingController _noteTextController = TextEditingController();
  final TextEditingController _noteListTextController = TextEditingController();
  final bool _noteListCheckValue = false;
  String currentEditingNoteId = "";
  final String _noteListJsonString = "";
  final dbHelper = DatabaseHelper.instance;
  var uuid = const Uuid();
  late Notes note;
  bool isCheckList = false;
  final List<NoteListItem> _noteListItems = [];

  void _saveNote() async {
    if (currentEditingNoteId.isEmpty) {
      setState(() {
        note = Notes(
            uuid.v1(),
            DateTime.now().toString(),
            _noteTitleController.text,
            _noteTextController.text,
            '',
            0,
            0,
            _noteListJsonString);
      });
      await dbHelper.insertNotes(note).then((value) {
        // loadNotes();
      });
    } else {
      setState(() {
        note = Notes(
            currentEditingNoteId,
            DateTime.now().toString(),
            _noteTitleController.text,
            _noteTextController.text,
            '',
            0,
            0,
            _noteListJsonString);
      });
      await dbHelper.updateNotes(note).then((value) {
        // loadNotes();
      });
    }
  }

  void onSubmitListItem() async {
    _noteListItems.add(NoteListItem(_noteListTextController.text, 'false'));
    _noteListTextController.text = "";
    print(_noteListCheckValue);
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      note = widget.note;
      _noteTextController.text = note.noteText;
      _noteTitleController.text = note.noteTitle;
      currentEditingNoteId = note.noteId;
      isCheckList = note.noteList.contains('{');
    });
    titleFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Builder(builder: (context) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: SAppBar(
              backgroundColor: Colors.greenAccent,
              title: '',
              onTap: _onBackPressed,
            ),
          ),
          body: GestureDetector(
            onTap: () {
              contentFocusNode.requestFocus();
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListView(
                children: [
                  TextField(
                    style: GoogleFonts.roboto(
                        fontSize: 25, fontWeight: FontWeight.bold),
                    controller: _noteTitleController,
                    focusNode: titleFocusNode,
                    onSubmitted: (value) {
                      contentFocusNode.requestFocus();
                    },
                    decoration: InputDecoration(
                      hintStyle: GoogleFonts.roboto(
                          fontSize: 25, fontWeight: FontWeight.bold),
                      hintText: 'Title',
                      fillColor: Colors.transparent,
                      enabledBorder:
                          const OutlineInputBorder(borderSide: BorderSide.none),
                      focusedBorder:
                          const OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Divider(
                    thickness: 1.2,
                    endIndent: 10,
                    indent: 10,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  TextField(
                    //style: GoogleFonts.roboto(fontSize:25,fontWeight: FontWeight.bold),
                    controller: _noteTextController,
                    focusNode: contentFocusNode,
                    maxLines: null,
                    onSubmitted: (value) {
                      contentFocusNode.requestFocus();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Content',
                      fillColor: Colors.transparent,
                      enabledBorder:
                          OutlineInputBorder(borderSide: BorderSide.none),
                      focusedBorder:
                          OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                  ),
                  if (isCheckList)
                    ...List.generate(
                        _noteListItems.length, generatenoteListItems),
                  Visibility(
                    visible: isCheckList,
                    child: NoteEditListTextField(
                      checkValue: _noteListCheckValue,
                      controller: _noteListTextController,
                      onSubmit: () => onSubmitListItem(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget generatenoteListItems(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
      child: Row(
        children: [
          const Icon(Icons.check_box),
          const SizedBox(
            width: 5.0,
          ),
          Expanded(
            child: Text(_noteListItems[index].value),
          ),
        ],
      ),
    );
  }

  Future<bool> _onBackPressed() async {
    if (_noteTextController.text.isNotEmpty) {
      _saveNote();
      Navigator.pop(context, note);
    } else {
      Navigator.pop(context, false);
    }
    return false;
  }
}
