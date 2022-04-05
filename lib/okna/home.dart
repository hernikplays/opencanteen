import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opencanteen/main.dart';
import 'package:opencanteen/util.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.user, required this.canteen})
      : super(key: key);

  final String user;
  final Canteen canteen;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double kredit = 0.0;
  Jidelnicek? dnes;
  Jidlo? jidloDnes;
  List<Widget> obsah = [];

  Future<void> nactiJidlo() async {
    obsah = [];
    widget.canteen.ziskejUzivatele().then((kr) {
      widget.canteen.jidelnicekDen().then((jd) {
        setState(() {
          kredit = kr.kredit;
          dnes = jd;
          for (var j in jd.jidla) {
            if (j.objednano) jidloDnes = j;
            obsah.add(
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(j.varianta),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        j.nazev,
                      ),
                    ),
                    Text("${j.cena} Kč"),
                    Checkbox(
                        value: j.objednano,
                        fillColor: (j.lzeObjednat)
                            ? MaterialStateProperty.all(Colors.blue)
                            : MaterialStateProperty.all(Colors.grey),
                        onChanged: (v) => setState(() {
                              // TODO exception handling
                              if (!j.lzeObjednat) return;
                              widget.canteen.objednat(j);
                              nactiJidlo();
                            }))
                  ],
                ),
              ),
            );
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
    nactiJidlo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawerGenerator(context, widget.canteen, widget.user, 1),
      appBar: AppBar(
        title: const Text("Domů"),
        actions: [
          IconButton(
              onPressed: (() {
                const storage = FlutterSecureStorage();
                storage.deleteAll();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (c) => const LoginPage()));
              }),
              icon: const Icon(Icons.logout))
        ],
      ),
      body: RefreshIndicator(
        onRefresh: nactiJidlo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: SizedBox(
              child: Column(
                children: [
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    "${widget.user} - $kredit kč",
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    "Dnes je ${DateTime.now().day}. ${DateTime.now().month}.",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(children: obsah),
                  ),
                ],
              ),
              width: MediaQuery.of(context).size.width - 50,
            ),
          ),
        ),
      ),
    );
  }
}
