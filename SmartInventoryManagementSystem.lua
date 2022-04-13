SLASH_SIMS1 = "/sims"

flags = {}
flags["Item Level"] = false
flags["Equipment"] = false
flags["Item Name"] = false
flags["Soulbound"] = false

dropDownValues = {}
dropDownValues["Equipment"] = nil
dropDownValues["Soulbound"] = nil

function CreateStandardCheckButton(name, parent, box, text, position, x, y)
    local CheckButton = CreateFrame("CheckButton", name, parent,
                                    "ChatConfigCheckButtonTemplate")
    CheckButton:SetPoint(position, x, y)
    getglobal(CheckButton:GetName() .. "Text"):SetText(text)
    CheckButton:SetScript("OnClick", function()
        flags[text] = not flags[text]
        if (flags[text]) then
            box:Show()
        else
            box:Hide()
        end
    end)
    return CheckButton
end

function CreateStandardEditBox(name, parent, position, x, y)
    local editBox = CreateFrame("EditBox", name, MainFrame,
                                BackdropTemplateMixin and "BackdropTemplate")
    editBox:SetPoint(position, x, y)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetMultiLine(false)
    editBox:SetSize(155, 40)
    editBox:SetAutoFocus(false)
    editBox:SetBackdrop(BACKDROP_DIALOG_32_32);
    editBox:SetTextInsets(15, 12, 12, 11)
    editBox:SetScript("OnEscapePressed", function() editBox:ClearFocus() end)
    editBox:Hide()

    return editBox
end

function CreateStandardFrame(name, text)
    local f =
        CreateFrame("Frame", name, UIParent, "BasicFrameTemplateWithInset")
    f:SetPoint("CENTER")
    f:SetSize(400, 500)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableKeyboard(true)
    f.title = f:CreateFontString(nil, "OVERLAY")
    f.title:SetFontObject("GameFontHighlight")
    f.title:SetPoint("CENTER", f.TitleBg, 5, 0)
    f.title:SetText(text)

    f:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then self:StartMoving() end
    end)
    f:SetScript("OnKeyDown", function(self, key)
        if (GetBindingFromClick(key) == "TOGGLEGAMEMENU") then
            self:Hide()
        end
    end)
    f:SetScript("OnMouseUp", f.StopMovingOrSizing)

    return f
end

function CreateStandardButton(parent, text, position, x, y, length, height, name)
    local button = nil
    if (name ~= nil) then
        button = CreateFrame("Button", name, parent, "GameMenuButtonTemplate")
    else
        button = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    end
    button:SetPoint(position, x, y)
    if (length ~= nil and height ~= nil) then button:SetSize(length, height) end
    button:SetText(text)
    return button
end

function CreateStandardDropDown(parent, position, x, y, width, text, menuItems,
                                target)
    local dropDown = CreateFrame("FRAME", nil, parent, "UIDropDownMenuTemplate")
    dropDown:SetPoint(position, x, y)
    dropDown:Hide()
    UIDropDownMenu_SetWidth(dropDown, width)
    UIDropDownMenu_SetText(dropDown, text)
    UIDropDownMenu_Initialize(dropDown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.func = self.SetValue
        for key, value in ipairs(menuItems) do

            info.text, info.arg1, info.checked = value, value, value ==
                                                     dropDownValues[target]
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    function dropDown:SetValue(newValue)
        dropDownValues[target] = newValue
        UIDropDownMenu_SetText(dropDown, newValue)
        CloseDropDownMenus()
    end

    return dropDown
end

function ConfirmationFrame_Show(itemLinks, totalSellPrice, itemCoords)
    if not ConfirmationFrame then
        local f = CreateStandardFrame("ConfirmationFrame", "Confirm")

        local MessageFrame = CreateFrame("ScrollingMessageFrame",
                                         "ConfirmationMessageFrame", f)
        MessageFrame:SetSize(200, 200)
        MessageFrame:SetPoint("CENTER")
        MessageFrame:SetFontObject(GameFontNormal)
        MessageFrame:SetJustifyH("LEFT")
        MessageFrame:SetFading(false)
        MessageFrame:SetMaxLines(100)
        MessageFrame:SetInsertMode(SCROLLING_MESSAGE_FRAME_INSERT_MODE_TOP)
        MessageFrame:SetHyperlinksEnabled(true)
        MessageFrame:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)
        MessageFrame:HookScript('OnHyperlinkEnter', ChatFrame_OnHyperlinkShow)

        local total = CreateFrame("ScrollingMessageFrame",
                                  "TotalSellPriceMessageFrame", f)
        total:SetSize(200, 200)
        total:SetPoint("BOTTOM", 0, 50)
        total:SetFontObject(GameFontNormal)
        total:SetJustifyH("LEFT")
        total:SetFading(false)
        total:SetMaxLines(100)

        local func = function(self) f:Hide() end

        local cancelCallback = function(self)
            f:Hide()
            MainFrame_Show()
        end

        local sellButton = CreateStandardButton(ConfirmationFrame, "Sell",
                                                "BOTTOM", 0, 10, 100, 25,
                                                "SellButton")
        sellButton:RegisterEvent("MERCHANT_SHOW")
        sellButton:RegisterEvent("MERCHANT_CLOSED")
        sellButton:SetEnabled(false)
        sellButton:SetScript("OnEvent", function(self, event)
            if event == "MERCHANT_SHOW" then
                self:SetEnabled(true)
            else
                self:SetEnabled(false)
            end
        end)

        local destroyButton = CreateStandardButton(ConfirmationFrame, "Destroy",
                                                   "BOTTOMLEFT", 20, 10, 100,
                                                   25, "DestroyButton")
        destroyButton:SetScript("OnClick", func)

        local cancelButton = CreateStandardButton(ConfirmationFrame, "Cancel",
                                                  "BOTTOMRIGHT", -20, 10, 100,
                                                  25, "CancelButton")
        cancelButton:SetScript("OnClick", cancelCallback)

        f:Show()
    end

    getglobal("SellButton"):SetScript("OnClick", function(self)
        for key, value in ipairs(itemCoords) do
            UseContainerItem(value.bag, value.slot)
        end

        ConfirmationFrame:Hide()
    end)
    getglobal("SellButton"):SetEnabled(MerchantFrame:IsVisible())

    getglobal("ConfirmationMessageFrame"):Clear()
    for key, value in ipairs(itemLinks) do
        getglobal("ConfirmationMessageFrame"):AddMessage(value)
    end

    getglobal("TotalSellPriceMessageFrame"):Clear()
    getglobal("TotalSellPriceMessageFrame"):AddMessage("Total Sell Price")
    getglobal("TotalSellPriceMessageFrame"):AddMessage(
        GetCoinTextureString(totalSellPrice))

    ConfirmationFrame:Show()
end

function filter(itemLink, filteredItems, itemCoords, currentBag, slot)
    itemName, _, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent =
        GetItemInfo(itemLink)
    icon, itemCount, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID, isBound =
        GetContainerItemInfo(currentBag, slot)
    local isHit = true
    if (sellPrice == nil or sellPrice == 0) then return 0 end
    if (flags["Item Name"] and isHit) then
        if (not string.find(itemName:lower(), ItemNameEditBox:GetText():lower())) then
            isHit = false
        end
    end
    if (flags["Item Level"] and isHit) then
        if (tonumber(ItemLevelEditBox:GetText()) ~= itemLevel) then
            isHit = false
        end
    end
    if (flags["Equipment"] and isHit) then
        if (dropDownValues["Equipment"] ~= itemType) then isHit = false end
    end
    if (flags["Soulbound"] and isHit) then
        if (dropDownValues["Soulbound"] == "Not Soulbound" and isBound ~= false) then
            isHit = false
        elseif (dropDownValues["Soulbound"] == "Soulbound" and isBound ~= true) then
            isHit = false
        end
    end
    if (isHit) then
        local coords = {}
        coords.bag = currentBag
        coords.slot = slot

        table.insert(itemCoords, coords)
        table.insert(filteredItems, itemLink)
        return sellPrice
    end

    return 0
end

function ParseBags()
    local filteredItems = {}
    local itemCoords = {}
    local totalSellPrice = 0
    for currentBag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(currentBag) do
            local itemLink = GetContainerItemLink(currentBag, slot)
            if (itemLink) then
                totalSellPrice = totalSellPrice +
                                     filter(itemLink, filteredItems, itemCoords,
                                            currentBag, slot)
            end
        end
    end

    ConfirmationFrame_Show(filteredItems, totalSellPrice, itemCoords)
end

function MainFrame_Show()
    if not MainFrame then
        local f = CreateStandardFrame("MainFrame", "S.I.M.S")

        local itemNameEditBox = CreateStandardEditBox("ItemNameEditBox",
                                                      MainFrame, "TOP", 65, -35)
        local itemNameButton = CreateStandardCheckButton("ItemNameCheckBox",
                                                         MainFrame,
                                                         itemNameEditBox,
                                                         "Item Name", "TOP",
                                                         -150, -40)

        local iLvlEditBox = CreateStandardEditBox("ItemLevelEditBox", MainFrame,
                                                  "TOP", 65, -75)
        local iLvlButton = CreateStandardCheckButton("ItemLevelCheckBox",
                                                     MainFrame, iLvlEditBox,
                                                     "Item Level", "TOP", -150,
                                                     -80)

        local equipmentDropDownMenuItems = {"Armor", "Weapon"}
        local equipmentDropDown = CreateStandardDropDown(MainFrame, "TOP", 65,
                                                         -117, 145,
                                                         "Equipment Type",
                                                         equipmentDropDownMenuItems,
                                                         "Equipment")

        local equipmentButton = CreateStandardCheckButton("EquipmentCheckBox",
                                                          MainFrame,
                                                          equipmentDropDown,
                                                          "Equipment", "TOP",
                                                          -150, -120)

        local soulBoundDropDownMenuItems = {"Soulbound", "Not Soulbound"}
        local soulBoundDropDown = CreateStandardDropDown(MainFrame, "TOP", 65,
                                                         -157, 145,
                                                         "Is Soulbound",
                                                         soulBoundDropDownMenuItems,
                                                         "Soulbound")
        local soulBoundButton = CreateStandardCheckButton("SoulBoundCheckBox",
                                                          MainFrame,
                                                          soulBoundDropDown,
                                                          "Soulbound", "TOP",
                                                          -150, -160)

        local button = CreateStandardButton(MainFrame, "Query Bags", "BOTTOM",
                                            0, 15, nil, nil, nil)
        button:SetScript("OnClick", function(self)
            ParseBags()
            f:Hide()
        end)

        f:Show()
    end
    if text then MainFrameEditBox:SetText(text) end

    MainFrame:Show()
end

local function SimsHandler() MainFrame_Show() end

SlashCmdList["SIMS"] = SimsHandler;
