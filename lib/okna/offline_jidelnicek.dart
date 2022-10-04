import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opencanteen/util.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../lang/lang.dart';
import '../main.dart';

class OfflineJidelnicek extends StatefulWidget {
  const OfflineJidelnicek({Key? key, required this.jidla}) : super(key: key);
  final List<OfflineJidlo> jidla;
  @override
  State<OfflineJidelnicek> createState() => _OfflineJidelnicekState();
}

class _OfflineJidelnicekState extends State<OfflineJidelnicek> {
  List<Widget> obsah = [const CircularProgressIndicator()];
  DateTime den = DateTime.now();
  String denTydne = "";
  Future<void> nactiJidlo() async {
    den = widget.jidla[0].den;
    switch (den.weekday) {
      case 2:
        denTydne = Languages.of(context)!.tuesday;
        break;
      case 3:
        denTydne = Languages.of(context)!.wednesday;
        break;
      case 4:
        denTydne = Languages.of(context)!.thursday;
        break;
      case 5:
        denTydne = Languages.of(context)!.friday;
        break;
      case 6:
        denTydne = Languages.of(context)!.saturday;
        break;
      case 7:
        denTydne = Languages.of(context)!.sunday;
        break;
      default:
        denTydne = Languages.of(context)!.monday;
    }
    obsah = [];
    for (OfflineJidlo j in widget.jidla) {
      obsah.add(
        Padding(
          padding: const EdgeInsets.only(top: 15),
          child: InkWell(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(j.varianta),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  j.nazev,
                ),
              ),
              Text((j.naBurze)
                  ? Languages.of(context)!.inExchange
                  : "${j.cena} Kč"),
              Checkbox(
                  value: j.objednano,
                  fillColor: MaterialStateProperty.all(Colors.grey),
                  onChanged: (v) async {
                    return;
                  })
            ],
          )),
        ),
      );
    }
    setState(() {});
  }

  void kliknuti(String value, BuildContext context) async {
    if (value == Languages.of(context)!.signOut) {
      const storage = FlutterSecureStorage();
      storage.deleteAll();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (c) => const LoginPage()));
    } else if (value == Languages.of(context)!.review) {
      (Platform.isAndroid)
          ? launchUrl(
              Uri.parse("market://details?id=cz.hernikplays.opencanteen"),
              mode: LaunchMode.externalApplication)
          : launchUrl(
              Uri.parse(
                  "https://apps.apple.com/cz/app/opencanteen/id1621124445"),
              mode: LaunchMode.externalApplication);
    } else if (value == Languages.of(context)!.reportBugs) {
      launchUrl(Uri.parse("https://forms.gle/jKN7QeFJwpaApSbC8"),
          mode: LaunchMode.externalApplication);
    } else if (value == Languages.of(context)!.about) {
      var packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      showAboutDialog(
          context: context,
          applicationName: "OpenCanteen",
          applicationLegalese:
              "${Languages.of(context)!.copyright}\n${Languages.of(context)!.license}",
          applicationVersion: packageInfo.version,
          children: [
            TextButton(
                onPressed: (() => launchUrl(
                    Uri.parse("https://github.com/hernikplays/opencanteen"))),
                child: Text(Languages.of(context)!.source))
          ]);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    nactiJidlo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Languages.of(context)!.menu),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton(
            onSelected: ((String value) => kliknuti(value, context)),
            itemBuilder: (BuildContext context) {
              return {
                Languages.of(context)!.reportBugs,
                Languages.of(context)!.review,
                Languages.of(context)!.about,
                Languages.of(context)!.signOut
              }.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 50,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  Languages.of(context)!.offline,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(Languages.of(context)!.mustLogout),
                const SizedBox(height: 10),
                TextButton(
                  child:
                      Text("${den.day}. ${den.month}. ${den.year} - $denTydne"),
                  onPressed: () => {},
                ),
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: obsah,
                  ),
                ),
              ],
            ),
          ),
        ),
        onRefresh: () => Navigator.pushReplacement(context,
            MaterialPageRoute(builder: ((context) => const LoginPage()))),
      ),
    );
  }
}
