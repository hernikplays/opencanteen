import 'dart:io';

import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:opencanteen/okna/burza.dart';
import 'package:opencanteen/okna/jidelnicek.dart';
import 'lang/lang.dart';

Drawer drawerGenerator(BuildContext context, Canteen canteen, int p) {
  Drawer drawer = const Drawer();
  switch (p) {
    case 1:
      // Home page
      drawer = Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text(Languages.of(context)!.appName),
            ),
            ListTile(
              selected: true,
              title: Text(Languages.of(context)!.home),
              leading: const Icon(Icons.home),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: Text(Languages.of(context)!.exchange),
              onTap: () => Navigator.push(
                context,
                platformRouter((context) => BurzaView(canteen: canteen)),
              ),
            ),
          ],
        ),
      );

      break;
    case 3:
      drawer = Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text(Languages.of(context)!.appName),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(Languages.of(context)!.home),
              onTap: () => Navigator.push(
                context,
                platformRouter((c) => MealView(canteen: canteen)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.store),
              selected: true,
              title: Text(Languages.of(context)!.exchange),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      );
  }
  return drawer;
}

class OfflineMeal {
  String name;
  String variant;
  bool ordered;
  double price;
  bool onExchange;
  DateTime day;

  OfflineMeal(
      {required this.name,
      required this.variant,
      required this.ordered,
      required this.price,
      required this.onExchange,
      required this.day});
}

/// Parses [DateTime] from [TimeOfDay]
DateTime timeToDate(TimeOfDay c) {
  var now = DateTime.now();
  return DateTime.parse(
      "${now.year}-${(now.month < 10 ? "0" : "") + now.month.toString()}-${(now.day < 10 ? "0" : "") + now.day.toString()} ${(c.hour < 10 ? "0" : "") + c.hour.toString()}:${(c.minute < 10 ? "0" : "") + c.minute.toString()}:00");
}

/// List of instances to be used in the dropdown menu
List<Map<String, String>> instance = [
  {"name": "SŠTE Brno, Olomoucká", "url": "https://stravovani.sstebrno.cz"},
  {"name": "Jiné", "url": ""}
];

/// Used to display either a toas or a snackbar
void showInfo(BuildContext context, String message) {
  if (Platform.isAndroid) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
      ),
    );
  } else {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}

Route platformRouter(Widget Function(BuildContext context) builder) =>
    (Platform.isAndroid)
        ? MaterialPageRoute(builder: builder)
        : CupertinoPageRoute(builder: builder);
