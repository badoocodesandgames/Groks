local NewTestDB = NewTestDB or {}

-- Create the main popup frame
local frame = CreateFrame("Frame", "ExpInfoFrame", UIParent)
frame:SetPoint("CENTER")
frame:Hide()
frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 0.9)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
tinsert(UISpecialFrames, "ExpInfoFrame")

-- Padding constants
local PADDING_X = 20  -- Horizontal padding on each side
local PADDING_Y = 10  -- Vertical padding on top and bottom

-- Close button
local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -2, -2)
closeButton:SetScript("OnClick", function() frame:Hide() end)

-- Title
frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.title:SetPoint("TOP", frame, "TOP", 0, -5)
frame.title:SetText("Experience Info")

-- Text displays
local expGainedText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
expGainedText:SetPoint("TOP", frame, "TOP", 0, -30)
expGainedText:SetTextColor(0, 1, 0, 1)
expGainedText:SetJustifyH("CENTER")

local totalExpText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
totalExpText:SetPoint("TOP", expGainedText, "BOTTOM", 0, -10)
totalExpText:SetTextColor(0, 1, 0, 1)
totalExpText:SetJustifyH("CENTER")

local lastKillText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lastKillText:SetPoint("TOP", totalExpText, "BOTTOM", 0, -10)
lastKillText:SetTextColor(1, 0, 0, 1)
lastKillText:SetJustifyH("CENTER")

local expToLevelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
expToLevelText:SetPoint("TOP", lastKillText, "BOTTOM", 0, -10)
expToLevelText:SetTextColor(0, 1, 0, 1)
expToLevelText:SetJustifyH("CENTER")

local killsToLevelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
killsToLevelText:SetPoint("TOP", expToLevelText, "BOTTOM", 0, -10)
killsToLevelText:SetTextColor(0, 1, 0, 1)
killsToLevelText:SetJustifyH("CENTER")

-- Variables
local previousXP = UnitXP("player")
local totalXPGained = NewTestDB.totalXPGained or 0
local lastKilledUnit = nil
local lastXPUpdate = 0
local lastValidXPDiff = NewTestDB.lastValidXPDiff or 1  -- Prevent divide-by-zero

-- Function to update frame size
local function UpdateFrameSize()
    local maxWidth = frame.title:GetWidth()
    maxWidth = math.max(maxWidth, expGainedText:GetWidth())
    maxWidth = math.max(maxWidth, totalExpText:GetWidth())
    maxWidth = math.max(maxWidth, lastKillText:GetWidth())
    maxWidth = math.max(maxWidth, expToLevelText:GetWidth())
    maxWidth = math.max(maxWidth, killsToLevelText:GetWidth())
    
    -- Add close button width consideration
    local closeButtonWidth = closeButton:GetWidth() + 4
    maxWidth = math.max(maxWidth, closeButtonWidth)
    
    -- Calculate total height
    local height = 30 +  -- From top to first text
        expGainedText:GetHeight() +
        10 + totalExpText:GetHeight() +  -- Spacing + next text
        10 + lastKillText:GetHeight() +
        10 + expToLevelText:GetHeight() +
        10 + killsToLevelText:GetHeight() +
        PADDING_Y  -- Bottom padding
    
    frame:SetSize(maxWidth + PADDING_X * 2, height + PADDING_Y)
end

-- Update function
local function UpdateXP()
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local xpDifference = currentXP - previousXP
    local xpRemaining = maxXP - currentXP
    local currentLevel = UnitLevel("player")
    local nextLevel = currentLevel + 1

    if xpDifference > 0 then
        totalXPGained = (NewTestDB.totalXPGained or 0) + xpDifference
        NewTestDB.totalXPGained = totalXPGained
        lastValidXPDiff = xpDifference
        NewTestDB.lastValidXPDiff = lastValidXPDiff
    end
    previousXP = currentXP

    local killsNeeded = math.ceil(xpRemaining / (lastValidXPDiff > 0 and lastValidXPDiff or 1))

    -- Update UI texts
    if frame:IsShown() then
        expGainedText:SetText("Exp Gained: " .. xpDifference)
        totalExpText:SetText("Total Exp Gained: " .. totalXPGained)
        lastKillText:SetText("Killed: " .. (lastKilledUnit or "None"))
        expToLevelText:SetText(xpRemaining .. " Exp To Level " .. nextLevel)
        killsToLevelText:SetText(killsNeeded .. " Kills To Level " .. nextLevel)
        UpdateFrameSize()  -- Update size after setting text
    end
end

-- Event handler
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_XP_UPDATE" then
        UpdateXP()
    elseif event == "PLAYER_LOGIN" then
        UpdateXP()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subevent, srcGUID, srcName, srcFlags, destGUID, destName, destFlags = ...
        if subevent == "PARTY_KILL" and srcGUID == UnitGUID("player") then
            lastKilledUnit = destName
            UpdateXP()
        end
    end
end)

-- Slash command
SLASH_EXPINFO1 = "/expinfo"
SlashCmdList["EXPINFO"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        UpdateXP()
    end
end

-------------------------------------------------------------------------------
-- ADD FRIEND POPUP -----------------------------------------------------------
-------------------------------------------------------------------------------

-- Create the main popup frame
local frame = CreateFrame("Frame", "AddFriendFrame", UIParent)
frame:SetSize(250, 120)
frame:SetPoint("CENTER")
frame:Hide()
frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 0.9)

-- Make frame draggable
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        self:StartMoving()
    end
end)
frame:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
end)

-- Close with Escape
frame:EnableKeyboard(true)
frame:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        self:Hide()
    end
end)
tinsert(UISpecialFrames, "AddFriendFrame")

-- Close button
local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -2, -2)
closeButton:SetScript("OnClick", function() frame:Hide() end)

-- Title
frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.title:SetPoint("TOP", frame, "TOP", 0, -5)
frame.title:SetText("Add Friend")

-- Edit box for entering the friend's name
local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
editBox:SetSize(200, 20)
editBox:SetPoint("TOP", frame, "TOP", 0, -30)
editBox:SetAutoFocus(false)
editBox:SetMaxLetters(12) -- WoW 3.3.5 character name limit
editBox:SetFontObject("GameFontNormal")

-- Add Friend button
local addButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
addButton:SetSize(100, 22)
addButton:SetPoint("TOP", editBox, "BOTTOM", 0, -10)
addButton:SetText("Add Friend")
addButton:SetScript("OnClick", function()
    local name = editBox:GetText():trim()
    if name and name ~= "" then
        -- Send friend request in WoW 3.3.5
        AddFriend(name)
        print("Friend request sent to: " .. name)
        editBox:SetText("") -- Clear the edit box
        frame:Hide() -- Close the frame
    else
        print("Please enter a valid name.")
    end
end)

-- Allow Enter key to trigger the Add Friend button
editBox:SetScript("OnEnterPressed", function()
    addButton:Click()
end)

-- Slash command to toggle the frame
SLASH_ADDF1 = "/addf"
SlashCmdList["ADDF"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        editBox:SetFocus() -- Automatically focus the edit box when opened
    end
end

-------------------------------------------------------------------------------
-- END ADD FRIEND POPUP -----------------------------------------------------------
-------------------------------------------------------------------------------