# 1.10.0
- Aktualizovat závislosti
- Změnit minSdk na 21
- Přidat možnost zobrazit alergeny
- Změnit fungování oznámení s aktualizací knihovny
- Žádost o oprávnění k posílání oznámení by se mělo posílat už jen v případě, že uživatel bude chtít používat funkci oznámení
# 1.9.1
- Opravit chybu s propisováním HTML do názvu obědů
# 1.9.0
- Opravit vzhled na iOS
- Opravit chybu s burzou (update canteenlib)
# 1.8.1
- aktualizace závislostí
# 1.8.0
- aktualizace závislostí
- předělání nastavení
- změna nastavení nyní nevyžaduje restart aplikace
# 1.7.0
- Implementovat Material 3 (Android)
- Upravit chování dle platformy
- Předělat jazykový systém na ARB
- Aktualizovat flutter_secure_storage
# 1.6.1
- opravit chybu s přidáváním do burzy aktualizací knihovny
# 1.6.0
- rozdělit iOS a Android UI zvlášť pro možnost využití Cupertino knihovny
- opravit chybu s FlutterLocalNotifications na iOS
- upravit vzhled
# 1.5.1
- aktualizovat knihovnu canteenlib
- přidat podporu pro splitování APK podle ABI
# 1.5.0
- umožnit ukládat více dnů offline
- chyba při ukládání offline vás nyní již nevyhodí ale zobrazí pouze zprávu
- "Přihlašování" pop-up zmizí, když není přihlášení úspěšné
# 1.4.2
- aktualizace knihovny flutter_local_notifications
- lepší podpora pro Android 13
- změna na adaptivní ikony na Androidu
# 1.4.1
- aktualizovat knihovnu canteenlib
- změnit odkaz na odeslání zpětné vazby
- přidat odkaz na hodnocení v obchodu s aplikacemi
- opravit chybu s vytvářením notifikace
# 1.4.0
- Opravit chybu, kdy po stisknutí tlačítka zpět na hlavní stránce byl uživatel vrácen na přihlašovací obrazovku
- Přidat výběr z instancí (aktuálně pouze SŠTE Olomoucká)
- Vylepšit oznámení o neobjednaném jídle
- Nahradit info stránku info dialogem
# 1.3.1
- Odstranit zbytečné podmínky
- Přidat oznámení o optimalizaci baterie
- Změnit ID kanálu pro android oznámení
- Změnit ikonu pro přesunutí na aktuální den
- Přidat varování před odhlášením
- Při prvním zapnutí nastavovat výchozí čas pro oznámení o hodinu dopředu
- V oznámení zobrazit nejdřív variantu a pak název jídla
# 1.3.0
- Odstranit connectivity_plus
- Přidat možnost oznámení s info o obědu v daný čas
- Přidat k jídelníčku tlačítko, které zobrazí dnešní jídelníček
# 1.2.0
- Přidat možnost zobrazení oznámení v případě neobjednaného jídla na příští týden
- Přidat oznámení o rozbitých uložených údajích
# 1.1.2
- Přidat chybějící knihovnu do O Aplikaci (licence)
# 1.1.1
- Přidat informaci o neobjednatelném obědě (specialitka pro apple)
- Zobrazovat uvítací obrazovku při nedokončení i když je uživatel zapamatován
- Kalendář se zobrazuje ve správném jazyce
# 1.1.0
- Přidat uvítací obrazovku při prvním spuštění
- Mírné vyčištění kódu
- Jídlo lze nyní objednat/zrušit i kliknutím na checkbox
# 1.0.0
- Ukládání dnešního jídelníčku offline
- Stránka s možnostmi nastavení aplikace
- Přidán anglický překlad
- Opravy chyb
- Přidání možnosti přeskočení víkendu
# 0.1.1
- Přidán RefreshIndicator na obrazovku s jídelníčkem
- Přidáno odsazení od okrajů u jídelníčku
- Upgrade knihovny
- Odhlášení přesunuto do textového menu
- Odstraněna stránka domů, hlavní stránka je nyní jídelníček
- Přidána stránka `O Aplikaci`
- Dialogové okno k burze se nezobrazí u jídel, která nelze přidat do burzy
- Přidán načítací dialog při objednání (#6)
# 0.1.0
- První verze
