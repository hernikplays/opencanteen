import 'dart:io';

import 'package:flutter/material.dart';

/// Abstract class used to create widgets for the respective platform UI library
abstract class PlatformWidget<A extends Widget, I extends Widget>
    extends StatelessWidget {
  const PlatformWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return createAndroidWidget(context);
    } else {
      return createIosWidget(context);
    }
  }

  A createAndroidWidget(BuildContext context);

  I createIosWidget(BuildContext context);
}
