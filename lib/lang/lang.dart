import 'package:flutter/material.dart';

abstract class Languages {
  static Languages? of(BuildContext context) {
    return Localizations.of<Languages>(context, Languages);
  }

  String get appName;

  String get home;

  // Login

  String get errorContacting;

  String get loggingIn;

  String get logIn;

  String get username;

  String get password;

  String get iCanteenUrl;

  String get rememberMe;

  String get httpLogin;

  String get yes;

  String get noChange;

  String get notOfficial;

  String get agree;

  String get disagree;

  String get loginFailed;

  String get warning;

  // Jídelníček

  String get loading;

  String get monday;

  String get tuesday;

  String get wednesday;

  String get thursday;

  String get friday;

  String get saturday;

  String get sunday;

  String get noFood;

  String get inExchange;

  String get ordering;

  String get errorOrdering;

  String get close;

  String get verifyExchange;

  String get no;

  String get exchangeError;

  String get signOut;

  String get reportBugs;

  String get about;

  String get menu;

  String get balance;

  // Burza

  String get exchange;

  String get noExchange;

  String get pullToReload;

  String get ordered;

  String get orderSuccess;

  String get ok;

  String get cannotOrder;

  String get order;

  // About

  String get usedLibs;

  String get license;

  String get copyright;

  // Settings

  String get settings;

  String get saveOffline;

  String get skipWeekend;

  // Offline
  String get offline;

  String get mustLogout;
}
