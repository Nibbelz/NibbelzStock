# Nibbelz Stock

## 1.0.1

- Fixed: characters were saved twice (once with realm "?"). The two records are merged back into one automatically.
- If a part of the addon can't start (overview, minimap button, options, tooltip), the others still load and the error is shown in chat. `/stock` says what went wrong instead of doing nothing.
- Faster: bag scans that change nothing no longer rebuild the lists, item info is looked up once per session, tooltips and the overview reuse what they built.

## 1.0.0

First public release.

- Tracks every item in your bags, reagent bag, bank (incl. reagent bank / bank tabs) and mailbox, for all characters on the account. Bags are read all the time, bank and mail whenever you open them.
- Mail you send to one of your own characters is counted on that character right away, without logging in.
- Item tooltips: how many the account has in total and which character holds how many, optionally split into bags / bank / mail, plus the AH value per item and for the whole stack. Option to show only characters of the current realm.
- Overview window (`/stock`): all items of the account in one list with search, character and place filters, "Materials only", and a minimum amount slider (e.g. only items you have at least 100 of), with a box to type an exact amount. Sortable by name, total, bags, bank, mail, AH price and AH value; the total AH value of everything shown is at the top. Resizable, Shift-click links an item in chat.
- "Sellable only" (on by default): hides items that can't be sold on the AH — soulbound, quest and account-bound items. Those items get no AH value anywhere.
- AH prices from **TradeSkillMaster**, **Auctionator**, **Auctioneer** or **NaowhForever**: Automatic (first addon that knows a price) or one fixed source. The last known price is kept for when the AH addon has none.
- `/stock <name>` opens the overview already searching for that item.
- Shows when bank and mail were last scanned, and reminds you which characters still need to open them once.
- Forget a character's data, rescan on demand.
- Six window styles (Nibbelz, EllesmereUI, Classic, Naowh, Midnight, Dark), minimap button with account total and AH value, addon compartment entry, English and German.
