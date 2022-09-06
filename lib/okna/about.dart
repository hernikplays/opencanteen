import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../lang/lang.dart';

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
        title: Text(Languages.of(context)!.about),
      ),
      body: Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width - 50,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text("OpenCanteen", style: TextStyle(fontSize: 30)),
              Text(Languages.of(context)!.copyright),
              InkWell(
                  onTap: () => launchUrl(Uri.parse(
                      "https://github.com/hernikplays/opencanteen/blob/main/LICENSE")),
                  child: Text(Languages.of(context)!.license)),
              const SizedBox(height: 15),
              Text(Languages.of(context)!.usedLibs,
                  style: const TextStyle(fontSize: 19)),
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
                  "Copyright 2013 The Flutter Authors. All rights reserved, licence BSD-3-Clause",
                  "https://github.com/flutter/plugins/blob/main/packages/path_provider/path_provider/LICENSE"),
              const SizedBox(height: 10),
              cudlik(
                  "shared_preferences",
                  "Copyright 2013 The Flutter Authors. All rights reserved, licence BSD-3-Clause",
                  "https://github.com/flutter/plugins/blob/main/packages/path_provider/path_provider/LICENSE"),
              const SizedBox(height: 10),
              cudlik(
                  "introduction_screen",
                  "Copyright 2019 Jean-Charles Moussé, licence MIT",
                  "https://github.com/Pyozer/introduction_screen/blob/master/LICENSE"),
              const SizedBox(height: 10),
              cudlik(
                  "flutter_local_notifications",
                  "Copyright 2018 Michael Bui. All rights reserved, licence BSD-3-Clause",
                  "https://github.com/MaikuB/flutter_local_notifications/blob/master/flutter_local_notifications/LICENSE"),
              const SizedBox(height: 10),
              cudlik(
                  "timezone",
                  "Copyright 2014, timezone project authors, licence BSD-2-Clause",
                  "https://github.com/srawlins/timezone/blob/master/LICENSE"),
              const SizedBox(height: 10),
              cudlik(
                  "flutter_native_timezone",
                  "Copyright 2019 pinkfish, licence Apache 2.0",
                  "https://github.com/pinkfish/flutter_native_timezone/blob/master/LICENSE"),
            ]),
          ),
        ),
      ),
    );
  }

  Widget cudlik(String nazev, String copyright, String licence) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(licence)),
      child: Column(children: [
        Text(
          nazev,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          textAlign: TextAlign.center,
        ),
        Text(
          copyright,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
      ]),
    );
  }
}
