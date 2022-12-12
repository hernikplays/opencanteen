import 'dart:io';

import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opencanteen/okna/android/welcome.dart';

import '../../lang/lang.dart';
import '../../loginmanager.dart';
import '../../main.dart';
import '../../util.dart';
import 'jidelnicek.dart';
import 'offline_jidelnicek.dart';

class AndroidLogin extends StatefulWidget {
  const AndroidLogin({Key? key}) : super(key: key);
  @override
  State<AndroidLogin> createState() => _AndroidLoginState();
}

class _AndroidLoginState extends State<AndroidLogin> {
  TextEditingController userControl = TextEditingController();
  TextEditingController passControl = TextEditingController();
  TextEditingController canteenControl = TextEditingController();
  bool rememberMe = false;
  bool _showUrl = false;
  String dropdownUrl = instance.first["url"] ?? "";

  @override
  void initState() {
    super.initState();
    LoginManager.getDetails().then((r) async {
      // žádat o oprávnění na android
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestPermission();

      if (r != null) {
        // Automaticky přihlásit
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
            if (!mounted) return;
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
          if (!mounted) return;
          if (odsouhlasil == null || odsouhlasil != "ano") {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (c) => AndroidWelcome(canteen: canteen),
                ),
                (route) => false);
          } else {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => AndroidJidelnicek(canteen: canteen),
                ),
                (route) => false);
          }
        } on PlatformException {
          if (!mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Languages.of(context)!.corrupted),
            ),
          );
        } catch (_) {
          if (!mounted) return;
          Navigator.of(context).pop();
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
                  const SizedBox(
                    height: 10,
                  ),
                  DropdownButton(
                    isExpanded: true,
                    value: dropdownUrl,
                    items: instance.map<DropdownMenuItem<String>>((e) {
                      return DropdownMenuItem<String>(
                        value: e["url"],
                        child: Text(e["name"]!),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        if (value == "") {
                          _showUrl = true;
                        } else {
                          _showUrl = false;
                        }
                        dropdownUrl = value!;
                      });
                    },
                  ),
                  AnimatedOpacity(
                    opacity: _showUrl ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: TextField(
                      autofillHints: const [AutofillHints.url],
                      decoration: InputDecoration(
                          labelText: Languages.of(context)!.iCanteenUrl),
                      keyboardType: TextInputType.url,
                      controller: canteenControl,
                    ),
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
                        var canteenUrl = (dropdownUrl == "")
                            ? canteenControl.text
                            : dropdownUrl;
                        if (!canteenUrl.startsWith("https://") &&
                            !canteenUrl.startsWith("http://")) {
                          canteenUrl = "https://$canteenUrl";
                        }
                        var canteen = Canteen(canteenUrl);
                        try {
                          var l = await canteen.login(
                              userControl.text, passControl.text);
                          if (!l) {
                            if (!mounted) return;
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
                            LoginManager.setDetails(
                                userControl.text, passControl.text, canteenUrl);
                          }
                          // souhlas
                          const storage = FlutterSecureStorage();
                          var odsouhlasil =
                              await storage.read(key: "oc_souhlas");
                          if (!mounted) return;
                          if (odsouhlasil == null || odsouhlasil != "ano") {
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (c) => AndroidWelcome(
                                          canteen: canteen,
                                        )),
                                (route) => false);
                          } else {
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AndroidJidelnicek(
                                          canteen: canteen,
                                        )),
                                (route) => false);
                          }
                        } on PlatformException {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(Languages.of(context)!.corrupted),
                            ),
                          );
                        } on Exception catch (_) {
                          if (!mounted) return;
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

  /// Získá offline soubor a zobrazí údaje
  void goOffline() async {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: ((context) => const AndroidOfflineJidelnicek())),
        (route) => false);
  }
}
