-- Modern Roblox Script with Highlight, Fly, Walkspeed and GUI
-- TYLKO PODŚWIETLENIE (Highlight ESP) dla pojazdów Junkyard.
-- DODANO KEY SYSTEM (Poprawiono ładowanie menu i tytuł)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

-- Konfiguracja Key System
local REQUIRED_KEY = "7Key" -- <--- ZMIEŃ TEN KLUCZ NA SWÓJ WŁASNY!
local isAuthorized = false 

-- Konfiguracja Gry
local JUNKYARD_CONTAINER_NAME = "Vehicles" -- <-- Sprawdź, czy ta nazwa folderu jest POPRAWNA!

-- Configuration
local config = {
    highlight = {
        enabled = false,
        color = Color3.fromRGB(0, 255, 255),
        transparency = 0.5
    },
    fly = {
        enabled = false,
        speed = 50
    },
    walkspeed = {
        enabled = false,
        speed = 16
    },
    junkyardESP = {
        enabled = false,
        color = Color3.fromRGB(255, 100, 0), -- Nowy kolor dla ESP Junkyard
        transparency = 0.5
    },
    menuKey = Enum.KeyCode.RightControl
}

-- Variables
local highlightObjects = {}
local flyConnection = nil
local flying = false
local flySpeed = config.fly.speed
local isChangingKeybind = false
local keybindButton = nil 
local espHighlights = {} 

local KeyGui = nil
local MainGui = nil
local TitleText = nil -- Deklaracja, aby funkcja KeyGUI mogła go użyć

-- === KEY SYSTEM GUI SETUP ===

local function createKeyInputGUI()
    KeyGui = Instance.new("ScreenGui")
    KeyGui.Name = "KeyInputGUI"
    KeyGui.ResetOnSpawn = false
    KeyGui.ZIndexBehavior = Enum.ZIndexBehavior.Global 
    KeyGui.Parent = game:GetService("CoreGui")

    local KeyFrame = Instance.new("Frame")
    KeyFrame.Name = "KeyFrame"
    KeyFrame.Size = UDim2.new(0, 300, 0, 150)
    KeyFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
    KeyFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    KeyFrame.BorderSizePixel = 0
    KeyFrame.Parent = KeyGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = KeyFrame
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Text = "Enter An Key"
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.Parent = KeyFrame

    local KeyBox = Instance.new("TextBox")
    KeyBox.Name = "KeyBox"
    KeyBox.Size = UDim2.new(1, -40, 0, 30)
    KeyBox.Position = UDim2.new(0.5, -130, 0, 60)
    KeyBox.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyBox.PlaceholderText = "Wpisz klucz..."
    KeyBox.TextSize = 14
    KeyBox.Font = Enum.Font.Gotham
    KeyBox.TextEditable = true
    KeyBox.Parent = KeyFrame
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 8)
    InputCorner.Parent = KeyBox

    local SubmitButton = Instance.new("TextButton")
    SubmitButton.Size = UDim2.new(1, -40, 0, 35)
    SubmitButton.Position = UDim2.new(0.5, -130, 0, 100)
    SubmitButton.BackgroundColor3 = Color3.fromRGB(50, 120, 255)
    SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitButton.Text = "Check"
    SubmitButton.TextSize = 16
    SubmitButton.Font = Enum.Font.GothamBold
    SubmitButton.Parent = KeyFrame
    
    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 8)
    ButtonCorner.Parent = SubmitButton
    
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Size = UDim2.new(1, 0, 0, 20)
    StatusLabel.Position = UDim2.new(0, 0, 1, -20)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusLabel.Text = "Waiting for an key..."
    StatusLabel.TextSize = 12
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Parent = KeyFrame

    -- P O P R A W I O N A   F U N K C J A   C H E C K K E Y
    local function checkKey(key)
        if key == REQUIRED_KEY then
            isAuthorized = true
            StatusLabel.Text = "Key is valid! Loading..."
            wait(0.5)
            KeyGui:Destroy()
            
            -- Wymuszone otwarcie głównego menu
            if MainGui then MainGui.Enabled = true end 
            
            -- POPRAWKA: Ustawienie poprawnego tytułu
            if TitleText then TitleText.Text = "7Menu" end 
            
            print("7Menu loaded successfully! Menu: " .. config.menuKey.Name)
        else
            StatusLabel.Text = "Invialid key!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            wait(1.5)
            StatusLabel.Text = "Enter key..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            KeyBox.Text = ""
        end
    end
    -- K O N I E C   P O P R A W I O N E J   F U N K C J I

    SubmitButton.MouseButton1Click:Connect(function()
        checkKey(KeyBox.Text)
    end)
    
    KeyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            checkKey(KeyBox.Text)
        end
    end)
end

-- === GŁÓWNY GUI SETUP ===

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "7Menu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Enabled = false -- Domyślnie wyłączony, włączy się po autoryzacji

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 450, 0, 350)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 12)
TitleFix.Position = UDim2.new(0, 0, 1, -12)
TitleFix.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

TitleText = Instance.new("TextLabel") -- Użycie wcześniej zadeklarowanej zmiennej
TitleText.Size = UDim2.new(1, -20, 1, 0)
TitleText.Position = UDim2.new(0, 20, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Wating for an key..." 
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 18
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 35, 0, 35)
CloseButton.Position = UDim2.new(1, -40, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 16
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseButton

local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(0, 120, 1, -55)
TabContainer.Position = UDim2.new(0, 10, 0, 50)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -140, 1, -55)
ContentContainer.Position = UDim2.new(0, 130, 0, 50)
ContentContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
ContentContainer.BorderSizePixel = 0
ContentContainer.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 10)
ContentCorner.Parent = ContentContainer

local tabs = {}
local currentTab = nil

local function createTab(name, order)
    local tab = {}
    
    local TabButton = Instance.new("TextButton")
    TabButton.Size = UDim2.new(1, 0, 0, 40)
    TabButton.Position = UDim2.new(0, 0, 0, (order - 1) * 45)
    TabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    TabButton.Text = name
    TabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    TabButton.TextSize = 14
    TabButton.Font = Enum.Font.GothamMedium
    TabButton.Parent = TabContainer
    
    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 8)
    TabCorner.Parent = TabButton
    
    local TabContent = Instance.new("ScrollingFrame")
    TabContent.Name = name .. "Content"
    TabContent.Size = UDim2.new(1, -20, 1, -20)
    TabContent.Position = UDim2.new(0, 10, 0, 10)
    TabContent.BackgroundTransparency = 1
    TabContent.ScrollBarThickness = 4
    TabContent.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 80)
    TabContent.Visible = false
    TabContent.BorderSizePixel = 0
    TabContent.Parent = ContentContainer
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Padding = UDim.new(0, 10)
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Parent = TabContent
    
    tab.button = TabButton
    tab.content = TabContent
    tab.name = name
    
    TabButton.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            t.content.Visible = false
            t.button.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
            t.button.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        TabContent.Visible = true
        TabButton.BackgroundColor3 = Color3.fromRGB(50, 120, 255)
        TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        currentTab = tab
    end)
    
    return tab
end

-- Create tabs
tabs.visual = createTab("Visual", 1)
tabs.player = createTab("Player", 2)
tabs.config = createTab("Config", 3)
tabs.settings = createTab("Settings", 4)

-- Helper functions for UI elements
local function createLabel(parent, text, order)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 25)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.LayoutOrder = order
    Label.Parent = parent
    return Label
end

local function createToggle(parent, text, order, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 35)
    Container.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    Container.LayoutOrder = order
    Container.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Container
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 45, 0, 20)
    ToggleButton.Position = UDim2.new(1, -50, 0.5, -10)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    ToggleButton.Text = ""
    ToggleButton.Parent = Container
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = ToggleButton
    
    local ToggleCircle = Instance.new("Frame")
    ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
    ToggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
    ToggleCircle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    ToggleCircle.Parent = ToggleButton
    
    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = ToggleCircle
    
    local toggled = false
    
    ToggleButton.MouseButton1Click:Connect(function()
        if not isAuthorized then return end -- BLOKADA

        toggled = not toggled
        
        if toggled then
            TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 120, 255)}):Play()
            TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
        else
            TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 75)}):Play()
            TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
        end
        
        callback(toggled)
    end)
    
    return Container
end

local function createSlider(parent, text, min, max, default, order, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 50)
    Container.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    Container.LayoutOrder = order
    Container.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Container
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 20)
    Label.Position = UDim2.new(0, 10, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = text .. ": " .. default
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container
    
    local SliderBack = Instance.new("Frame")
    SliderBack.Size = UDim2.new(1, -20, 0, 4)
    SliderBack.Position = UDim2.new(0, 10, 1, -15)
    SliderBack.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    SliderBack.Parent = Container
    
    local SliderCorner = Instance.new("UICorner")
    SliderCorner.CornerRadius = UDim.new(1, 0)
    SliderCorner.Parent = SliderBack
    
    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(50, 120, 255)
    SliderFill.Parent = SliderBack
    
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = SliderFill
    
    local SliderButton = Instance.new("TextButton")
    SliderButton.Size = UDim2.new(1, 0, 1, 0)
    SliderButton.BackgroundTransparency = 1
    SliderButton.Text = ""
    SliderButton.Parent = SliderBack
    
    local dragging = false
    
    SliderButton.MouseButton1Down:Connect(function()
        if not isAuthorized then return end -- BLOKADA
        dragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if not isAuthorized then return end -- BLOKADA
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
            SliderFill.Size = UDim2.new(pos, 0, 1, 0)
            local value = math.floor(min + (max - min) * pos)
            Label.Text = text .. ": " .. value
            callback(value)
        end
    end)
    
    return Container
end

local function createButton(parent, text, order, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 35)
    Button.BackgroundColor3 = Color3.fromRGB(50, 120, 255)
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 13
    Button.Font = Enum.Font.GothamBold
    Button.LayoutOrder = order
    Button.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button
    
    Button.MouseButton1Click:Connect(function()
        if not isAuthorized then return end -- BLOKADA
        callback()
    end)
    
    return Button
end

-- === COLOR PICKER ===
local function createColorPicker(parent, text, defaultColor, order, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 35)
    Container.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    Container.LayoutOrder = order
    Container.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Container
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -80, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container
    
    local ColorDisplay = Instance.new("Frame")
    ColorDisplay.Size = UDim2.new(0, 60, 0, 25)
    ColorDisplay.Position = UDim2.new(1, -65, 0.5, -12.5)
    ColorDisplay.BackgroundColor3 = defaultColor
    ColorDisplay.Parent = Container
    
    local ColorCorner = Instance.new("UICorner")
    ColorCorner.CornerRadius = UDim.new(0, 6)
    ColorCorner.Parent = ColorDisplay
    
    local ColorButton = Instance.new("TextButton")
    ColorButton.Size = UDim2.new(1, 0, 1, 0)
    ColorButton.BackgroundTransparency = 1
    ColorButton.Text = ""
    ColorButton.Parent = ColorDisplay
    
    local rgbFrame = nil
    local currentR = math.floor(defaultColor.R * 255)
    local currentG = math.floor(defaultColor.G * 255)
    local currentB = math.floor(defaultColor.B * 255)
    
    local clickOutsideConnection = nil

    local function closePicker()
        if rgbFrame then
            if clickOutsideConnection then
                clickOutsideConnection:Disconnect()
                clickOutsideConnection = nil
            end
            rgbFrame:Destroy()
            rgbFrame = nil
        end
    end

    local function checkClickOutside(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and rgbFrame then
            local mousePos = input.Position
            
            local inRGBFrame = mousePos.X >= rgbFrame.AbsolutePosition.X and mousePos.X <= rgbFrame.AbsolutePosition.X + rgbFrame.AbsoluteSize.X and
                               mousePos.Y >= rgbFrame.AbsolutePosition.Y and mousePos.Y <= rgbFrame.AbsolutePosition.Y + rgbFrame.AbsoluteSize.Y

            if not inRGBFrame then
                closePicker()
            end
        end
    end

    
    ColorButton.MouseButton1Click:Connect(function()
        if not isAuthorized then return end -- BLOKADA

        if rgbFrame then
            closePicker()
        else
            rgbFrame = Instance.new("Frame")
            rgbFrame.Size = UDim2.new(0, 220, 0, 170)
            rgbFrame.Position = UDim2.new(0, 70, 0, -135)
            rgbFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
            rgbFrame.BorderSizePixel = 0
            rgbFrame.ZIndex = 20
            rgbFrame.Parent = Container
            
            local RGBCorner = Instance.new("UICorner")
            RGBCorner.CornerRadius = UDim.new(0, 10)
            RGBCorner.Parent = rgbFrame
            
            local contentHolder = Instance.new("Frame")
            contentHolder.Size = UDim2.new(1, -10, 1, -10)
            contentHolder.Position = UDim2.new(0, 5, 0, 5)
            contentHolder.BackgroundTransparency = 1
            contentHolder.Parent = rgbFrame
            
            local innerLayout = Instance.new("UIListLayout")
            innerLayout.Padding = UDim.new(0, 5)
            innerLayout.SortOrder = Enum.SortOrder.LayoutOrder
            innerLayout.Parent = contentHolder
            
            local function updateColor()
                local newColor = Color3.fromRGB(currentR, currentG, currentB)
                ColorDisplay.BackgroundColor3 = newColor
                callback(newColor)
            end
            
            createSlider(contentHolder, "Red", 0, 255, currentR, 1, function(value)
                currentR = value
                updateColor()
            end)
            
            createSlider(contentHolder, "Green", 0, 255, currentG, 2, function(value)
                currentG = value
                updateColor()
            end)
            
            createSlider(contentHolder, "Blue", 0, 255, currentB, 3, function(value)
                currentB = value
                updateColor()
            end)

            if not clickOutsideConnection then
                clickOutsideConnection = UserInputService.InputBegan:Connect(checkClickOutside)
            end
        end
    end)
    
    return Container
end

-- === LOGIKA JUNKYARD ESP ===
local espConnection = nil

local function cleanupESP()
    for vehicle, highlight in pairs(espHighlights) do
        if highlight then highlight:Destroy() end
    end
    espHighlights = {}
end

local function updateJunkyardESP()
    if not isAuthorized then return end -- BLOKADA

    if not config.junkyardESP.enabled then
        cleanupESP()
        if espConnection then
            espConnection:Disconnect()
            espConnection = nil
        end
        return
    end

    if not espConnection then
        espConnection = RunService.Heartbeat:Connect(function()
            local vehiclesContainer = workspace:FindFirstChild(JUNKYARD_CONTAINER_NAME)

            if not vehiclesContainer then
                return
            end

            local currentlyVisible = {}

            for _, vehicle in ipairs(vehiclesContainer:GetChildren()) do
                -- Sprawdzenie, czy to model I ma atrybut "Junkyard" = true
                if vehicle:IsA("Model") and vehicle:GetAttribute("Junkyard") == true then
                    
                    currentlyVisible[vehicle] = true
                    
                    -- Tworzenie/Aktualizacja Highlight
                    if not espHighlights[vehicle] then
                        local highlight = Instance.new("Highlight")
                        highlight.FillColor = config.junkyardESP.color
                        highlight.FillTransparency = config.junkyardESP.transparency
                        highlight.OutlineTransparency = 1
                        highlight.Parent = vehicle 

                        espHighlights[vehicle] = highlight
                    end
                    
                end
            end

            -- Usuwanie Highlight z pojazdów, które już nie istnieją lub straciły atrybut
            for vehicle, highlight in pairs(espHighlights) do
                if not currentlyVisible[vehicle] then
                    if highlight then highlight:Destroy() end
                    espHighlights[vehicle] = nil
                end
            end
        end)
    end
end
-- === KONIEC LOGIKI JUNKYARD ESP ===

-- VISUAL TAB 
createLabel(tabs.visual.content, "Player Highlight Settings", 1)

createToggle(tabs.visual.content, "Enable Player Highlight", 2, function(enabled)
    config.highlight.enabled = enabled
    if enabled then
        local function addHighlightToPlayer(otherPlayer)
            if otherPlayer ~= player and otherPlayer.Character and not highlightObjects[otherPlayer] then
                local highlight = Instance.new("Highlight")
                highlight.FillColor = config.highlight.color
                highlight.FillTransparency = config.highlight.transparency
                highlight.OutlineTransparency = 1
                highlight.Parent = otherPlayer.Character
                highlightObjects[otherPlayer] = highlight
            end
        end

        for _, otherPlayer in pairs(Players:GetPlayers()) do
            addHighlightToPlayer(otherPlayer)
        end
        
        Players.PlayerAdded:Connect(function(otherPlayer)
            otherPlayer.CharacterAdded:Connect(function(char)
                if config.highlight.enabled and otherPlayer ~= player then
                    if highlightObjects[otherPlayer] then
                        highlightObjects[otherPlayer]:Destroy()
                    end
                    local highlight = Instance.new("Highlight")
                    highlight.FillColor = config.highlight.color
                    highlight.FillTransparency = config.highlight.transparency
                    highlight.OutlineTransparency = 1
                    highlight.Parent = char
                    highlightObjects[otherPlayer] = highlight
                end
            end)
            addHighlightToPlayer(otherPlayer)
        end)
    else
        for _, highlight in pairs(highlightObjects) do
            if highlight then
                highlight:Destroy()
            end
        end
        highlightObjects = {}
    end
end)

createColorPicker(tabs.visual.content, "Player Highlight Color", config.highlight.color, 3, function(color)
    config.highlight.color = color
    for _, highlight in pairs(highlightObjects) do
        if highlight then
            highlight.FillColor = color
        end
    end
end)

-- NOWY ELEMENT ESP JUNKYARD (tylko Highlight)
createLabel(tabs.visual.content, "---", 4)
createLabel(tabs.visual.content, "Junkyard Highlight Settings", 5)

createToggle(tabs.visual.content, "Enable Junkyard Highlight", 6, function(enabled)
    config.junkyardESP.enabled = enabled
    updateJunkyardESP()
end)

createColorPicker(tabs.visual.content, "Junkyard Highlight Color", config.junkyardESP.color, 7, function(color)
    config.junkyardESP.color = color
    for _, highlight in pairs(espHighlights) do
        if highlight then
            highlight.FillColor = color
        end
    end
end)

-- PLAYER TAB 
createLabel(tabs.player.content, "Movement Settings", 1)
createToggle(tabs.player.content, "Enable Fly", 2, function(enabled)
    if not isAuthorized then return end -- BLOKADA
    
    config.fly.enabled = enabled
    flying = enabled
    
    local hrp = character:FindFirstChild("HumanoidRootPart")

    if enabled and hrp then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Name = "FlyVelocity"
        bodyVelocity.Parent = hrp
        
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.P = 9e9
        bodyGyro.Name = "FlyGyro"
        bodyGyro.Parent = hrp
        
        flyConnection = RunService.RenderStepped:Connect(function()
            if flying and hrp then
                local currentCamera = workspace.CurrentCamera
                local moveDirection = Vector3.new()
                
                hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveDirection = moveDirection + currentCamera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveDirection = moveDirection - currentCamera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveDirection = moveDirection - currentCamera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveDirection = moveDirection + currentCamera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    moveDirection = moveDirection + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    moveDirection = moveDirection - Vector3.new(0, 1, 0)
                end
                
                bodyVelocity.Velocity = moveDirection.Unit * flySpeed
                bodyGyro.CFrame = currentCamera.CFrame
                
                humanoid.Sit = true 
            end
        end)
    else
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        if hrp and hrp:FindFirstChild("FlyVelocity") then
            hrp.FlyVelocity:Destroy()
        end
        if hrp and hrp:FindFirstChild("FlyGyro") then
            hrp.FlyGyro:Destroy()
        end
        humanoid.Sit = false
    end
end)

createSlider(tabs.player.content, "Fly Speed", 10, 200, config.fly.speed, 3, function(value)
    flySpeed = value
    config.fly.speed = value
end)

createToggle(tabs.player.content, "Enable Custom Walkspeed", 4, function(enabled)
    if not isAuthorized then return end -- BLOKADA
    
    config.walkspeed.enabled = enabled
    if enabled then
        humanoid.WalkSpeed = config.walkspeed.speed
    else
        humanoid.WalkSpeed = 16
    end
end)

createSlider(tabs.player.content, "Walkspeed", 16, 200, config.walkspeed.speed, 5, function(value)
    config.walkspeed.speed = value
    if config.walkspeed.enabled then
        humanoid.WalkSpeed = value
    end
end)

-- CONFIG TAB 
createLabel(tabs.config.content, "Configuration Management", 1)
createButton(tabs.config.content, "Save Config", 2, function()
    if not isAuthorized then return end -- BLOKADA
    
    local configString = HttpService:JSONEncode(config)
    local success, err = pcall(function()
        writefile("script_config.json", configString)
    end)
    if success then
        TitleText.Text = "Config Saved!"
    else
        TitleText.Text = "Save Failed: " .. (err or "Unknown error")
    end
    wait(2)
    TitleText.Text = "Modern Script Hub"
end)

createButton(tabs.config.content, "Load Config", 3, function()
    if not isAuthorized then return end -- BLOKADA

    local success, loadedConfig
    if isfile("script_config.json") then
        local configString = readfile("script_config.json")
        success, loadedConfig = pcall(function()
            return HttpService:JSONDecode(configString)
        end)
    end
    
    if success and loadedConfig then
        config = loadedConfig
        TitleText.Text = "Config Loaded!"
        
        flySpeed = config.fly.speed
        if config.walkspeed.enabled then
            humanoid.WalkSpeed = config.walkspeed.speed
        else
            humanoid.WalkSpeed = 16
        end
        
        updateJunkyardESP()
        if keybindButton and config.menuKey and config.menuKey.Name then
             keybindButton.Text = "Change Menu Keybind: " .. config.menuKey.Name
        end
        
    else
        TitleText.Text = "No Config Found!"
    end
    wait(2)
    TitleText.Text = "Modern Script Hub"
end)

-- SETTINGS TAB 
createLabel(tabs.settings.content, "Menu Settings", 1)

keybindButton = createButton(tabs.settings.content, "Change Menu Keybind: " .. config.menuKey.Name, 2, function()
    if not isAuthorized then return end -- BLOKADA

    if isChangingKeybind then return end 

    isChangingKeybind = true
    keybindButton.Text = "Press any key..."
    
    ScreenGui.Enabled = true

    local connection 

    local function finishKeybind(newKeyCode)
        if connection then
            connection:Disconnect()
            connection = nil 
        end
        config.menuKey = newKeyCode
        keybindButton.Text = "Change Menu Keybind: " .. newKeyCode.Name
        isChangingKeybind = false
    end

    connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
            
            if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl or
               input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift or
               input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt or
               input.KeyCode == Enum.KeyCode.Unknown then
                
                keybindButton.Text = "Invalid Key! Try again..."
                wait(1.5)
                keybindButton.Text = "Press any key..."
                return
            end
            
            finishKeybind(input.KeyCode)
            
        elseif input.KeyCode == Enum.KeyCode.Escape and isChangingKeybind then
            finishKeybind(config.menuKey)
            
        end
    end)
    
end)

-- Close button functionality
CloseButton.MouseButton1Click:Connect(function()
    if not isAuthorized then return end -- BLOKADA
    ScreenGui.Enabled = false
end)

-- Menu toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not isAuthorized then return end -- BLOKADA

    if not gameProcessed and not isChangingKeybind and input.KeyCode == config.menuKey then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

-- Set default tab
wait(0.1)
for _, t in pairs(tabs) do
    t.content.Visible = false
    t.button.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    t.button.TextColor3 = Color3.fromRGB(200, 200, 200)
end
tabs.visual.content.Visible = true
tabs.visual.button.BackgroundColor3 = Color3.fromRGB(50, 120, 255)
tabs.visual.button.TextColor3 = Color3.fromRGB(255, 255, 255)
currentTab = tabs.visual

-- Parent GUI
MainGui = ScreenGui -- Zapisz referencję do głównego GUI
ScreenGui.Parent = game:GetService("CoreGui")

-- URUCHOM KEY SYSTEM
createKeyInputGUI()
