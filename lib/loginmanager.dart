import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginManager {
  static Future<Map<String, String>?> getDetails(String id) async {
    // zkontrolovat secure storage pokud je něco uložené
    const storage = FlutterSecureStorage();
    var user = await storage.read(key: "oc_user_$id");
    var pass = await storage.read(key: "oc_pass_$id");
    var url = await storage.read(key: "oc_url_$id");
    if (user == null || pass == null || url == null) return null;
    return {"user": user, "pass": pass, "url": url};
  }

  static Future<Map<int, List<String>>> ziskatVsechnyUlozene() async {
    const storage = FlutterSecureStorage();

    if (await storage.containsKey(key: "oc_user")) {
      await prevest();
    }
    var vsechno = await storage.readAll();
    vsechno.removeWhere((key, value) => key.startsWith("oc_pass_"));
    var uzivatele = <int, List<String>>{};
    vsechno.forEach((key, value) {
      if (key.startsWith("oc_user_")) {
        var user = int.parse(key.substring(8));
        if (uzivatele[user] == null) {
          uzivatele[user] = [value];
        } else {
          uzivatele[user]!.add(value);
        }
      } else {
        var user = int.parse(key.substring(8));
        if (uzivatele[user] == null) {
          uzivatele[user] = [value];
        } else {
          uzivatele[user]!.add(value);
        }
      }
    });
    print(uzivatele);
    return uzivatele;
  }

  static Future<void> setDetails(String user, String pass, String url) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: "oc_user", value: user);
    await storage.write(key: "oc_pass", value: pass);
    await storage.write(key: "oc_url", value: url);
  }

  static Future<bool> zapamatovat() async {
    const storage = FlutterSecureStorage();
    return await storage.containsKey(key: "oc_pass");
  }

  /// Převést na nový formát ukládání
  static Future<bool> prevest() async {
    const storage = FlutterSecureStorage();
    var user = await storage.read(key: "oc_user");
    var pass = await storage.read(key: "oc_pass");
    var url = await storage.read(key: "oc_url");
    if (user == null || pass == null || url == null) return false;
    await storage.write(key: "oc_user_0", value: user);
    await storage.write(key: "oc_pass_0", value: pass);
    await storage.write(key: "oc_url_0", value: url);

    await storage.delete(key: "oc_user");
    await storage.delete(key: "oc_pass");
    await storage.delete(key: "oc_url");
    return true;
  }
}
