import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';
import 'package:opencanteen/okna/burza.dart';

import 'lang/lang.dart';
import 'okna/jidelnicek.dart';

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
                MaterialPageRoute(
                  builder: (context) => BurzaPage(canteen: canteen),
                ),
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
                  MaterialPageRoute(
                      builder: (c) => JidelnicekPage(canteen: canteen))),
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

class OfflineJidlo {
  String nazev;
  String varianta;
  bool objednano;
  double cena;
  bool naBurze;
  DateTime den;

  OfflineJidlo(
      {required this.nazev,
      required this.varianta,
      required this.objednano,
      required this.cena,
      required this.naBurze,
      required this.den});
}
