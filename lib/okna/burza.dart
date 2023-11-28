import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';
import 'package:opencanteen/okna/login.dart';
import 'package:opencanteen/pw/platformbutton.dart';
import 'package:opencanteen/pw/platformdialog.dart';
import 'package:opencanteen/util.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BurzaView extends StatefulWidget {
  const BurzaView({super.key, required this.canteen});
  final Canteen canteen;
  @override
  State<BurzaView> createState() => _BurzaViewState();
}

class _BurzaViewState extends State<BurzaView> {
  List<Widget> content = [];
  double balance = 0.0;

  Future<void> loadExchange(BuildContext context) async {
    content = [const CircularProgressIndicator()];
    var uzivatel = await widget.canteen.ziskejUzivatele().catchError((o) {
      if (!widget.canteen.prihlasen) {
        Navigator.pushReplacement(
            context, platformRouter((c) => const LoginPage()));
      }
      return Uzivatel(kredit: 0);
    });
    balance = uzivatel.kredit;
    var burza = await widget.canteen.ziskatBurzu();
    setState(() {
      content = [];
      if (burza.isEmpty) {
        content = [
          Text(
            AppLocalizations.of(context)!.noExchange,
            style: const TextStyle(fontSize: 20),
          ),
          Text(AppLocalizations.of(context)!.pullToReload)
        ];
      } else {
        for (var b in burza) {
          content.add(
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${b.den.day}. ${b.den.month}."),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      b.nazev,
                    ),
                  ),
                  Text("${b.pocet}x"),
                  PlatformButton(
                    onPressed: () {
                      widget.canteen.objednatZBurzy(b).then(
                        (a) {
                          if (a) {
                            showDialog(
                              context: context,
                              builder: (context) => PlatformDialog(
                                title: AppLocalizations.of(context)!.ordered,
                                content:
                                    AppLocalizations.of(context)!.orderSuccess,
                                actions: [
                                  PlatformButton(
                                    text: AppLocalizations.of(context)!.ok,
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  )
                                ],
                              ),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => PlatformDialog(
                                title:
                                    AppLocalizations.of(context)!.cannotOrder,
                                content:
                                    AppLocalizations.of(context)!.errorOrdering,
                                actions: [
                                  PlatformButton(
                                    text: AppLocalizations.of(context)!.ok,
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  )
                                ],
                              ),
                            );
                          }
                          loadExchange(context);
                        },
                      );
                    },
                    text: AppLocalizations.of(context)!.order,
                  ),
                ],
              ),
            ),
          );
        }
      }
    });
    return;
  }

  @override
  void initState() {
    super.initState();
    loadExchange(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawerGenerator(context, widget.canteen, 3),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.exchange),
      ),
      body: RefreshIndicator(
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 50,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text("${AppLocalizations.of(context)!.balance}$balance Kč"),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height / 1.3,
                      child: Column(children: content),
                    ),
                  )
                ],
              ),
            ),
          ),
          onRefresh: () => loadExchange(context)),
    );
  }
}
