import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:opencanteen/pw/platformwidget.dart';

class PlatformButton extends PlatformWidget<TextButton, CupertinoButton> {
  final String text;
  final void Function()? onPressed;

  final TextStyle? textStyle;
  const PlatformButton(
      {super.key, required this.text, required this.onPressed, this.textStyle});

  @override
  TextButton createAndroidWidget(BuildContext context) => TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: textStyle,
        ),
      );

  @override
  CupertinoButton createIosWidget(BuildContext context) => CupertinoButton(
        onPressed: onPressed,
        child: Text(text, style: textStyle),
      );
}
