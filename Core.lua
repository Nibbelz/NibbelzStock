-- Core.lua: saved data (one record per character), item info, auction house prices,
-- the account-wide index of who holds what, events and slash commands.
local ADDON, ns = ...
_G.NibbelzStock = ns
local L = ns.L

local format, floor = string.format, math.floor
local sort, wipe, concat = table.sort, wipe, table.concat
local time = time

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant

ns.PLACES = { "bags", "bank", "mail" }

-------------------------------------------------------------------------------
--  Helpers
-------------------------------------------------------------------------------
local isSecret = issecretvalue or function() return false end

-- A value we may read: not a secret (12.x restricted value) and of the wanted type.
local function Plain(v, kind)
    if v == nil or isSecret(v) then return nil end
    if kind and type(v) ~= kind then return nil end
    return v
end
ns.Plain = Plain

function ns.Print(msg)
    print("|cff0cd29fNibbelz Stock|r " .. tostring(msg))
end

function ns.ClassColor(class)
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if c then return c.r, c.g, c.b end
    return 0.85, 0.85, 0.85
end

function ns.Hex(r, g, b)
    return format("|cff%02x%02x%02x", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
end

function ns.QualityColor(q)
    local c = q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

-- 12345 -> "12,345" (the game's own grouping).
function ns.Num(n)
    n = floor(n or 0)
    return BreakUpLargeNumbers and BreakUpLargeNumbers(n) or tostring(n)
end

-- Money as coins: 12g 34s 5c with the game's coin icons.
local GOLD = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
local SILVER = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
local COPPER = "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
local moneyParts = {}
function ns.Money(copper)
    copper = floor(copper or 0)
    if copper <= 0 then return "0" .. COPPER end
    local g, s, c = floor(copper / 10000), floor(copper / 100) % 100, copper % 100
    local n = 0
    if g > 0 then n = n + 1; moneyParts[n] = ns.Num(g) .. GOLD end
    if s > 0 and g < 1000 then n = n + 1; moneyParts[n] = s .. SILVER end
    if c > 0 and g < 100 then n = n + 1; moneyParts[n] = c .. COPPER end
    return concat(moneyParts, " ", 1, n)
end

-- "just now", "5 min ago", "3 h ago", "2 days ago", "never"
function ns.Ago(t)
    if not t then return L["never"] end
    local d = time() - t
    if d < 60 then return L["just now"] end
    if d < 3600 then return format(L["%d min ago"], floor(d / 60)) end
    if d < 86400 then return format(L["%d h ago"], floor(d / 3600)) end
    return format(L["%d days ago"], floor(d / 86400))
end

-------------------------------------------------------------------------------
--  Character names. WoW Forever characters have a surname: UnitName() gives the
--  first name and the surname apart. We keep the one full spelling.
-------------------------------------------------------------------------------
local IS_FOREVER = (function()
    local v = select(4, GetBuildInfo())
    return type(v) == "number" and v >= 16000 and v < 20000
end)()
local SEP = (Constants and Constants.CharacterNameSeparatorConsts
    and Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR) or " "

-- Name, realm and key don't change during a session: worked out once, as soon
-- as the game knows them.
local myName, myRealm, myKey

function ns.MyName()
    if myName then return myName end
    local first, second = (UnitNameUnmodified or UnitName)("player")
    first, second = Plain(first, "string"), Plain(second, "string")
    if not first or first == "" or first == UNKNOWNOBJECT then return UnitName("player") end
    myName = (IS_FOREVER and second and second ~= "") and (first .. SEP .. second) or first
    return myName
end

-- WoW Forever gives an empty realm name: then "" (that's how the data has
-- always been saved, so the keys stay the same).
function ns.MyRealm()
    if myRealm then return myRealm end
    local realm = (GetRealmName and GetRealmName()) or ""
    if realm == "" and GetNormalizedRealmName then realm = GetNormalizedRealmName() or "" end
    if realm ~= "" then myRealm = realm end
    return realm
end

function ns.MyKey()
    if myKey then return myKey end
    local name, realm = ns.MyName(), ns.MyRealm()
    if myName and IsLoggedIn and IsLoggedIn() then myKey = name .. " - " .. realm end
    return name .. " - " .. realm
end

-- A character's name coloured by class, the realm added when it is not ours.
function ns.CharLabel(c, withRealm)
    local text = ns.Hex(ns.ClassColor(c.class)) .. (c.name or "?") .. "|r"
    if withRealm ~= false and c.realm and c.realm ~= ns.MyRealm() then
        text = text .. " |cff777777(" .. c.realm .. ")|r"
    end
    return text
end

-------------------------------------------------------------------------------
--  Change notification (the windows listen)
-------------------------------------------------------------------------------
local listeners = {}
function ns.Listen(fn) listeners[#listeners + 1] = fn end

local debounced = {}
function ns.Debounce(key, delay, fn)
    if debounced[key] then return end
    debounced[key] = true
    C_Timer.After(delay, function()
        debounced[key] = nil
        fn()
    end)
end

local notifyQueued = false
function ns.Notify()
    if notifyQueued then return end
    notifyQueued = true
    C_Timer.After(0, function()
        notifyQueued = false
        for i = 1, #listeners do listeners[i]() end
    end)
end

-------------------------------------------------------------------------------
--  Saved data
--    chars[key] = { name, realm, class, faction, last, money,
--                   bags = { [itemID] = count }, bank = {...}, mail = {...},
--                   bagsT, bankT, mailT (time of the last scan) }
--    info[itemID] = { n = name, q = quality, i = icon, c = classID, bt = bind type,
--                     b = seen soulbound, u = seen not soulbound }
--    prices[itemID] = { p = copper, t = time } (the last AH price seen)
-------------------------------------------------------------------------------
local DB

local DEFAULTS = {
    scale = 1,
    minimapAngle = 215,
    minimapHide = false,
    theme = "nibbelz",
    ahSource = "auto",
    tooltip = true,           -- counts in item tooltips
    tooltipPlaces = true,     -- split by bags / bank / mail
    tooltipAH = true,         -- AH value in the tooltip
    realmOnly = false,        -- tooltip: only characters of this realm
    minCount = 0,             -- overview: minimum amount
    matsOnly = false,         -- overview: trade goods / reagents / gems only
    sellableOnly = true,      -- overview: hide items that can't go on the AH
    filterChar = "all",       -- overview: "all" or a character key
    filterPlace = "all",      -- overview: "all", "bags", "bank", "mail"
    sortKey = "total",
    sortDesc = true,
}

local function InitDB()
    NibbelzStockDB = NibbelzStockDB or {}
    DB = NibbelzStockDB
    DB.chars = DB.chars or {}
    DB.info = DB.info or {}
    DB.prices = DB.prices or {}
    DB.pos = DB.pos or {}
    DB.opts = DB.opts or {}
    for k, v in pairs(DEFAULTS) do
        if DB.opts[k] == nil then DB.opts[k] = v end
    end
    ns.db = DB
end

-- 1.0.0 briefly saved an empty realm as "?", which split a character into two
-- records ("Name - ?" and "Name - "). Put them back together: the newer scan
-- of each place wins.
local function FixRealmKeys()
    local chars = DB.chars
    local moved = {}
    for key, c in pairs(chars) do
        if c.realm == "?" or key:sub(-4) == " - ?" then moved[#moved + 1] = key end
    end
    for _, key in ipairs(moved) do
        local c = chars[key]
        chars[key] = nil
        c.realm = ""
        local newKey = key:gsub(" %- %?$", " - ")
        local old = chars[newKey]
        if old then
            for _, place in ipairs(ns.PLACES) do
                local t = place .. "T"
                if (c[t] or 0) < (old[t] or 0) then c[place], c[t] = old[place], old[t] end
            end
            if (c.last or 0) < (old.last or 0) then c.money = old.money end
            c.last = math.max(c.last or 0, old.last or 0)
        end
        chars[newKey] = c
        if DB.opts.filterChar == key then DB.opts.filterChar = newKey end
    end
end

-- The record of the character we are playing (made on first login).
function ns.Me()
    local key = ns.MyKey()
    local c = DB.chars[key]
    if not c then
        c = { bags = {}, bank = {}, mail = {} }
        DB.chars[key] = c
    end
    c.name, c.realm = ns.MyName(), ns.MyRealm()
    c.class = select(2, UnitClass("player"))
    c.faction = UnitFactionGroup("player")
    c.last = time()
    c.money = GetMoney()
    return c, key
end

-- Characters sorted: this realm first, then by name.
function ns.SortedChars()
    local list, realm = {}, ns.MyRealm()
    for key, c in pairs(DB.chars) do list[#list + 1] = { key = key, c = c } end
    sort(list, function(a, b)
        local ra, rb = a.c.realm == realm, b.c.realm == realm
        if ra ~= rb then return ra end
        if (a.c.realm or "") ~= (b.c.realm or "") then return (a.c.realm or "") < (b.c.realm or "") end
        return (a.c.name or "") < (b.c.name or "")
    end)
    return list
end

function ns.ForgetChar(key)
    local c = DB.chars[key]
    if not c then return end
    DB.chars[key] = nil
    if DB.opts.filterChar == key then DB.opts.filterChar = "all" end
    ns.MarkDirty()
    ns.Print(format(L["%s forgotten."], ns.CharLabel(c)))
end

-------------------------------------------------------------------------------
--  Item info: saved when an item is scanned, so the overview can name items
--  the game has not loaded this session.
-------------------------------------------------------------------------------
-- Items whose full info (GetItemInfo) we already have this session. Item data
-- never changes, so each item is asked only once.
local complete = {}

-- bound: true = this stack is soulbound, false = it is not, nil = unknown (mail).
-- Called for every slot on every scan, so it does as little as it can.
function ns.Remember(id, link, quality, icon, name, bound)
    local info = DB.info[id]
    if not info then
        info = {}
        DB.info[id] = info
    end
    if bound == true then info.b = true elseif bound == false then info.u = true end
    if complete[id] then return end
    if not info.n then
        if not name and type(link) == "string" then name = link:match("%[(.-)%]") end
        if name and name ~= "" then info.n = name end
    end
    if quality then info.q = quality end
    if icon then info.i = icon end
    if not info.c then
        local _, _, _, _, tex, classID = GetItemInfoInstant(id)
        info.c = classID
        info.i = info.i or tex
    end
end

-- name, quality, icon, classID
function ns.Info(id)
    local info = DB.info[id]
    if not complete[id] then
        local name, _, quality, _, _, _, _, _, _, icon, _, classID, _, bindType = GetItemInfo(id)
        if name then
            if not info then
                info = {}
                DB.info[id] = info
            end
            info.n, info.q, info.i, info.c, info.bt = name, quality, icon, classID, bindType
            complete[id] = true
        end
    end
    if not info then return "item:" .. id, nil, 134400, nil end
    return info.n or ("item:" .. id), info.q, info.i or 134400, info.c
end

function ns.ItemLink(id)
    local _, link = GetItemInfo(id)
    return link
end

-- Trade goods, reagents, gems and item enhancements count as materials.
local MAT_CLASSES = {
    [(Enum and Enum.ItemClass and Enum.ItemClass.Tradegoods) or 7] = true,
    [(Enum and Enum.ItemClass and Enum.ItemClass.Reagent) or 5] = true,
    [(Enum and Enum.ItemClass and Enum.ItemClass.Gem) or 3] = true,
    [(Enum and Enum.ItemClass and Enum.ItemClass.ItemEnhancement) or 8] = true,
}
function ns.IsMat(id)
    local _, _, _, classID = ns.Info(id)
    return classID and MAT_CLASSES[classID] or false
end

-- Can it go on the auction house? Not: bind on pickup, quest items, account-bound
-- items, and items we have only ever seen soulbound (equipped BoE gear and the like).
local IB = (Enum and Enum.ItemBind) or {}
local BOUND_TYPES = {
    [IB.OnAcquire or 1] = true,
    [IB.Quest or 4] = true,
    [IB.ToWoWAccount or 7] = true,
    [IB.ToBnetAccount or 8] = true,
}
local QUEST_CLASS = (Enum and Enum.ItemClass and Enum.ItemClass.Questitem) or 12
function ns.CanSell(id)
    local _, _, _, classID = ns.Info(id)
    if classID == QUEST_CLASS then return false end
    local info = DB.info[id]
    if not info then return true end
    if info.bt and BOUND_TYPES[info.bt] then return false end
    if info.b and not info.u then return false end
    return true
end

-------------------------------------------------------------------------------
--  Auction house prices. Each source: available() and price(itemID, link) -> copper.
--  "auto" asks them in this order and takes the first price found.
-------------------------------------------------------------------------------
local function Num(ok, v)
    if ok and type(v) == "number" and v > 0 then return floor(v) end
end
ns.AH_SOURCES = {
    {   -- NaowhForever: its own scans or the prices shipped in NaowhForever_AuctionData
        key = "naowh", label = "NaowhForever",
        available = function() return _G.NaowhForever and type(NaowhForever.AuctionPrice) == "function" end,
        price = function(id) return Num(pcall(NaowhForever.AuctionPrice, id)) end,
    },
    {   -- TradeSkillMaster: AuctionDB market value, else min buyout
        key = "tsm", label = "TradeSkillMaster",
        available = function() return _G.TSM_API and type(TSM_API.GetCustomPriceValue) == "function" end,
        price = function(id)
            local item = "i:" .. id
            return Num(pcall(TSM_API.GetCustomPriceValue, "dbmarket", item))
                or Num(pcall(TSM_API.GetCustomPriceValue, "dbminbuyout", item))
        end,
    },
    {   -- Auctionator: last scanned price
        key = "auctionator", label = "Auctionator",
        available = function()
            local api = _G.Auctionator and Auctionator.API and Auctionator.API.v1
            return api and type(api.GetAuctionPriceByItemID) == "function"
        end,
        price = function(id)
            return Num(pcall(Auctionator.API.v1.GetAuctionPriceByItemID, "NibbelzStock", id))
        end,
    },
    {   -- Auctioneer: market value
        key = "auctioneer", label = "Auctioneer",
        available = function()
            return _G.AucAdvanced and AucAdvanced.API and type(AucAdvanced.API.GetMarketValue) == "function"
        end,
        price = function(id)
            local link = ns.ItemLink(id)
            if not link then return nil end
            return Num(pcall(AucAdvanced.API.GetMarketValue, link))
        end,
    },
}

function ns.HasAH()
    for _, src in ipairs(ns.AH_SOURCES) do
        if src.available() then return true end
    end
    return false
end

-- Asked once per item per session (false = no price); ns.ResetPrices() asks again.
local memo = {}
function ns.ResetPrices()
    wipe(memo)
    ns.Notify()   -- the tooltip lines hold prices too
end

function ns.Price(id)
    if not ns.CanSell(id) then return nil end
    local p = memo[id]
    if p ~= nil then return p or nil end
    local want = DB.opts.ahSource or "auto"
    for _, src in ipairs(ns.AH_SOURCES) do
        if (want == "auto" or want == src.key) and src.available() then
            p = src.price(id)
            if p then break end
        end
    end
    if p then
        DB.prices[id] = { p = p, t = time() }
    else
        -- No source knows it right now: the last price we saw, if any.
        local last = DB.prices[id]
        p = last and last.p
    end
    memo[id] = p or false
    return p
end

-------------------------------------------------------------------------------
--  The index: itemID -> { t = account total, [charKey] = { bags, bank, mail, total } }
--  Built lazily after a scan changed something.
-------------------------------------------------------------------------------
local index, dirty = {}, true

function ns.MarkDirty()
    dirty = true
    ns.Notify()
end

-- Same item counts? (so a scan that changed nothing doesn't rebuild everything)
function ns.SameItems(a, b)
    if not a or not b then return a == b end
    for id, n in pairs(a) do
        if b[id] ~= n then return false end
    end
    for id in pairs(b) do
        if a[id] == nil then return false end
    end
    return true
end

function ns.Index()
    if not dirty then return index end
    wipe(index)
    for key, c in pairs(DB.chars) do
        for pi, place in ipairs(ns.PLACES) do
            local items = c[place]
            if items then
                for id, n in pairs(items) do
                    local e = index[id]
                    if not e then
                        e = { t = 0 }
                        index[id] = e
                    end
                    local per = e[key]
                    if not per then
                        per = { 0, 0, 0, 0 }
                        e[key] = per
                    end
                    per[pi] = per[pi] + n
                    per[4] = per[4] + n
                    e.t = e.t + n
                end
            end
        end
    end
    dirty = false
    return index
end

-- Account totals: number of distinct items, number of items, AH value.
function ns.AccountTotals()
    local kinds, count, value = 0, 0, 0
    for id, e in pairs(ns.Index()) do
        kinds = kinds + 1
        count = count + e.t
        local p = ns.Price(id)
        if p then value = value + p * e.t end
    end
    return kinds, count, value
end

-------------------------------------------------------------------------------
--  Slash commands
-------------------------------------------------------------------------------
local function Help()
    ns.Print(L["Commands:"])
    print("  " .. L["/stock - overview"])
    print("  " .. L["/stock <name> - overview searching for <name>"])
    print("  " .. L["/stock options - options"])
    print("  " .. L["/stock minimap - minimap button on / off"])
end

local function Slash(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$")
    local cmd = msg:lower()
    if not ns.db then
        ns.Print("|cffff5555" .. L["Not started yet - saved data not loaded."] .. "|r")
        return
    end
    -- A part that failed at start-up: say so instead of doing nothing.
    local part = (cmd == "options" or cmd == "config" or cmd == "opt") and "options"
        or (cmd == "minimap" and "minimap") or (cmd ~= "scan" and cmd ~= "help" and cmd ~= "?" and "overview")
    if part and ns.failed[part] then
        ns.Print("|cffff5555" .. format(L["Could not start the %s: %s"], part, (ns.failed[part]:match("^[^\n]*"))) .. "|r")
        return
    end
    if cmd == "" then
        ns.Overview:Toggle()
    elseif cmd == "options" or cmd == "config" or cmd == "opt" then
        ns.Options:Toggle()
    elseif cmd == "minimap" then
        ns.Minimap:Toggle()
    elseif cmd == "scan" then
        ns.ScanBags()
        ns.Print(L["Bags scanned."])
    elseif cmd == "help" or cmd == "?" then
        Help()
    else
        ns.Overview:Open(msg)   -- anything else: search for it
    end
end

SLASH_NIBBELZSTOCK1 = "/stock"
SLASH_NIBBELZSTOCK2 = "/nstock"
SlashCmdList.NIBBELZSTOCK = Slash

function NibbelzStock_OnAddonCompartmentClick(_, button)
    if button == "RightButton" then ns.Options:Toggle() else ns.Overview:Toggle() end
end

function NibbelzStock_OnAddonCompartmentEnter(_, frame)
    GameTooltip:SetOwner(frame or UIParent, "ANCHOR_LEFT")
    ns.FillButtonTooltip(GameTooltip)
    GameTooltip:Show()
end

function NibbelzStock_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end

-------------------------------------------------------------------------------
--  Events
-------------------------------------------------------------------------------
-- Runs one part of the start-up. An error is printed in chat (and passed on to
-- BugSack / the error frame) instead of silently stopping everything after it.
ns.failed = {}
local function SafeInit(part, fn, a1)
    local ok, err = xpcall(function() return fn(a1) end, function(e)
        return tostring(e) .. "\n" .. (debugstack and debugstack(2, 8, 0) or "")
    end)
    if ok then return true end
    ns.failed[part] = err
    ns.Print("|cffff5555" .. format(L["Could not start the %s: %s"], part, (tostring(err):match("^[^\n]*"))) .. "|r")
    local handler = geterrorhandler and geterrorhandler()
    if handler then pcall(handler, err) end
    return false
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_MONEY")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
pcall(events.RegisterEvent, events, "AUCTION_HOUSE_CLOSED")

events:SetScript("OnEvent", function(_, event, a1)
    if event == "ADDON_LOADED" then
        if a1 ~= ADDON then return end
        InitDB()   -- the character record is made at login (Scan.lua), when the name is known
        SafeInit("data", FixRealmKeys)
        SafeInit("style", ns.St.ApplyTheme, DB.opts.theme)   -- before any window is built
        -- Each part on its own: one that fails doesn't take the others with it.
        SafeInit("overview", ns.Overview.Init, ns.Overview)
        SafeInit("minimap", ns.Minimap.Init, ns.Minimap)
        SafeInit("options", ns.Options.Init, ns.Options)
        SafeInit("tooltip", ns.Tooltip.Init, ns.Tooltip)
    elseif not DB then
        return
    elseif event == "PLAYER_MONEY" then
        ns.Me()
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        ns.Debounce("itemInfo", 0.3, ns.Notify)
    elseif event == "AUCTION_HOUSE_CLOSED" then
        -- The price addons may have scanned: ask them again.
        ns.ResetPrices()
    end
end)
