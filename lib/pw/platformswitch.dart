import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:opencanteen/pw/platformwidget.dart';

class PlatformSwitch extends PlatformWidget<Switch, CupertinoSwitch> {
  final bool value;
  final void Function(bool)? onChanged;
  final Color? thumbColor;
  const PlatformSwitch(
      {super.key,
      required this.value,
      required this.onChanged,
      this.thumbColor});

  @override
  Switch createAndroidWidget(BuildContext context) => Switch(
        value: value,
        onChanged: onChanged,
        thumbColor: MaterialStateProperty.all(thumbColor),
      );

  @override
  CupertinoSwitch createIosWidget(BuildContext context) => CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        thumbColor: thumbColor,
      );
}
