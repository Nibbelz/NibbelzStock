-- Minimap.lua: a round minimap button with a bag. Left-click: overview,
-- right-click: options, drag: move it. Named like other addon buttons so
-- EllesmereUI's minimap button bar can collect it.
local _, ns = ...
local L = ns.L

local format, max, min, sqrt, rad, deg, cos, sin = string.format, math.max, math.min, math.sqrt, math.rad, math.deg, math.cos, math.sin
local atan2 = math.atan2 or atan2

local MM = {}
ns.Minimap = MM

local ICON = "Interface\\Icons\\INV_Misc_Bag_10"
local button

-- Which quadrants of the minimap are round (LibDBIcon's table), for square minimaps.
local SHAPES = {
    ["ROUND"] = { true, true, true, true },
    ["SQUARE"] = { false, false, false, false },
    ["CORNER-TOPLEFT"] = { false, false, false, true },
    ["CORNER-TOPRIGHT"] = { false, false, true, false },
    ["CORNER-BOTTOMLEFT"] = { false, true, false, false },
    ["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
    ["SIDE-LEFT"] = { false, true, false, true },
    ["SIDE-RIGHT"] = { true, false, true, false },
    ["SIDE-TOP"] = { false, false, true, true },
    ["SIDE-BOTTOM"] = { true, true, false, false },
    ["TRICORNER-TOPLEFT"] = { false, true, true, true },
    ["TRICORNER-TOPRIGHT"] = { true, false, true, true },
    ["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
    ["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

local function Place(angle)
    local a = rad(angle or 215)
    local x, y, q = cos(a), sin(a), 1
    if x < 0 then q = q + 1 end
    if y > 0 then q = q + 2 end
    local shape = (GetMinimapShape and GetMinimapShape()) or "ROUND"
    local quad = SHAPES[shape] or SHAPES.ROUND
    local w = Minimap:GetWidth() / 2 + 5
    local h = Minimap:GetHeight() / 2 + 5
    if quad[q] then
        x, y = x * w, y * h
    else
        local dw, dh = sqrt(2 * w * w) - 10, sqrt(2 * h * h) - 10
        x = max(-w, min(x * dw, w))
        y = max(-h, min(y * dh, h))
    end
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function OnDragUpdate()
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale
    ns.db.opts.minimapAngle = deg(atan2(py - my, px - mx)) % 360
    Place(ns.db.opts.minimapAngle)
end

-------------------------------------------------------------------------------
--  Tooltip (also used by the addon compartment entry)
-------------------------------------------------------------------------------
function ns.FillButtonTooltip(tip)
    tip:AddLine("|cff0cd29fNibbelz|r Stock")
    if ns.db then
        local kinds, count, value = ns.AccountTotals()
        local chars = 0
        for _ in pairs(ns.db.chars) do chars = chars + 1 end
        tip:AddLine(" ")
        tip:AddDoubleLine(L["Items on the account"], ns.Num(count) .. " |cff9a9a9a(" .. ns.Num(kinds) .. ")|r", 1, 1, 1, 1, 1, 1)
        if value > 0 then
            tip:AddDoubleLine(L["AH value of everything"], ns.Money(value), 1, 1, 1, 1, 1, 1)
        end
        tip:AddLine("|cff9a9a9a" .. (chars == 1 and L["1 character"] or format(L["%d characters"], chars)) .. "|r")
    end
    tip:AddLine(" ")
    tip:AddLine(L["Left-click: overview"], 0.8, 0.8, 0.8)
    tip:AddLine(L["Right-click: options"], 0.8, 0.8, 0.8)
    tip:AddLine(L["Drag: move the button"], 0.8, 0.8, 0.8)
end

-------------------------------------------------------------------------------
--  Button
-------------------------------------------------------------------------------
local function Build()
    button = CreateFrame("Button", "NibbelzStockMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", 7, -5)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexture(ICON)
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetScript("OnClick", function(_, which)
        if which == "RightButton" then ns.Options:Toggle() else ns.Overview:Toggle() end
    end)
    button:SetScript("OnMouseDown", function() icon:SetTexCoord(0.1, 0.9, 0.1, 0.9) end)
    button:SetScript("OnMouseUp", function() icon:SetTexCoord(0.05, 0.95, 0.05, 0.95) end)
    button:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", OnDragUpdate)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        ns.FillButtonTooltip(GameTooltip)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function MM:Init()
    if not Minimap then return end
    Build()
    Place(ns.db.opts.minimapAngle)
    button:SetShown(not ns.db.opts.minimapHide)
end

function MM:SetShown(show)
    ns.db.opts.minimapHide = not show
    if button then button:SetShown(show) end
end

function MM:Toggle()
    self:SetShown(ns.db.opts.minimapHide)
    ns.Print(format(L["Minimap button: %s"], ns.db.opts.minimapHide and L["off"] or L["on"]))
end
