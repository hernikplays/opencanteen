import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';
import 'package:opencanteen/okna/login.dart';
import 'package:opencanteen/pw/platformbutton.dart';
import 'package:opencanteen/pw/platformdialog.dart';
import 'package:opencanteen/util.dart';

import '../../lang/lang.dart';

class BurzaView extends StatefulWidget {
  const BurzaView({Key? key, required this.canteen}) : super(key: key);
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
            Languages.of(context)!.noExchange,
            style: const TextStyle(fontSize: 20),
          ),
          Text(Languages.of(context)!.pullToReload)
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
                                title: Languages.of(context)!.ordered,
                                content: Languages.of(context)!.orderSuccess,
                                actions: [
                                  PlatformButton(
                                    text: Languages.of(context)!.ok,
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
                                title: Languages.of(context)!.cannotOrder,
                                content: Languages.of(context)!.errorOrdering,
                                actions: [
                                  PlatformButton(
                                    text: Languages.of(context)!.ok,
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
                    text: Languages.of(context)!.order,
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
        title: Text(Languages.of(context)!.exchange),
      ),
      body: RefreshIndicator(
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 50,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text("${Languages.of(context)!.balance}$balance Kč"),
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
