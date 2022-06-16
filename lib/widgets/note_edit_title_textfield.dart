import 'package:flutter/material.dart';

class NoteEditTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? onSubmitFocusNode;
  final String? hint;
  final bool? isContentField;
  const NoteEditTextField(
      {Key? key,
      required this.controller,
      this.focusNode,
      this.onSubmitFocusNode,
      this.hint,
      this.isContentField})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: isContentField ?? false
          ? TextInputType.multiline
          : TextInputType.text,
      onSubmitted: isContentField ?? false
          ? null
          : (value) => onSubmitFocusNode?.requestFocus(),
      maxLines: null,
      decoration: InputDecoration.collapsed(
          hintText: hint ?? 'Hint',
          hintStyle: TextStyle(
              fontWeight: isContentField ?? false
                  ? FontWeight.normal
                  : FontWeight.bold)),
    );
  }
}
