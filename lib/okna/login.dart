import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opencanteen/okna/welcome.dart';
import 'package:opencanteen/pw/platformbutton.dart';
import 'package:opencanteen/pw/platformfield.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../loginmanager.dart';
import '../../main.dart';
import '../../util.dart';
import '../pw/platformswitch.dart';
import 'jidelnicek.dart';
import 'offline_jidelnicek.dart';

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
  bool _showUrl = false;
  String dropdownUrl = instance.first["url"] ?? "";

  @override
  void initState() {
    super.initState();
    LoginManager.getDetails().then((r) async {
      // request android notification access
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestPermission();

      if (r != null) {
        // Autologin
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
                      Text(AppLocalizations.of(context)!.loggingIn)
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
                content: Text(AppLocalizations.of(context)!.loginFailed),
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
                platformRouter(
                  (c) => WelcomePage(canteen: canteen),
                ),
                (route) => false);
          } else {
            Navigator.pushAndRemoveUntil(
                context,
                platformRouter(
                  (context) => MealView(canteen: canteen),
                ),
                (route) => false);
          }
        } on PlatformException {
          if (!mounted) return;
          Navigator.of(context).pop();
          showInfo(context, AppLocalizations.of(context)!.corrupted);
        } catch (_) {
          if (!mounted) return;
          Navigator.of(context).pop();
          showInfo(context, AppLocalizations.of(context)!.errorContacting);
          goOffline();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.logIn),
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
                  AppLocalizations.of(context)!.appName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 40),
                ),
                Text(
                  AppLocalizations.of(context)!.logIn,
                  textAlign: TextAlign.center,
                ),
                PlatformField(
                  controller: userControl,
                  autofillHints: const [AutofillHints.username],
                  labelText: AppLocalizations.of(context)!.username,
                ),
                PlatformField(
                  autofillHints: const [AutofillHints.password],
                  labelText: AppLocalizations.of(context)!.password,
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
                  child: PlatformField(
                    autofillHints: const [AutofillHints.url],
                    labelText: AppLocalizations.of(context)!.iCanteenUrl,
                    keyboardType: TextInputType.url,
                    controller: canteenControl,
                  ),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  PlatformSwitch(
                    value: rememberMe,
                    onChanged: (value) {
                      setState(() {
                        rememberMe = value;
                      });
                    },
                  ),
                  Text(AppLocalizations.of(context)!.rememberMe)
                ]),
                PlatformButton(
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
                          showInfo(context,
                              AppLocalizations.of(context)!.loginFailed);
                          return;
                        }
                        if (rememberMe) {
                          LoginManager.setDetails(
                              userControl.text, passControl.text, canteenUrl);
                        }
                        // souhlas
                        const storage = FlutterSecureStorage();
                        var odsouhlasil = await storage.read(key: "oc_souhlas");
                        if (!mounted) return;
                        if (odsouhlasil == null || odsouhlasil != "ano") {
                          Navigator.pushAndRemoveUntil(
                              context,
                              platformRouter(
                                (context) => WelcomePage(
                                  canteen: canteen,
                                ),
                              ),
                              (route) => false);
                        } else {
                          Navigator.pushAndRemoveUntil(
                              context,
                              platformRouter(
                                (context) => MealView(
                                  canteen: canteen,
                                ),
                              ),
                              (route) => false);
                        }
                      } on PlatformException {
                        if (!mounted) return;
                        showInfo(
                            context, AppLocalizations.of(context)!.corrupted);
                      } on Exception catch (_) {
                        if (!mounted) return;
                        showInfo(context,
                            AppLocalizations.of(context)!.errorContacting);
                        //goOffline();
                      }
                    },
                    text: AppLocalizations.of(context)!.logIn),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Switch to offline view
  void goOffline() async {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        platformRouter((context) => const OfflineMealView()), (route) => false);
  }
}
