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

  String get corrupted;

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

  String get review;

  String get about;

  String get menu;

  String get balance;

  String get noOrder;

  String get signOutWarn;

  String get jump;

  // Uvítací obrazovka

  String get welcome;

  String get appDesc;

  String get aboutOrder;

  String get howOrder;

  String get aboutToExch;

  String get howToExch;

  String get aboutFromExch;

  String get howFromExch;

  String get next;

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

  String get license;

  String get copyright;

  String get source;

  // Nastavení

  String get settings;

  String get saveOffline;

  String get skipWeekend;

  String get checkOrdered;

  String get notifyLunch;

  String get notifyAt;

  String get notifyWarning;

  String get autoburzaSetting;

  // Offline
  String get offline;

  String get mustLogout;

  // Oznámit před obědem
  String get lunchNotif;

  String get error;

  String get needRemember;
}
