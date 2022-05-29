import 'dart:convert';
import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
=======
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

// Pouze pro Android
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // Timeout
    debugPrint("[BackgroundFetch] Headless task má time-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  debugPrint('[BackgroundFetch] Přišel headless event.');

  var d = await LoginManager.getDetails(); // získat údaje
  if (d != null) {
    var c = Canteen(d["url"]!);
    await c.login(d["user"]!, d["pass"]!); // přihlásit se
    var burza = await c.ziskatBurzu(); // získat burzu

    for (var jidlo in burza) {
      try {
        String locale = Intl.getCurrentLocale();
        String title;
        switch (locale) {
          case "cs_CZ":
            title = LanguageCz().autoFound;
            break;
          default:
            title = LanguageEn().autoFound;
        }
        var r = await c.objednatZBurzy(jidlo); // objednat
        if (r) {
          const AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails('opencanteen', 'autoburza',
                  channelDescription: 'Oznámení o objednání jídla z burzy',
                  importance: Importance.max,
                  priority: Priority.high,
                  ticker: 'burza success');
          const NotificationDetails platformChannelSpecifics =
              NotificationDetails(android: androidPlatformChannelSpecifics);
          await flutterLocalNotificationsPlugin.show(
              0, title, null, platformChannelSpecifics);
          break; // ukončit pokud objednáno
        }
      } catch (e) {
        const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails('opencanteen', 'autoburza',
                channelDescription: 'Oznámení o objednání jídla z burzy',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'burza fail');
        const NotificationDetails platformChannelSpecifics =
            NotificationDetails(android: androidPlatformChannelSpecifics);
        await flutterLocalNotificationsPlugin.show(
            0,
            "CHYBA PŘI OBJEDNÁVÁNÍ ${jidlo.nazev}",
            e.toString(),
            platformChannelSpecifics);
      }
    }
  }
  BackgroundFetch.finish(taskId);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('notif_icon');

  /// Note: permissions aren't requested here just to demonstrate that can be
  /// done later
  final IOSInitializationSettings initializationSettingsIOS =
      IOSInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          onDidReceiveLocalNotification: (
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

  runApp(const MyApp());
  var prefs = await SharedPreferences.getInstance();

  if (prefs.getBool("autoburza") ?? false) {
    debugPrint("Nastavuji");
    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
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

  void nastavitPozadi() async {
    // Configure BackgroundFetch.
    int status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.ANY), (String taskId) async {
      // Callback
      debugPrint("[BackgroundFetch] Event získán $taskId");
      var d = await LoginManager.getDetails();
      if (d != null) {
        var c = Canteen(d["url"]!);
        await c.login(d["user"]!, d["pass"]!);
        var burza = await c.ziskatBurzu();

        for (var jidlo in burza) {
          // DEBUG
          var debugge = const AndroidNotificationDetails(
              'opencanteen', 'debugge',
              channelDescription: 'Debug opencanteen',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'burza debug');
          await flutterLocalNotificationsPlugin.show(
              0,
              "Nalezeno jídlo ${jidlo.nazev}",
              null,
              NotificationDetails(android: debugge)); // TODO debug
          try {
            var r = await c.objednatZBurzy(jidlo); // objednat
            if (r) {
              const AndroidNotificationDetails androidPlatformChannelSpecifics =
                  AndroidNotificationDetails('opencanteen', 'autoburza',
                      channelDescription: 'Oznámení o objednání jídla z burzy',
                      importance: Importance.max,
                      priority: Priority.high,
                      ticker: 'burza success');
              const NotificationDetails platformChannelSpecifics =
                  NotificationDetails(android: androidPlatformChannelSpecifics);
              await flutterLocalNotificationsPlugin.show(
                  0,
                  Languages.of(context)!.autoFound,
                  null,
                  platformChannelSpecifics);
              break; // ukončit pokud objednáno
            }
          } catch (e) {
            const AndroidNotificationDetails androidPlatformChannelSpecifics =
                AndroidNotificationDetails('opencanteen', 'autoburza',
                    channelDescription: 'Oznámení o objednání jídla z burzy',
                    importance: Importance.max,
                    priority: Priority.high,
                    ticker: 'burza fail');
            const NotificationDetails platformChannelSpecifics =
                NotificationDetails(android: androidPlatformChannelSpecifics);
            await flutterLocalNotificationsPlugin.show(
                0,
                "CHYBA PŘI OBJEDNÁVÁNÍ ${jidlo.nazev}",
                e.toString(),
                platformChannelSpecifics);
          }
        }
      }
      BackgroundFetch.finish(taskId);
    }, (String taskId) async {
      debugPrint("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
      BackgroundFetch.finish(taskId);
    });
    debugPrint('[BackgroundFetch] úspěšně nakonfigurováno: $status');
  }

  @override
  void initState() {
    super.initState();
    LoginManager.getDetails().then((r) async {
      if (Platform.isIOS) {
        await flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(
                  alert: true,
                  badge: true,
                  sound: true,
                ) ??
            false;
      }
      if (r != null) {
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
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(Languages.of(context)!.loginFailed),
              ),
            );
            return;
          }
          var prefs = await SharedPreferences.getInstance();
          if (prefs.getBool("autoburza") ?? false) {
            nastavitPozadi();
          }
          const storage = FlutterSecureStorage();
          var odsouhlasil = await storage.read(key: "oc_souhlas");
          if (odsouhlasil == null || odsouhlasil != "ano") {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (c) => WelcomeScreen(canteen: canteen)));
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => JidelnicekPage(
                        canteen: canteen,
                      )),
            );
          }
        } on PlatformException {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Languages.of(context)!.corrupted),
            ),
          );
        } catch (e) {
          // DEBUG ODSTRANIT
          showDialog(
              context: context,
              builder: (c) => SimpleDialog(
                  title: Text("Chyba"), children: [Text(e.toString())]));

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
                        if (!canteenControl.text.startsWith("https://") &&
                            !canteenControl.text.startsWith("http://")) {
                          canteenControl.text =
                              "https://" + canteenControl.text;
                        }
                        var canteen = Canteen(canteenControl.text);
                        try {
                          var l = await canteen.login(
                              userControl.text, passControl.text);
                          if (!l) {
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
                          if (odsouhlasil == null || odsouhlasil != "ano") {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (c) =>
                                        WelcomeScreen(canteen: canteen)));
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JidelnicekPage(
                                  canteen: canteen,
                                ),
                              ),
                            );
                          }
                        } on PlatformException {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(Languages.of(context)!.corrupted),
                            ),
                          );
                        
                        } on Exception catch (e) {
                          // TODO: DEBUG ODSTRANIT
                          showDialog(
                              context: context,
                              builder: (c) => SimpleDialog(
                                  title: Text("Chyba"),
                                  children: [Text(e.toString())]));
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

  void goOffline() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    var den = DateTime.now();
    var soubor = File(appDocDir.path +
        "/jidelnicek_${den.year}-${den.month}-${den.day}.json");
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
