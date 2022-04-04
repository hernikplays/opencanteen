import 'package:canteenlib/canteenlib.dart';
import 'package:flutter/material.dart';
import 'package:opencanteen/util.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';

import '../main.dart';

class JidelnicekPage extends StatefulWidget {
  const JidelnicekPage({Key? key, required this.canteen, required this.user})
      : super(key: key);
  final Canteen canteen;
  final String user;
  @override
  State<JidelnicekPage> createState() => _JidelnicekPageState();
}

class _JidelnicekPageState extends State<JidelnicekPage> {
  List<Widget> obsah = [];
  DateTime den = DateTime.now();
  String denTydne = "";
  double kredit = 0.0;
  Future<void> nactiJidlo() async {
    obsah = [];
    widget.canteen.ziskejUzivatele().then((kr) {
      kredit = kr.kredit;
      widget.canteen.jidelnicekDen(den: den).then((jd) {
        setState(() {
          for (var j in jd.jidla) {
            obsah.add(
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Row(
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
                        onChanged: (v) async {
                          if (!j.lzeObjednat) return;

                          widget.canteen
                              .objednat(j)
                              .then((value) => nactiJidlo);
                        })
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
    switch (den.weekday) {
      case 2:
        denTydne = "Úterý";
        break;
      case 3:
        denTydne = "Středa";
        break;
      case 4:
        denTydne = "Čtvrtek";
        break;
      case 5:
        denTydne = "Pátek";
        break;
      case 6:
        denTydne = "Sobota";
        break;
      case 7:
        denTydne = "Neděle";
        break;
      default:
        denTydne = "Pondělí";
    }
    nactiJidlo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawerGenerator(context, widget.canteen, widget.user, 2),
      appBar: AppBar(
        title: const Text('Jídelníček'),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text("Kredit: $kredit"),
            TextButton(
                onPressed: () async {
                  var datePicked = await DatePicker.showSimpleDatePicker(
                    context,
                    initialDate: den,
                    dateFormat: "dd-MMMM-yyyy",
                    locale: DateTimePickerLocale.en_us,
                    looping: true,
                  );
                  if (datePicked == null) return;
                  setState(() {
                    den = datePicked;
                    switch (den.weekday) {
                      case 2:
                        denTydne = "Úterý";
                        break;
                      case 3:
                        denTydne = "Středa";
                        break;
                      case 4:
                        denTydne = "Čtvrtek";
                        break;
                      case 5:
                        denTydne = "Pátek";
                        break;
                      case 6:
                        denTydne = "Sobota";
                        break;
                      case 7:
                        denTydne = "Neděle";
                        break;
                      default:
                        denTydne = "Pondělí";
                    }
                    nactiJidlo();
                  });
                },
                child:
                    Text("${den.day}. ${den.month}. ${den.year} - $denTydne")),
            ...obsah
          ],
        ),
      ),
    );
  }
}
