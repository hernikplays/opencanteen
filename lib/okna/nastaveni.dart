import 'dart:io';

import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../lang/lang.dart';
import '../loginmanager.dart';
import '../util.dart';

class Nastaveni extends StatefulWidget {
  const Nastaveni({Key? key, required this.n}) : super(key: key);

  final FlutterLocalNotificationsPlugin n;

  @override
  State<Nastaveni> createState() => _NastaveniState();
}

class _NastaveniState extends State<Nastaveni> {
  bool _ukladatOffline = false;
  bool _preskakovatVikend = false;
  bool _kontrolovatTyden = false;
  bool _oznameniObed = false;
  TimeOfDay _oznameniCas = TimeOfDay.now();

  void najitNastaveni() async {
    var preferences = await SharedPreferences.getInstance();
    setState(() {
      _ukladatOffline = preferences.getBool("offline") ?? false;
      _preskakovatVikend = preferences.getBool("skip") ?? false;
      _kontrolovatTyden = preferences.getBool("tyden") ?? false;
      _oznameniObed = preferences.getBool("oznamit") ?? false;
      var _casStr = preferences.getString("oznameni_cas");
      if (_casStr == null) {
        var now = DateTime.now();
        _oznameniCas = TimeOfDay.fromDateTime(DateTime.now());
        preferences.setString("oznameni_cas", now.toString());
      } else {
        _oznameniCas = TimeOfDay.fromDateTime(DateTime.parse(_casStr));
      }
    });
  }

  void zmenitNastaveni(String key, bool value) async {
    var preferences = await SharedPreferences.getInstance();
    preferences.setBool(key, value);
  }

  @override
  void initState() {
    super.initState();
    najitNastaveni();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Languages.of(context)!.settings),
      ),
      body: Center(
          child: SizedBox(
        width: MediaQuery.of(context).size.width / 1.1,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Languages.of(context)!.saveOffline),
                Switch(
                    value: _ukladatOffline,
                    onChanged: (value) {
                      setState(() {
                        _ukladatOffline = value;
                        cistit(value);
                        zmenitNastaveni("offline", value);
                      });
                    })
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Languages.of(context)!.skipWeekend),
                Switch(
                    value: _preskakovatVikend,
                    onChanged: (value) {
                      setState(() {
                        _preskakovatVikend = value;
                        zmenitNastaveni("skip", value);
                      });
                    })
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(Languages.of(context)!.checkOrdered)),
                Switch(
                    value: _kontrolovatTyden,
                    onChanged: (value) {
                      setState(() {
                        _kontrolovatTyden = value;
                        zmenitNastaveni("tyden", value);
                      });
                    })
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(Languages.of(context)!.notifyLunch)),
                Switch(
                    value: _oznameniObed,
                    onChanged: (value) {
                      setState(() {
                        _oznameniObed = value;
                        zmenitNastaveni("oznamit",
                            value); // TODO: změnit pouze s uloženými údaji
                      });
                    })
              ],
            ),
            Text(Languages.of(context)!.notifyAt),
            TextButton(
                style: ButtonStyle(
                    textStyle: MaterialStateProperty.all(TextStyle(
                        color: (_oznameniObed) ? Colors.grey : Colors.purple))),
                onPressed: () async {
                  if (_oznameniObed) {
                    var cas = await showTimePicker(
                        context: context, initialTime: _oznameniCas);
                    if (cas != null) {
                      var prefs = await SharedPreferences.getInstance();
                      prefs.setString(
                          "oznameni_cas",
                          casNaDate(cas)
                              .toString()); // aktualizovat vybraný čas
                      var d = await LoginManager.getDetails(); // získat údaje
                      if (d != null) {
                        // Nové oznámení
                        var c = Canteen(d["url"]!);
                        if (await c.login(d["user"]!, d["pass"]!)) {
                          var jidla = await c.jidelnicekDen();
                          try {
                            var jidlo = jidla.jidla
                                .singleWhere((element) => element.objednano);

                            const AndroidNotificationDetails androidSpec =
                                AndroidNotificationDetails(
                                    'opencanteen', 'predobjedem',
                                    channelDescription:
                                        'Oznámení o dnešním jídle',
                                    importance: Importance.max,
                                    priority: Priority.high,
                                    ticker: 'today meal');
                            const IOSNotificationDetails iOSpec =
                                IOSNotificationDetails(
                                    presentAlert: true, presentBadge: true);
                            debugPrint(casNaDate(cas).toString());
                            var l = tz.getLocation(
                                await FlutterNativeTimezone.getLocalTimezone());
                            await widget.n.zonedSchedule(
                                // Vytvoří nové oznámení pro daný čas a datum
                                0,
                                Languages.of(context)!.lunchNotif,
                                "${jidlo.nazev} - ${jidlo.varianta}",
                                tz.TZDateTime.from(casNaDate(cas), l),
                                const NotificationDetails(
                                    android: androidSpec, iOS: iOSpec),
                                androidAllowWhileIdle: true,
                                uiLocalNotificationDateInterpretation:
                                    UILocalNotificationDateInterpretation
                                        .absoluteTime);
                          } on StateError catch (_) {
                            // nenalezeno
                          }
                        }
                      }
                    }
                    setState(() {
                      _oznameniCas = cas ?? _oznameniCas;
                    });
                  }
                },
                child: Text(
                    "${(_oznameniCas.hour < 10 ? "0" : "") + _oznameniCas.hour.toString()}:${(_oznameniCas.minute < 10 ? "0" : "") + _oznameniCas.minute.toString()}")),
          ],
        ),
      )),
    );
  }

  void cistit(bool value) async {
    if (!value) {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      for (var f in appDocDir.listSync()) {
        // Vymažeme obsah
        if (f.path.contains("jidelnicek")) {
          f.deleteSync();
        }
      }
    }
  }
}
