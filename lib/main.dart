import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String locale = Intl.getCurrentLocale();
  switch (locale) {
    case "cs_CZ":
      title = LanguageCz().lunchNotif;
      break;
    default:
      title = LanguageEn().lunchNotif;
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

        // data o oznámení
        const AndroidNotificationDetails androidSpec =
            AndroidNotificationDetails('predobedem', 'Oznámení před obědem',
                channelDescription: 'Oznámení o dnešním jídle',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'today meal');
        const IOSNotificationDetails iOSpec =
            IOSNotificationDetails(presentAlert: true, presentBadge: true);

        // naplánovat
        await flutterLocalNotificationsPlugin.zonedSchedule(
            0,
            title,
            "${jidlo.varianta} - ${jidlo.nazev}",
            tz.TZDateTime.from(
                casNaDate(
                  TimeOfDay(hour: kdy.hour, minute: kdy.minute),
                ),
                l),
            const NotificationDetails(android: androidSpec, iOS: iOSpec),
            androidAllowWhileIdle: true,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime);
      } on StateError catch (_) {
        // nenalezeno
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

  var prefs = await SharedPreferences.getInstance();
  if (prefs.getBool("oznamit") ?? false) {
    oznamitPredem(prefs, l);
  }

  // nastavit oznámení
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('notif_icon');

  final IOSInitializationSettings initializationSettingsIOS =
      IOSInitializationSettings(onDidReceiveLocalNotification: (
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    debugPrint(body);
  });

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String? payload) async {
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
  });

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
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (c) => WelcomeScreen(
                        canteen: canteen, n: flutterLocalNotificationsPlugin)));
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => JidelnicekPage(
                      canteen: canteen, n: flutterLocalNotificationsPlugin)),
            );
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
                  TextField(
                    autofillHints: const [AutofillHints.url],
                    decoration: InputDecoration(
                        labelText: Languages.of(context)!.iCanteenUrl),
                    keyboardType: TextInputType.url,
                    controller: canteenControl,
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
                        if (canteenControl.text.contains("http://")) {
                          // kontrolujeme šifrované spojení
                          var d = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                    title: Text(Languages.of(context)!.warning),
                                    content: SingleChildScrollView(
                                        child: Text(
                                            Languages.of(context)!.httpLogin)),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, true),
                                          child:
                                              Text(Languages.of(context)!.yes)),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, false),
                                          child: Text(
                                              Languages.of(context)!.noChange))
                                    ],
                                  ));
                          if (!d!) return;
                        }
                        if (!canteenControl.text.startsWith("https://") &&
                            !canteenControl.text.startsWith("http://")) {
                          canteenControl.text =
                              "https://${canteenControl.text}";
                        }
                        var canteen = Canteen(canteenControl.text);
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
                            LoginManager.setDetails(userControl.text,
                                passControl.text, canteenControl.text);
                          }
                          // souhlas
                          const storage = FlutterSecureStorage();
                          var odsouhlasil =
                              await storage.read(key: "oc_souhlas");
                          if (!mounted) return;
                          if (odsouhlasil == null || odsouhlasil != "ano") {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (c) => WelcomeScreen(
                                        canteen: canteen,
                                        n: flutterLocalNotificationsPlugin)));
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => JidelnicekPage(
                                      canteen: canteen,
                                      n: flutterLocalNotificationsPlugin)),
                            );
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
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: ((context) => OfflineJidelnicek(jidla: jidla))));
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
