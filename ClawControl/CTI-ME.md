# Claw Control 0.5.11 alpha — MSI Claw 7 AI+ / WoW Retail

## Aktualizace

1. WoW úplně zavři. Tato aktualizace přidává soubor NativeBars.lua.
2. Rozbal ZIP a nahraď celou složku `ClawControl` v `_retail_/Interface/AddOns/`.
3. Spusť hru. Nastavení otevřeš plovoucím ozubeným kolem, případně stiskem levé páčky L3, pokud ho nemáš obsazený jinak.
4. Je-li profil vypnutý, použij v editoru **Uložit a zapnout**. ConsolePort a jiné addony přebírající stejný ovladač musí být vypnuté.

Dosavadní nastavení pohybu, progrese, letu, schopností a samostatných zadních vstupů se zachovává.

## Oprava dolozene Lua chyby — verze 0.5.11

Screenshot z klientu dolozil RestrictedExecution.lua: Direct table creation is not permitted pri StartBindings/RegisterStateDriver. Pricinou byly tri literalni tabulky v NS.SecureRefresh, kterou WoW kompiluje v omezenem prostredi. Seznamy prefixu, pomocnych klaves a smeru pacek se nove pripravuji mimo zabezpeceny snippet a predavaji jako jednotlive atributy. Ve snippetu jsou pouze ciselne cykly a cteni atributu.

Tato chyba prerusovala take obnoveni ovladani pri zavreni kruhu a potvrzeni Game menu, jeste pred zobrazenim okna. Novy regresni test kontroluje vsech deset zabezpecenych snippetu a testovaci vykonavac vyslovne odmita prime vytvareni tabulek. Po instalaci WoW uplne restartuj a vyzkousej A na Game menu i B pro zavreni. Setup se nemeni. Oprava dolozene konstrukce prosla testy mimo hru; overeni celeho klienta stale zbyva.

## Zavreni B a diagnostika — verze 0.5.10

B reaguje pri stisku i pusteni, aby zruseni nezaviselo jen na udalosti pusteni klavesy. Game menu ma priznak pressAndHoldAction jako akcni tlacitka a podrobne vypisuje fazi zabezpeceneho pozadavku, pokud se okno neotevre. Hodnota no-action znamena, ze zabezpecena akce neprobehla; request/close-ring/show-menu urcuji posledni dosazeny krok; missing-menu a closed-ring urcuji chybejici podminku. Tyto zmeny jsou overene pouze v simulaci. Predchozi verze v realnem WoW menu neotevrela a oprava otevreni stale neni potvrzena.

Pri dalsim selhani zapni /console scriptErrors 1 a posli text Lua chyby i novou zpravu Game menu: faze=... . Nastaveni addonu se zachovava.

## Akcni prijem A pro Game menu — verze 0.5.9

Game menu nove prijima A pres SecureActionButtonTemplate stejne jako funkcni tlacitka schopnosti. Nativni akce typu attribute predava pozadavek zabezpecenemu ramci, ktery zavre kruh a zobrazi menu. Dosavadni SecureHandlerClickTemplate se pro prijem A nepouziva. Testy ted prochazeji skutecnym kodem SecureActionButton_OnClick a nespousteji koncovou sekvenci napriamo. Testovane je opakovane otevreni, vsechny vrstvy a ukonceni pri vstupu do boje. Klient WoW zatim overeny neni.

Pokud vstup dojde, ale menu se neukaze, addon vypise diagnostickou zpravu. V /claw status je nove pocet prijatych potvrzeni Game menu a viditelnost okna. Ulozeny setup se nemeni.

## Oprava potvrzeni Game menu — verze 0.5.8

Game menu reaguje uz na stisk A, ne az na pusteni. U teto polozky se vypina automaticke zavreni po 0.05 s; kruh zavre az zabezpeceny klik. Tato kombinace ve verzi 0.5.7 mohla zrusit prirazeni A drive, nez uzivatel tlacitko pustil, takze se kruh zavrel bez otevreni menu. Pusteni A uz druhou akci nevyvola. U ostatnich polozek kruhu se chovani nemeni.

Novy test simuluje drzeni A po dobu 0.5 s a nasledne potvrzeni zabezpecenym klikem. Overuje, ze se prirazeni neztrati, menu se otevre jen jednou a pusteni je nezavre. Overeni primo ve WoW stale zbyva. Podklad: [Blizzard SecureHandlerClickTemplate](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/SecureHandlerTemplates.xml).

## Game menu z kruhu — verze 0.5.7

Polozka Game menu se potvrzuje tlacitkem A. Nove pouziva samostatne zabezpecene tlacitko, ktere nejdrive zavre kruh a pote zobrazi Blizzard GameMenuFrame. Nepouziva pro tuto polozku obecny Escape, ktery muze pouze zavrit jine okno. D-pad vpravo zustava nativni Escape. Kruh je nadale dostupny mimo boj. Zbytek ulozeneho nastaveni se nemeni.

Test mimo hru overil zabezpecenou sekvenci pro vsechny ctyri kombinace spousti, obnoveni prirazeni a zachovani kurzoru hlavniho menu. Skutecny klient WoW zatim overeny neni. Referencni kod: [Blizzard GameMenuFrame](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_GameMenu/Shared/GameMenuFrame.lua).

## Velikost jednotlivych krizu 0.0 az 1.0 — verze 0.5.6

V Krizove rozlozeni ma kazdy kriz vlastni scale od 0.00 do 1.00 po 0.05. 0.00 jej skryje, 0.50 znamena polovicni a 1.00 plnou velikost. Potvrd Ulozit a pouzit. Ulozene hodnoty 0.50 se nemeni; starsi hodnoty nad 1.00 se omezi na 1.00. Celkovy scale cele sestavy v Zobrazeni a let ma nadale puvodni rozsah a nasobi velikost jednotlivych krizu. Skryti nulou zachova pozici a tlacitka; pro opetovne zobrazeni zvol kladnou velikost a zapni viditelnost. Pokud jsou puvodni bary skryte, ponech alespon jeden kriz viditelny s nenulovou velikosti.

## Skryti tlacitek Presun — verze 0.5.5

Tlacitka Presun 1/2/3/4 a Presun vse jsou vychozim nastavenim skryta. Zobrazis je v ozubenem kole: Krizove rozlozeni > Povolit presouvani krizu > Ulozit a pouzit. Po uprave pozic tuto volbu vypni a opet uloz. Pozice, velikosti a viditelnost krizu zustanou zachovane. Prepinac funguje i pro puvodni radkove zobrazeni.

## M1/M2 pouze BAR 1 — verze 0.5.4

M1 (F9) a M2 (F10) jsou napevno pozice 7 a 8 hlavniho akcniho baru 1. Drzeni RT, LT nebo obou spousti jejich kouzla nemeni. Zmena cisla baru pro vrstvu 1 take nemeni tyto dva sloty. Hlavni bar dale respektuje nativni prepinani stranek, vozidla a formy. Ikony M1/M2 se zobrazuji jen u zakladniho krize; ostatni krize maji A/B/X/Y/RB/LB. Celkem je viditelnych 26 jedinecnych pozic misto 32. Prirazeni klaves, kouzla ani rozmisteni krizu se nemazou.

## Oprava M1/M2 ve verzi 0.5.3

V MSI Center M nastav M1 na samotne F9 a M2 na samotne F10. Verze 0.5.3 pri prvnim nacteni priradi slot 7 na F9 a slot 8 na F10 i v existujicim profilu. Dalsi zmeny uz zachova. Vyjimka: pokud F9 nebo F10 uz pouziva slot 1–6, aktualizace tyto volby neprepise; v editoru Schopnosti vyres konflikt a nastav sloty 7/8 rucne. Vsechny ctyri vrstvy pouzivaji stejne vstupy, spouste pouze meni bar. Predni View/Menu zustavaji mapa a kruhovy volic. Zkontroluj, ze jsou na vsech pouzivanych barech obsazene pozice 7 a 8. Ostatni ovladani a upravene rozlozeni se zachovaji.

Testy mimo hru overily F9/F10 na slotech 7/8 ve vsech ctyrech vrstvach, s modifikatory i bez nich. Skutecne vysilani klaves z MSI Center M zatim overene neni.

## Novinky 0.5.2

- Levá páčka nově ovládá pohled nahoru/dolů i při chůzi. Vypneš jej v **Zobrazení a let → Pohled nahoru/dolů i při chůzi**. Při ovládání kurzoru a otevřeném kruhovém voliči se kamera nehýbe. Citlivost upravíš v **Pohyb a otáčení → Citlivost svislého pohledu / letu**.
- Na nové páté záložce **Křížové rozložení** zvolíš pro každý kříž viditelnost a velikost 50–150 %. Čísla křížů odpovídají vrstvám 1–4. Skrytí kříže nemění jeho tlačítka ani kouzla. Změny potvrď **Uložit a použít**.
- Každý kříž přetáhneš samostatně za **Přesun 1–4**: drž levé tlačítko myši nebo odpovídající klik ovladače a táhni. Pozice se ukládá po puštění. **Přesun vše** posune celou sestavu včetně samostatně upravených křížů. Přesouvání je dostupné mimo boj.
- Celou sestavu zmenšíš v **Zobrazení a let → Velikost přehledu**, například `0.7` znamená 70 %. Nový rozsah je 0.35–1.8. Velikost jednotlivého kříže se násobí velikostí celé sestavy. Dosavadní velikost se automaticky nepřepisuje.
- **Obnovit výchozí pozice křížů** připraví původní rozmístění. Ulož jej pro potvrzení; samostatné velikosti a viditelnost tím nezměníš.
- Kompaktní kříže podle náčrtu používají ikony 36 px: Y nad A bez prázdného středu, X/B po stranách, LB/RB šikmo nahoře a M1/M2 šikmo dole. Nejmenší mezery jsou 2 px. Popisky jsou uvnitř ikon. Rozměry se násobí zvolenou velikostí.

## Přední tlačítka

- **Levé View / Back:** mapa světa.
- **Pravé Menu / Start:** osmipoložkový kruhový volič.

Přední tlačítka mají v editoru samostatné řádky na záložce **D-pad a stisky**. Nejde o D-pad vlevo/vpravo ani o zadní M1/M2.

**M1/M2 musí vysílat jiné vstupy než přední View/Menu.** Pokud tvé existující nastavení už používá samostatné klávesy nebo paddles, aktualizace je zachová. Pokud starší profil ještě používá PADBACK/PADFORWARD pro schopnosti, tyto konfliktní pozice se označí jako nepřiřazené; v editoru vyber skutečné zadní vstupy. Od verze 0.5.3 jsou výchozí vstupy M1 = F9 a M2 = F10 podle nastavení tohoto zařízení. Addon firmware sám nemění.

## Kruhový volič

Otevři ho pravým předním tlačítkem Menu. Pravou páčkou zvol položku a **A potvrď**. **B nebo opětovné Menu volič zavře.** Po vrácení páčky do středu se zachová poslední výběr. Kurzorem/dotykem lze také označit položku; potvrzení se provádí tlačítkem A.

Položky po směru hodinových ručiček odshora:

1. Postava
2. Profese
3. Tašky
4. Kniha kouzel
5. Herní menu
6. Chat
7. Úkoly a mapa
8. Talenty

Volič je v této verzi **dostupný mimo boj**. Při začátku boje se automaticky zavře a obnoví běžné přiřazení. Vlastní schopnosti se během otevřeného voliče blokují a A vyvolává vybraný nativní herní příkaz. Addon přímo nevolá chráněná okna Blizzardu. Dostupnost jednotlivých panelů dál řídí WoW (např. talenty postavy dané úrovně).

## Nové zobrazení schopností

Verze 0.5.1 při prvním spuštění zapne křížový přehled a skryje osm původních akčních barů WoW. Kouzla a jejich přiřazení zůstávají zachovaná. V editoru **Zobrazení a let → Skrýt původní akční bary WoW (1–8)** můžeš skrytí vypnout a uložit, například pro přesouvání kouzel. Po vypnutí profilu se bary vrátí pod původní nadřazené rámy. Změny prováděj mimo boj. Speciální ovládání vozidel, mazlíčků a úkolových schopností se tímto přepínačem neskrývá; bary jiných addonů tento přepínač neovládá.

Původní řádek nahrazují čtyři skupiny:

- **Základ:** nahoře uprostřed.
- **LT:** vlevo.
- **RT:** vpravo.
- **LT + RT:** dole uprostřed.

Každá skupina má **A/B/X/Y do kříže**, dále **LB, RB, M1 a M2**. Zobrazují se všechny čtyři vrstvy a všech 32 ikon; aktivní vrstva je zvýrazněná. Při prohození spouští se jejich popisky odpovídajícím způsobem změní. Cooldowny používají nativní kruh a číselný odpočet WoW.

Přehled přesuň tažením za **Přesun vše**, jednotlivé skupiny za **Přesun 1–4**. Prázdné plochy mezi ikonami neblokují klikání do herního světa. Typ rozložení upravíš v editoru **Zobrazení a let → Rozložení schopností**. Původní jeden řádek zůstává jako volitelná varianta; nastavení jednotlivých křížů se uplatní po návratu ke skupinám.

## Výchozí zbytek layoutu

- Pravá páčka: pohyb dopředu/dozadu a úkroky, stisk: skok.
- Levá páčka: otáčení postavy, nahoru/dolů řízení letu. Stisk otevírá editor, pokud byl dříve bez funkce.
- RT: vrstva 2; LT: vrstva 3; obě spouště: vrstva 4.
- A, B, X, Y, RB, LB, M1, M2: sloty 1–8.
- D-pad nahoru: další nepřítel; vlevo: interakce; vpravo: Escape/menu; dolů: hlavní batoh.
- Otáčení: maximum 1.5, exponent 2. Poloviční vychýlení po mrtvé zóně dává výslednou odezvu 0.375. Nejde o rychlost ve stupních za sekundu.
- Skyriding: nativní svislé analogové řízení na mountovi, citlivost 0.75. Při chůzi je nově zapnutý svislý pohled; při ovládání kurzoru zůstává vypnutý. Vzlet/letové schopnosti ovládej příslušnou schopností, ne pouhým vychýlením páčky na zemi.

## Editor a obnova

Pět záložek editoru upravuje akční vstupy/bary, pomocné ovladače, pohyb/otáčení, zobrazení/let a samostatné kříže. Změny se projeví až po **Uložit a použít**. **Výchozí layout** připraví návrh, který ještě musíš uložit. Ukládání je možné mimo boj. Tažení přehledu a křížů ukládá pozice ihned při puštění.

Příkazy pro diagnostiku: `/claw`, `/claw on`, `/claw off`, `/claw status`, `/claw test`, `/claw speed 1.5`, `/claw cursor`.

Před odebráním addonu použij `/claw off`, aby se obnovila záloha původních proměnných a konfigurace ovladače. Trvalé klávesové zkratky se nepřepisují pomocí SaveBindings. Nastavení je společné pro postavy účtu a ukládá se do SavedVariables/ClawControl.lua.

## Ověření a meze

Syntaxe devíti Lua souborů a 37 integračních scénářů prošly mimo hru. Pokrývají editor, vstupy, kruhový volič, cooldowny, skrytí a obnovení barů, svislý pohled při chůzi, samostatné velikosti a viditelnost křížů, ukládání pozic při různých velikostech a kompaktní rozestupy. Testy provádějí akční cesty přes skutečný veřejný kód SecureActionButton se simulovaným herním enginem.

**Přímo v klientu WoW a na MSI Clawu tato verze ověřena není.** Zejména je nutné potvrdit zachytávání páček při otevřeném kruhu, skutečné otevírání panelů přes A, chování při přechodu do boje a čitelnost nového přehledu. Přiložený samostatný PNG návrh používá zástupné číslované dlaždice; nejde o screenshot fungující hry. Skutečné ikony a cooldowny se načtou až z klientu.

Grafika kruhu je nově vytvořená geometrická textura. Addon nepřibaluje kód ani grafiku ConsolePortu; odkazy na ikony používají prostředky samotného WoW. Referenční obrázky byly použity pouze jako vizuální zadání.

Podklady: [nativní příkazy WoW](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_FrameXML/Bindings_Standard.xml), [chráněná přiřazení](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/RestrictedFrames.lua), [ConsolePort](https://github.com/seblindfors/ConsolePort).









