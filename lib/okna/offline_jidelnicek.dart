import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opencanteen/okna/login.dart';
import 'package:opencanteen/pw/platformbutton.dart';
import 'package:opencanteen/util.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OfflineMealView extends StatefulWidget {
  const OfflineMealView({Key? key}) : super(key: key);
  @override
  State<OfflineMealView> createState() => _OfflineMealViewState();
}

class _OfflineMealViewState extends State<OfflineMealView> {
  List<Widget> content = [const CircularProgressIndicator()]; // view content
  var _skipWeekend = false; // skip weekend setting
  DateTime currentDay = DateTime.now(); // the day we are supposed to show
  String dayOWeek = ""; // the name of the day (to show to user)
  List<List<OfflineMeal>> data = []; // meal data
  var mealIndex = 0; // index of the currently shown day

  /// Loads the offline data from local storage
  void loadFromFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    for (var f in appDocDir.listSync()) {
      if (f.path.contains("jidelnicek")) {
        var soubor = File(f.path);
        var input = await soubor.readAsString();
        var r = jsonDecode(input);
        List<OfflineMeal> jidla = [];
        for (var j in r) {
          jidla.add(OfflineMeal(
              name: j["nazev"],
              variant: j["varianta"],
              ordered: j["objednano"],
              price: j["cena"],
              onExchange: j["naBurze"],
              day: DateTime.parse(j["den"])));
        }
        data.add(jidla);
      }
    }
    loadFood();
  }

  Future<void> loadFood() async {
    var jidelnicek = data[mealIndex];
    currentDay = jidelnicek[0].day;
    switch (currentDay.weekday) {
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
    content = [];
    for (OfflineMeal j in jidelnicek) {
      content.add(
        Padding(
          padding: const EdgeInsets.only(top: 15),
          child: InkWell(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(j.variant),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    j.name,
                  ),
                ),
                Text((j.onExchange)
                    ? AppLocalizations.of(context)!.inExchange
                    : "${j.price} Kč"),
                Checkbox(
                  value: j.ordered,
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

  void click(String value, BuildContext context) async {
    if (value == AppLocalizations.of(context)!.signOut) {
      const storage = FlutterSecureStorage();
      storage.deleteAll();
      Navigator.pushReplacement(
          context, platformRouter((c) => const LoginPage()));
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
                Uri.parse("https://git.mnau.xyz/hernik/opencanteen"))),
            text: AppLocalizations.of(context)!.source,
          )
        ],
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadSettings();
  }

  void loadSettings() async {
    var prefs = await SharedPreferences.getInstance();
    _skipWeekend = prefs.getBool("skip") ?? false;
    if (!mounted) return;
    loadFromFile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.menu),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton(
            onSelected: ((String value) => click(value, context)),
            itemBuilder: (BuildContext context) {
              return {
                AppLocalizations.of(context)!.reportBugs,
                AppLocalizations.of(context)!.review,
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
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 50,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)!.offline,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(AppLocalizations.of(context)!.mustLogout),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(
                      onPressed: () {
                        if (data.length <= 1) return;
                        content = [const CircularProgressIndicator()];
                        setState(() {
                          if (currentDay.weekday == 1 && _skipWeekend) {
                            // pokud je pondělí a chceme přeskočit víkend
                            if (mealIndex - 2 >= 0) {
                              mealIndex -= data.length - 3;
                            } else {
                              mealIndex = data.length - 1;
                            }
                          } else if (mealIndex == 0) {
                            mealIndex = data.length - 1;
                          } else {
                            mealIndex -= 1;
                          }

                          loadFood();
                        });
                      },
                      icon: const Icon(Icons.arrow_left)),
                  PlatformButton(
                      onPressed: () async {},
                      text:
                          "${currentDay.day}. ${currentDay.month}. ${currentDay.year} - $dayOWeek"),
                  IconButton(
                    onPressed: () {
                      if (data.length <= 1) return;
                      content = [const CircularProgressIndicator()];
                      setState(() {
                        if (currentDay.weekday == 5 && _skipWeekend) {
                          // pokud je pondělí a chceme přeskočit víkend
                          if (mealIndex + 2 <= data.length - 1) {
                            mealIndex += 2;
                          } else {
                            mealIndex = 0;
                          }
                        } else if (mealIndex == data.length) {
                          mealIndex = 0;
                        } else {
                          mealIndex += 1;
                        }
                        loadFood();
                      });
                    },
                    icon: const Icon(Icons.arrow_right),
                  ),
                  IconButton(
                      onPressed: () {
                        mealIndex = 0;
                      },
                      icon: const Icon(Icons.today))
                ]),
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: content,
                  ),
                ),
              ],
            ),
          ),
        ),
        onRefresh: () => Navigator.pushReplacement(
            context, platformRouter((context) => const LoginPage())),
      ),
    );
  }
}
