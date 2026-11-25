-- Scan.lua: reads the bags (always), the bank (while it is open) and the mailbox
-- (while it is open) into the character's record. Mail sent to one of your own
-- characters is added to that character's mail right away.
local _, ns = ...

local time = time
local C = C_Container

local GetNumSlots = (C and C.GetContainerNumSlots) or _G.GetContainerNumSlots

-- itemID, count, link, quality, icon of one slot.
local function SlotItem(bag, slot)
    if C and C.GetContainerItemInfo then
        local info = C.GetContainerItemInfo(bag, slot)
        if info and info.itemID then
            return info.itemID, info.stackCount or 1, info.hyperlink, info.quality, info.iconFileID,
                info.isBound and true or false
        end
        return nil
    end
    local icon, count, _, quality, _, _, link, _, _, id = _G.GetContainerItemInfo(bag, slot)
    if id then return id, count or 1, link, quality, icon, nil end
end

-------------------------------------------------------------------------------
--  Containers. Newer clients name them in Enum.BagIndex (bank tabs instead of
--  bank bags); older ones use the BANK_CONTAINER / NUM_BAG_SLOTS numbering.
-------------------------------------------------------------------------------
local BagIndex = (Enum and Enum.BagIndex) or {}
local NUM_BAGS = (Constants and Constants.InventoryConstants and Constants.InventoryConstants.NumBagSlots)
    or NUM_BAG_SLOTS or 4

local BAGS = { BagIndex.Backpack or BACKPACK_CONTAINER or 0 }
for i = 1, NUM_BAGS do BAGS[#BAGS + 1] = BagIndex["Bag_" .. i] or i end
if BagIndex.ReagentBag then BAGS[#BAGS + 1] = BagIndex.ReagentBag end

local BANK = {}
for i = 1, 10 do
    local tab = BagIndex["CharacterBankTab_" .. i]
    if tab then BANK[#BANK + 1] = tab end
end
if #BANK == 0 then
    BANK[1] = BagIndex.Bank or BANK_CONTAINER or -1
    for i = 1, NUM_BANKBAGSLOTS or 7 do
        BANK[#BANK + 1] = BagIndex["BankBag_" .. i] or (NUM_BAGS + i)
    end
    local reagent = BagIndex.Reagentbank or REAGENTBANK_CONTAINER
    if reagent then BANK[#BANK + 1] = reagent end
end

local function ScanContainers(list)
    local items, slots = {}, 0
    for _, bag in ipairs(list) do
        local n = GetNumSlots(bag) or 0
        slots = slots + n
        for slot = 1, n do
            local id, count, link, quality, icon, bound = SlotItem(bag, slot)
            if id then
                items[id] = (items[id] or 0) + count
                ns.Remember(id, link, quality, icon, nil, bound)
            end
        end
    end
    return items, slots
end

-- Store a fresh scan; only rebuild the index / windows when the counts changed
-- (bag events also fire for cooldowns, durability, locking a slot, ...).
local function Store(me, place, items)
    local first = not me[place .. "T"]
    me[place .. "T"] = time()
    if ns.SameItems(me[place], items) then
        if first then ns.Notify() end   -- "never scanned" goes away
        return
    end
    me[place] = items
    ns.MarkDirty()
end

function ns.ScanBags()
    Store(ns.Me(), "bags", (ScanContainers(BAGS)))
end

local bankOpen, mailOpen = false, false

function ns.ScanBank()
    if not bankOpen then return end
    local items, slots = ScanContainers(BANK)
    if slots == 0 then return end   -- not loaded yet: keep what we had
    Store(ns.Me(), "bank", items)
end

-------------------------------------------------------------------------------
--  Mail
-------------------------------------------------------------------------------
local MAX_RECEIVE = ATTACHMENTS_MAX_RECEIVE or 16
local MAX_SEND = ATTACHMENTS_MAX_SEND or 12

function ns.ScanMail()
    if not mailOpen then return end
    local items = {}
    for i = 1, GetInboxNumItems() do
        local _, _, _, _, _, _, _, hasItem = GetInboxHeaderInfo(i)
        if hasItem then
            for a = 1, MAX_RECEIVE do
                local name, id, icon, count, quality = GetInboxItem(i, a)
                if id then
                    items[id] = (items[id] or 0) + (count or 1)
                    ns.Remember(id, nil, quality, icon, name)
                end
            end
        end
    end
    Store(ns.Me(), "mail", items)
end

-- One of our characters on this realm, by the name typed as recipient.
local function FindAlt(recipient)
    if type(recipient) ~= "string" or recipient == "" then return nil end
    local name, realm = recipient:match("^([^%-]+)%-?(.*)$")
    name = (name or recipient):lower():gsub("%s+$", "")
    if realm == "" then realm = ns.MyRealm() end
    for _, c in pairs(ns.db.chars) do
        if c.realm and c.realm:gsub("%s", ""):lower() == realm:gsub("%s", ""):lower() then
            local full = (c.name or ""):lower()
            local first = full:match("^(%S+)") or full
            if full == name or first == name then return c end
        end
    end
end

-- SendMail(): remember what goes out; on success it lands in the alt's mailbox.
local pending
hooksecurefunc("SendMail", function(recipient)
    local items = {}
    for i = 1, MAX_SEND do
        local name, id, icon, count, quality = GetSendMailItem(i)
        if id then
            items[id] = (items[id] or 0) + (count or 1)
            ns.Remember(id, nil, quality, icon, name)
        end
    end
    pending = next(items) and { to = recipient, items = items } or nil
end)

local function OnMailSent()
    local p = pending
    pending = nil
    if not p then return end
    local alt = FindAlt(p.to)
    if not alt then return end
    alt.mail = alt.mail or {}
    for id, n in pairs(p.items) do alt.mail[id] = (alt.mail[id] or 0) + n end
    ns.MarkDirty()
end

-------------------------------------------------------------------------------
--  Events
-------------------------------------------------------------------------------
local PI = Enum and Enum.PlayerInteractionType or {}

local function BankOpened()
    bankOpen = true
    C_Timer.After(0.3, ns.ScanBank)   -- the bank contents arrive a moment later
end
local function MailOpened()
    mailOpen = true
    if CheckInbox then CheckInbox() end
    C_Timer.After(0.5, ns.ScanMail)
end

local f = CreateFrame("Frame")
for _, ev in ipairs({
    "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED",
    "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED", "PLAYERREAGENTBANKSLOTS_CHANGED",
    "PLAYER_INTERACTION_MANAGER_FRAME_SHOW", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",
    "MAIL_SHOW", "MAIL_CLOSED", "MAIL_INBOX_UPDATE", "MAIL_SEND_SUCCESS", "MAIL_FAILED",
}) do
    pcall(f.RegisterEvent, f, ev)
end

f:SetScript("OnEvent", function(_, event, a1)
    if not ns.db then return end
    if event == "PLAYER_ENTERING_WORLD" then
        ns.ScanBags()
    elseif event == "BAG_UPDATE_DELAYED" then
        ns.Debounce("bags", 0.5, ns.ScanBags)
        if bankOpen then ns.Debounce("bank", 0.5, ns.ScanBank) end
    elseif event == "PLAYERBANKSLOTS_CHANGED" or event == "PLAYERREAGENTBANKSLOTS_CHANGED" then
        ns.Debounce("bank", 0.5, ns.ScanBank)
    elseif event == "BANKFRAME_OPENED" then
        BankOpened()
    elseif event == "BANKFRAME_CLOSED" then
        bankOpen = false
    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
        if PI.Banker and a1 == PI.Banker then BankOpened()
        elseif PI.MailInfo and a1 == PI.MailInfo then MailOpened() end
    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
        if PI.Banker and a1 == PI.Banker then bankOpen = false
        elseif PI.MailInfo and a1 == PI.MailInfo then mailOpen = false end
    elseif event == "MAIL_SHOW" then
        MailOpened()
    elseif event == "MAIL_CLOSED" then
        mailOpen = false
    elseif event == "MAIL_INBOX_UPDATE" then
        ns.Debounce("mail", 0.3, ns.ScanMail)
    elseif event == "MAIL_SEND_SUCCESS" then
        OnMailSent()
    elseif event == "MAIL_FAILED" then
        pending = nil
    end
end)
