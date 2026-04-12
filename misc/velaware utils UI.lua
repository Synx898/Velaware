-- ================================================
--   VELAWARE UI LIBRARY
--   loadstring this, then call VelaUI:AddToggle etc
-- ================================================

local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local TweenService     = game:GetService("TweenService")

-- ── Theme ─────────────────────────────────────────
local T = {
    BG       = Color3.fromRGB(15, 18, 28),
    TitleBG  = Color3.fromRGB(25, 30, 48),
    Accent   = Color3.fromRGB(54, 147, 227),
    BtnOff   = Color3.fromRGB(35, 38, 55),
    BtnOn    = Color3.fromRGB(54, 147, 227),
    TextOff  = Color3.fromRGB(140, 150, 175),
    TextOn   = Color3.fromRGB(255, 255, 255),
    Divider  = Color3.fromRGB(80, 100, 140),
    StatusTx = Color3.fromRGB(150, 150, 180),
    MinBtn   = Color3.fromRGB(40, 45, 65),
    Corner   = 10,
    BtnH     = 30,
    Pad      = 6,
    TitleH   = 32,
    Width    = 220,
    Font     = Enum.Font.GothamSemibold,
    FontBold = Enum.Font.GothamBold,
}

-- ── Internal helpers ──────────────────────────────
local function corner(parent, r)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, r or T.Corner)
    return c
end

local function padding(parent, left, right, top, bottom)
    local p = Instance.new("UIPadding", parent)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    return p
end

-- ── VelaUI object ─────────────────────────────────
local VelaUI = {}
VelaUI.__index = VelaUI

function VelaUI.new(title, keybind)
    local self = setmetatable({}, VelaUI)

    self._items     = {}  -- ordered list of items
    self._minimized = false
    self._visible   = true
    self._keybind   = keybind or Enum.KeyCode.RightShift
    self._curY      = T.Pad   -- current Y offset inside content

    -- ScreenGui
    self._gui = Instance.new("ScreenGui")
    self._gui.Name           = "VelaUI_" .. title:gsub("%s", "")
    self._gui.ResetOnSpawn   = false
    self._gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self._gui.Parent         = CoreGui

    -- Outer frame (resizes on minimize)
    self._frame = Instance.new("Frame")
    self._frame.BackgroundColor3 = T.BG
    self._frame.BorderSizePixel  = 0
    self._frame.Active    = true
    self._frame.Draggable = true
    self._frame.Parent    = self._gui
    corner(self._frame)
    local sk = Instance.new("UIStroke", self._frame)
    sk.Color     = T.Accent
    sk.Thickness = 1.5

    -- Title bar
    self._titleBar = Instance.new("Frame")
    self._titleBar.Size             = UDim2.new(1, 0, 0, T.TitleH)
    self._titleBar.BackgroundColor3 = T.TitleBG
    self._titleBar.BorderSizePixel  = 0
    self._titleBar.Parent           = self._frame
    corner(self._titleBar)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size               = UDim2.new(1, -38, 1, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text               = "⚡ " .. title
    titleLbl.TextColor3         = T.Accent
    titleLbl.TextSize           = 13
    titleLbl.Font               = T.FontBold
    titleLbl.TextXAlignment     = Enum.TextXAlignment.Center
    titleLbl.Parent             = self._titleBar

    -- Minimize button
    self._minBtn = Instance.new("TextButton")
    self._minBtn.Size             = UDim2.new(0, 26, 0, 22)
    self._minBtn.Position         = UDim2.new(1, -30, 0.5, -11)
    self._minBtn.BackgroundColor3 = T.MinBtn
    self._minBtn.BorderSizePixel  = 0
    self._minBtn.Text             = "−"
    self._minBtn.TextColor3       = Color3.fromRGB(180, 190, 220)
    self._minBtn.TextSize         = 14
    self._minBtn.Font             = T.FontBold
    self._minBtn.Parent           = self._titleBar
    corner(self._minBtn, 5)

    self._minBtn.MouseButton1Click:Connect(function()
        self:_toggleMinimize()
    end)

    -- Content frame
    self._content = Instance.new("Frame")
    self._content.BackgroundTransparency = 1
    self._content.BorderSizePixel        = 0
    self._content.Parent                 = self._frame

    -- Keybind
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == self._keybind then
            self._frame.Visible = not self._frame.Visible
        end
    end)

    -- Initial layout (no items yet)
    self:_relayout()

    return self
end

function VelaUI:_relayout()
    local contentH = self._curY
    local totalH   = T.TitleH + contentH

    self._frame.Size     = UDim2.new(0, T.Width, 0, self._minimized and T.TitleH or totalH)
    self._content.Size   = UDim2.new(1, 0, 0, contentH)
    self._content.Position = UDim2.new(0, 0, 0, T.TitleH)

    -- Centre on screen if not already positioned
    if self._frame.Position == UDim2.new(0, 0, 0, 0) then
        self._frame.Position = UDim2.new(0, 20, 0.5, -totalH / 2)
    end
end

function VelaUI:_toggleMinimize()
    self._minimized = not self._minimized
    self._content.Visible = not self._minimized
    self._minBtn.Text     = self._minimized and "+" or "−"

    local contentH = self._curY
    local totalH   = T.TitleH + contentH
    self._frame.Size = UDim2.new(0, T.Width, 0, self._minimized and T.TitleH or totalH)
end

-- ── Public API ────────────────────────────────────

--- Add a toggle button
--- @param label string
--- @param callback function(bool)
--- @return table { SetState = function(bool) }
function VelaUI:AddToggle(label, callback)
    local active = false
    local y = self._curY

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, T.Width - 16, 0, T.BtnH)
    btn.Position         = UDim2.new(0, 8, 0, y)
    btn.BackgroundColor3 = T.BtnOff
    btn.BorderSizePixel  = 0
    btn.Text             = "○  " .. label
    btn.TextColor3       = T.TextOff
    btn.TextSize         = 12
    btn.Font             = T.Font
    btn.TextXAlignment   = Enum.TextXAlignment.Left
    btn.Parent           = self._content
    corner(btn, 6)
    padding(btn, 10)

    local function setState(val)
        active               = val
        btn.BackgroundColor3 = active and T.BtnOn  or T.BtnOff
        btn.TextColor3       = active and T.TextOn or T.TextOff
        btn.Text             = (active and "◉  " or "○  ") .. label
        pcall(callback, active)
    end

    btn.MouseButton1Click:Connect(function()
        setState(not active)
    end)

    self._curY += T.BtnH + T.Pad
    self:_relayout()

    local handle = { SetState = setState, Button = btn }
    table.insert(self._items, handle)
    return handle
end

--- Add a label / divider line
--- @param text string
--- @param color Color3?
function VelaUI:AddLabel(text, color)
    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(0, T.Width - 16, 0, 16)
    lbl.Position           = UDim2.new(0, 8, 0, self._curY)
    lbl.BackgroundTransparency = 1
    lbl.Text               = text
    lbl.TextColor3         = color or T.Divider
    lbl.TextSize           = 11
    lbl.Font               = Enum.Font.Gotham
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Parent             = self._content

    self._curY += 16 + T.Pad
    self:_relayout()
end

--- Add a status label that can be updated
--- @param defaultText string
--- @return function(text, color?) updater
function VelaUI:AddStatus(defaultText)
    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(0, T.Width - 16, 0, 18)
    lbl.Position           = UDim2.new(0, 8, 0, self._curY)
    lbl.BackgroundTransparency = 1
    lbl.Text               = defaultText or ""
    lbl.TextColor3         = T.StatusTx
    lbl.TextSize           = 11
    lbl.Font               = Enum.Font.Gotham
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Parent             = self._content

    self._curY += 18 + T.Pad
    self:_relayout()

    return function(txt, col)
        lbl.Text       = txt
        lbl.TextColor3 = col or T.StatusTx
    end
end

--- Add a plain action button (not a toggle)
--- @param label string
--- @param callback function
function VelaUI:AddButton(label, callback)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, T.Width - 16, 0, T.BtnH)
    btn.Position         = UDim2.new(0, 8, 0, self._curY)
    btn.BackgroundColor3 = T.Accent
    btn.BorderSizePixel  = 0
    btn.Text             = label
    btn.TextColor3       = T.TextOn
    btn.TextSize         = 12
    btn.Font             = T.FontBold
    btn.TextXAlignment   = Enum.TextXAlignment.Center
    btn.Parent           = self._content
    corner(btn, 6)

    btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)

    self._curY += T.BtnH + T.Pad
    self:_relayout()
end

--- Add a divider (styled label shorthand)
--- @param text string?
function VelaUI:AddDivider(text)
    self:AddLabel(text and ("── " .. text .. " ──") or "────────────────────")
end

--- Add vertical spacer
--- @param height number?
function VelaUI:AddSpace(height)
    self._curY += (height or T.Pad)
    self:_relayout()
end

return VelaUI
