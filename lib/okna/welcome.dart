import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:opencanteen/lang/lang.dart';
import 'package:opencanteen/okna/jidelnicek.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key, required this.canteen, required this.n})
      : super(key: key);

  final Canteen canteen;
  final FlutterLocalNotificationsPlugin n;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    var listPagesViewModel = [
      PageViewModel(
        title: Languages.of(context)!.welcome,
        body: Languages.of(context)!.appDesc,
        image: const Center(
          child: Icon(Icons.waving_hand_outlined, size: 175),
        ),
      ),
      PageViewModel(
        title: Languages.of(context)!.aboutOrder,
        body: Languages.of(context)!.howOrder,
        image: Center(
          child: Image.asset('assets/objednavam.png',
              width: MediaQuery.of(context).size.width * 0.85),
        ),
      ),
      PageViewModel(
        title: Languages.of(context)!.aboutToExch,
        body: Languages.of(context)!.howToExch,
        image: Center(
          child: Image.asset('assets/doburzy.png',
              width: MediaQuery.of(context).size.width * 0.85),
        ),
      ),
      PageViewModel(
        title: Languages.of(context)!.aboutFromExch,
        body: Languages.of(context)!.howFromExch,
        image: Center(
          child: Image.asset('assets/burza.png',
              width: MediaQuery.of(context).size.width * 0.85),
        ),
      ),
      PageViewModel(
        title: Languages.of(context)!.warning,
        body: Languages.of(context)!.notOfficial,
        image: const Center(
          child: Icon(Icons.warning_amber_outlined, size: 175),
        ),
      ),
    ];
    return Scaffold(
      body: IntroductionScreen(
        pages: listPagesViewModel,
        next: Text(Languages.of(context)!.next),
        done: Text(Languages.of(context)!.ok,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        onDone: () async {
          const storage = FlutterSecureStorage();
          await storage.write(key: "oc_souhlas", value: "ano");
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (c) =>
                  JidelnicekPage(canteen: widget.canteen, n: widget.n)));
        },
      ),
    );
  }
}
