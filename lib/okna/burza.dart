import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';
import 'package:opencanteen/util.dart';

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
  Future<void> nactiBurzu() async {
    obsah = [const CircularProgressIndicator()];
    widget.canteen.ziskejUzivatele().then((kr) {
      kredit = kr.kredit;
      widget.canteen.ziskatBurzu().then((burza) {
        setState(() {
          obsah = [];
          if (burza.isEmpty) {
            obsah = [
              const Text(
                "Žádné jídlo v burze.",
                style: TextStyle(fontSize: 20),
              ),
              const Text("Potáhněte zvrchu pro načtení.")
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
                                    title: const Text("Objednáno"),
                                    content: const Text(
                                        "Jídlo bylo úspěšně objednáno."),
                                    actions: [
                                      TextButton(
                                        child: const Text("OK"),
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
                                    title: const Text("Nelze objednat"),
                                    content: const Text(
                                        "Jídlo se nepodařilo objednat."),
                                    actions: [
                                      TextButton(
                                        child: const Text("OK"),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      )
                                    ],
                                  ),
                                );
                              }
                              nactiBurzu();
                            });
                          },
                          child: const Text("Objednat")),
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
    nactiBurzu();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawerGenerator(context, widget.canteen, widget.user, 3),
      appBar: AppBar(
        title: const Text('Burza'),
      ),
      body: RefreshIndicator(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text("Kredit: $kredit Kč"),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 120,
                    child: Column(children: obsah),
                  ),
                )
              ],
            ),
          ),
          onRefresh: () => nactiBurzu()),
    );
  }
}
