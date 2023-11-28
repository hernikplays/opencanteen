import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:canteenlib/canteenlib.dart';
import 'package:opencanteen/okna/login.dart';
import 'package:opencanteen/util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'color_schemes.g.dart';
import 'loginmanager.dart';
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
final settings = SettingsManager();

/// Used to setup notifications about ordered food
void setupNotification(SharedPreferences prefs, tz.Location l) async {
  String title;

  String locale = Intl.getCurrentLocale();
  switch (locale) {
    case "cs_CZ":
      title = "Dnes máte objednáno";
      break;
    default:
      title = "Today's ordered meal";
  }

  /*if (prefs.getBool("offline") ?? false) {
    // TODO grab data from offline storage
  } else {*/
  // data from the web
  var d = await LoginManager.getDetails(); // grab login
  if (d != null) {
    var c = Canteen(d["url"]!);
    if (await c.login(d["user"]!, d["pass"]!)) {
      var jidla = await c.jidelnicekDen();
      try {
        var jidlo = jidla.jidla
            .singleWhere((element) => element.objednano); // grab ordered meal
        var kdy = DateTime.parse(prefs.getString(
            "oznameni_cas")!); // save the time the notif should be sent
        var cas = timeToDate(
          TimeOfDay(hour: kdy.hour, minute: kdy.minute),
        );
        if (cas.isBefore(DateTime.now())) return;
        // notif data
        const AndroidNotificationDetails androidSpec =
            AndroidNotificationDetails('predobedem', 'Oznámení před obědem',
                channelDescription: 'Oznámení o dnešním jídle',
                importance: Importance.max,
                priority: Priority.high,
                styleInformation: BigTextStyleInformation(''),
                ticker: 'today meal');

        // plan through lib
        await flutterLocalNotificationsPlugin.zonedSchedule(
            0,
            title,
            "${jidlo.varianta} - ${jidlo.nazev}",
            tz.TZDateTime.from(cas, l),
            const NotificationDetails(android: androidSpec),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime);
      } on StateError catch (_) {
        // no ordered meal found
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
    setupNotification(prefs, l);
  }
  settings.checkOrdered = prefs.getBool("tyden") ?? false;
  settings.saveOffline = prefs.getBool("oznamit") ?? false;
  settings.skipWeekend = prefs.getBool("skip") ?? false;
  settings.allergens = prefs.getBool("allergens") ?? false;

  // notif library setup
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('notif_icon');

  const ios = DarwinInitializationSettings();

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid, iOS: ios);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return (Platform
            .isAndroid) // run app based on current platform  to make use of the platform's respective UI lib
        ? MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            title: "OpenCanteen",
            theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
            darkTheme: ThemeData(
                brightness: Brightness.dark,
                useMaterial3: true,
                colorScheme: darkColorScheme),
            home: const LoginPage(),
          )
        : Theme(
            data: ThemeData(
                useMaterial3: true,
                colorScheme: (MediaQuery.of(context).platformBrightness ==
                        Brightness.dark)
                    ? darkColorScheme
                    : lightColorScheme),
            child: const CupertinoApp(
              debugShowCheckedModeBanner: false,
              localizationsDelegates: [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              title: "OpenCanteen",
              theme: CupertinoThemeData(
                primaryColor: Colors.purple,
              ),
              home: LoginPage(),
            ),
          );
  }
}
