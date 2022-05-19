import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opencanteen/lang/lang_cz.dart';
import 'package:opencanteen/loginmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:canteenlib/canteenlib.dart';
import 'package:opencanteen/okna/offline_jidelnicek.dart';
import 'package:opencanteen/okna/welcome.dart';
import 'package:opencanteen/util.dart';
import 'package:path_provider/path_provider.dart';

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

void main() {
  runApp(const MyApp());
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

  @override
  void initState() {
    super.initState();
    LoginManager.getDetails().then((r) async {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Languages.of(context)!.errorContacting),
          ),
        );
        goOffline();
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
        } catch (_) {
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
                                      )),
                            );
                          }
                        } on Exception catch (_) {
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
