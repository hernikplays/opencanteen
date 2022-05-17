import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';
import 'package:opencanteen/util.dart';

import '../lang/lang.dart';
import '../main.dart';

class BurzaPage extends StatefulWidget {
  const BurzaPage({Key? key, required this.canteen, required this.user})
      : super(key: key);
  final Canteen canteen;
  final String user;
  @override
  State<BurzaPage> createState() => _BurzaPageState();
}

class _BurzaPageState extends State<BurzaPage> {
  List<Widget> obsah = [];
  double kredit = 0.0;
  Future<void> nactiBurzu(BuildContext context) async {
    obsah = [const CircularProgressIndicator()];
    widget.canteen.ziskejUzivatele().then((kr) {
      kredit = kr.kredit;
      widget.canteen.ziskatBurzu().then((burza) {
        setState(() {
          obsah = [];
          if (burza.isEmpty) {
            obsah = [
              Text(
                Languages.of(context)!.noExchange,
                style: const TextStyle(fontSize: 20),
              ),
              Text(Languages.of(context)!.pullToReload)
            ];
          } else {
            for (var b in burza) {
              obsah.add(
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
                      TextButton(
                          onPressed: () {
                            widget.canteen.objednatZBurzy(b).then((a) {
                              if (a) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(Languages.of(context)!.ordered),
                                    content: Text(
                                        Languages.of(context)!.orderSuccess),
                                    actions: [
                                      TextButton(
                                        child: Text(Languages.of(context)!.ok),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      )
                                    ],
                                  ),
                                );
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                        Languages.of(context)!.cannotOrder),
                                    content: Text(
                                        Languages.of(context)!.errorOrdering),
                                    actions: [
                                      TextButton(
                                        child: Text(Languages.of(context)!.ok),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      )
                                    ],
                                  ),
                                );
                              }
                              nactiBurzu(context);
                            });
                          },
                          child: Text(Languages.of(context)!.order)),
                    ],
                  ),
                ),
              );
            }
          }
        });
      });
    }).catchError((o) {
      if (!widget.canteen.prihlasen) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (c) => const LoginPage()));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    nactiBurzu(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawerGenerator(context, widget.canteen, widget.user, 3),
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
                  Text("${Languages.of(context)!.balance}$kredit Kč"),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height / 1.3,
                      child: Column(children: obsah),
                    ),
                  )
                ],
              ),
            ),
          ),
          onRefresh: () => nactiBurzu(context)),
    );
  }
}
