import 'dart:convert';
import 'dart:io';

import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opencanteen/main.dart';
import 'package:opencanteen/okna/login.dart';
import 'package:opencanteen/okna/nastaveni.dart';
import 'package:opencanteen/pw/platformbutton.dart';
import 'package:opencanteen/pw/platformdialog.dart';
import 'package:opencanteen/util.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MealView extends StatefulWidget {
  const MealView({Key? key, required this.canteen}) : super(key: key);
  final Canteen canteen;
  @override
  State<MealView> createState() => _MealViewState();
}

class _MealViewState extends State<MealView> {
  List<Widget> content = [const CircularProgressIndicator()];
  DateTime day = DateTime.now();
  String dayOWeek = "";
  double balance = 0.0;

  void checkWeek(BuildContext context) async {
    if (settings.checkOrdered) {
      // Check if user has ordered a meal in the next week
      var pristi = day.add(const Duration(days: 6));
      for (var i = 0; i < 5; i++) {
        var jidelnicek = await widget.canteen
            .jidelnicekDen(den: pristi.add(Duration(days: i + 1)));
        if (jidelnicek.jidla.isNotEmpty &&
            !jidelnicek.jidla.any((element) => element.objednano == true)) {
          if (!mounted) break;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noOrder),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                onPressed: () => setState(
                  () {
                    day = pristi.add(Duration(days: i + 1));
                    loadMeals();
                  },
                ),
                label: AppLocalizations.of(context)!.jump,
              ),
            ),
          );
          break;
        }
      }
    }
  }

  Future<void> loadMeals() async {
    content = [const CircularProgressIndicator()];
    switch (day.weekday) {
      case 2:
        dayOWeek = AppLocalizations.of(context)!.tuesday;
        break;
      case 3:
        dayOWeek = AppLocalizations.of(context)!.wednesday;
        break;
      case 4:
        dayOWeek = AppLocalizations.of(context)!.thursday;
        break;
      case 5:
        dayOWeek = AppLocalizations.of(context)!.friday;
        break;
      case 6:
        dayOWeek = AppLocalizations.of(context)!.saturday;
        break;
      case 7:
        dayOWeek = AppLocalizations.of(context)!.sunday;
        break;
      default:
        dayOWeek = AppLocalizations.of(context)!.monday;
    }
    Uzivatel uzivatel;
    try {
      uzivatel = await widget.canteen.ziskejUzivatele();
    } catch (e) {
      if (!widget.canteen.prihlasen) {
        Navigator.pushReplacement(
            context, platformRouter((c) => const LoginPage()));
      }
      return;
    }
    balance = uzivatel.kredit;
    var jd = await widget.canteen.jidelnicekDen(den: day).catchError((_) {
      showInfo(context, AppLocalizations.of(context)!.errorContacting);
      return Jidelnicek(DateTime.now(), []);
    });
    setState(
      () {
        content = [];
        if (jd.jidla.isEmpty) {
          content.add(Text(
            AppLocalizations.of(context)!.noFood,
            style: const TextStyle(fontSize: 15),
          ));
        } else {
          for (var j in jd.jidla) {
            content.add(
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
                          ? AppLocalizations.of(context)!.inExchange
                          : "${j.cena} Kč"),
                      Checkbox(
                        value: j.objednano,
                        side: BorderSide(
                            width: 2,
                            color: (j.lzeObjednat)
                                ? (Colors.purple)
                                : (Colors.grey)),
                        fillColor: (j.lzeObjednat && j.objednano)
                            ? MaterialStateProperty.all(Colors.purple)
                            : (j.objednano)
                                ? MaterialStateProperty.all(Colors.grey)
                                : MaterialStateProperty.all(Colors.transparent),
                        onChanged: (v) async {
                          if (!j.lzeObjednat) {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return PlatformDialog(
                                  title: AppLocalizations.of(context)!
                                      .errorOrdering,
                                  content:
                                      AppLocalizations.of(context)!.cannotOrder,
                                  actions: [
                                    PlatformButton(
                                      text: AppLocalizations.of(context)!.ok,
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    )
                                  ],
                                );
                              },
                            );
                          } else {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => Dialog(
                                child: SizedBox(
                                  height: 100,
                                  child: Row(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: CircularProgressIndicator(),
                                      ),
                                      Text(AppLocalizations.of(context)!
                                          .ordering)
                                    ],
                                  ),
                                ),
                              ),
                            );
                            widget.canteen.objednat(j).then((_) {
                              Navigator.of(context, rootNavigator: true).pop();
                              loadMeals();
                            }).catchError(
                              (o) {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                                showDialog(
                                  context: context,
                                  builder: (bc) => PlatformDialog(
                                    title: AppLocalizations.of(context)!
                                        .errorOrdering,
                                    content: o.toString(),
                                    actions: [
                                      PlatformButton(
                                        text:
                                            AppLocalizations.of(context)!.close,
                                        onPressed: () {
                                          Navigator.pop(bc);
                                        },
                                      )
                                    ],
                                  ),
                                );
                              },
                            );
                          }
                        },
                      )
                    ],
                  ),
                  onTap: () async {
                    if (!j.lzeObjednat) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return PlatformDialog(
                            title: AppLocalizations.of(context)!.errorOrdering,
                            content: AppLocalizations.of(context)!.cannotOrder,
                            actions: [
                              PlatformButton(
                                text: AppLocalizations.of(context)!.ok,
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          );
                        },
                      );
                    } else {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => Dialog(
                          child: SizedBox(
                            height: 100,
                            child: Row(children: [
                              const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(),
                              ),
                              Text(AppLocalizations.of(context)!.ordering)
                            ]),
                          ),
                        ),
                      );
                      widget.canteen.objednat(j).then((_) {
                        Navigator.of(context, rootNavigator: true).pop();
                        loadMeals();
                      }).catchError(
                        (o) {
                          Navigator.of(context, rootNavigator: true).pop();
                          showDialog(
                            context: context,
                            builder: (bc) => PlatformDialog(
                              title:
                                  AppLocalizations.of(context)!.errorOrdering,
                              content: o.toString(),
                              actions: [
                                PlatformButton(
                                  text: AppLocalizations.of(context)!.close,
                                  onPressed: () {
                                    Navigator.pop(bc);
                                  },
                                )
                              ],
                            ),
                          );
                        },
                      );
                    }
                  },
                  onLongPress: () async {
                    if (!j.objednano || j.burzaUrl == null) return;
                    if (!j.naBurze) {
                      // if not in exchange, we ask
                      var d = await showDialog(
                        context: context,
                        builder: (bc) => PlatformDialog(
                          title: AppLocalizations.of(context)!.verifyExchange,
                          actions: [
                            PlatformButton(
                              onPressed: () {
                                Navigator.pop(bc, true);
                              },
                              text: AppLocalizations.of(context)!.yes,
                            ),
                            PlatformButton(
                              onPressed: () {
                                Navigator.pop(bc, false);
                              },
                              text: AppLocalizations.of(context)!.no,
                            ),
                          ],
                        ),
                      );
                      if (d) {
                        widget.canteen
                            .doBurzy(j)
                            .then((_) => loadMeals())
                            .catchError((o) {
                          showDialog(
                            context: context,
                            builder: (bc) => PlatformDialog(
                              title:
                                  AppLocalizations.of(context)!.exchangeError,
                              content: o.toString(),
                              actions: [
                                PlatformButton(
                                  text: AppLocalizations.of(context)!.close,
                                  onPressed: () {
                                    Navigator.pop(bc);
                                  },
                                )
                              ],
                            ),
                          );
                        });
                      }
                    } else {
                      // else no
                      widget.canteen.doBurzy(j).then((_) => loadMeals());
                    }
                  },
                ),
              ),
            );
          }
        }
      },
    );
    return;
  }

  Future<void> click(String value, BuildContext context) async {
    if (value == AppLocalizations.of(context)!.signOut) {
      await showDialog<bool>(
        context: context,
        builder: (c) => PlatformDialog(
          title: AppLocalizations.of(context)!.warning,
          content: AppLocalizations.of(context)!.signOutWarn,
          actions: [
            PlatformButton(
                onPressed: () {
                  const storage = FlutterSecureStorage();
                  storage.deleteAll();
                  Navigator.pushAndRemoveUntil(
                      context,
                      platformRouter((c) => const LoginPage()),
                      (route) => false);
                },
                text: AppLocalizations.of(context)!.yes),
            PlatformButton(
              onPressed: () => Navigator.of(context).pop(),
              text: AppLocalizations.of(context)!.no,
            )
          ],
        ),
      );
    } else if (value == AppLocalizations.of(context)!.review) {
      launchUrl(
          Uri.parse((Platform.isAndroid)
              ? "market://details?id=cz.hernikplays.opencanteen"
              : "https://apps.apple.com/cz/app/opencanteen/id1621124445"),
          mode: LaunchMode.externalApplication);
    } else if (value == AppLocalizations.of(context)!.reportBugs) {
      launchUrl(Uri.parse("https://forms.gle/jKN7QeFJwpaApSbC8"),
          mode: LaunchMode.externalApplication);
    } else if (value == AppLocalizations.of(context)!.about) {
      var packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      showAboutDialog(
          context: context,
          applicationName: "OpenCanteen",
          applicationLegalese:
              "${AppLocalizations.of(context)!.copyright}\n${AppLocalizations.of(context)!.license}",
          applicationVersion: packageInfo.version,
          children: [
            PlatformButton(
              onPressed: (() => launchUrl(
                  Uri.parse("https://git.mnau.xyz/hernik/opencanteen"),
                  mode: LaunchMode.externalApplication)),
              text: AppLocalizations.of(context)!.source,
            )
          ]);
    } else if (value == AppLocalizations.of(context)!.settings) {
      Navigator.push(context, platformRouter((c) => const AndroidNastaveni()));
    }
  }

  void loadSettings() async {
    if (!mounted) return;
    checkWeek(context);
  }

  void saveOffline() async {
    if (!settings.saveOffline) return;
    // clear offline storage
    Directory appDocDir = await getApplicationDocumentsDirectory();
    for (var f in appDocDir.listSync()) {
      if (f.path.contains("jidelnicek")) {
        f.deleteSync();
      }
    }
    var prefs = await SharedPreferences.getInstance();
    // save X meal lists
    var pocet = prefs.getInt("offline_pocet") ?? 1;
    if (pocet > 7) pocet = 7;
    for (var i = 0; i < pocet; i++) {
      var d = day.add(Duration(days: i));
      Jidelnicek? j;
      try {
        j = await widget.canteen.jidelnicekDen(den: d);
      } catch (e) {
        if (!widget.canteen.prihlasen) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSaving),
            duration: const Duration(seconds: 5),
          ));
          break;
        }
      }
      var soubor = File(
          "${appDocDir.path}/jidelnicek_${d.year}-${d.month}-${d.day}.json");
      soubor.createSync();
      var jidla = [];
      for (var jidlo in j!.jidla) {
        jidla.add({
          "nazev": jidlo.nazev,
          "varianta": jidlo.varianta,
          "objednano": jidlo.objednano,
          "cena": jidlo.cena,
          "naBurze": jidlo.naBurze,
          "den": d.toString()
        });
      }
      await soubor.writeAsString(json.encode(jidla));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadSettings();
    saveOffline();
    loadMeals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawerGenerator(context, widget.canteen, 1),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.menu),
        actions: [
          PopupMenuButton(
            onSelected: ((String value) => click(value, context)),
            itemBuilder: (BuildContext context) {
              return {
                AppLocalizations.of(context)!.reportBugs,
                AppLocalizations.of(context)!.review,
                AppLocalizations.of(context)!.settings,
                AppLocalizations.of(context)!.about,
                AppLocalizations.of(context)!.signOut
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
        onRefresh: loadMeals,
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text("${AppLocalizations.of(context)!.balance}$balance Kč"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        onPressed: () {
                          setState(() {
                            day = day.subtract(const Duration(days: 1));
                            if (day.weekday == 7 && settings.skipWeekend) {
                              day = day.subtract(const Duration(days: 2));
                            }
                            loadMeals();
                          });
                        },
                        icon: const Icon(Icons.arrow_left)),
                    PlatformButton(
                      onPressed: () async {
                        var datePicked = await showDatePicker(
                            context: context,
                            initialDate: day,
                            currentDate: day,
                            firstDate: DateTime(2019, 1, 1),
                            lastDate: DateTime(day.year + 1, 12, 31),
                            locale: Localizations.localeOf(context));
                        if (datePicked == null) return;
                        setState(() {
                          day = datePicked;
                          loadMeals();
                        });
                      },
                      text: "${day.day}. ${day.month}. ${day.year} - $dayOWeek",
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          day = day.add(const Duration(days: 1));
                          if (day.weekday == 6 && settings.skipWeekend) {
                            day = day.add(const Duration(days: 2));
                          }
                          loadMeals();
                        });
                      },
                      icon: const Icon(Icons.arrow_right),
                    ),
                    Tooltip(
                      message: AppLocalizations.of(context)!.todayTooltip,
                      child: IconButton(
                        onPressed: () => setState(
                          () {
                            day = DateTime.now();
                            loadMeals();
                          },
                        ),
                        icon: const Icon(Icons.today),
                      ),
                    )
                  ],
                ),
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: GestureDetector(
                    child: Container(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withOpacity(0),
                      height: MediaQuery.of(context).size.height / 1.3,
                      child: Column(children: content),
                    ),
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity?.compareTo(0) == -1) {
                        setState(() {
                          day = day.add(const Duration(days: 1));
                          if (day.weekday == 6 && settings.skipWeekend) {
                            day = day.add(const Duration(days: 2));
                          }
                          loadMeals();
                        });
                      } else {
                        setState(
                          () {
                            day = day.subtract(const Duration(days: 1));
                            if (day.weekday == 7 && settings.skipWeekend) {
                              day = day.subtract(const Duration(days: 2));
                            }
                            loadMeals();
                          },
                        );
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
