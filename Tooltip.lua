-- Tooltip.lua: under every item tooltip, how many the account has and which
-- character holds how many (bags / bank / mail), plus the AH value.
local _, ns = ...
local L, St = ns.L, ns.St

local format, sort, wipe, concat = string.format, table.sort, wipe, table.concat

local Tooltip = {}
ns.Tooltip = Tooltip

local DIM = "|cff9a9a9a"

-- "Bags 20  Bank 140  Mail 5" (only the places that hold some).
local function Places(per)
    local parts = {}
    if per[1] > 0 then parts[#parts + 1] = L["Bags"] .. " " .. ns.Num(per[1]) end
    if per[2] > 0 then parts[#parts + 1] = L["Bank"] .. " " .. ns.Num(per[2]) end
    if per[3] > 0 then parts[#parts + 1] = L["Mail"] .. " " .. ns.Num(per[3]) end
    return DIM .. concat(parts, "  ") .. "|r"
end

local function ByCount(a, b)
    if a.n ~= b.n then return a.n > b.n end
    return a.name < b.name
end

-- The finished lines per item: { total, header, { left, right }..., ahLine }.
-- Tooltips refresh all the time (bag items about once a second), so they are
-- built once and kept until a scan or an option changes something.
local cache = {}
local NONE = {}

local function Lines(id)
    local lines = cache[id]
    if lines then return lines end
    local o = ns.db.opts
    local e = ns.Index()[id]
    if not e then
        cache[id] = NONE
        return NONE
    end

    local realm = ns.MyRealm()
    local rows, total = {}, 0
    for key, per in pairs(e) do
        if key ~= "t" then
            local c = ns.db.chars[key]
            if c and (not o.realmOnly or c.realm == realm) and per[4] > 0 then
                rows[#rows + 1] = { c = c, per = per, n = per[4], name = c.name or "" }
                total = total + per[4]
            end
        end
    end
    if total == 0 then
        cache[id] = NONE
        return NONE
    end
    sort(rows, ByCount)

    lines = { total = total }
    lines.header = St.AccentHex() .. "Nibbelz Stock|r  " .. DIM .. L["Account"] .. "|r"
    lines.headerRight = "|cffffffff" .. ns.Num(total) .. "|r"
    for i, row in ipairs(rows) do
        local right = "|cffffffff" .. ns.Num(row.n) .. "|r"
        if o.tooltipPlaces then right = Places(row.per) .. "   " .. right end
        lines[i] = { "  " .. ns.CharLabel(row.c), right }
    end
    if o.tooltipAH then
        local p = ns.Price(id)
        if p then
            lines.ah = DIM .. format(L["AH: %s each, %s total"], "|r" .. ns.Money(p) .. DIM, "|r" .. ns.Money(p * total))
        end
    end
    cache[id] = lines
    return lines
end

local function AddLines(tip, id)
    local o = ns.db and ns.db.opts
    if not (o and o.tooltip) then return end
    if tip.nstockID == id then return end   -- already added to this tooltip
    local lines = Lines(id)
    if not lines.total then return end

    tip.nstockID = id
    tip:AddLine(" ")
    tip:AddDoubleLine(lines.header, lines.headerRight)
    for i = 1, #lines do
        tip:AddDoubleLine(lines[i][1], lines[i][2])
    end
    if lines.ah then tip:AddLine(lines.ah) end
    tip:Show()
end

local function Reset(tip) tip.nstockID = nil end

-- Compare tooltips (shopping tooltips) stay as they are.
local function Wanted(tip)
    return tip and tip.AddDoubleLine and tip ~= ShoppingTooltip1 and tip ~= ShoppingTooltip2
end

local hooked = {}
local function HookReset(tip)
    if hooked[tip] then return end
    hooked[tip] = true
    pcall(tip.HookScript, tip, "OnTooltipCleared", Reset)
    pcall(tip.HookScript, tip, "OnHide", Reset)
end

function Tooltip:Init()
    -- Scans, options, item info and AH prices all end in ns.Notify(): start over.
    ns.Listen(function() wipe(cache) end)
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tip, data)
            if not Wanted(tip) then return end
            local id = data and ns.Plain(data.id, "number")
            if not id then return end
            HookReset(tip)
            AddLines(tip, id)
        end)
        return
    end
    -- Older clients: OnTooltipSetItem.
    local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant
    for _, tip in ipairs({ GameTooltip, ItemRefTooltip }) do
        if tip then
            HookReset(tip)
            tip:HookScript("OnTooltipSetItem", function(self)
                local _, link = self:GetItem()
                local id = link and GetItemInfoInstant(link)
                if id then AddLines(self, id) end
            end)
        end
    end
end
