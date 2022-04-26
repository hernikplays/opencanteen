import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("O Aplikaci"),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("OpenCanteen", style: TextStyle(fontSize: 30)),
          const Text("© 2022 Matyáš Caras a přispěvatelé"),
          InkWell(
              onTap: () => launch(
                  "https://github.com/hernikplays/opencanteen/blob/main/LICENSE"),
              child: const Text("Vydáno pod licencí GNU GPLv3")),
          const SizedBox(height: 15),
          const Text("Použité knihovny:", style: TextStyle(fontSize: 19)),
          const SizedBox(height: 10),
          cudlik(
              "Flutter",
              "Copyright 2014 The Flutter Authors. All rights reserved, licence BSD 3-Clause",
              "https://github.com/flutter/flutter/blob/master/LICENSE"),
          const SizedBox(height: 10),
          cudlik(
              "Flutter_secure_storage",
              "Copyright 2017 German Saprykin. All rights reserved, licence BSD 3-Clause",
              "https://github.com/mogol/flutter_secure_storage/blob/develop/flutter_secure_storage/LICENSE"),
          const SizedBox(height: 10),
          cudlik(
              "connectivity_plus",
              "Copyright 2017 The Chromium Authors. All rights reserved, licence BSD 3-Clause",
              "https://github.com/fluttercommunity/plus_plugins/blob/main/packages/connectivity_plus/connectivity_plus/LICENSE"),
          const SizedBox(height: 10),
          cudlik(
              "url_launcher",
              "Copyright 2013 The Flutter Authors. All rights reserved, licence BSD 3-Clause",
              "https://github.com/flutter/plugins/blob/main/packages/url_launcher/url_launcher/LICENSE"),
          const SizedBox(height: 10),
          cudlik(
              "canteenlib",
              "Copyright (c) 2022 Matyáš Caras and contributors, licence MIT",
              "https://github.com/hernikplays/canteenlib/blob/main/LICENSE"),
          const SizedBox(height: 10),
          cudlik(
              "path_provider",
              "Copyright 2013 The Flutter Authors. All rights reserved., licence BSD-3-Clause",
              "https://github.com/flutter/plugins/blob/main/packages/path_provider/path_provider/LICENSE")
        ]),
      ),
    );
  }

  Widget cudlik(String nazev, String copyright, String licence) {
    return InkWell(
      onTap: () => launch(licence),
      child: Column(children: [
        Text(
          nazev,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          textAlign: TextAlign.center,
        ),
        Text(
          copyright,
        ),
      ]),
    );
  }
}
