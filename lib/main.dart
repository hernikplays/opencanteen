import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opencanteen/loginmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:canteenlib/canteenlib.dart';

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
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale("cs")],
      title: 'OpenCanteen',
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
          const SnackBar(
            content: Text(
                "Nastala chyba při kontaktování serveru, zkontrolujte připojení"),
          ),
        );
      }

      if (r != null) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => Dialog(
                  child: SizedBox(
                    height: 100,
                    child: Row(children: const [
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(),
                      ),
                      Text("Přihlašuji vás")
                    ]),
                  ),
                ));
        var canteen = Canteen(r["url"]!);
        var l = await canteen.login(r["user"]!, r["pass"]!);
        if (!l) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Přihlášení se nezdařilo, zkontrolujte údaje"),
            ),
          );
          return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => JidelnicekPage(
                    user: r["user"]!,
                    canteen: canteen,
                  )),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Přihlášení"),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'OpenCanteen',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
                  ),
                  const Text(
                    'Přihlášení',
                    textAlign: TextAlign.center,
                  ),
                  TextField(
                    controller: userControl,
                    autofillHints: const [AutofillHints.username],
                    decoration:
                        const InputDecoration(labelText: 'Uživatelské jméno'),
                  ),
                  TextField(
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Heslo'),
                    controller: passControl,
                    obscureText: true,
                  ),
                  TextField(
                    autofillHints: const [AutofillHints.url],
                    decoration:
                        const InputDecoration(labelText: 'iCanteen URL'),
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
                    const Text("Zapamatovat si mě")
                  ]),
                  TextButton(
                      onPressed: () async {
                        if (canteenControl.text.contains("http://")) {
                          // kontrolujeme šifrované spojení
                          var d = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                    title: const Text("Varování!"),
                                    content: const SingleChildScrollView(
                                        child: Text(
                                            "Snažíte se přihlásit přes nešifrované spojení HTTP, jste si jisti, že tak chcete učinit?")),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, true),
                                          child: const Text("Ano")),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, false),
                                          child: const Text("Ne, změnit"))
                                    ],
                                  ));
                          if (!d!) return;
                        }

                        // souhlas
                        const storage = FlutterSecureStorage();
                        var odsouhlasil = await storage.read(key: "oc_souhlas");
                        if (odsouhlasil == null || odsouhlasil != "ano") {
                          var d = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                    title: const Text("Pozor"),
                                    content: const SingleChildScrollView(
                                        child: Text(
                                            "Toto není oficiální aplikace k ovládání iCanteen. Autor neručí za ztráty nebo nefunkčnost v souvislosti s používáním této aplikace. Tato zpráva se znovu neukáže.")),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, true),
                                          child: const Text("Souhlasím")),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, false),
                                          child: const Text("Nesouhlasím"))
                                    ],
                                  ));
                          if (!d!) return;
                          await storage.write(key: "oc_souhlas", value: "ano");
                        }
                        if (!canteenControl.text.startsWith("https://") &&
                            !canteenControl.text.startsWith("http://")) {
                          canteenControl.text =
                              "https://" + canteenControl.text;
                        }
                        var canteen = Canteen(canteenControl.text);
                        var l = await canteen.login(
                            userControl.text, passControl.text);
                        if (!l) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Přihlášení se nezdařilo, zkontrolujte údaje"),
                            ),
                          );
                          return;
                        }
                        if (rememberMe) {
                          LoginManager.setDetails(userControl.text,
                              passControl.text, canteenControl.text);
                        }
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => JidelnicekPage(
                                    user: userControl.text,
                                    canteen: canteen,
                                  )),
                        );
                      },
                      child: const Text("Přihlásit se")),
                ],
              ),
            ),
          ),
        ));
  }
}
