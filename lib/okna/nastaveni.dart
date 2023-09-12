import 'dart:io';

import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:opencanteen/pw/platformbutton.dart';
import 'package:opencanteen/pw/platformdialog.dart';
import 'package:opencanteen/pw/platformfield.dart';
import 'package:path_provider/path_provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../loginmanager.dart';
import '../../main.dart';
import '../../util.dart';

class AndroidNastaveni extends StatefulWidget {
  const AndroidNastaveni({Key? key}) : super(key: key);

  @override
  State<AndroidNastaveni> createState() => _AndroidNastaveniState();
}

class _AndroidNastaveniState extends State<AndroidNastaveni> {
  bool _saveOffline = false;
  bool _skipWeekend = false;
  bool _checkWeek = false;
  bool _notifyMeal = false;
  bool _remember = false;
  TimeOfDay _notifTime = TimeOfDay.now();
  final TextEditingController _countController =
      TextEditingController(text: "1");
  SharedPreferences? preferences;

  void loadSettings() async {
    preferences = await SharedPreferences.getInstance();
    _remember = await LoginManager.rememberme();
    setState(
      () {
        _saveOffline = preferences!.getBool("offline") ?? false;
        _skipWeekend = preferences!.getBool("skip") ?? false;
        _checkWeek = preferences!.getBool("tyden") ?? false;
        _notifyMeal = preferences!.getBool("oznamit") ?? false;
        _countController.text =
            (preferences!.getInt("offline_pocet") ?? 1).toString();
        var casStr = preferences!.getString("oznameni_cas");
        if (casStr == null) {
          var now = DateTime.now();
          _notifTime = TimeOfDay.fromDateTime(
              DateTime.now().add(const Duration(hours: 1)));
          preferences!.setString("oznameni_cas", now.toString());
        } else {
          _notifTime = TimeOfDay.fromDateTime(DateTime.parse(casStr));
        }
      },
    );
  }

  void changeSetting(String key, bool value) async {
    preferences!.setBool(key, value);
  }

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: SettingsList(
        platform: DevicePlatform.device,
        sections: [
          SettingsSection(
            tiles: [
              SettingsTile.switchTile(
                initialValue: _saveOffline,
                onToggle: (value) {
                  _saveOffline = value;
                  settings.saveOffline = value;
                  changeSetting("offline", value);
                  setState(() {});
                },
                title: Text(AppLocalizations.of(context)!.saveOffline),
              ),
              CustomSettingsTile(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.76,
                      child: Text(
                        AppLocalizations.of(context)!.saveCount,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: (Platform.isAndroid) ? 18 : 17,
                          fontWeight:
                              (Platform.isAndroid) ? FontWeight.w400 : null,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    SizedBox(
                      width: 35,
                      child: PlatformField(
                        controller: _countController,
                        enabled: _saveOffline,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
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
              ),
              SettingsTile.switchTile(
                initialValue: _skipWeekend,
                onToggle: (value) {
                  _skipWeekend = value;
                  settings.skipWeekend = value;
                  changeSetting("skip", value);
                  setState(() {});
                },
                title: Text(AppLocalizations.of(context)!.skipWeekend),
              ),
              SettingsTile.switchTile(
                initialValue: _checkWeek,
                onToggle: (value) {
                  _checkWeek = value;
                  settings.checkOrdered = value;
                  changeSetting("tyden", value);
                  setState(() {});
                },
                title: Text(AppLocalizations.of(context)!.checkOrdered),
              ),
            ],
            title: Text(AppLocalizations.of(context)!.settingsExperience),
          ),
          SettingsSection(
            tiles: [
              SettingsTile.switchTile(
                initialValue: _notifyMeal,
                enabled: _remember,
                onToggle: (value) {
                  if (!_remember) {
                    showDialog(
                      context: context,
                      builder: (bc) => PlatformDialog(
                        title: AppLocalizations.of(context)!.error,
                        content: AppLocalizations.of(context)!.needRemember,
                        actions: [
                          PlatformButton(
                            text: AppLocalizations.of(context)!.ok,
                            onPressed: () {
                              Navigator.of(bc).pop();
                            },
                          )
                        ],
                      ),
                    );
                  } else {
                    _notifyMeal = value;
                    if (_notifyMeal) {
                      showDialog(
                        context: context,
                        builder: (context) => PlatformDialog(
                          title: AppLocalizations.of(context)!.warning,
                          content: AppLocalizations.of(context)!.notifyWarning,
                          actions: [
                            PlatformButton(
                              text: AppLocalizations.of(context)!.ok,
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            )
                          ],
                        ),
                      );
                      createNotif(timeToDate(_notifTime));
                    }
                    changeSetting("oznamit", value);
                    setState(() {});
                  }
                },
                title: Text(
                  AppLocalizations.of(context)!.notifyLunch,
                ),
              ),
              CustomSettingsTile(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.notifyAt,
                      style: TextStyle(
                        fontSize: (Platform.isAndroid) ? 18 : 17,
                        fontWeight:
                            (Platform.isAndroid) ? FontWeight.w400 : null,
                      ),
                    ),
                    PlatformButton(
                      textStyle:
                          TextStyle(fontSize: (Platform.isAndroid ? 18 : 17)),
                      text: _notifTime.format(context),
                      onPressed: () async {
                        if (!_notifyMeal) return;
                        var cas = await showTimePicker(
                            context: context, initialTime: _notifTime);
                        if (cas == null) return;
                        var prefs = await SharedPreferences.getInstance();
                        prefs.setString(
                            "oznameni_cas",
                            timeToDate(cas)
                                .toString()); // aktualizovat vybraný čas
                        var den = timeToDate(cas);
                        debugPrint(den.isAfter(DateTime.now()).toString());
                        if (den.isAfter(DateTime.now())) {
                          // znovu vytvořit oznámení POUZE když je čas v budoucnosti
                          createNotif(den);
                        }

                        _notifTime = cas;
                        setState(() {});
                      },
                    )
                  ],
                ),
              )
            ],
            title: Text(AppLocalizations.of(context)!.settingsFunctions),
          )
        ],
      ),
    );
  }

  void clear(bool value) async {
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

  void createNotif(DateTime den) async {
    await flutterLocalNotificationsPlugin.cancelAll();
    var d = await LoginManager.getDetails(); // grab details
    if (d != null) {
      var c = Canteen(d["url"]!);
      if (await c.login(d["user"]!, d["pass"]!)) {
        var jidla = await c.jidelnicekDen();
        try {
          var jidlo = jidla.jidla.singleWhere((element) => element.objednano);

          const AndroidNotificationDetails androidSpec =
              AndroidNotificationDetails('opencanteen', 'predobjedem',
                  channelDescription: 'Oznámení o dnešním jídle',
                  importance: Importance.max,
                  priority: Priority.high,
                  ticker: 'today meal');
          var l =
              tz.getLocation(await FlutterNativeTimezone.getLocalTimezone());
          if (!mounted) return;
          await flutterLocalNotificationsPlugin.zonedSchedule(
              // schedules a notification
              0,
              AppLocalizations.of(context)!.lunchNotif,
              "${jidlo.varianta} - ${jidlo.nazev}",
              tz.TZDateTime.from(den, l),
              const NotificationDetails(android: androidSpec),
              androidAllowWhileIdle: true,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime);
        } on StateError catch (_) {
          // no meal found
        }
      }
    }
  }
}
