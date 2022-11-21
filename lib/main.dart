import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opencanteen/lang/lang_cz.dart';
import 'package:opencanteen/loginmanager.dart';
import 'package:canteenlib/canteenlib.dart';
import 'package:opencanteen/okna/offline_jidelnicek.dart';
import 'package:opencanteen/okna/welcome.dart';
import 'package:opencanteen/util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'lang/lang.dart';
import 'lang/lang_en.dart';
import 'okna/jidelnicek.dart';

/*
Copyright (C) 2022  Matyáš Caras a přispěvatelé

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void oznamitPredem(SharedPreferences prefs, tz.Location l) async {
  String title;
  String notif;
  String locale = Intl.getCurrentLocale();
  debugPrint(locale);
  switch (locale) {
    case "cs_CZ":
      title = LanguageCz().lunchNotif;
      notif = LanguageCz().wakeLock;
      break;
    default:
      notif = LanguageEn().wakeLock;
      title = LanguageEn().lunchNotif;
      break;
  }

  /*if (prefs.getBool("offline") ?? false) {
    // TODO možnost brát z offline dat
  } else {*/
  // bere online
  var d = await LoginManager.getDetails(); // získat údaje
  if (d != null) {
    var c = Canteen(d["url"]!);
    if (await c.login(d["user"]!, d["pass"]!)) {
      var jidla = await c.jidelnicekDen();
      try {
        var jidlo = jidla.jidla.singleWhere(
            (element) => element.objednano); // získá objednané jídlo
        var kdy = DateTime.parse(prefs.getString(
            "oznameni_cas")!); // uložíme čas, kdy se má odeslat oznámení
        var cas = casNaDate(
          TimeOfDay(hour: kdy.hour, minute: kdy.minute),
        );
        if (cas.isBefore(DateTime.now())) return;

        // data o oznámení
        const AndroidNotificationDetails androidSpec =
            AndroidNotificationDetails('predobedem', 'Oznámení před obědem',
                channelDescription: 'Oznámení o dnešním jídle',
                importance: Importance.max,
                priority: Priority.high,
                styleInformation: BigTextStyleInformation(''),
                ticker: 'today meal');

        // blokovat vypnutí
        if (Platform.isAndroid) {
          // ! TODO: OTESTOVAT, JESTLI FUNGUJE IMPORT NA IOSu
          var androidConfig = FlutterBackgroundAndroidConfig(
              notificationTitle: "OpenCanteen",
              notificationText: notif,
              notificationImportance: AndroidNotificationImportance.Default,
              notificationIcon: const AndroidResource(
                  name: 'notif_icon', defType: 'drawable'),
              enableWifiLock: true);
          bool success =
              await FlutterBackground.initialize(androidConfig: androidConfig);
          if (success) await FlutterBackground.enableBackgroundExecution();
        }

        // naplánovat
        await flutterLocalNotificationsPlugin.zonedSchedule(
            0,
            title,
            "${jidlo.varianta} - ${jidlo.nazev}",
            tz.TZDateTime.from(cas, l),
            const NotificationDetails(android: androidSpec),
            androidAllowWhileIdle: true,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime);
      } on StateError catch (_) {
        // nenalezeno
        debugPrint("Nenalezeno");
      }
    }
    // }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  var l = tz.getLocation(await FlutterNativeTimezone.getLocalTimezone());
  tz.setLocalLocation(l);

  // nastavit oznámení
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('notif_icon');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  var prefs = await SharedPreferences.getInstance();
  if (prefs.getBool("oznamit") ?? false) {
    oznamitPredem(prefs, l);
  }

  // spustit aplikaci
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates
      ],
      supportedLocales: const [Locale("cs", ""), Locale("en", "")],
      title: "OpenCanteen",
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.purple,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController userControl = TextEditingController();
  TextEditingController passControl = TextEditingController();
  TextEditingController canteenControl = TextEditingController();
  bool rememberMe = false;
  bool _showUrl = false;
  String dropdownUrl = instance.first["url"] ?? "";

  @override
  void initState() {
    super.initState();
    LoginManager.getDetails().then((r) async {
      if (Platform.isIOS) {
        // žádat o oprávnění na iOS
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      } else if (Platform.isAndroid) {
        // žádat o oprávnění na android
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestPermission();
      }
      if (r != null) {
        // Automaticky přihlásit
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
                      Text(Languages.of(context)!.loggingIn)
                    ]),
                  ),
                ));
        var canteen = Canteen(r["url"]!);
        try {
          var l = await canteen.login(r["user"]!, r["pass"]!);
          if (!l) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(Languages.of(context)!.loginFailed),
              ),
            );
            return;
          }
          const storage = FlutterSecureStorage();
          var odsouhlasil = await storage.read(key: "oc_souhlas");
          if (!mounted) return;
          if (odsouhlasil == null || odsouhlasil != "ano") {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (c) => WelcomeScreen(
                      canteen: canteen, n: flutterLocalNotificationsPlugin),
                ),
                (route) => false);
          } else {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => JidelnicekPage(
                      canteen: canteen, n: flutterLocalNotificationsPlugin),
                ),
                (route) => false);
          }
        } on PlatformException {
          if (!mounted) return;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Languages.of(context)!.corrupted),
            ),
          );
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Languages.of(context)!.errorContacting),
            ),
          );
          goOffline();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(Languages.of(context)!.logIn),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    Languages.of(context)!.appName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 40),
                  ),
                  Text(
                    Languages.of(context)!.logIn,
                    textAlign: TextAlign.center,
                  ),
                  TextField(
                    controller: userControl,
                    autofillHints: const [AutofillHints.username],
                    decoration: InputDecoration(
                        labelText: Languages.of(context)!.username),
                  ),
                  TextField(
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                        labelText: Languages.of(context)!.password),
                    controller: passControl,
                    obscureText: true,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  DropdownButton(
                    isExpanded: true,
                    value: dropdownUrl,
                    items: instance.map<DropdownMenuItem<String>>((e) {
                      return DropdownMenuItem<String>(
                        value: e["url"],
                        child: Text(e["name"]!),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        if (value == "") {
                          _showUrl = true;
                        } else {
                          _showUrl = false;
                        }
                        dropdownUrl = value!;
                      });
                    },
                  ),
                  AnimatedOpacity(
                    opacity: _showUrl ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: TextField(
                      autofillHints: const [AutofillHints.url],
                      decoration: InputDecoration(
                          labelText: Languages.of(context)!.iCanteenUrl),
                      keyboardType: TextInputType.url,
                      controller: canteenControl,
                    ),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Switch(
                        value: rememberMe,
                        onChanged: (value) {
                          setState(() {
                            rememberMe = value;
                          });
                        }),
                    Text(Languages.of(context)!.rememberMe)
                  ]),
                  TextButton(
                      onPressed: () async {
                        var canteenUrl = (dropdownUrl == "")
                            ? canteenControl.text
                            : dropdownUrl;
                        if (!canteenUrl.startsWith("https://") &&
                            !canteenUrl.startsWith("http://")) {
                          canteenUrl = "https://$canteenUrl";
                        }
                        var canteen = Canteen(canteenUrl);
                        try {
                          var l = await canteen.login(
                              userControl.text, passControl.text);
                          if (!l) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text(Languages.of(context)!.loginFailed),
                              ),
                            );
                            return;
                          }
                          if (rememberMe) {
                            LoginManager.setDetails(
                                userControl.text, passControl.text, canteenUrl);
                          }
                          // souhlas
                          const storage = FlutterSecureStorage();
                          var odsouhlasil =
                              await storage.read(key: "oc_souhlas");
                          if (!mounted) return;
                          if (odsouhlasil == null || odsouhlasil != "ano") {
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (c) => WelcomeScreen(
                                        canteen: canteen,
                                        n: flutterLocalNotificationsPlugin)),
                                (route) => false);
                          } else {
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => JidelnicekPage(
                                        canteen: canteen,
                                        n: flutterLocalNotificationsPlugin)),
                                (route) => false);
                          }
                        } on PlatformException {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(Languages.of(context)!.corrupted),
                            ),
                          );
                        } on Exception catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text(Languages.of(context)!.errorContacting),
                            ),
                          );
                          goOffline();
                        }
                      },
                      child: Text(Languages.of(context)!.logIn)),
                ],
              ),
            ),
          ),
        ));
  }

  /// Získá offline soubor a zobrazí údaje
  void goOffline() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    var den = DateTime.now();
    var soubor = File(
        "${appDocDir.path}/jidelnicek_${den.year}-${den.month}-${den.day}.json");
    if (soubor.existsSync()) {
      // načteme offline jídelníček
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
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: ((context) => OfflineJidelnicek(jidla: jidla))),
          (route) => false);
    }
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<Languages> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['cs', 'en'].contains(locale.languageCode);

  @override
  Future<Languages> load(Locale locale) => _load(locale);

  static Future<Languages> _load(Locale locale) async {
    switch (locale.languageCode) {
      case 'cs':
        return LanguageCz();
      default:
        return LanguageEn();
    }
  }

  @override
  bool shouldReload(LocalizationsDelegate<Languages> old) => false;
}
