import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:opencanteen/okna/jidelnicek.dart';
import 'package:opencanteen/util.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, required this.canteen});

  final Canteen canteen;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    var listPagesViewModel = [
      PageViewModel(
        title: AppLocalizations.of(context)!.welcome,
        body: AppLocalizations.of(context)!.appDesc,
        image: const Center(
          child: Icon(Icons.waving_hand_outlined, size: 175),
        ),
      ),
      PageViewModel(
        title: AppLocalizations.of(context)!.aboutOrder,
        body: AppLocalizations.of(context)!.howOrder,
        image: Center(
          child: Image.asset('assets/objednavam.png',
              width: MediaQuery.of(context).size.width * 0.85),
        ),
      ),
      PageViewModel(
        title: AppLocalizations.of(context)!.aboutToExch,
        body: AppLocalizations.of(context)!.howToExch,
        image: Center(
          child: Image.asset('assets/doburzy.png',
              width: MediaQuery.of(context).size.width * 0.85),
        ),
      ),
      PageViewModel(
        title: AppLocalizations.of(context)!.aboutFromExch,
        body: AppLocalizations.of(context)!.howFromExch,
        image: Center(
          child: Image.asset('assets/burza.png',
              width: MediaQuery.of(context).size.width * 0.85),
        ),
      ),
      PageViewModel(
        title: AppLocalizations.of(context)!.warning,
        body: AppLocalizations.of(context)!.notOfficial,
        image: const Center(
          child: Icon(Icons.warning_amber_outlined, size: 175),
        ),
      ),
    ];
    return Scaffold(
      body: IntroductionScreen(
        pages: listPagesViewModel,
        next: Text(AppLocalizations.of(context)!.next),
        done: Text(AppLocalizations.of(context)!.ok,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        onDone: () async {
          const storage = FlutterSecureStorage();
          await storage.write(key: "oc_souhlas", value: "ano");
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
              platformRouter((c) => MealView(canteen: widget.canteen)),
              (route) => false);
        },
      ),
    );
  }
}
