import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:opencanteen/lang/lang.dart';
import 'package:opencanteen/okna/ios/jidelnicek.dart';

class IOSWelcome extends StatefulWidget {
  const IOSWelcome({Key? key, required this.canteen}) : super(key: key);

  final Canteen canteen;

  @override
  State<IOSWelcome> createState() => _IOSWelcomeState();
}

class _IOSWelcomeState extends State<IOSWelcome> {
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
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (c) => IOSJidelnicek(canteen: widget.canteen)),
              (route) => false);
        },
      ),
    );
  }
}
