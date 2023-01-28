import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opencanteen/pw/platformwidget.dart';

class PlatformField extends PlatformWidget<TextField, CupertinoTextField> {
  final TextEditingController? controller;
  final bool? enabled;
  final bool obscureText;
  final String? labelText;
  final bool autocorrect;
  final TextInputType? keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final void Function(String)? onChanged;
  final List<String>? autofillHints;
  const PlatformField({
    super.key,
    this.controller,
    this.enabled,
    this.labelText,
    this.obscureText = false,
    this.autocorrect = false,
    this.keyboardType,
    this.inputFormatters = const [],
    this.onChanged,
    this.autofillHints,
  });

  @override
  TextField createAndroidWidget(BuildContext context) => TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        decoration: InputDecoration(labelText: labelText),
        autocorrect: autocorrect,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        autofillHints: autofillHints,
      );

  @override
  CupertinoTextField createIosWidget(BuildContext context) =>
      CupertinoTextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        prefix: (labelText == null) ? null : Text(labelText!),
        autocorrect: autocorrect,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
      );
}
