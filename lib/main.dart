import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:opencanteen/lang/lang_cz.dart';
import 'package:opencanteen/loginmanager.dart';
import 'package:canteenlib/canteenlib.dart';
import 'package:opencanteen/okna/login.dart';
import 'package:opencanteen/util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'lang/lang.dart';
import 'lang/lang_en.dart';

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

  const ios = DarwinInitializationSettings();

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid, iOS: ios);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

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
