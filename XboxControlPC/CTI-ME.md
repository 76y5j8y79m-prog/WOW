# Xbox Control PC 1.0.0 alpha — WoW Retail

Samostatná varianta pro standardní Xbox ovladač bez zadních tlačítek. Vychází z ClawControl 0.5.11, kterou uživatel ověřil ve hře. Xbox varianta prošla testy mimo hru; na konkrétním PC a Xbox ovladači ještě ověřená není.

## Instalace

1. Úplně zavři WoW.
2. Rozbal ZIP a složku XboxControlPC vlož do World of Warcraft/_retail_/Interface/AddOns/.
3. V seznamu addonů zapni Xbox Control PC. ClawControl, ConsolePort a další addony přebírající ovladač vypni.
4. Připoj Xbox ovladač a spusť hru. Ozubené kolo otevře editor. Použij Uložit a zapnout.

Nastavení se ukládá do XboxControlPCDB, odděleně od ClawControlDB. Existující konfigurace MSI Claw se neimportuje ani nemění. Složky obou addonů mohou být nainstalované, současně zapínej pouze jednu variantu.

## Ovládání

| Vstup | Funkce |
|---|---|
| Pravá páčka | Pohyb dopředu/dozadu a úkroky |
| Stisk pravé páčky | Skok |
| Levá páčka vlevo/vpravo | Otáčení postavy |
| Levá páčka nahoru/dolů | Svislý pohled při chůzi, řízení Skyridingu na mountovi |
| Stisk levé páčky | Nastavení addonu |
| A / B / X / Y / RB / LB | Pozice 1 / 2 / 3 / 4 / 5 / 6 |
| Bez spouště | BAR 1 |
| Držené RT | BAR 2 |
| Držené LT | BAR 3 |
| Držené RT + LT | BAR 4 |
| D-pad nahoru | Další nepřítel |
| D-pad vlevo | Interakce |
| D-pad vpravo | Escape / herní menu |
| D-pad dolů | Batoh |
| View / Back | Mapa |
| Menu / Start | Kruhový výběr |

Zachovává původně domluvené rozdělení páček. V editoru Pohyb a otáčení je lze prohodit. Všechny čtyři vrstvy mají šest schopností, celkem 24. Zadní tlačítka, paddles ani F9/F10 se nepoužívají.

## Kruh a kříže

V kruhu vybírá pravá páčka, A potvrzuje, B nebo opětovné Menu zavírá. Kruh je dostupný mimo boj. Game menu používá zabezpečené potvrzení z opravené verze 0.5.11. Zakázané vytváření tabulek ve všech zabezpečených úsecích je odstraněné.

Čtyři kříže mají A/B/X/Y a postranní RB/LB, nativní ikony a cooldowny. Velikost jednotlivých křížů nastavíš na záložce Křížové rozložení v rozsahu 0.00–1.00, krok 0.05; nula kříž skryje. Zde nastavíš i jejich viditelnost a zapneš Povolit přesouvání křížů. Přesun 1–4 posouvá jednotlivé kříže, Přesun vše celou sestavu. Po vypnutí přesouvání tlačítka zmizí. Pozice se při tažení ukládají po puštění, ostatní změny potvrď Uložit a použít.

Původní akční bary 1–8 se při aktivním profilu standardně skryjí. Pro přesouvání kouzel vypni jejich skrytí v Zobrazení a let. Na každém používaném baru obsazuj první šest pozic. Speciální ovládání vozidel, úkolů a mazlíčků se neskrývá.

## Diagnostika a vypnutí

/xboxcontrol otevře editor, /xboxcontrol status zobrazí stav, /xboxcontrol test test vstupů, /xboxcontrol off obnoví předchozí konfiguraci. Ozubené kolo funguje i bez klávesnice. Změny a přepínání profilu prováděj mimo boj. Před odebráním nebo přechodem na druhou variantu profil vypni, aby se obnovila původní konfigurace ovladače a CVars.
