# WoW controller addons

Dvě samostatné varianty pro **World of Warcraft Retail**. Každý ZIP obsahuje vlastní složku addonu včetně editovatelných zdrojů Lua a grafiky.

| Varianta | Zařízení | Schopnosti | ZIP |
|---|---|---|---|
| ClawControl 0.5.11 alpha | MSI Claw 7 AI+ | A/B/X/Y/RB/LB na 4 vrstvách + M1/F9 a M2/F10 napevno na pozicích 7/8 v BAR 1 | [Stáhnout ClawControl](dist/ClawControl-0.5.11-alpha.zip?raw=true) |
| Xbox Control PC 1.0.1 alpha | Standardní Xbox ovladač na PC | A/B/X/Y/RB/LB na 4 vrstvách = 24 pozic | [Stáhnout Xbox Control PC](dist/XboxControlPC-1.0.1-alpha.zip?raw=true) |

## Instalace

Úplně zavři WoW. Rozbal vybraný ZIP a jeho složku `ClawControl` nebo `XboxControlPC` vlož do `_retail_/Interface/AddOns/`. Při instalaci ze zdrojů tohoto repozitáře použij přímo příslušnou složku. Oba addony mohou být nainstalované, ale **zapni vždy jen jeden**. ConsolePort a jiné addony přebírající stejný ovladač vypni. Ve hře otevři ozubené kolo a aktivuj profil.

Každá varianta má vlastní názvy rámců, uložené nastavení a příkaz: `/claw` versus `/xboxcontrol`. Xbox varianta původní setup Clawu nemění. Před přechodem na jinou variantu nejprve profil vypni v editoru.

## Společné ovládání

- Pravá páčka: pohyb a úkroky; stisk: skok.
- Levá páčka: otáčení a pohled nahoru/dolů, včetně Skyridingu; stisk: editor.
- Rozdělení páček lze v editoru prohodit.
- A/B/X/Y/RB/LB: pozice 1–6. RT, LT a obě spouště volí další vrstvy.
- View/Back: mapa. Menu/Start: kruhový výběr; pravá páčka vybírá, A potvrzuje, B/Menu zavírá. Kruh je mimo boj.
- D-pad: nahoru další nepřítel, vlevo interakce, vpravo Escape, dolů batoh.
- Kompaktní kříže s cooldowny lze samostatně posouvat, zmenšit nebo skrýt. Tlačítka Přesun se zobrazí až po odemčení v editoru.

## Návody a ověření

- [ClawControl – podrobný návod](ClawControl/CTI-ME.md)
- [Xbox Control PC – podrobný návod](XboxControlPC/CTI-ME.md)
- [Výsledky ověření](VALIDACE.md)

ClawControl 0.5.11 uživatel potvrdil jako funkční ve hře. Xbox varianta prošla simulovanými integračními kontrolami, ale na konkrétním PC/Xbox ovladači ještě ověřená není. Repozitář obsahuje původní kód addonu a vytvořené textury kruhu; neobsahuje zdrojový kód ani grafiku ConsolePortu. Herní ikony a cooldowny poskytuje klient WoW.

PC verze 1.0.1 po zapnutí podpory gamepadu vyhledává zařízení opakovaně až osm sekund; starý nebo nefunkční první vstup nepřekryje další připojený ovladač.
