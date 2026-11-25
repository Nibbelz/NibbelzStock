-- Locale.lua: English keys, German texts on a German client.
local _, ns = ...

local DE = {
    -- Places
    ["Bags"] = "Taschen",
    ["Bank"] = "Bank",
    ["Mail"] = "Post",
    ["All places"] = "Alle Orte",
    ["All characters"] = "Alle Charaktere",

    -- Overview
    ["Overview"] = "Übersicht",
    ["Search item"] = "Item suchen",
    ["Minimum amount"] = "Mindestmenge",
    ["at least %s"] = "mindestens %s",
    ["any amount"] = "jede Menge",
    ["Materials only"] = "Nur Materialien",
    ["Sellable only"] = "Nur verkaufbare",
    ["Hides soulbound, quest and account-bound items."] = "Blendet seelengebundene, Quest- und accountgebundene Items aus.",
    ["Item"] = "Item",
    ["Total"] = "Gesamt",
    ["AH each"] = "AH Stück",
    ["AH value"] = "AH-Wert",
    ["%d items shown"] = "%d Items angezeigt",
    ["1 item shown"] = "1 Item angezeigt",
    ["Value: %s"] = "Wert: %s",
    ["No items match."] = "Keine Items passen.",
    ["Bank never scanned - open the bank once on this character."] = "Bank nie gescannt - öffne einmal die Bank mit diesem Charakter.",
    ["Mail never scanned - open the mailbox once on this character."] = "Post nie gescannt - öffne einmal den Briefkasten mit diesem Charakter.",
    ["Bank: %s"] = "Bank: %s",
    ["Mail: %s"] = "Post: %s",
    ["never"] = "nie",
    ["just now"] = "gerade eben",
    ["%d min ago"] = "vor %d Min.",
    ["%d h ago"] = "vor %d Std.",
    ["%d days ago"] = "vor %d Tagen",
    ["%d characters"] = "%d Charaktere",
    ["1 character"] = "1 Charakter",
    ["Shift-click: link in chat"] = "Shift-Klick: Link in den Chat",
    ["no AH source"] = "keine AH-Quelle",

    -- Tooltip
    ["Account"] = "Account",
    ["AH: %s each, %s total"] = "AH: %s pro Stück, %s gesamt",

    -- Minimap / compartment
    ["Items on the account"] = "Items auf dem Account",
    ["AH value of everything"] = "AH-Wert von allem",
    ["Left-click: overview"] = "Linksklick: Übersicht",
    ["Right-click: options"] = "Rechtsklick: Optionen",
    ["Drag: move the button"] = "Ziehen: Button verschieben",
    ["Minimap button: %s"] = "Minimap-Button: %s",
    ["on"] = "an",
    ["off"] = "aus",

    -- Options
    ["Options"] = "Optionen",
    ["TOOLTIP"] = "TOOLTIP",
    ["DISPLAY"] = "ANZEIGE",
    ["CHARACTERS"] = "CHARAKTERE",
    ["Show the counts in item tooltips"] = "Mengen im Item-Tooltip anzeigen",
    ["Split by bags / bank / mail"] = "Nach Taschen / Bank / Post aufteilen",
    ["Show the AH value"] = "AH-Wert anzeigen",
    ["Only characters of this realm"] = "Nur Charaktere dieses Realms",
    ["Window size"] = "Fenstergröße",
    ["Show minimap button"] = "Minimap-Button anzeigen",
    ["AH prices: "] = "AH-Preise: ",
    ["Automatic"] = "Automatisch",
    ["not installed"] = "nicht installiert",
    ["Style: "] = "Stil: ",
    ["Nibbelz"] = "Nibbelz",
    ["EllesmereUI"] = "EllesmereUI",
    ["Classic"] = "Klassisch",
    ["Naowh"] = "Naowh",
    ["Midnight"] = "Midnight",
    ["Dark"] = "Dunkel",
    ["The new window style is used after a UI reload. Reload now?"] = "Der neue Fensterstil wird nach einem UI-Reload benutzt. Jetzt neu laden?",
    ["Reload now"] = "Jetzt neu laden",
    ["Later"] = "Später",
    ["Type /reload after combat to use the new style."] = "Tippe nach dem Kampf /reload, um den neuen Stil zu nutzen.",
    ["Forget a character..."] = "Charakter vergessen...",
    ["Forget all data of %s?"] = "Alle Daten von %s vergessen?",
    ["Open overview"] = "Übersicht öffnen",
    ["Rescan now"] = "Jetzt neu scannen",
    ["Bank and mail are read when you open them. Mail you send to your own characters is counted right away."] = "Bank und Post werden gelesen, wenn du sie öffnest. Post an deine eigenen Charaktere zählt sofort mit.",
    ["Settings are in their own window."] = "Die Einstellungen haben ein eigenes Fenster.",
    ["Open options"] = "Optionen öffnen",

    -- Chat
    ["Commands:"] = "Befehle:",
    ["/stock - overview"] = "/stock - Übersicht",
    ["/stock <name> - overview searching for <name>"] = "/stock <Name> - Übersicht mit Suche nach <Name>",
    ["/stock options - options"] = "/stock options - Optionen",
    ["/stock minimap - minimap button on / off"] = "/stock minimap - Minimap-Button an / aus",
    ["%s forgotten."] = "%s vergessen.",
    ["Bags scanned."] = "Taschen gescannt.",
    ["Could not start the %s: %s"] = "Konnte %s nicht starten: %s",
    ["Not started yet - saved data not loaded."] = "Noch nicht gestartet - gespeicherte Daten nicht geladen.",
}

local strings = (GetLocale() == "deDE") and DE or {}
ns.L = setmetatable(strings, { __index = function(_, key) return key end })
ns.IS_DE = GetLocale() == "deDE"
