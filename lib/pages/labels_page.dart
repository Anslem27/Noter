import 'dart:async';
import 'package:flex_color_scheme/flex_color_scheme.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';
import '../helpers/database_helper.dart';
import '../models/labels_model.dart';
import '../widgets/fancy_toasts.dart';

class LabelsPage extends StatefulWidget {
  final String noteid;
  final String notelabel;

  const LabelsPage({Key? key, required this.noteid, required this.notelabel})
      : super(key: key);
  @override
  _LabelsPageState createState() => _LabelsPageState();
}

class _LabelsPageState extends State<LabelsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final dbHelper = DatabaseHelper.instance;
  late StreamController<List<Labels>> _labelsController;
  final TextEditingController _newLabelController = TextEditingController();
  var uuid = const Uuid();
  List _selectedLabels = [];

  loadLabels() async {
    final allRows = await dbHelper.getLabelsAll();
    _labelsController.add(allRows);
  }

  void _saveLabel() async {
    if (_newLabelController.text.isNotEmpty) {
      await dbHelper
          .insertLabel(Labels(uuid.v1(), _newLabelController.text))
          .then((value) {
        setState(() {
          _newLabelController.text = "";
        });
        loadLabels();
      });
    }
  }

  void _deleteLabel(String labelId) async {
    await dbHelper.deleteLabel(labelId).then((value) {
      loadLabels();
    });
  }

  void _assignLabel() async {
    await dbHelper
        .updateNoteLabel(widget.noteid, _selectedLabels.join(","))
        .then((value) {
      Navigator.pop(context, _selectedLabels.join(","));
    });
  }

  Future showTip() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text('Tap on the Label to Assign to a Note'),
      duration: Duration(seconds: 5),
    ));
  }

  void _onLabelSelected(bool selected, String labelName) {
    if (selected) {
      setState(() {
        _selectedLabels.add(labelName);
      });
    } else {
      setState(() {
        _selectedLabels.remove(labelName);
      });
    }
  }

  @override
  void initState() {
    _labelsController = StreamController<List<Labels>>();
    loadLabels();
    super.initState();
    if (widget.notelabel.isNotEmpty) {
      _selectedLabels = widget.notelabel.split(",");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        key: _scaffoldKey,
        body: SafeArea(
          child: Column(
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
                          icon: Icon(Icons.adaptive.arrow_back),
                          splashRadius: 24,
                        ),
                        Text(
                          "My labels",
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Theme.of(context).cardColor,
                            child: const Icon(
                              Iconsax.tag,
                              size: 25,
                              color: Colors.greenAccent,
                            ),
                          ),
                          Visibility(
                            visible: widget.noteid.isNotEmpty,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  primary: Colors.greenAccent,
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(23),
                                  ),
                                ),
                                child: const Text('Done'),
                                onPressed: () => _assignLabel(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 600,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // SizedBox(height: MediaQuery.of(context).size.height / 19),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newLabelController,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  hintText: 'Add a Label',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: const BorderSide(color: Colors.blue),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide:
                                        const BorderSide(color: Colors.purple),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              splashRadius: 24,
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                _saveLabel();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    content: SuccessToast(
                                      body: "You have created a  label",
                                      title: "Label",
                                      widget: Icon(
                                        Iconsax.tag,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              splashRadius: 24,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    content: InfoToast(
                                      body:
                                          "Swipe either left or right to delete a label",
                                      title: "Edit Label!",
                                      widget: Icon(
                                        Iconsax.tag,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.info_outline_rounded),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          "assets/illustrations/Saly-5.png",
                          alignment: Alignment.center,
                          height: MediaQuery.of(context).size.height / 3.5,
                          width: MediaQuery.of(context).size.width / 2.5,
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height / 19),
                      const SizedBox(height: 10),
                      Expanded(
                        child: StreamBuilder<List<Labels>>(
                            stream: _labelsController.stream,
                            builder: (BuildContext context,
                                AsyncSnapshot<List<Labels>> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color.fromARGB(255, 204, 118, 112),
                                  ),
                                );
                              }
                              if (snapshot.hasError) {
                                return Text(snapshot.error.toString());
                              }
                              if (snapshot.hasData) {
                                return ListView.builder(
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    var label = snapshot.data![index];
                                    return Dismissible(
                                      background: SizedBox(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Container(
                                                alignment: Alignment.centerLeft,
                                                padding: const EdgeInsets.only(
                                                    left: 15.0),
                                                decoration: const BoxDecoration(
                                                  color:
                                                      FlexColor.redDarkPrimary,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    bottomLeft:
                                                        Radius.circular(10),
                                                    topLeft:
                                                        Radius.circular(10),
                                                  ),
                                                ),
                                                child: const Icon(Icons
                                                    .delete_outline_rounded),
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                alignment:
                                                    Alignment.centerRight,
                                                padding: const EdgeInsets.only(
                                                    right: 15.0),
                                                decoration: const BoxDecoration(
                                                  color:
                                                      FlexColor.redDarkPrimary,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    bottomRight:
                                                        Radius.circular(
                                                      10,
                                                    ),
                                                    topRight: Radius.circular(
                                                      10,
                                                    ),
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.delete_outline_rounded,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      key: Key(label.labelId),
                                      onDismissed: (direction) {
                                        setState(() {
                                          _deleteLabel(label.labelId);
                                          snapshot.data!.removeAt(index);
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            backgroundColor: Colors.transparent,
                                            elevation: 0,
                                            content: FancySnackBar(
                                              body: "You have deleted a  label",
                                              title: "Deleted!",
                                              widget: Icon(
                                                Iconsax.trash,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: widget.noteid.isNotEmpty
                                          ? CheckboxListTile(
                                              value: _selectedLabels
                                                  .contains(label.labelName),
                                              title: Text(label.labelName),
                                              onChanged: (value) {
                                                _onLabelSelected(
                                                    value!, label.labelName);
                                              },
                                            )
                                          : ListTile(
                                              //TODO: Add another label image
                                              leading: SvgPicture.asset(
                                                  "assets/svg/box.svg",
                                                  height: 22),
                                              title: Text(
                                                label.labelName,
                                                style: GoogleFonts.roboto(),
                                              ),
                                            ),
                                    );
                                  },
                                );
                              } else {
                                return const Center(
                                  child:
                                      Text("You hav'nt created any note yet"),
                                );
                              }
                            }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _onBackPressed() async {
    Navigator.pop(context, null);
    return true;
  }
}
