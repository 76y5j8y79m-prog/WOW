# Ověření

ClawControl 0.5.11: uživatel dne 5. 11. 2026 potvrdil „už vše funguje jak má“. Předtím byla opravena doložená chyba RestrictedExecution: Direct table creation is not permitted. Všechny zabezpečené úseky nyní používají seznamy předané v atributech mimo omezené prostředí.

Xbox Control PC 1.0.1: prošla syntaxe všech devíti Lua souborů a kontroly všech zabezpečených úseků bez přímého vytváření tabulek. Simulovaný test používá skutečný veřejný kód SecureActionButton pro všech 24 akčních cest. Ověřuje samostatné názvy a nastavení, absenci slotů 7/8 a vazeb F9/F10, mapu a kruh, potvrzení Game menu, zavření B, šest ikon na každém kříži, řádkové zobrazení, skrytí nulovým scale, odemykání přesunu, svislý pohled při chůzi a odmítnutí aktivace se zapnutým ClawControl. Test v reálném klientu na standardním Xbox ovladači zatím neproběhl.

Oba instalační ZIPy prošly kontrolou integrity a názvů složek. Kontrolní součty jsou v SHA256SUMS.txt. Nejsou přiložena žádná osobní SavedVariables ani jiné soubory uživatele.

Doplněný test rozpoznání zařízení simuluje ovladač dostupný až po třech intervalech od GamePadEnable=1, neplatné první zařízení, staré uložené ID, zachování původní zálohy CVar, ruční zrušení hledání, vypršení limitu, pozastavení v boji a obnovení po reloadu. Tyto kontroly prošly mimo klienta WoW.
