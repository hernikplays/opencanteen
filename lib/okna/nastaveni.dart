import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lang/lang.dart';

class Nastaveni extends StatefulWidget {
  const Nastaveni({Key? key}) : super(key: key);

  @override
  State<Nastaveni> createState() => _NastaveniState();
}

class _NastaveniState extends State<Nastaveni> {
  bool _ukladatOffline = false;
  bool _preskakovatVikend = false;
  bool _kontrolovatTyden = false;
  bool _oznameniObed = false;
  String? _oznameniCas;

  void najitNastaveni() async {
    var preferences = await SharedPreferences.getInstance();
    setState(() {
      _ukladatOffline = preferences.getBool("offline") ?? false;
      _preskakovatVikend = preferences.getBool("skip") ?? false;
      _kontrolovatTyden = preferences.getBool("tyden") ?? false;
      _oznameniObed = preferences.getBool("oznamit") ?? false;
      _oznameniCas = preferences.getString("oznameni_cas");
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
                Text(Languages.of(context)!.skipWeekend),
                Switch(
                    value: _oznameniObed,
                    onChanged: (value) {
                      setState(() {
                        _oznameniObed = value;
                        zmenitNastaveni("oznamit", value);
                      });
                    })
              ],
            ),
            Text(Languages.of(context)!.notifyAt),
            TimePickerDialog(
              initialTime: (_oznameniCas == null)
                  ? TimeOfDay.now()
                  : TimeOfDay.fromDateTime(DateTime.parse(_oznameniCas!)),
            )
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
