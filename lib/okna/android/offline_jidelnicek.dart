import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opencanteen/okna/android/login.dart';
import 'package:opencanteen/util.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../lang/lang.dart';

class AndroidOfflineJidelnicek extends StatefulWidget {
  const AndroidOfflineJidelnicek({Key? key}) : super(key: key);
  @override
  State<AndroidOfflineJidelnicek> createState() =>
      _AndroidOfflineJidelnicekState();
}

class _AndroidOfflineJidelnicekState extends State<AndroidOfflineJidelnicek> {
  List<Widget> obsah = [const CircularProgressIndicator()];
  var _skipWeekend = false;
  DateTime den = DateTime.now();
  String denTydne = "";
  List<List<OfflineJidlo>> data = [];
  var jidloIndex = 0;

  void nactiZeSouboru() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    for (var f in appDocDir.listSync()) {
      if (f.path.contains("jidelnicek")) {
        var soubor = File(f.path);
        var input = await soubor.readAsString();
        var r = jsonDecode(input);
        List<OfflineJidlo> jidla = [];
        for (var j in r) {
          jidla.add(OfflineJidlo(
              nazev: j["nazev"],
              varianta: j["varianta"],
              objednano: j["objednano"],
              cena: j["cena"],
              naBurze: j["naBurze"],
              den: DateTime.parse(j["den"])));
        }
        data.add(jidla);
      }
    }
    nactiJidlo();
  }

  Future<void> nactiJidlo() async {
    var jidelnicek = data[jidloIndex];
    den = jidelnicek[0].den;
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
    for (OfflineJidlo j in jidelnicek) {
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
                  },
                )
              ],
            ),
          ),
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
          context, MaterialPageRoute(builder: (c) => const AndroidLogin()));
    } else if (value == Languages.of(context)!.review) {
      launchUrl(Uri.parse("market://details?id=cz.hernikplays.opencanteen"),
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
                    Uri.parse("https://git.mnau.xyz/hernik/opencanteen"))),
                child: Text(Languages.of(context)!.source))
          ]);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    nactiNastaveni();
  }

  void nactiNastaveni() async {
    var prefs = await SharedPreferences.getInstance();
    _skipWeekend = prefs.getBool("skip") ?? false;
    if (!mounted) return;
    nactiZeSouboru();
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
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(
                      onPressed: () {
                        if (data.length <= 1) return;
                        obsah = [const CircularProgressIndicator()];
                        setState(() {
                          if (den.weekday == 1 && _skipWeekend) {
                            // pokud je pondělí a chceme přeskočit víkend
                            if (jidloIndex - 2 >= 0) {
                              jidloIndex -= data.length - 3;
                            } else {
                              jidloIndex = data.length - 1;
                            }
                          } else if (jidloIndex == 0) {
                            jidloIndex = data.length - 1;
                          } else {
                            jidloIndex -= 1;
                          }

                          nactiJidlo();
                        });
                      },
                      icon: const Icon(Icons.arrow_left)),
                  TextButton(
                      onPressed: () async {},
                      child: Text(
                          "${den.day}. ${den.month}. ${den.year} - $denTydne")),
                  IconButton(
                    onPressed: () {
                      if (data.length <= 1) return;
                      obsah = [const CircularProgressIndicator()];
                      setState(() {
                        if (den.weekday == 5 && _skipWeekend) {
                          // pokud je pondělí a chceme přeskočit víkend
                          if (jidloIndex + 2 <= data.length - 1) {
                            jidloIndex += 2;
                          } else {
                            jidloIndex = 0;
                          }
                        } else if (jidloIndex == data.length) {
                          jidloIndex = 0;
                        } else {
                          jidloIndex += 1;
                        }
                        nactiJidlo();
                      });
                    },
                    icon: const Icon(Icons.arrow_right),
                  ),
                  IconButton(
                      onPressed: () {
                        jidloIndex = 0;
                      },
                      icon: const Icon(Icons.today))
                ]),
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
            MaterialPageRoute(builder: ((context) => const AndroidLogin()))),
      ),
    );
  }
}
