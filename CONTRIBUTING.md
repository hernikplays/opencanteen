# Přispívání do OpenCanteen
OpenCanteen je **aplikace** pro přístup do iCanteen. Pokud chcete přispět kód související s komunikací s iCanteen, podívejte se na [canteenlib](https://github.com/hernikplays/canteenlib).

## Jak přispět do vývoje
### Nahlašování chyb
Prosté vyhledání a nahlášení chyby je asi nejjednodušší a zároveň nejpřínosnější způsob přispívání. Stačí vám běžné zařízení a stažená aplikace, pokud objevíte jakoukoliv chybu nebo nesrovnalost, nahlaste ji v [Issues](https://github.com/hernikplays/opencanteen/issues/new/choose).

Při nahlašování chyb se snažte řídit předlohou pro nahlašování chyb, informace, které se nikam nevlezly, napište úplně na konec.
### Přidání funkcí nebo oprava chyb
Pokud chcete jakkoliv přispět kódem, jste vítání. Zde následují věci, kterými byste se měli řídit.

#### Připravení projektu na vašem počítači
Budete potřebovat
- [Flutter](https://flutter.dev) (poslední stabilní verzi)
- Vývojové prostředí (Doporučuji [VS Code](https://code.visualstudio.com))
- [Git](https://git-scm.org) (není výhradně nutné, ale hodí se pro získání/přidání kódu na GitHub)

Jakmile máte všechno potřebné, [forkněte tento repozitář](https://docs.github.com/en/get-started/quickstart/fork-a-repo) na váš účet.

Poté si **váš** repozitář stáhněte, buď pomocí tlačítka `Code > Download ZIP` nebo (máte-li nainstalovaný Git) pomocí příkazu `git clone https://github.com/VASEJMENO/opencanteen`.

Následně můžete složku otevřít ve vámi preferovaném editoru a začít editovat

Budete-li chtít nahrát změny zpět do vašeho GitHub repozitáře, buďto je nahrajte na webu nebo použijte následující příkazy (jeden po druhém; může vyžadovat přihlášení):
- `git add .`
- `git commit -m 'feature: nové funkce'` (Místo "nové funkce" je dobré přidat krátký popis co přidáváte. **Tento repozitář se řídí [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) formátem, ujistěte se, že váš commit je ve stejném formátu**)
- `git push main`

#### Přidání kódu zpět do repozitáře
Jakmile máte přidáno všechno, je na čase otevřít [pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork) v našem repozitáři.

Všechny pull requesty **musí** být směřovány na větev `dev` a jejích název musí odpovídat [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) formátu, jinak budou automaticky zamítnuty.

Pokuste se v těle pull requestu popsat jaké funkce přidáváte nebo opravujete, případně přidejte odkaz na otevřený problém, pokud s ním souvisí.

Nějaký člověk váš kód zkontroluje a případně okomentuje co byste měl změnit. V případě, že všechno půjde hladce, vám potvrdíme pull request a váš kód se stane součástí.
