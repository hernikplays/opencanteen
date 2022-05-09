import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// TODO

class Nastaveni extends StatefulWidget {
  const Nastaveni({Key? key}) : super(key: key);

  @override
  State<Nastaveni> createState() => _NastaveniState();
}

class _NastaveniState extends State<Nastaveni> {
  bool _ukladatOffline = false;

  void najitNastaveni() async {
    var preferences = await SharedPreferences.getInstance();
    _ukladatOffline = preferences.getBool("offline") ?? false;
  }

  void zmenitNastaveni(String key, bool value) async {
    var preferences = await SharedPreferences.getInstance();
    preferences.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nastavení'),
      ),
      body: Center(
          child: Column(
        children: [
          Row(
            children: [
              const Text("Ukládat jídelníček na dnešní den offline"),
              Switch(
                  value: _ukladatOffline,
                  onChanged: (value) {
                    setState(() {
                      _ukladatOffline = value;
                      zmenitNastaveni("offline", value);
                    });
                  })
            ],
          )
        ],
      )),
    );
  }
}
