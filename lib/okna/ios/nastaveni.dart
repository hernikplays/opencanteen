import 'dart:io';

import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../lang/lang.dart';
import '../../loginmanager.dart';
import '../../main.dart';
import '../../util.dart';

class IOSNastaveni extends StatefulWidget {
  const IOSNastaveni({Key? key}) : super(key: key);

  @override
  State<IOSNastaveni> createState() => _IOSNastaveniState();
}

class _IOSNastaveniState extends State<IOSNastaveni> {
  bool _ukladatOffline = false;
  bool _preskakovatVikend = false;
  bool _kontrolovatTyden = false;
  bool _oznameniObed = false;
  bool _zapamatovany = false;
  TimeOfDay _oznameniCas = TimeOfDay.now();
  final TextEditingController _countController =
      TextEditingController(text: "1");
  SharedPreferences? preferences;
  void najitNastaveni() async {
    preferences = await SharedPreferences.getInstance();
    _zapamatovany = await LoginManager.zapamatovat();
    setState(() {
      _ukladatOffline = preferences!.getBool("offline") ?? false;
      _preskakovatVikend = preferences!.getBool("skip") ?? false;
      _kontrolovatTyden = preferences!.getBool("tyden") ?? false;
      _oznameniObed = preferences!.getBool("oznamit") ?? false;
      _countController.text =
          (preferences!.getInt("offline_pocet") ?? 1).toString();
      var casStr = preferences!.getString("oznameni_cas");
      if (casStr == null) {
        var now = DateTime.now();
        _oznameniCas = TimeOfDay.fromDateTime(
            DateTime.now().add(const Duration(hours: 1)));
        preferences!.setString("oznameni_cas", now.toString());
      } else {
        _oznameniCas = TimeOfDay.fromDateTime(DateTime.parse(casStr));
      }
    });
  }

  void zmenitNastaveni(String key, bool value) async {
    preferences!.setBool(key, value);
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
                CupertinoSwitch(
                    activeColor: Colors.purple,
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
                Text(Languages.of(context)!.saveCount),
                SizedBox(
                  width: 35,
                  child: CupertinoTextField(
                    controller: _countController,
                    enabled: _ukladatOffline,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (c) {
                      var cislo = int.tryParse(c);
                      if (cislo != null) {
                        preferences!.setInt("offline_pocet", cislo);
                      }
                    },
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Languages.of(context)!.skipWeekend),
                CupertinoSwitch(
                    activeColor: Colors.purple,
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
                CupertinoSwitch(
                    activeColor: Colors.purple,
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
                CupertinoSwitch(
                    activeColor: Colors.purple,
                    value: _oznameniObed,
                    onChanged: (value) {
                      if (!_zapamatovany) {
                        showDialog(
                            context: context,
                            builder: (bc) => CupertinoAlertDialog(
                                  title: Text(Languages.of(context)!.error),
                                  content:
                                      Text(Languages.of(context)!.needRemember),
                                  actions: [
                                    CupertinoButton(
                                      child: Text(Languages.of(context)!.ok),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    )
                                  ],
                                ));
                      } else {
                        setState(() {
                          _oznameniObed = value;
                          if (_oznameniObed) {
                            showDialog(
                                context: context,
                                builder: (context) => CupertinoAlertDialog(
                                      title:
                                          Text(Languages.of(context)!.warning),
                                      content: Text(
                                          Languages.of(context)!.notifyWarning),
                                      actions: [
                                        CupertinoButton(
                                          child:
                                              Text(Languages.of(context)!.ok),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        )
                                      ],
                                    ));
                            vytvoritOznameni(casNaDate(_oznameniCas));
                          }
                          zmenitNastaveni("oznamit", value);
                        });
                      }
                    })
              ],
            ),
            Text(Languages.of(context)!.notifyAt),
            CupertinoButton(
              onPressed: () async {
                if (_oznameniObed) {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (c) {
                      return Container(
                        height: 216,
                        padding: const EdgeInsets.only(top: 6),
                        margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        color: CupertinoColors.systemBackground
                            .resolveFrom(context),
                        child: SafeArea(
                          top: false,
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            onDateTimeChanged: (cas) {
                              setState(() {
                                _oznameniCas = TimeOfDay.fromDateTime(cas);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  );
                }
              },
              child: Text(
                "${(_oznameniCas.hour < 10 ? "0" : "") + _oznameniCas.hour.toString()}:${(_oznameniCas.minute < 10 ? "0" : "") + _oznameniCas.minute.toString()}",
                style: TextStyle(
                    color: (!_oznameniObed) ? Colors.grey : Colors.purple),
              ),
            ),
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

  void vytvoritOznameni(DateTime den) async {
    await flutterLocalNotificationsPlugin.cancelAll();
    var d = await LoginManager.getDetails(); // získat údaje
    if (d != null) {
      // Nové oznámení
      var c = Canteen(d["url"]!);
      if (await c.login(d["user"]!, d["pass"]!)) {
        var jidla = await c.jidelnicekDen();
        try {
          var jidlo = jidla.jidla.singleWhere((element) => element.objednano);
          var l =
              tz.getLocation(await FlutterNativeTimezone.getLocalTimezone());
          if (!mounted) return;
          await flutterLocalNotificationsPlugin.zonedSchedule(
              // Vytvoří nové oznámení pro daný čas a datum
              0,
              Languages.of(context)!.lunchNotif,
              "${jidlo.varianta} - ${jidlo.nazev}",
              tz.TZDateTime.from(den, l),
              const NotificationDetails(),
              androidAllowWhileIdle: true,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime);
        } on StateError catch (_) {
          // nenalezeno
        }
      }
    }
  }
}
