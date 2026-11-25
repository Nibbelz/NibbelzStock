-- Style.lua: the window styles and the widgets every window is built from.
--
-- Styles (chosen in the options, applied at the next UI reload):
--   ellesmere  EllesmereUI: warm near-black panels, 1px white-alpha lines, its accent colour
--   classic    Blizzard: tooltip-style frame, gold titles, the red panel buttons
--   naowh      NaowhForever: graphite panels, blue accent
--   midnight   NaowhForever's midnight: deep blue panels, soft blue accent
--   dark       ElvUI-like: flat black, black 1px borders, outlined font, class colour accent
local _, ns = ...
local St = {}
ns.St = St

local floor, max, min, format = math.floor, math.max, math.min, string.format

St.THEMES = {
    -- The look of Nibbelz Debuff Gradiant: neutral #111 panels, a darkened title bar
    -- with a thin turquoise line, "NIBBELZ" + title, flat buttons with a turquoise
    -- hover edge, switches instead of boxes, Expressway font.
    { key = "nibbelz", label = "Nibbelz", titleBar = true, closeX = true, button = "flat", check = "toggle",
      panel = { 0.067, 0.067, 0.067, 0.97 }, inset = { 0, 0, 0, 0.3 }, btn = { 1, 1, 1, 0.06 },
      line = { 1, 1, 1 }, lineMul = 1, accent = { 0.047, 0.824, 0.624 }, font = "expressway",
      section = { 0.047, 0.824, 0.624, 1 } },
    { key = "ellesmere", label = "EllesmereUI",
      panel = { 0.069, 0.058, 0.047, 0.97 }, inset = { 0.103, 0.095, 0.088, 0.55 }, btn = { 0.089, 0.080, 0.072, 0.60 },
      line = { 1, 1, 1 }, lineMul = 1, accent = "eui", font = "eui" },
    { key = "classic", label = "Classic", frame = "blizzard", button = "blizzard",
      panel = { 0.02, 0.02, 0.02, 0.88 }, inset = { 0, 0, 0, 0.45 }, btn = { 0.2, 0.04, 0.02, 0.9 },
      line = { 0.8, 0.65, 0.3 }, lineMul = 2.5, accent = { 1, 0.82, 0 }, title = { 1, 0.82, 0 },
      section = { 1, 0.82, 0, 0.75 } },
    { key = "naowh", label = "Naowh",
      panel = { 0.098, 0.106, 0.114, 0.97 }, inset = { 0.118, 0.125, 0.133, 0.9 }, btn = { 0.15, 0.16, 0.17, 0.9 },
      line = { 1, 1, 1 }, lineMul = 0.9, accent = { 0, 0.569, 0.929 } },
    { key = "midnight", label = "Midnight",
      panel = { 0.043, 0.063, 0.125, 0.97 }, inset = { 0.082, 0.11, 0.188, 0.9 }, btn = { 0.1, 0.13, 0.22, 0.9 },
      line = { 0.6, 0.7, 1 }, lineMul = 1.2, accent = { 0.357, 0.549, 1 } },
    { key = "dark", label = "Dark",
      panel = { 0.04, 0.04, 0.04, 0.93 }, inset = { 0.08, 0.08, 0.08, 0.85 }, btn = { 0.1, 0.1, 0.1, 0.95 },
      line = { 0, 0, 0 }, lineMul = 10, accent = "class", outline = "OUTLINE" },
}
local THEME_BY_KEY = {}
for _, t in ipairs(St.THEMES) do THEME_BY_KEY[t.key] = t end

local theme = St.THEMES[1]
St.PANEL, St.INSET, St.BTN = theme.panel, theme.inset, theme.btn
St.BORDER_A = 0.10
St.DIM = 0.53
St.SECTION = 0.41

-- Accent colour and font, worked out once (not on every repaint).
local accent = { 0.05, 0.82, 0.62 }
local fontPath = STANDARD_TEXT_FONT

function St.RefreshAccent()
    local a = theme.accent
    if a == "eui" then
        local eui = _G.EllesmereUI
        if eui and eui.GetAccentColor then
            local ok, r, g, b = pcall(eui.GetAccentColor)
            if ok and type(r) == "number" then accent = { r, g, b } return end
        end
        accent = { 0.05, 0.82, 0.62 }
    elseif a == "class" then
        local _, class = UnitClass("player")
        local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        accent = c and { c.r, c.g, c.b } or { 0.9, 0.9, 0.9 }
    else
        accent = a
    end
end

function St.ApplyTheme(key)
    theme = THEME_BY_KEY[key] or St.THEMES[1]
    St.theme = theme
    St.PANEL, St.INSET, St.BTN = theme.panel, theme.inset, theme.btn
    fontPath = STANDARD_TEXT_FONT
    if theme.font == "eui" then
        local eui = _G.EllesmereUI
        if eui and eui.GetFontPath then
            local ok, path = pcall(eui.GetFontPath)
            if ok and type(path) == "string" and path ~= "" then fontPath = path end
        end
    elseif theme.font == "expressway" then
        -- EllesmereUI's Expressway; St.Text falls back to the game font if it's missing.
        local eui = _G.EllesmereUI
        fontPath = (eui and eui.EXPRESSWAY) or "Interface\\AddOns\\EllesmereUI\\media\\fonts\\Expressway.TTF"
    end
    St.RefreshAccent()
end

function St.AccentHex()
    return format("|cff%02x%02x%02x", floor(accent[1] * 255 + 0.5), floor(accent[2] * 255 + 0.5), floor(accent[3] * 255 + 0.5))
end

function St.Accent()
    return accent[1], accent[2], accent[3]
end

function St.FontPath()
    return fontPath
end

-- The style's line colour at a given strength (white-alpha, gold, black...).
function St.Line(a)
    local c = theme.line
    return c[1], c[2], c[3], min(1, (a or St.BORDER_A) * theme.lineMul)
end

function St.SectionColor()
    local c = theme.section
    if c then return c[1], c[2], c[3], c[4] end
    return 1, 1, 1, St.SECTION
end

local function Pixel(region, w, h)
    if PixelUtil then
        if w then PixelUtil.SetWidth(region, w) end
        if h then PixelUtil.SetHeight(region, h) end
    else
        if w then region:SetWidth(w) end
        if h then region:SetHeight(h) end
    end
end

function St.Text(parent, size, justify, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    local flags = theme.outline or ""
    if not fs:SetFont(fontPath, size or 11, flags) then
        fs:SetFont(STANDARD_TEXT_FONT, size or 11, flags)
    end
    fs:SetShadowColor(0, 0, 0, theme.outline and 0 or 0.9)
    fs:SetShadowOffset(1, -1)
    fs:SetJustifyH(justify or "LEFT")
    fs:SetJustifyV("MIDDLE")
    fs:SetWordWrap(false)
    fs:SetTextColor(1, 1, 1, 1)
    return fs
end

function St.Fill(parent, color, layer, sub)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sub or 0)
    t:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    return t
end

-- 1px border made of four textures; :SetBorderColor(r, g, b, a) recolours it.
function St.Border(frame, a, r, g, b)
    local edges = {}
    local lr, lg, lb, la = St.Line(a)
    if r then lr, lg, lb, la = r, g, b, a or St.BORDER_A end
    local function Edge()
        local t = frame:CreateTexture(nil, "BORDER", nil, 7)
        t:SetColorTexture(lr, lg, lb, la)
        if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false); t:SetTexelSnappingBias(0) end
        edges[#edges + 1] = t
        return t
    end
    local top, bottom, left, right = Edge(), Edge(), Edge(), Edge()
    top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); Pixel(top, nil, 1)
    bottom:SetPoint("BOTTOMLEFT"); bottom:SetPoint("BOTTOMRIGHT"); Pixel(bottom, nil, 1)
    left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT"); Pixel(left, 1, nil)
    right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT"); Pixel(right, 1, nil)
    frame.SetBorderColor = function(_, nr, ng, nb, na)
        for _, t in ipairs(edges) do t:SetColorTexture(nr, ng, nb, na) end
    end
    return edges
end

-- A movable top-level window with title bar and close button.
function St.Window(name, w, h, title, posKey)
    local classic = theme.frame == "blizzard" and BackdropTemplateMixin
    local f = CreateFrame("Frame", name, UIParent, classic and "BackdropTemplate" or nil)
    f:SetSize(w, h)
    f:SetFrameStrata("MEDIUM")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    if classic then
        -- Blizzard's own frame: tooltip border, dark parchment-less background.
        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetBackdropColor(St.PANEL[1], St.PANEL[2], St.PANEL[3], St.PANEL[4])
        f:SetBackdropBorderColor(0.8, 0.65, 0.3, 1)
    else
        f.bg = St.Fill(f, St.PANEL)
        f.bg:SetAllPoints()
        St.Border(f, 0.12)
    end

    local bar = CreateFrame("Frame", nil, f)
    bar:SetPoint("TOPLEFT"); bar:SetPoint("TOPRIGHT"); bar:SetHeight(28)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function() f:StartMoving() end)
    bar:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local point, _, relPoint, x, y = f:GetPoint()
        ns.db.pos[posKey] = { point, relPoint, x, y }
    end)
    f.bar = bar
    if theme.titleBar then
        -- Darkened title bar with a thin accent line underneath (Nibbelz style).
        local shade = St.Fill(bar, { 0, 0, 0, 0.35 })
        shade:SetAllPoints()
        local r, g, b = St.Accent()
        local line = St.Fill(bar, { r, g, b, 0.9 }, "ARTWORK")
        line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT"); Pixel(line, nil, 1)
    else
        local lr, lg, lb, la = St.Line(0.06)
        local line = St.Fill(bar, { lr, lg, lb, la }, "BORDER")
        line:SetPoint("BOTTOMLEFT", 1, 0); line:SetPoint("BOTTOMRIGHT", -1, 0); Pixel(line, nil, 1)
    end

    f.title = St.Text(bar, theme.titleBar and 14 or 13)
    f.title:SetPoint("LEFT", 10, 0)
    if theme.titleBar then
        f.title:SetText("NIBBELZ " .. St.AccentHex() .. title .. "|r")
    else
        f.title:SetText(title)
    end
    if theme.title then f.title:SetTextColor(theme.title[1], theme.title[2], theme.title[3]) end

    if classic and UIPanelCloseButton then
        f.close = CreateFrame("Button", nil, bar, "UIPanelCloseButton")
        f.close:SetSize(24, 24)
        f.close:SetPoint("RIGHT", -2, 0)
    elseif theme.closeX then
        -- A plain "x" that turns red on hover.
        f.close = CreateFrame("Button", nil, bar)
        f.close:SetSize(28, 28)
        f.close:SetPoint("RIGHT")
        local x = St.Text(f.close, 16, "CENTER")
        x:SetPoint("CENTER")
        x:SetText("x")
        x:SetTextColor(1, 1, 1, 0.6)
        f.close:SetScript("OnEnter", function() x:SetTextColor(1, 0.3, 0.3, 1) end)
        f.close:SetScript("OnLeave", function() x:SetTextColor(1, 1, 1, 0.6) end)
    else
        f.close = St.CloseButton(bar)
        f.close:SetPoint("RIGHT", -6, 0)
    end
    f.close:SetScript("OnClick", function() f:Hide() end)

    f.Place = function(self, default)
        local p = ns.db.pos[posKey]
        self:ClearAllPoints()
        if type(p) == "table" and p[1] then
            self:SetPoint(p[1], UIParent, p[2], p[3], p[4])
        else
            self:SetPoint(unpack(default))
        end
    end
    return f
end

function St.CloseButton(parent)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(18, 18)
    local lines = {}
    for i = 1, 2 do
        local l = b:CreateLine(nil, "OVERLAY")
        l:SetThickness(1.5)
        l:SetColorTexture(1, 1, 1, 0.5)
        lines[i] = l
    end
    lines[1]:SetStartPoint("TOPLEFT", b, 5, -5); lines[1]:SetEndPoint("BOTTOMRIGHT", b, -5, 5)
    lines[2]:SetStartPoint("TOPRIGHT", b, -5, -5); lines[2]:SetEndPoint("BOTTOMLEFT", b, 5, 5)
    b:SetScript("OnEnter", function()
        local r, g, bb = St.Accent()
        for _, l in ipairs(lines) do l:SetColorTexture(r, g, bb, 1) end
    end)
    b:SetScript("OnLeave", function()
        for _, l in ipairs(lines) do l:SetColorTexture(1, 1, 1, 0.5) end
    end)
    return b
end

-- EllesmereUI button: dark fill, white-alpha border and text; active = accent fill, dark text.
-- Blizzard's red panel button (Classic style): up / down art, gold text, white on hover.
local function BlizzardButton(b)
    local coords = { 0, 0.625, 0, 0.6875 }
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.bg:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    b.bg:SetTexCoord(unpack(coords))
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    hl:SetTexCoord(unpack(coords))
    hl:SetBlendMode("ADD")
    b.SetBorderColor = function() end
    function b:Paint()
        local hover = self:IsMouseOver()
        if self.active then
            self.bg:SetTexture("Interface\\Buttons\\UI-Panel-Button-Down")
            self.text:SetTextColor(1, 1, 1, 1)
        else
            self.bg:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
            if self.danger then
                self.text:SetTextColor(1, 0.4, 0.35, 1)
            elseif hover then
                self.text:SetTextColor(1, 1, 1, 1)
            else
                self.text:SetTextColor(1, 0.82, 0, 1)
            end
        end
        self.bg:SetTexCoord(unpack(coords))
    end
end

function St.Button(parent, label, w, h, onClick, template)
    local b = CreateFrame("Button", nil, parent, template)
    b:SetSize(w, h or 20)
    b.text = St.Text(b, 11, "CENTER")
    b.text:SetPoint("CENTER", 0, 0)
    b.text:SetText(label)
    b.active = false
    function b:SetActive(on)
        self.active = on and true or false
        self:Paint()
    end
    if theme.button == "blizzard" then
        BlizzardButton(b)
        b:SetScript("OnEnter", b.Paint)
        b:SetScript("OnLeave", b.Paint)
        if onClick then b:SetScript("OnClick", onClick) end
        b:Paint()
        return b
    end
    if theme.button == "flat" then
        -- Nibbelz style: faint white fill, thin white edge that turns accent on hover;
        -- the selected one gets an accent tint and a 2px accent underline (like its tabs).
        b.bg = St.Fill(b, St.BTN)
        b.bg:SetAllPoints()
        St.Border(b, 0.15)
        b.under = St.Fill(b, { 0, 0, 0, 0 }, "ARTWORK")
        b.under:SetPoint("BOTTOMLEFT"); b.under:SetPoint("BOTTOMRIGHT"); b.under:SetHeight(2)
        function b:Paint()
            local r, g, bl = St.Accent()
            local hover = self:IsMouseOver()
            if self.active then
                self.bg:SetColorTexture(r, g, bl, 0.16)
                self:SetBorderColor(r, g, bl, 0.8)
                self.under:SetColorTexture(r, g, bl, 1)
                self.text:SetTextColor(1, 1, 1, 1)
            else
                self.bg:SetColorTexture(1, 1, 1, hover and 0.09 or 0.06)
                self.under:SetColorTexture(0, 0, 0, 0)
                if self.danger then
                    self:SetBorderColor(0.95, 0.3, 0.28, hover and 0.8 or 0.4)
                    self.text:SetTextColor(1, 0.4, 0.35, 1)
                elseif hover then
                    self:SetBorderColor(r, g, bl, 0.8)
                    self.text:SetTextColor(1, 1, 1, 1)
                else
                    self:SetBorderColor(1, 1, 1, 0.15)
                    self.text:SetTextColor(1, 1, 1, 0.9)
                end
            end
        end
        b:SetScript("OnEnter", b.Paint)
        b:SetScript("OnLeave", b.Paint)
        if onClick then b:SetScript("OnClick", onClick) end
        b:Paint()
        return b
    end
    b.bg = St.Fill(b, St.BTN)
    b.bg:SetAllPoints()
    St.Border(b, 0.3)
    function b:Paint()
        local r, g, bl = St.Accent()
        if self.active then
            self.bg:SetColorTexture(r, g, bl, 0.9)
            self:SetBorderColor(r, g, bl, 1)
            self.text:SetTextColor(0.06, 0.05, 0.04, 1)
            self.text:SetShadowOffset(0, 0)
        else
            local hover = self:IsMouseOver()
            self.bg:SetColorTexture(St.BTN[1], St.BTN[2], St.BTN[3], hover and 0.65 or 0.6)
            if self.danger then
                self:SetBorderColor(0.95, 0.3, 0.28, hover and 0.6 or 0.35)
                self.text:SetTextColor(0.95, 0.35, 0.3, hover and 1 or 0.8)
            else
                self:SetBorderColor(St.Line(hover and 0.45 or 0.3))
                self.text:SetTextColor(1, 1, 1, hover and 0.85 or 0.6)
            end
            self.text:SetShadowOffset(1, -1)
        end
    end
    function b:SetActive(on)
        self.active = on and true or false
        self:Paint()
    end
    b:SetScript("OnEnter", b.Paint)
    b:SetScript("OnLeave", b.Paint)
    if onClick then b:SetScript("OnClick", onClick) end
    b:Paint()
    return b
end

-- Item icon with a 1px quality-coloured border.
function St.Icon(parent, size)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(size, size)
    local bg = St.Fill(f, { 0, 0, 0, 0.6 })
    bg:SetAllPoints()
    f.tex = f:CreateTexture(nil, "ARTWORK")
    f.tex:SetPoint("TOPLEFT", 1, -1)
    f.tex:SetPoint("BOTTOMRIGHT", -1, 1)
    f.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    St.Border(f, 0.8)
    function f:SetItem(icon, quality)
        self.tex:SetTexture(icon or 134400)
        local r, g, b = ns.QualityColor(quality)
        self:SetBorderColor(r, g, b, 0.9)
    end
    return f
end

-- Search box.
function St.Search(parent, w, h, placeholder, onChange)
    local e = CreateFrame("EditBox", nil, parent)
    e:SetSize(w, h or 20)
    e:SetAutoFocus(false)
    e:SetFont(St.FontPath(), 11, "")
    e:SetTextInsets(6, 6, 0, 0)
    e:SetTextColor(1, 1, 1, 0.9)
    local bg = St.Fill(e, { 0, 0, 0, 0.35 })
    bg:SetAllPoints()
    St.Border(e, 0.15)
    local hint = St.Text(e, 11)
    hint:SetPoint("LEFT", 7, 0)
    hint:SetText(placeholder)
    hint:SetTextColor(1, 1, 1, 0.3)
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEditFocusGained", function(self) self:SetBorderColor(St.Accent()); end)
    e:SetScript("OnEditFocusLost", function(self) self:SetBorderColor(St.Line(0.15)) end)
    e:SetScript("OnTextChanged", function(self)
        local text = self:GetText() or ""
        hint:SetShown(text == "")
        if onChange then onChange(text) end
    end)
    return e
end

-------------------------------------------------------------------------------
--  Virtual list: a few row frames, data scrolled through them.
--  Each data item may carry its own height (item.h).
-------------------------------------------------------------------------------
function St.List(parent, rowH, make, fill)
    local l = CreateFrame("Frame", nil, parent)
    l.rows, l.data, l.offset = {}, {}, 0
    l:EnableMouseWheel(true)

    local track = St.Fill(l, { 1, 1, 1, 0.04 }, "ARTWORK")
    track:SetPoint("TOPRIGHT"); track:SetPoint("BOTTOMRIGHT"); track:SetWidth(3)
    local thumb = l:CreateTexture(nil, "OVERLAY")
    thumb:SetWidth(3)
    l.track, l.thumb = track, thumb

    local function H(item) return item.h or rowH end

    function l:MaxOffset()
        local height, y = self:GetHeight(), 0
        for i = #self.data, 1, -1 do
            y = y + H(self.data[i])
            if y > height then return i end
        end
        return 0
    end

    function l:Scroll(delta)
        self.offset = max(0, min(self:MaxOffset(), self.offset + delta))
        self:Refresh()
    end

    function l:SetData(data, keepOffset)
        self.data = data
        if not keepOffset then self.offset = 0 end
        self:Scroll(0)
    end

    function l:Refresh()
        local height = self:GetHeight()
        if height <= 0 then return end
        local maxOffset = self:MaxOffset()
        local scrollable = maxOffset > 0
        local right = scrollable and -7 or 0
        local y, used = 0, 0
        local idx = self.offset + 1
        while self.data[idx] and y < height - 1 do
            used = used + 1
            local row = self.rows[used]
            if not row then
                row = make(self)
                self.rows[used] = row
            end
            local item = self.data[idx]
            local h = H(item)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -y)
            row:SetPoint("TOPRIGHT", right, -y)
            row:SetHeight(h)
            row.item, row.index = item, idx
            fill(row, item, idx)
            row:Show()
            y = y + h
            idx = idx + 1
        end
        for i = used + 1, #self.rows do
            self.rows[i]:Hide()
            self.rows[i].item = nil
        end
        if scrollable then
            local r, g, b = St.Accent()
            thumb:SetColorTexture(r, g, b, 0.7)
            local total = #self.data
            local th = max(18, height * (total - maxOffset) / total)
            thumb:SetHeight(th)
            thumb:ClearAllPoints()
            thumb:SetPoint("TOPRIGHT", 0, -(height - th) * self.offset / maxOffset)
            track:Show(); thumb:Show()
        else
            track:Hide(); thumb:Hide()
        end
    end

    l:SetScript("OnMouseWheel", function(self, delta) self:Scroll(-delta * 3) end)
    l:SetScript("OnSizeChanged", function(self) self:Scroll(0) end)
    return l
end

-- A hover/selection background for list rows.
function St.RowBackground(row)
    row.hl = St.Fill(row, { 1, 1, 1, 0 }, "BACKGROUND", 1)
    row.hl:SetAllPoints()
    row.bar = St.Fill(row, { 1, 1, 1, 0 }, "ARTWORK", 1)
    row.bar:SetPoint("TOPLEFT"); row.bar:SetPoint("BOTTOMLEFT"); row.bar:SetWidth(2)
    function row:PaintState(selected)
        local r, g, b = St.Accent()
        if selected then
            self.hl:SetColorTexture(r, g, b, 0.14)
            self.bar:SetColorTexture(r, g, b, 1)
        elseif self:IsMouseOver() then
            self.hl:SetColorTexture(1, 1, 1, 0.05)
            self.bar:SetColorTexture(0, 0, 0, 0)
        else
            self.hl:SetColorTexture(0, 0, 0, 0)
            self.bar:SetColorTexture(0, 0, 0, 0)
        end
    end
end

-- Small icon button (gear etc.): dim white, accent on hover.
function St.IconButton(parent, texture, size, tooltip, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size, size)
    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetAllPoints()
    b.tex:SetTexture(texture)
    b.tex:SetDesaturated(true)
    b.tex:SetVertexColor(1, 1, 1, 0.6)
    b:SetScript("OnEnter", function(self)
        local r, g, bl = St.Accent()
        self.tex:SetVertexColor(r, g, bl, 1)
        if tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(tooltip, 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self)
        self.tex:SetVertexColor(1, 1, 1, 0.6)
        GameTooltip:Hide()
    end)
    if onClick then b:SetScript("OnClick", onClick) end
    return b
end

-- Checkbox: dark box with white-alpha border, accent square when on; the label clicks too.
function St.Checkbox(parent, label, onChange)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(22)
    b.box = CreateFrame("Frame", nil, b)
    b.box:SetSize(16, 16)
    b.box:SetPoint("LEFT", 0, 0)
    local bg = St.Fill(b.box, { 0, 0, 0, 0.35 })
    bg:SetAllPoints()
    St.Border(b.box, 0.3)
    b.mark = b.box:CreateTexture(nil, "ARTWORK")
    b.mark:SetPoint("TOPLEFT", 3, -3)
    b.mark:SetPoint("BOTTOMRIGHT", -3, 3)
    b.text = St.Text(b, 11)
    b.text:SetPoint("LEFT", b.box, "RIGHT", 8, 0)
    b.text:SetPoint("RIGHT", b, "RIGHT", 0, 0)
    b.text:SetText(label)
    if theme.check == "toggle" then
        -- A switch: track turns accent when on, the knob slides right (Nibbelz style).
        b.box:SetSize(30, 16)
        b.box:SetBorderColor(0, 0, 0, 0)
        b.mark:ClearAllPoints()
        b.mark:SetSize(12, 12)
        function b:Paint()
            local r, g, bl = St.Accent()
            local hover = self:IsMouseOver()
            if self.checked then
                bg:SetColorTexture(r, g, bl, 0.9)
            else
                bg:SetColorTexture(1, 1, 1, hover and 0.22 or 0.15)
            end
            self.mark:SetColorTexture(1, 1, 1, 1)
            self.mark:Show()
            self.mark:ClearAllPoints()
            self.mark:SetPoint(self.checked and "RIGHT" or "LEFT", self.checked and -2 or 2, 0)
            self.text:SetTextColor(1, 1, 1, hover and 1 or 0.85)
        end
    else
        function b:Paint()
            local r, g, bl = St.Accent()
            local hover = self:IsMouseOver()
            self.mark:SetColorTexture(r, g, bl, 1)
            self.mark:SetShown(self.checked)
            if self.checked then
                self.box:SetBorderColor(r, g, bl, 0.9)
            else
                self.box:SetBorderColor(St.Line(hover and 0.5 or 0.3))
            end
            self.text:SetTextColor(1, 1, 1, hover and 1 or 0.8)
        end
    end
    function b:SetChecked(on)
        self.checked = on and true or false
        self:Paint()
    end
    b:SetScript("OnClick", function(self)
        self:SetChecked(not self.checked)
        if onChange then onChange(self.checked) end
    end)
    b:SetScript("OnEnter", b.Paint)
    b:SetScript("OnLeave", b.Paint)
    b.checked = false
    b:Paint()
    return b
end

-- Slider: label left, value right, thin track with accent fill and thumb.
function St.Slider(parent, label, minV, maxV, step, fmt, onChange)
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(38)
    f.label = St.Text(f, 11)
    f.label:SetPoint("TOPLEFT", 0, 0)
    f.label:SetText(label)
    f.label:SetTextColor(1, 1, 1, 0.8)
    f.value = St.Text(f, 11, "RIGHT")
    f.value:SetPoint("TOPRIGHT", 0, 0)

    local s = CreateFrame("Slider", nil, f)
    s:SetOrientation("HORIZONTAL")
    s:SetPoint("TOPLEFT", 0, -18)
    s:SetPoint("TOPRIGHT", 0, -18)
    s:SetHeight(16)
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step)
    if s.SetObeyStepDuringDrag then s:SetObeyStepDuringDrag(true) end
    s:EnableMouseWheel(false)
    local track = St.Fill(s, { 1, 1, 1, 0.1 })
    track:SetPoint("LEFT"); track:SetPoint("RIGHT"); track:SetHeight(4)
    local fill = s:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT")
    fill:SetHeight(4)
    local thumb = s:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(8, 16)
    thumb:SetColorTexture(1, 1, 1, 1)
    s:SetThumbTexture(thumb)
    f.slider = s

    function f:Update(v)
        self.value:SetText(fmt(v))
        local r, g, b = St.Accent()
        fill:SetColorTexture(r, g, b, 0.8)
        thumb:SetColorTexture(r, g, b, 1)
        local w = s:GetWidth()
        if w > 0 then fill:SetWidth(max(1, w * (v - minV) / (maxV - minV))) end
    end
    function f:SetValue(v)
        s:SetValue(v)
        self:Update(v)
    end
    s:SetScript("OnValueChanged", function(_, v, userInput)
        v = floor(v / step + 0.5) * step
        f:Update(v)
        if userInput and onChange then onChange(v) end
    end)
    s:SetScript("OnSizeChanged", function() f:Update(s:GetValue()) end)
    return f
end

-- A yes / no question in the addon's own style (Blizzard's popups get reskinned
-- or taken over by other addons). St.Confirm(text, onYes)
local confirm
function St.Confirm(text, onYes)
    if not confirm then
        confirm = CreateFrame("Frame", "NibbelzStockConfirm", UIParent)
        confirm:SetSize(360, 130)
        confirm:SetPoint("CENTER", 0, 120)
        confirm:SetFrameStrata("FULLSCREEN_DIALOG")
        confirm:EnableMouse(true)
        confirm:SetToplevel(true)
        local bg = St.Fill(confirm, St.PANEL)
        bg:SetAllPoints()
        St.Border(confirm, 0.25)
        confirm.text = St.Text(confirm, 12, "CENTER")
        confirm.text:SetPoint("TOPLEFT", 16, -18)
        confirm.text:SetPoint("TOPRIGHT", -16, -18)
        confirm.text:SetWordWrap(true)
        confirm.yes = St.Button(confirm, YES or "Yes", 140, 26, function()
            confirm:Hide()
            if confirm.onYes then confirm.onYes() end
        end)
        confirm.yes.danger = true
        confirm.yes:Paint()
        confirm.yes:SetPoint("BOTTOMLEFT", 16, 14)
        confirm.no = St.Button(confirm, NO or "No", 140, 26, function() confirm:Hide() end)
        confirm.no:SetPoint("BOTTOMRIGHT", -16, 14)
        confirm:Hide()
        tinsert(UISpecialFrames, "NibbelzStockConfirm")
    end
    confirm.text:SetText(text)
    confirm.onYes = onYes
    confirm:Show()
    confirm:Raise()
end

-- "Reload now?" -- ReloadUI() is protected for addons, so the button is a secure
-- action button running /reload: it reloads on the player's own click.
local reloadPrompt
function St.ReloadPrompt(text)
    if InCombatLockdown() then
        ns.Print(ns.L["Type /reload after combat to use the new style."])
        return
    end
    if not reloadPrompt then
        reloadPrompt = CreateFrame("Frame", "NibbelzStockReloadPrompt", UIParent)
        reloadPrompt:SetSize(380, 130)
        reloadPrompt:SetPoint("CENTER", 0, 120)
        reloadPrompt:SetFrameStrata("FULLSCREEN_DIALOG")
        reloadPrompt:EnableMouse(true)
        reloadPrompt:SetToplevel(true)
        local bg = St.Fill(reloadPrompt, St.PANEL)
        bg:SetAllPoints()
        St.Border(reloadPrompt, 0.25)
        reloadPrompt.text = St.Text(reloadPrompt, 12, "CENTER")
        reloadPrompt.text:SetPoint("TOPLEFT", 16, -18)
        reloadPrompt.text:SetPoint("TOPRIGHT", -16, -18)
        reloadPrompt.text:SetWordWrap(true)
        -- No OnClick of our own: that would replace the secure click handler.
        local yes = St.Button(reloadPrompt, ns.L["Reload now"], 160, 26, nil, "SecureActionButtonTemplate")
        yes:RegisterForClicks("AnyUp", "AnyDown")
        yes:SetAttribute("type", "macro")
        yes:SetAttribute("macrotext", "/reload")
        yes:SetActive(true)
        yes:SetPoint("BOTTOMLEFT", 16, 14)
        local later = St.Button(reloadPrompt, ns.L["Later"], 160, 26, function() reloadPrompt:Hide() end)
        later:SetPoint("BOTTOMRIGHT", -16, 14)
        reloadPrompt:Hide()
        tinsert(UISpecialFrames, "NibbelzStockReloadPrompt")
    end
    reloadPrompt.text:SetText(text)
    reloadPrompt:Show()
    reloadPrompt:Raise()
end

-- A small right-click menu at the cursor. items = { { text, func, danger }, ... }
local menu, menuBlocker
-- items = { { text, func, danger, selected }, ... }; anchor = drop below this frame
-- (a dropdown), else at the cursor (a right-click menu).
function St.ContextMenu(items, anchor)
    if not menu then
        menuBlocker = CreateFrame("Button", nil, UIParent)
        menuBlocker:SetAllPoints(UIParent)
        menuBlocker:SetFrameStrata("FULLSCREEN")
        menuBlocker:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        menuBlocker:SetScript("OnClick", function() menu:Hide(); menuBlocker:Hide() end)
        menu = CreateFrame("Frame", nil, UIParent)
        menu:SetFrameStrata("FULLSCREEN_DIALOG")
        local bg = St.Fill(menu, { St.PANEL[1], St.PANEL[2], St.PANEL[3], 0.98 })
        bg:SetAllPoints()
        St.Border(menu, 0.2)
        menu.buttons = {}
    end
    for i, item in ipairs(items) do
        local b = menu.buttons[i]
        if not b then
            b = CreateFrame("Button", nil, menu)
            b:SetHeight(20)
            b.hl = St.Fill(b, { 1, 1, 1, 0 })
            b.hl:SetAllPoints()
            b.text = St.Text(b, 11)
            b.text:SetPoint("LEFT", 10, 0)
            b:SetScript("OnEnter", function(self) self.hl:SetColorTexture(1, 1, 1, 0.08) end)
            b:SetScript("OnLeave", function(self) self.hl:SetColorTexture(1, 1, 1, 0) end)
            menu.buttons[i] = b
        end
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", 2, -2 - (i - 1) * 20)
        b:SetPoint("TOPRIGHT", -2, -2 - (i - 1) * 20)
        b.text:SetText(item[1])
        if item[3] then
            b.text:SetTextColor(0.95, 0.35, 0.3)
        elseif item[4] then
            b.text:SetTextColor(St.Accent())   -- the current choice
        else
            b.text:SetTextColor(1, 1, 1)
        end
        b:SetScript("OnClick", function()
            menu:Hide()
            menuBlocker:Hide()
            item[2]()
        end)
        b:Show()
    end
    for i = #items + 1, #menu.buttons do menu.buttons[i]:Hide() end
    menu:ClearAllPoints()
    if anchor then
        menu:SetScale(anchor:GetEffectiveScale() / UIParent:GetEffectiveScale())
        menu:SetSize(max(180, anchor:GetWidth()), #items * 20 + 4)
        menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    else
        menu:SetScale(1)
        menu:SetSize(180, #items * 20 + 4)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    end
    menuBlocker:Show()
    menu:Show()
end

-- A dropdown: a button showing the current choice and a "v"; a click opens the list.
-- getText() = the button's text, getItems() = the St.ContextMenu items.
function St.Dropdown(parent, w, h, getText, getItems)
    local b
    b = St.Button(parent, "", w, h, function() St.ContextMenu(getItems(), b) end)
    b.text:ClearAllPoints()
    b.text:SetPoint("LEFT", 8, 0)
    b.text:SetPoint("RIGHT", -18, 0)
    b.text:SetJustifyH("LEFT")
    local arrow = St.Text(b, 11, "RIGHT")
    arrow:SetPoint("RIGHT", -7, 0)
    arrow:SetText("v")
    arrow:SetTextColor(1, 1, 1, 0.5)
    function b:Update()
        self.text:SetText(getText())
    end
    b:Update()
    return b
end

-- Section title (EllesmereUI: small, uppercase-ish, dim).
function St.Section(parent, text)
    local fs = St.Text(parent, 10)
    fs:SetText(text)
    fs:SetTextColor(St.SectionColor())
    return fs
end
