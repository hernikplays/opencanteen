import 'dart:convert';
import 'dart:io';

import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opencanteen/util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../loginmanager.dart';
import '../main.dart';
import 'about.dart';

class JidelnicekPage extends StatefulWidget {
  const JidelnicekPage({Key? key, required this.canteen, required this.user})
      : super(key: key);
  final Canteen canteen;
  final String user;
  @override
  State<JidelnicekPage> createState() => _JidelnicekPageState();
}

class _JidelnicekPageState extends State<JidelnicekPage> {
  List<Widget> obsah = [const Text("Načítám...")];
  DateTime den = DateTime.now();
  String denTydne = "";
  double kredit = 0.0;
  Future<void> nactiJidlo() async {
    obsah = [const CircularProgressIndicator()];
    switch (den.weekday) {
      case 2:
        denTydne = "Úterý";
        break;
      case 3:
        denTydne = "Středa";
        break;
      case 4:
        denTydne = "Čtvrtek";
        break;
      case 5:
        denTydne = "Pátek";
        break;
      case 6:
        denTydne = "Sobota";
        break;
      case 7:
        denTydne = "Neděle";
        break;
      default:
        denTydne = "Pondělí";
    }
    widget.canteen.ziskejUzivatele().then((kr) {
      kredit = kr.kredit;
      widget.canteen.jidelnicekDen(den: den).then((jd) async {
        setState(() {
          obsah = [];
          if (jd.jidla.isEmpty) {
            obsah.add(const Text(
              "Žádné jídlo pro tento den",
              style: TextStyle(fontSize: 15),
            ));
          } else {
            for (var j in jd.jidla) {
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
                        Text((j.naBurze) ? "V BURZE" : "${j.cena} Kč"),
                        Checkbox(
                            value: j.objednano,
                            fillColor: (j.lzeObjednat)
                                ? MaterialStateProperty.all(Colors.blue)
                                : MaterialStateProperty.all(Colors.grey),
                            onChanged: (v) async {
                              return;
                            })
                      ],
                    ),
                    onTap: () async {
                      if (!j.lzeObjednat) return;
                      showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => Dialog(
                                child: SizedBox(
                                  height: 100,
                                  child: Row(children: const [
                                    Padding(
                                      padding: EdgeInsets.all(10),
                                      child: CircularProgressIndicator(),
                                    ),
                                    Text("Objednávám...")
                                  ]),
                                ),
                              ));
                      widget.canteen.objednat(j).then((_) {
                        Navigator.of(context, rootNavigator: true).pop();
                        nactiJidlo();
                      }).catchError((o) {
                        Navigator.of(context, rootNavigator: true).pop();
                        showDialog(
                            context: context,
                            builder: (bc) => AlertDialog(
                                  title: const Text(
                                      "Jídlo se nepodařilo objednat."),
                                  content: Text(o.toString()),
                                  actions: [
                                    TextButton(
                                      child: const Text("Zavřít"),
                                      onPressed: () {
                                        Navigator.pop(bc);
                                      },
                                    )
                                  ],
                                ));
                      });
                    },
                    onLongPress: () async {
                      if (!j.objednano || j.burzaUrl == null) return;
                      if (!j.naBurze) {
                        // pokud není na burze, radši se zeptáme
                        var d = await showDialog(
                            context: context,
                            builder: (bc) => SimpleDialog(
                                  title: const Text(
                                      "Opravdu chcete vložit jídlo na burzu?"),
                                  children: [
                                    SimpleDialogOption(
                                      onPressed: () {
                                        Navigator.pop(bc, true);
                                      },
                                      child: const Text("Ano"),
                                    ),
                                    SimpleDialogOption(
                                      onPressed: () {
                                        Navigator.pop(bc, false);
                                      },
                                      child: const Text("Ne"),
                                    ),
                                  ],
                                ));
                        if (d) {
                          widget.canteen
                              .doBurzy(j)
                              .then((_) => nactiJidlo())
                              .catchError((o) {
                            showDialog(
                                context: context,
                                builder: (bc) => AlertDialog(
                                      title: const Text(
                                          "Nepodařilo se vložit jídlo na burzu"),
                                      content: Text(o.toString()),
                                      actions: [
                                        TextButton(
                                          child: const Text("Zavřít"),
                                          onPressed: () {
                                            Navigator.pop(bc);
                                          },
                                        )
                                      ],
                                    ));
                          });
                        }
                      } else {
                        // jinak ne
                        widget.canteen.doBurzy(j).then((_) => nactiJidlo());
                      }
                    },
                  ),
                ),
              );
            }
          }
        });
      });
    }).catchError((o) {
      if (!widget.canteen.prihlasen) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (c) => const LoginPage()));
      }
    });
  }

  void kliknuti(String value) {
    switch (value) {
      case 'Odhlásit se':
        const storage = FlutterSecureStorage();
        storage.deleteAll();
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (c) => const LoginPage()));
        break;
      case 'Nahlásit chybu':
        launch("https://github.com/hernikplays/opencanteen/issues/new/choose");
        break;
      case 'O Aplikaci':
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => const AboutPage()));
        break;
    }
  }

  /// uložení jídelníčku pro dnešek offline
  void ulozitDnesekOffline() async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("offline") != null && prefs.getBool("offline")!) {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      for (var f in appDocDir.listSync()) {
        // Vymažeme obsah
        if (f.path.contains("jidelnicek")) {
          f.deleteSync();
        }
      }
      // Uložíme nová data
      var j = await widget.canteen.jidelnicekDen();
      var soubor = File(appDocDir.path +
          "/jidelnicek_${den.year}-${den.month}-${den.day}.json");
      soubor.createSync();
      var jidla = [];
      for (var jidlo in j.jidla) {
        jidla.add({
          "nazev": jidlo.nazev,
          "varianta": jidlo.varianta,
          "objednano": jidlo.objednano,
          "cena": jidlo.cena,
          "naBurze": jidlo.naBurze
        });
      }
      await soubor.writeAsString(json.encode(jidla));
    }
  }

  @override
  void initState() {
    super.initState();
    ulozitDnesekOffline();
    nactiJidlo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawerGenerator(context, widget.canteen, widget.user, 1),
      appBar: AppBar(
        title: const Text('Jídelníček'),
        actions: [
          PopupMenuButton(
            onSelected: kliknuti,
            itemBuilder: (BuildContext context) {
              return {'Nahlásit chybu', 'O Aplikaci', 'Odhlásit se'}
                  .map((String choice) {
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
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text("Kredit: $kredit Kč"),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(
                      onPressed: () {
                        setState(() {
                          den = den.subtract(const Duration(days: 1));
                          nactiJidlo();
                        });
                      },
                      icon: const Icon(Icons.arrow_left)),
                  TextButton(
                      onPressed: () async {
                        var datePicked = await showDatePicker(
                            context: context,
                            initialDate: den,
                            currentDate: den,
                            firstDate: DateTime(2019, 1, 1),
                            lastDate: DateTime(den.year + 1, 12, 31),
                            locale: const Locale("cs"));
                        if (datePicked == null) return;
                        setState(() {
                          den = datePicked;
                          nactiJidlo();
                        });
                      },
                      child: Text(
                          "${den.day}. ${den.month}. ${den.year} - $denTydne")),
                  IconButton(
                      onPressed: () {
                        setState(() {
                          den = den.add(const Duration(days: 1));
                          nactiJidlo();
                        });
                      },
                      icon: const Icon(Icons.arrow_right)),
                ]),
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: GestureDetector(
                    child: Container(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withOpacity(0),
                      child: Column(children: obsah),
                      height: MediaQuery.of(context).size.height / 1.3,
                    ),
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity?.compareTo(0) == -1) {
                        setState(() {
                          den = den.add(const Duration(days: 1));
                          nactiJidlo();
                        });
                      } else {
                        setState(() {
                          den = den.subtract(const Duration(days: 1));
                          nactiJidlo();
                        });
                      }
                    },
                  ),
                )
              ],
            ),
            width: MediaQuery.of(context).size.width - 50,
          ),
        ),
        onRefresh: nactiJidlo,
      ),
    );
  }
}
