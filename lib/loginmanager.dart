import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginManager {
  static Future<Map<String, String>?> getDetails() async {
    // zkontrolovat secure storage pokud je něco uložené
    const storage = FlutterSecureStorage();
    var user = await storage.read(key: "oc_user");
    var pass = await storage.read(key: "oc_pass");
    var url = await storage.read(key: "oc_url");
    if (user == null || pass == null || url == null) return null;
    return {"user": user, "pass": pass, "url": url};
  }

  static Future<void> setDetails(String user, String pass, String url) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: "oc_user", value: user);
    await storage.write(key: "oc_pass", value: pass);
    await storage.write(key: "oc_url", value: url);
  }
}
