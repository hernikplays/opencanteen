import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';

import 'okna/home.dart';
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
              leading: const Icon(Icons.home),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Jídelníček'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      JidelnicekPage(canteen: canteen, user: user),
                ),
              ),
            ),
          ],
        ),
      );

      break;
    case 2:
      // Jidelnicek page
      drawer = Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text("OpenCanteen"),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) => HomePage(canteen: canteen, user: user))),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant),
              selected: true,
              title: const Text('Jídelníček'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      break;
  }
  return drawer;
}
