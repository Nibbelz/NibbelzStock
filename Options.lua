-- Options.lua: the options window (switches, sliders, dropdowns).
-- Also listed under the game's Options > AddOns.
local _, ns = ...
local St, L = ns.St, ns.L

local format, floor = string.format, math.floor

local Options = {}
ns.Options = Options

local W = 380
local PAD = 16
local COL_W = (W - PAD * 2 - 8) / 2

local frame
local controls = {}

local function Apply()
    local o = ns.db.opts
    controls.tooltip:SetChecked(o.tooltip)
    controls.tooltipPlaces:SetChecked(o.tooltipPlaces)
    controls.tooltipAH:SetChecked(o.tooltipAH)
    controls.realmOnly:SetChecked(o.realmOnly)
    controls.scale:SetValue(floor((o.scale or 1) * 100 + 0.5))
    controls.minimap:SetChecked(not o.minimapHide)
    controls.style:Update()
    controls.ahSource:Update()
end

local function Build()
    frame = St.Window("NibbelzStockOptionsFrame", W, 400, L["Options"], "options")
    frame:Place({ "CENTER", UIParent, "CENTER", 0, 60 })
    frame:SetFrameStrata("DIALOG")
    frame:Hide()
    tinsert(UISpecialFrames, "NibbelzStockOptionsFrame")

    local logo = frame.bar:CreateTexture(nil, "OVERLAY")
    logo:SetSize(16, 16)
    logo:SetPoint("LEFT", 10, 0)
    logo:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
    logo:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.title:ClearAllPoints()
    frame.title:SetPoint("LEFT", logo, "RIGHT", 6, 0)
    frame.title:SetText("|cff0cd29fNibbelz|r Stock  |cff9a9a9a" .. L["Options"] .. "|r")

    local y = 40
    local function Section(text)
        local fs = St.Section(frame, text)
        fs:SetPoint("TOPLEFT", PAD, -y)
        local line = St.Fill(frame, { 1, 1, 1, 0.06 }, "BORDER")
        line:SetPoint("LEFT", fs, "RIGHT", 8, 0)
        line:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
        line:SetHeight(1)
        y = y + 20
    end
    local function Full(widget, h)
        widget:SetPoint("TOPLEFT", PAD, -y)
        widget:SetPoint("TOPRIGHT", -PAD, -y)
        y = y + h
    end
    local function Note(text)
        local fs = St.Text(frame, 10)
        fs:SetPoint("TOPLEFT", PAD, -y)
        fs:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
        fs:SetWordWrap(true)
        fs:SetText(text)
        fs:SetTextColor(1, 1, 1, 0.5)
        y = y + 30
    end
    local function Switch(key, label)
        controls[key] = St.Checkbox(frame, label, function(on)
            ns.db.opts[key] = on
            ns.Notify()
        end)
        Full(controls[key], 26)
    end

    -- Tooltip
    Section(L["TOOLTIP"])
    Switch("tooltip", L["Show the counts in item tooltips"])
    Switch("tooltipPlaces", L["Split by bags / bank / mail"])
    Switch("tooltipAH", L["Show the AH value"])
    Switch("realmOnly", L["Only characters of this realm"])
    y = y + 8

    -- Display
    Section(L["DISPLAY"])
    controls.scale = St.Slider(frame, L["Window size"], 60, 150, 5,
        function(v) return v .. "%" end,
        function(v)
            ns.db.opts.scale = v / 100
            ns.Overview:ApplyScale()
        end)
    Full(controls.scale, 44)
    controls.minimap = St.Checkbox(frame, L["Show minimap button"], function(on)
        ns.Minimap:SetShown(on)
    end)
    Full(controls.minimap, 26)

    -- Where the AH value comes from: automatic = the first addon that knows a price.
    local function SourceLabel(key)
        for _, src in ipairs(ns.AH_SOURCES) do
            if src.key == key then return src.label end
        end
        return L["Automatic"]
    end
    controls.ahSource = St.Dropdown(frame, W - PAD * 2, 22, function()
        return L["AH prices: "] .. SourceLabel(ns.db.opts.ahSource or "auto")
    end, function()
        local cur = ns.db.opts.ahSource or "auto"
        local function Pick(key)
            return function()
                ns.db.opts.ahSource = key
                ns.ResetPrices()
                controls.ahSource:Update()
                ns.Notify()
            end
        end
        local items = { { L["Automatic"], Pick("auto"), nil, cur == "auto" } }
        for _, src in ipairs(ns.AH_SOURCES) do
            local text = src.label
            if not src.available() then text = "|cff777777" .. text .. " (" .. L["not installed"] .. ")|r" end
            items[#items + 1] = { text, Pick(src.key), nil, cur == src.key }
        end
        return items
    end)
    Full(controls.ahSource, 28)

    -- Window style: a new style needs a UI reload.
    local function StyleLabel(key)
        for _, t in ipairs(St.THEMES) do
            if t.key == key then return L[t.label] end
        end
        return L[St.THEMES[1].label]
    end
    controls.style = St.Dropdown(frame, W - PAD * 2, 22, function()
        return L["Style: "] .. StyleLabel(ns.db.opts.theme)
    end, function()
        local items = {}
        for _, t in ipairs(St.THEMES) do
            local key = t.key
            items[#items + 1] = { L[t.label], function()
                if ns.db.opts.theme == key then return end
                ns.db.opts.theme = key
                controls.style:Update()
                St.ReloadPrompt(L["The new window style is used after a UI reload. Reload now?"])
            end, nil, key == ns.db.opts.theme }
        end
        return items
    end)
    Full(controls.style, 28)
    y = y + 6

    -- Characters
    Section(L["CHARACTERS"])
    Note(L["Bank and mail are read when you open them. Mail you send to your own characters is counted right away."])
    local forget
    forget = St.Dropdown(frame, COL_W, 22, function() return L["Forget a character..."] end, function()
        local items = {}
        for _, entry in ipairs(ns.SortedChars()) do
            local key, c = entry.key, entry.c
            items[#items + 1] = { ns.CharLabel(c), function()
                St.Confirm(format(L["Forget all data of %s?"], ns.CharLabel(c)), function()
                    ns.ForgetChar(key)
                    if ns.Overview then ns.Overview:Refresh() end
                end)
            end }
        end
        return items
    end)
    forget:SetPoint("TOPLEFT", PAD, -y)
    local rescan = St.Button(frame, L["Rescan now"], COL_W, 22, function()
        ns.ScanBags()
        ns.ScanBank()
        ns.ScanMail()
        ns.Print(L["Bags scanned."])
    end)
    rescan:SetPoint("TOPLEFT", PAD + COL_W + 8, -y)
    y = y + 28
    local open = St.Button(frame, L["Open overview"], W - PAD * 2, 24, function() ns.Overview:Toggle() end)
    open:SetActive(true)
    Full(open, 34)

    local hint = St.Text(frame, 10)
    hint:SetPoint("TOPLEFT", PAD, -y)
    hint:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
    hint:SetText("/stock   ·   /stock <item>   ·   /stock options   ·   /stock minimap")
    hint:SetTextColor(1, 1, 1, 0.35)
    y = y + 24

    frame:SetHeight(y)
    frame:SetScript("OnShow", Apply)
end

-- An entry under Options > AddOns that opens the window.
local function RegisterBlizzard()
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end
    local panel = CreateFrame("Frame")
    panel.name = "Nibbelz Stock"
    local title = St.Text(panel, 16)
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff0cd29fNibbelz|r Stock")
    local note = St.Text(panel, 11)
    note:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    note:SetText(L["Settings are in their own window."])
    note:SetTextColor(1, 1, 1, 0.7)
    local open = St.Button(panel, L["Open options"], 180, 24, function()
        if SettingsPanel and SettingsPanel:IsShown() then pcall(HideUIPanel, SettingsPanel) end
        Options:Open()
    end)
    open:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -14)
    local category = Settings.RegisterCanvasLayoutCategory(panel, "Nibbelz Stock")
    Settings.RegisterAddOnCategory(category)
end

function Options:Init()
    Build()
    pcall(RegisterBlizzard)
end

function Options:Open()
    if not frame then return end
    frame:Show()
    frame:Raise()
end

function Options:Toggle()
    if not frame then return end
    if frame:IsShown() then frame:Hide() else self:Open() end
end
