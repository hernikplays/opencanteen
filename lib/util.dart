import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';
import 'package:opencanteen/okna/burza.dart';

import 'okna/jidelnicek.dart';

Drawer drawerGenerator(
    BuildContext context, Canteen canteen, String user, int p) {
  Drawer drawer = const Drawer();
  switch (p) {
    case 1:
      // Home page
      drawer = Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text("OpenCanteen"),
            ),
            ListTile(
              selected: true,
              title: const Text("Domů"),
              leading: const Icon(Icons.home),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Burza'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BurzaPage(canteen: canteen, user: user),
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
            const DrawerHeader(
              child: Text("OpenCanteen"),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Domů"),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) =>
                          JidelnicekPage(canteen: canteen, user: user))),
            ),
            ListTile(
              leading: const Icon(Icons.store),
              selected: true,
              title: const Text('Burza'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      );
  }
  return drawer;
}
