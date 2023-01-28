import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:opencanteen/pw/platformwidget.dart';

class PlatformDialog extends PlatformWidget<AlertDialog, CupertinoAlertDialog> {
  final String title;
  final String? content;
  final List<Widget> actions;
  const PlatformDialog(
      {super.key, required this.title, this.content, this.actions = const []});

  @override
  AlertDialog createAndroidWidget(BuildContext context) => AlertDialog(
        title: Text(title),
        content: (content != null)
            ? SingleChildScrollView(child: Text(content!))
            : null,
        actions: actions,
      );

  @override
  CupertinoAlertDialog createIosWidget(BuildContext context) =>
      CupertinoAlertDialog(
        title: Text(title),
        content: (content != null)
            ? SingleChildScrollView(child: Text(content!))
            : null,
        actions: actions,
      );
}
