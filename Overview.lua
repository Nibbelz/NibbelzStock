-- Overview.lua: the main window. Every item on the account (or on one character),
-- split into bags / bank / mail, with the AH value. A slider (and a box to type
-- in) hides everything below a minimum amount; search, place and materials filters.
local _, ns = ...
local St, L = ns.St, ns.L

local format, floor, max, min, sort, concat = string.format, math.floor, math.max, math.min, table.sort, table.concat
local lower, find = string.lower, string.find

local Overview = {}
ns.Overview = Overview

local W, H = 700, 520
local PAD = 12
local ROW_H = 22
local SLIDER_MAX = 1000

local frame, list, controls = nil, nil, {}
local search = ""

-- Columns from the right: key, header, width. The item name takes the rest.
local COLS = {
    { key = "value", label = L["AH value"], w = 104 },
    { key = "price", label = L["AH each"],  w = 92 },
    { key = "mail",  label = L["Mail"],     w = 54 },
    { key = "bank",  label = L["Bank"],     w = 60 },
    { key = "bags",  label = L["Bags"],     w = 60 },
    { key = "total", label = L["Total"],    w = 66 },
}
local GAP = 6
local RIGHT_W = 0
for _, c in ipairs(COLS) do RIGHT_W = RIGHT_W + c.w + GAP end

-------------------------------------------------------------------------------
--  Data
-------------------------------------------------------------------------------
-- Reused between refreshes: the list of rows, the row tables, lowercase names.
local data, pool, lowerName = {}, {}, {}

local function SortRows(a, b)
    local key = ns.db.opts.sortKey or "total"
    local va, vb = a[key], b[key]
    if va ~= vb then
        if ns.db.opts.sortDesc then return va > vb end
        return va < vb
    end
    return a.name < b.name
end

local function Build()
    local o = ns.db.opts
    local idx = ns.Index()
    local charKey = o.filterChar
    if charKey ~= "all" and not ns.db.chars[charKey] then
        charKey = "all"
        o.filterChar = "all"
    end
    local place = o.filterPlace
    local minCount = max(1, o.minCount or 0)
    local n, value = 0, 0
    for id, e in pairs(idx) do
        local b, k, m = 0, 0, 0
        if charKey == "all" then
            for key, per in pairs(e) do
                if key ~= "t" then b, k, m = b + per[1], k + per[2], m + per[3] end
            end
        else
            local per = e[charKey]
            if per then b, k, m = per[1], per[2], per[3] end
        end
        local total
        if place == "bags" then total = b
        elseif place == "bank" then total = k
        elseif place == "mail" then total = m
        else total = b + k + m end
        if total >= minCount and (not o.sellableOnly or ns.CanSell(id))
            and (not o.matsOnly or ns.IsMat(id)) then
            local name, quality, icon = ns.Info(id)
            local match = search == ""
            if not match then
                local low = lowerName[name]
                if not low then
                    low = lower(name)
                    lowerName[name] = low
                end
                match = find(low, search, 1, true) ~= nil
            end
            if match then
                local price = ns.Price(id) or 0
                n = n + 1
                local row = pool[n]
                if not row then
                    row = {}
                    pool[n] = row
                end
                row.id, row.name, row.q, row.icon = id, name, quality, icon
                row.total, row.bags, row.bank, row.mail = total, b, k, m
                row.price, row.value = price, price * total
                data[n] = row
                value = value + row.value
            end
        end
    end
    for i = #data, n + 1, -1 do data[i] = nil end
    sort(data, SortRows)
    return data, value
end

-------------------------------------------------------------------------------
--  Rows
-------------------------------------------------------------------------------
local function MakeRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:RegisterForClicks("LeftButtonUp")
    St.RowBackground(row)
    row.icon = St.Icon(row, 18)
    row.icon:SetPoint("LEFT", 4, 0)
    row.name = St.Text(row, 11)
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.name:SetPoint("RIGHT", row, "RIGHT", -RIGHT_W - 4, 0)
    row.cells = {}
    local x = -4
    for _, c in ipairs(COLS) do
        local fs = St.Text(row, 11, "RIGHT")
        fs:SetPoint("RIGHT", row, "RIGHT", x, 0)
        fs:SetWidth(c.w)
        row.cells[c.key] = fs
        x = x - c.w - GAP
    end
    row:SetScript("OnEnter", function(self)
        self:PaintState(false)
        if not self.item then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if GameTooltip.SetItemByID then
            GameTooltip:SetItemByID(self.item.id)
        else
            GameTooltip:SetHyperlink("item:" .. self.item.id)
        end
        GameTooltip:AddLine(L["Shift-click: link in chat"], 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        self:PaintState(false)
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function(self)
        if not self.item then return end
        if IsModifiedClick and IsModifiedClick("CHATLINK") or IsShiftKeyDown() then
            local link = ns.ItemLink(self.item.id)
            if link and ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
        end
    end)
    return row
end

local function Count(n, dim)
    if not n or n <= 0 then return "|cff444444-|r" end
    if dim then return "|cffb0b0b0" .. ns.Num(n) .. "|r" end
    return ns.Num(n)
end

local function FillRow(row, item)
    row.icon:SetItem(item.icon, item.q)
    row.name:SetText(item.name)
    row.name:SetTextColor(ns.QualityColor(item.q))
    row.cells.total:SetText(Count(item.total))
    row.cells.bags:SetText(Count(item.bags, true))
    row.cells.bank:SetText(Count(item.bank, true))
    row.cells.mail:SetText(Count(item.mail, true))
    row.cells.price:SetText(item.price > 0 and ns.Money(item.price) or "|cff444444-|r")
    row.cells.value:SetText(item.value > 0 and ns.Money(item.value) or "|cff444444-|r")
    row:PaintState(false)
end

-------------------------------------------------------------------------------
--  Header (click to sort)
-------------------------------------------------------------------------------
local headers = {}

local function PaintHeaders()
    local o = ns.db.opts
    local r, g, b = St.Accent()
    for key, h in pairs(headers) do
        if key == o.sortKey then
            h.text:SetText(h.label .. (o.sortDesc and " v" or " ^"))
            h.text:SetTextColor(r, g, b, 1)
        else
            h.text:SetText(h.label)
            h.text:SetTextColor(1, 1, 1, h:IsMouseOver() and 0.9 or 0.5)
        end
    end
end

local function Header(parent, key, label, w, justify)
    local h = CreateFrame("Button", nil, parent)
    h:SetSize(w, 18)
    h.label = label
    h.text = St.Text(h, 10, justify)
    h.text:SetAllPoints()
    h:SetScript("OnClick", function()
        local o = ns.db.opts
        if o.sortKey == key then
            o.sortDesc = not o.sortDesc
        else
            o.sortKey = key
            o.sortDesc = key ~= "name"
        end
        Overview:Refresh()
    end)
    h:SetScript("OnEnter", PaintHeaders)
    h:SetScript("OnLeave", PaintHeaders)
    headers[key] = h
    return h
end

-------------------------------------------------------------------------------
--  Footer: when the bank / mail of the shown character was read
-------------------------------------------------------------------------------
local function FooterText()
    local o = ns.db.opts
    if o.filterChar == "all" then
        local n, missing = 0, {}
        for _, entry in ipairs(ns.SortedChars()) do
            n = n + 1
            if not entry.c.bankT then missing[#missing + 1] = ns.CharLabel(entry.c, false) end
        end
        local text = n == 1 and L["1 character"] or format(L["%d characters"], n)
        if #missing > 0 then
            text = text .. "   |cffff8844" .. L["Bank"] .. "?|r " .. concat(missing, ", ")
        end
        return text
    end
    local c = ns.db.chars[o.filterChar]
    if not c then return "" end
    if not c.bankT then return "|cffff8844" .. L["Bank never scanned - open the bank once on this character."] .. "|r" end
    if not c.mailT then return "|cffff8844" .. L["Mail never scanned - open the mailbox once on this character."] .. "|r" end
    return format(L["Bank: %s"], ns.Ago(c.bankT)) .. "   ·   " .. format(L["Mail: %s"], ns.Ago(c.mailT))
end

-------------------------------------------------------------------------------
--  Window
-------------------------------------------------------------------------------
local function CharText()
    local key = ns.db.opts.filterChar
    local c = key ~= "all" and ns.db.chars[key]
    if c then return ns.CharLabel(c) end
    return L["All characters"]
end

local PLACE_LABEL = { all = L["All places"], bags = L["Bags"], bank = L["Bank"], mail = L["Mail"] }

local function SetMin(v)
    v = max(0, floor(tonumber(v) or 0))
    ns.db.opts.minCount = v
    controls.slider:SetValue(min(v, SLIDER_MAX))
    controls.slider.value:SetText(v > 0 and format(L["at least %s"], ns.Num(v)) or L["any amount"])
    if not controls.minBox:HasFocus() then controls.minBox:SetText(tostring(v)) end
    Overview:Refresh()
end

local function BuildWindow()
    frame = St.Window("NibbelzStockFrame", W, H, "Stock", "overview")
    frame:Place({ "CENTER", UIParent, "CENTER", 0, 40 })
    if not (St.theme and St.theme.titleBar) then frame.title:SetText("|cff0cd29fNibbelz|r Stock") end
    frame:SetScale(ns.db.opts.scale or 1)
    frame:SetResizable(true)
    if frame.SetResizeBounds then frame:SetResizeBounds(W, 300, W + 400, 1000) end
    frame:Hide()
    tinsert(UISpecialFrames, "NibbelzStockFrame")

    -- Gear in the title bar: the options.
    local gear = St.IconButton(frame.bar, "Interface\\Buttons\\UI-OptionsButton", 14, L["Options"],
        function() ns.Options:Toggle() end)
    gear:SetPoint("RIGHT", frame.close, "LEFT", -6, 0)

    -- Row 1: search, character, place, materials only.
    local y = -38
    controls.search = St.Search(frame, 200, 22, L["Search item"], function(text)
        search = lower(text or "")
        Overview:Refresh()
    end)
    controls.search:SetPoint("TOPLEFT", PAD, y)

    controls.char = St.Dropdown(frame, 200, 22, CharText, function()
        local cur = ns.db.opts.filterChar
        local function Pick(key)
            return function()
                ns.db.opts.filterChar = key
                controls.char:Update()
                Overview:Refresh()
            end
        end
        local items = { { L["All characters"], Pick("all"), nil, cur == "all" } }
        for _, entry in ipairs(ns.SortedChars()) do
            items[#items + 1] = { ns.CharLabel(entry.c), Pick(entry.key), nil, cur == entry.key }
        end
        return items
    end)
    controls.char:SetPoint("LEFT", controls.search, "RIGHT", 8, 0)

    controls.place = St.Dropdown(frame, 120, 22, function()
        return PLACE_LABEL[ns.db.opts.filterPlace] or PLACE_LABEL.all
    end, function()
        local cur = ns.db.opts.filterPlace
        local items = {}
        for _, key in ipairs({ "all", "bags", "bank", "mail" }) do
            items[#items + 1] = { PLACE_LABEL[key], function()
                ns.db.opts.filterPlace = key
                controls.place:Update()
                Overview:Refresh()
            end, nil, cur == key }
        end
        return items
    end)
    controls.place:SetPoint("LEFT", controls.char, "RIGHT", 8, 0)

    controls.mats = St.Checkbox(frame, L["Materials only"], function(on)
        ns.db.opts.matsOnly = on
        Overview:Refresh()
    end)
    controls.mats:SetPoint("LEFT", controls.place, "RIGHT", 12, 0)
    controls.mats:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)

    -- Row 2: minimum amount slider + exact box, summary on the right.
    y = y - 32
    controls.slider = St.Slider(frame, L["Minimum amount"], 0, SLIDER_MAX, 10,
        function(v)
            local cur = ns.db.opts.minCount or 0
            if cur > SLIDER_MAX then v = cur end
            return v > 0 and format(L["at least %s"], ns.Num(v)) or L["any amount"]
        end,
        function(v) SetMin(v) end)
    controls.slider:SetPoint("TOPLEFT", PAD, y)
    controls.slider:SetWidth(300)

    local box = CreateFrame("EditBox", nil, frame)
    box:SetSize(64, 20)
    box:SetPoint("BOTTOMLEFT", controls.slider, "BOTTOMRIGHT", 10, 0)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetMaxLetters(7)
    box:SetFont(St.FontPath(), 11, "")
    box:SetJustifyH("CENTER")
    box:SetTextColor(1, 1, 1, 0.9)
    local bg = St.Fill(box, { 0, 0, 0, 0.35 })
    bg:SetAllPoints()
    St.Border(box, 0.15)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus(); SetMin(self:GetText()) end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); self:SetText(tostring(ns.db.opts.minCount or 0)) end)
    box:SetScript("OnEditFocusGained", function(self) self:SetBorderColor(St.Accent()); self:HighlightText() end)
    box:SetScript("OnEditFocusLost", function(self) self:SetBorderColor(St.Line(0.15)); SetMin(self:GetText()) end)
    controls.minBox = box

    controls.sellable = St.Checkbox(frame, L["Sellable only"], function(on)
        ns.db.opts.sellableOnly = on
        Overview:Refresh()
    end)
    controls.sellable:SetPoint("LEFT", box, "RIGHT", 14, 0)
    controls.sellable:SetWidth(150)
    controls.sellable:SetScript("OnEnter", function(self)
        self:Paint()
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["Hides soulbound, quest and account-bound items."], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    controls.sellable:SetScript("OnLeave", function(self)
        self:Paint()
        GameTooltip:Hide()
    end)

    controls.summary = St.Text(frame, 12, "RIGHT")
    controls.summary:SetPoint("TOPRIGHT", -PAD, y - 2)
    controls.value = St.Text(frame, 12, "RIGHT")
    controls.value:SetPoint("TOPRIGHT", controls.summary, "BOTTOMRIGHT", 0, -6)

    -- Header line.
    y = y - 50
    local head = CreateFrame("Frame", nil, frame)
    head:SetPoint("TOPLEFT", PAD, y)
    head:SetPoint("TOPRIGHT", -PAD, y)
    head:SetHeight(18)
    local nameH = Header(head, "name", L["Item"], 200, "LEFT")
    nameH:SetPoint("LEFT", 28, 0)
    local x = -4 - 7   -- the list's scrollbar
    for _, c in ipairs(COLS) do
        local h = Header(head, c.key, c.label, c.w, "RIGHT")
        h:SetPoint("RIGHT", head, "RIGHT", x, 0)
        x = x - c.w - GAP
    end
    local line = St.Fill(frame, { St.Line(0.08) }, "BORDER")
    line:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -2)
    line:SetPoint("TOPRIGHT", head, "BOTTOMRIGHT", 0, -2)
    line:SetHeight(1)

    -- The list.
    list = St.List(frame, ROW_H, MakeRow, FillRow)
    list:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -5)
    list:SetPoint("BOTTOMRIGHT", -PAD, 30)

    controls.empty = St.Text(frame, 12, "CENTER")
    controls.empty:SetPoint("CENTER", list, "CENTER")
    controls.empty:SetText(L["No items match."])
    controls.empty:SetTextColor(1, 1, 1, 0.4)

    -- Footer + resize grip.
    controls.footer = St.Text(frame, 10)
    controls.footer:SetPoint("BOTTOMLEFT", PAD, 10)
    controls.footer:SetPoint("RIGHT", frame, "RIGHT", -30, 0)
    controls.footer:SetTextColor(1, 1, 1, 0.55)

    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        ns.db.pos.overviewSize = { frame:GetWidth(), frame:GetHeight() }
        local point, _, relPoint, px, py = frame:GetPoint()
        ns.db.pos.overview = { point, relPoint, px, py }
    end)
    local size = ns.db.pos.overviewSize
    if type(size) == "table" and size[1] then frame:SetSize(max(W, size[1]), max(300, size[2])) end

    frame:SetScript("OnShow", function()
        ns.ResetPrices()   -- prices may have changed since the last look
        controls.char:Update()
        controls.place:Update()
        controls.mats:SetChecked(ns.db.opts.matsOnly)
        controls.sellable:SetChecked(ns.db.opts.sellableOnly)
        SetMin(ns.db.opts.minCount or 0)
    end)
end

-- Refresh() can be asked for many times in one frame (slider drag, filters set
-- on show, scans): the list is rebuilt once, on the next frame.
local refreshQueued = false

local function DoRefresh()
    refreshQueued = false
    if not (frame and frame:IsShown()) then return end
    local data, value = Build()
    list:SetData(data, true)
    controls.empty:SetShown(#data == 0)
    controls.summary:SetText(#data == 1 and L["1 item shown"] or format(L["%d items shown"], #data))
    if ns.HasAH() or value > 0 then
        controls.value:SetText(format(L["Value: %s"], ns.Money(value)))
    else
        controls.value:SetText("|cff777777" .. L["AH value"] .. ": " .. L["no AH source"] .. "|r")
    end
    controls.footer:SetText(FooterText())
    PaintHeaders()
end

function Overview:Refresh()
    if refreshQueued or not (frame and frame:IsShown()) then return end
    refreshQueued = true
    C_Timer.After(0, DoRefresh)
end

function Overview:Init()
    BuildWindow()
    ns.Listen(function() Overview:Refresh() end)
end

function Overview:Open(text)
    if not frame then return end
    frame:Show()
    frame:Raise()
    if text then
        controls.search:SetText(text)
    end
end

function Overview:Toggle()
    if not frame then return end
    if frame:IsShown() then frame:Hide() else self:Open() end
end

function Overview:ApplyScale()
    if frame then frame:SetScale(ns.db.opts.scale or 1) end
end
