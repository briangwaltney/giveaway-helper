--zip -r ../GiveAwayHelper-v0.1.2.zip . -x '*.git*'
SLASH_CHAN1 = "/gaChan"
SLASH_LIST1 = "/gaList"
SLASH_CATS1 = "/gaCats"
SLASH_GRAB1 = "/gaGrab"
SLASH_HELP1 = "/gahelp"
SLASH_DB1 = "/gadb"
SLASH_RESET1 = "/gareset"
SLASH_FRAMESTK1 = "/fs"
SLASH_BANKALTS1 = "/gabankalts"
SLASH_NOTES1 = "/ganotes"

GiveAwayHelper = {
	items = {},
	filteredItems = {},
	minLvl = 1,
	maxLvl = 60,
	type = "All",
	subType = "All",
	slot = "All",
	search = "",
}

local default = {
	CHANNEL = "7",
	BankAlts = {
		holdmytea = true,
		levelup = true,
		baggervance = true,
		ofthewhale = true,
	},
	Notes = {
		raid = "(Core raider mains only)",
		recycle = "(Recyclable - Return when finished using)",
	},
}

GiveAwayHelperDB = GiveAwayHelperDB or default

GiveAwayHelper.resetVars = function()
	GiveAwayHelperDB = default
end

GiveAwayHelper.bankAlts = function(input)
	local name, add = strsplit(" ", input)
	if add == "add" then
		GiveAwayHelperDB.BankAlts[string.lower(name)] = true
		print("Added " .. name .. " to bank alts")
	else
		GiveAwayHelperDB.BankAlts[string.lower(name)] = nil
		print("Removed " .. name .. " from bank alts")
	end
end

GiveAwayHelper.notes = function(input)
	local label, note = input:match("([^%s]+)%s(.*)")
	if note == "remove" then
		GiveAwayHelperDB.Notes[string.lower(label)] = nil
		print("Removed note for " .. label)
	else
		GiveAwayHelperDB.Notes[string.lower(label)] = note
		print("Added note for " .. label)
	end
end

GiveAwayHelper.setChannel = function(channelNum)
	if channelNum == "" then
		GiveAwayHelperDB.CHANNEL = "7"
	else
		GiveAwayHelperDB.CHANNEL = channelNum
	end
	print("CHANNEL SET TO: " .. GiveAwayHelperDB.CHANNEL)
	GiveAwayHelper.PrintListButton:SetText("Print To: " .. GiveAwayHelperDB.CHANNEL)
end

GiveAwayHelper.SendMessage = function(msg, channel)
	if channel == nil then
		channel = "7"
	end
	if string.lower(channel) == "guild" then
		SendChatMessage(msg, "GUILD")
	else
		SendChatMessage(msg, "CHANNEL", nil, channel)
	end
end

GiveAwayHelper.CatFilter = function(cat, itemType, itemSubType, loc)
	if cat == "rings" and loc == "INVTYPE_FINGER" then
		return true
	end
	if cat == "necks" and loc == "INVTYPE_NECK" then
		return true
	end
	if cat == "cloaks" and loc == "INVTYPE_CLOAK" then
		return true
	end
	if cat == "trinkets" and loc == "INVTYPE_TRINKET" then
		return true
	end
	if cat == "offhands" and (loc == "INVTYPE_RELIC" or loc == "INVTYPE_HOLDABLE") then
		return true
	end
	if Filters[cat].type == itemType and Filters[cat].subType == itemSubType and loc ~= "INVTYPE_CLOAK" then
		return true
	else
		return false
	end
end

GiveAwayHelper.SearchForItem = function(fullName)
	local numItems = GetInboxNumItems()
	local i = 1
	local j = 1

	while i <= numItems do
		while j < 21 do
			local link = GetInboxItemLink(i, j)
			if link == fullName then
				TakeInboxItem(i, j)
				return
			end
			j = j + 1
		end
		j = 1
		i = i + 1
	end
	print("ITEM NOT FOUND IN MAILBOX")
end

GiveAwayHelper.LevelFilter = function(min, max, itemLevel)
	if itemLevel >= tonumber(min) and itemLevel <= tonumber(max) then
		return true
	else
		return false
	end
end

BUTTON_COUNT = 0

GiveAwayHelper.CreateButton = function(item)
	BUTTON_COUNT = BUTTON_COUNT + 1
	local buttonName = "GiveawayHelper_Button_" .. BUTTON_COUNT
	local button = CreateFrame("BUTTON", buttonName, GiveAwayHelper.mainFrame.ScrollChild)
	button:SetWidth(270)
	button:SetHeight(28)
	button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	button:EnableMouseWheel(true)
	button:RegisterForClicks("AnyDown") --"AnyUp",

	-- background
	button.background = button:CreateTexture(buttonName .. "_background", "BACKGROUND")
	button.background:SetAllPoints(button)
	-- button.background:SetColorTexture(unpack(DEFAULT_BACKGROUND_COLOR))
	button.background:Hide()

	-- highlight Background
	local highlightBg = button:CreateTexture(buttonName .. "_highlightBg")
	highlightBg:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
	highlightBg:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -(button:GetWidth() / 2), 0)
	highlightBg:SetColorTexture(1, 0, 0)
	highlightBg:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.45), CreateColor(1, 1, 1, 0))
	highlightBg:Hide()
	button.highlightBg = highlightBg

	-- Icon <texture>
	button.icon = button:CreateTexture(buttonName .. "_icon")
	button.icon:SetDrawLayer("ARTWORK", 0)
	button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
	button.icon:SetHeight(26)
	button.icon:SetWidth(26)
	button.icon:SetTexture(item.itemTexture)

	local getFontColor = function(qual)
		if qual == 0 then
			return 0.5, 0.5, 0.5
		elseif qual == 1 then
			return 1, 1, 1
		elseif qual == 2 then
			return 0, 0.8, 0
		elseif qual == 3 then
			return 0, 0.8, 0.8
		elseif qual == 4 then
			return 0.8, 0, 0.8
		elseif qual == 5 then
			return 1, 0.5, 0
		elseif qual == 6 then
			return 1, 0.5, 0
		end
	end

	-- ItemName <FontString>
	button.name = button:CreateFontString(buttonName .. "_name", "ARTWORK", "GameFontNormal")
	button.name:SetPoint("TOPLEFT", button.icon, "TOPRIGHT", 3, 0)
	button.name:SetJustifyH("LEFT")
	button.name:SetText("")
	button.name:SetWidth(230)
	button.name:SetHeight(12)
	button.name:SetText(item.itemName)
	button.name:SetTextColor(getFontColor(item.itemQuality))

	-- ExtraText <FontString>
	button.extra = button:CreateFontString(buttonName .. "_extra", "ARTWORK", "GameFontNormalSmall")
	button.extra:SetPoint("TOPLEFT", button.name, "BOTTOMLEFT", 0, -1)
	button.extra:SetJustifyH("LEFT")
	button.extra:SetText("")
	button.extra:SetWidth(230)
	button.extra:SetHeight(10)
	button.extra:SetTextColor(1, 1, 1, 1)
	button.extra:SetText(item.itemType .. ", " .. item.itemSubType .. ", " .. item.itemMinLevel .. " " .. item.note)

	-- counter
	button.count = button:CreateFontString(buttonName .. "_count", "ARTWORK", "GameFontNormalSmall")
	button.count:SetTextColor(1, 1, 1, 1)
	button.count:SetDrawLayer(button.icon:GetDrawLayer(), 1)
	button.count:SetPoint("BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", -1, 1)
	button.count:SetJustifyH("RIGHT")
	button.count:SetHeight(15)
	button.count:SetText(item.itemCount)
	if item.itemCount == 1 then
		button.count:Hide()
	end

	button:Hide()

	button:SetScript("OnClick", function()
		if IsShiftKeyDown() then
			ChatEdit_InsertLink(item.itemLink)
		end
	end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -100, 0)
		GameTooltip:SetHyperlink(item.itemLink)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	return button
end

GiveAwayHelper.GetAllItems = function()
	local items = {}
	local numItems = GetInboxNumItems()
	for i = 1, numItems do
		local _, _, _, subject, _, _, _, numItems, _, _, _, _, isGM = GetInboxHeaderInfo(i)
		if not isGM and numItems ~= nil then
			for j = 1, 20 do
				local name, itemID, _, itemCount = GetInboxItem(i, j)
				local link = GetInboxItemLink(i, j)
				if name then
					local _, _, qual, _, itemMinLevel, itemType, itemSubType, _, slot, texture = GetItemInfo(itemID)
					local note = ""

					for key, value in pairs(GiveAwayHelperDB.Notes) do
						if string.find(string.lower(subject), string.lower(key)) then
							note = value
						end
					end

					for match in subject:gmatch("%[(.-)%]") do
						note = match
					end

					if items[name] ~= nil then
						items[name].itemCount = items[name].itemCount + itemCount
						if items[name].note == "" then
							items[name].note = note
						end
					else
						items[name] = {
							itemName = name,
							itemLink = link,
							itemMinLevel = itemMinLevel,
							itemType = itemType,
							itemSubType = itemSubType,
							itemCount = itemCount,
							itemTexture = texture,
							itemQuality = qual,
							itemSlot = slot,
							note = note,
						}
					end
				end
			end
		end
	end

	GiveAwayHelper.items = {}

	for _, item in pairs(items) do
		local f = GiveAwayHelper.CreateButton(item)
		item.frame = f
		table.insert(GiveAwayHelper.items, item)
	end

	table.sort(GiveAwayHelper.items, GiveAwayHelper.sortByLevel)
end

GiveAwayHelper.sortByLevel = function(a, b)
	return a.itemMinLevel > b.itemMinLevel
end

GiveAwayHelper.filterItems = function()
	for i, item in pairs(GiveAwayHelper.filteredItems) do
		item.frame:Hide()
		GiveAwayHelper.filteredItems[i] = nil
	end

	for _, item in pairs(GiveAwayHelper.items) do
		if
			GiveAwayHelper.search == "" or string.find(string.lower(item.itemName), string.lower(GiveAwayHelper.search))
		then
			if GiveAwayHelper.type == "All" or GiveAwayHelper.type == item.itemType then
				if GiveAwayHelper.subType == "All" or GiveAwayHelper.subType == item.itemSubType then
					if GiveAwayHelper.slot == "All" or GiveAwayHelper.slot == _G[item.itemSlot] then
						if GiveAwayHelper.minLvl == 1 or GiveAwayHelper.minLvl <= item.itemMinLevel then
							if GiveAwayHelper.maxLvl >= item.itemMinLevel then
								table.insert(GiveAwayHelper.filteredItems, item)
							end
						end
					end
				end
			end
		end
	end
end

GiveAwayHelper.printFiltered = function()
	local typeString = ""
	local subTypeString = ""
	local slotString = ""
	if GiveAwayHelper.type ~= "All" then
		typeString = string.upper(GiveAwayHelper.type) .. " - "
	end
	if GiveAwayHelper.subType ~= "All" then
		subTypeString = string.upper(GiveAwayHelper.subType) .. " "
	end
	if GiveAwayHelper.slot ~= "All" then
		slotString = string.upper(GiveAwayHelper.slot) .. " "
	end
	local startString = "---- "
		.. typeString
		.. subTypeString
		.. slotString
		.. " LEVELS: "
		.. GiveAwayHelper.minLvl
		.. "-"
		.. GiveAwayHelper.maxLvl
		.. " ----"
	GiveAwayHelper.SendMessage(startString, GiveAwayHelperDB.CHANNEL)

	for _, item in pairs(GiveAwayHelper.filteredItems) do
		local countText = ""
		if item.itemCount > 1 then
			countText = "(x" .. item.itemCount .. ") "
		end

		local levelRange = ""
		if item.itemMinLevel == 60 then
			levelRange = "min lvl to claim: 60 "
		else
			levelRange = "min lvl to claim: " .. GiveAwayHelper.Max(1, item.itemMinLevel - 5) .. " "
		end

		GiveAwayHelper.SendMessage(
			item.itemLink .. " " .. countText .. " " .. levelRange .. item.note,
			GiveAwayHelperDB.CHANNEL
		)
	end
	GiveAwayHelper.SendMessage("---- END OF SEGMENT ----", GiveAwayHelperDB.CHANNEL)
end

GiveAwayHelper.ShowItems = function()
	for _, item in pairs(GiveAwayHelper.items) do
		item.frame:Hide()
	end
	GiveAwayHelper.filterItems()
	for i, item in pairs(GiveAwayHelper.filteredItems) do
		item.frame:SetPoint("TOPLEFT", 40, -30 * (i - 1) - 90)
		item.frame:Show()
		GiveAwayHelper.search_title:SetText("Item Search" .. " (" .. #GiveAwayHelper.filteredItems .. ")")
	end
end

GiveAwayHelper.GetMailByCat = function(input)
	if input == "" or input == nil then
		return
	end
	local cat, lvlMin, lvlMax = strsplit(" ", input)

	if lvlMin == nil then
		lvlMin = 0
	end
	if lvlMax == nil then
		lvlMax = 60
	end

	local list = {}

	for _, item in pairs(GiveAwayHelper.items) do
		if GiveAwayHelper.CatFilter(cat, item.itemType, item.itemSubType, item.equipLoc) then
			if GiveAwayHelper.LevelFilter(lvlMin, lvlMax, item.itemMinLevel) then
				table.insert(list, item)
			end
		end
	end

	local type = cat
	if Filters[cat] ~= nil then
		type = Filters[cat].subType
	end

	local startString = "---- " .. string.upper(type) .. " LEVELS: " .. lvlMin .. "-" .. lvlMax .. " ----"
	GiveAwayHelper.SendMessage(startString, GiveAwayHelperDB.CHANNEL)

	for _, item in pairs(list) do
		local countText = ""
		if item.itemCount > 1 then
			countText = "(x" .. item.itemCount .. ") "
		end

		local levelRange = ""
		if item.itemMinLevel == 60 then
			levelRange = "min lvl to claim: 60 "
		else
			levelRange = "min lvl to claim: " .. GiveAwayHelper.Max(1, item.itemMinLevel - 5) .. " "
		end

		GiveAwayHelper.SendMessage(
			item.itemLink .. " " .. countText .. " " .. levelRange .. item.note,
			GiveAwayHelperDB.CHANNEL
		)
	end
	GiveAwayHelper.SendMessage("---- END OF SEGMENT ----", GiveAwayHelperDB.CHANNEL)
end

GiveAwayHelper.PrintCats = function()
	local withoutKeys = {}
	for cat, val in pairs(Filters) do
		table.insert(withoutKeys, {
			order = val.order,
			key = cat,
		})
	end
	local function sortByOrder(a, b)
		return a.order < b.order
	end
	table.sort(withoutKeys, sortByOrder)
	for _, val in pairs(withoutKeys) do
		print(val.order .. ": " .. val.key)
	end
end

GiveAwayHelper.mainFrame = CreateFrame("Frame", "GiveAwayHelperMainFrame", MailFrame, "BasicFrameTemplateWithInset")
GiveAwayHelper.mainFrame:SetSize(HonorFrameProgressButton:GetWidth() + 300, MailFrame:GetHeight())
GiveAwayHelper.mainFrame:SetPoint("LEFT", MailFrame, "RIGHT", 10, 0)
GiveAwayHelper.mainFrame.Title = GiveAwayHelper.mainFrame:CreateFontString(nil, "OVERLAY")
GiveAwayHelper.mainFrame.Title:SetFontObject("GameFontHighlight")
GiveAwayHelper.mainFrame.Title:SetPoint("CENTER", GiveAwayHelper.mainFrame.TitleBg, "CENTER", 11, 0)
GiveAwayHelper.mainFrame.Title:SetText("Giveaway Helper")
GiveAwayHelper.mainFrame.ScrollFrame =
	CreateFrame("ScrollFrame", nil, GiveAwayHelper.mainFrame, "UIPanelScrollFrameTemplate")
GiveAwayHelper.mainFrame.ScrollFrame:SetPoint("TOPLEFT", GiveAwayHelper.mainFrame, "TOPLEFT", -26, -40)
GiveAwayHelper.mainFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", GiveAwayHelper.mainFrame, "BOTTOMRIGHT", -31, 15)
GiveAwayHelper.mainFrame.ScrollChild = CreateFrame("Frame", nil, GiveAwayHelper.mainFrame.ScrollFrame)
GiveAwayHelper.mainFrame.ScrollChild:SetSize(
	GiveAwayHelper.mainFrame:GetWidth(),
	GiveAwayHelper.mainFrame:GetHeight() - 100
)
GiveAwayHelper.mainFrame.ScrollFrame:SetScrollChild(GiveAwayHelper.mainFrame.ScrollChild)
GiveAwayHelper.mainFrame:Hide()

GiveAwayHelper.mainFrame:RegisterEvent("MAIL_INBOX_UPDATE")
GiveAwayHelper.mainFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "MAIL_INBOX_UPDATE" then
		GiveAwayHelper.GetAllItems()
	end
end)

--- Opts:
---     name (string): Name of the dropdown (lowercase)
---     parent (Frame): Parent frame of the dropdown.
---     items (Table): String table of the dropdown options.
---     defaultVal (String): String value for the dropdown to default to (empty otherwise).
---     changeFunc (Function): A custom function to be called, after selecting a dropdown option.
local function createDropdown(opts)
	local dropdown_name = "$parent_" .. opts["name"] .. "_dropdown"
	local menu_items = opts["items"] or {}
	local title_text = opts["title"] or ""
	local dropdown_width = 0
	local default_val = opts["defaultVal"] or ""
	local change_func = opts["changeFunc"] or function(dropdown_val) end

	local dropdown = CreateFrame("Frame", dropdown_name, opts["parent"], "UIDropDownMenuTemplate")
	local dd_title = dropdown:CreateFontString(dropdown_name .. "_title", "OVERLAY", "GameFontNormal")
	dd_title:SetPoint("TOPLEFT", 20, 15)

	for _, item in pairs(menu_items) do -- Sets the dropdown width to the largest item string width.
		dd_title:SetText(item)
		local text_width = dd_title:GetStringWidth() + 20
		if text_width > dropdown_width then
			dropdown_width = text_width
		end
	end

	UIDropDownMenu_SetWidth(dropdown, dropdown_width)
	UIDropDownMenu_SetText(dropdown, default_val)
	dd_title:SetText(title_text)

	UIDropDownMenu_Initialize(dropdown, function(self, level, _)
		local info = UIDropDownMenu_CreateInfo()
		for key, val in pairs(menu_items) do
			info.text = val
			info.checked = false
			info.menuList = key
			info.hasArrow = false
			info.func = function(b)
				UIDropDownMenu_SetSelectedValue(dropdown, b.value, b.value)
				UIDropDownMenu_SetText(dropdown, b.value)
				b.checked = true
				change_func(dropdown, b.value)
			end
			UIDropDownMenu_AddButton(info)
		end
	end)

	return dropdown
end

GiveAwayHelper.getItemFields = function(key)
	local types = {}
	for _, item in pairs(GiveAwayHelper.items) do
		if not types[item[key]] then
			types[item[key]] = true
		end
	end
	local valuesOnly = { "All" }
	for k in pairs(types) do
		if key == "itemSlot" then
			table.insert(valuesOnly, _G[k])
		else
			table.insert(valuesOnly, k)
		end
	end
	return valuesOnly
end

GiveAwayHelper.CreateInputs = function()
	local dds = {}
	local typestart = 20
	local subTypeStart = 0
	local slotStart = 0
	dds.type_dd = {
		["name"] = "Type",
		["parent"] = GiveAwayHelper.mainFrame.ScrollChild,
		["title"] = "Types",
		["items"] = GiveAwayHelper.getItemFields("itemType"),
		["defaultVal"] = "All",
		["changeFunc"] = function(dropdown_frame, dropdown_val)
			GiveAwayHelper.type = dropdown_val
			GiveAwayHelper.ShowItems()
		end,
	}

	dds.subType_dd = {
		["name"] = "SubType",
		["parent"] = GiveAwayHelper.mainFrame.ScrollChild,
		["title"] = "SubTypes",
		["items"] = GiveAwayHelper.getItemFields("itemSubType"),
		["defaultVal"] = "All",
		["changeFunc"] = function(dropdown_frame, dropdown_val)
			GiveAwayHelper.subType = dropdown_val
			GiveAwayHelper.ShowItems()
		end,
	}

	dds.slot_dd = {
		["name"] = "loc",
		["parent"] = GiveAwayHelper.mainFrame.ScrollChild,
		["title"] = "Item Slot",
		["items"] = GiveAwayHelper.getItemFields("itemSlot"),
		["defaultVal"] = "All",
		["changeFunc"] = function(dropdown_frame, dropdown_val)
			GiveAwayHelper.slot = dropdown_val
			GiveAwayHelper.ShowItems()
		end,
	}

	dds.typeDD = createDropdown(dds.type_dd)
	dds.typeDD:SetPoint("TOPLEFT", typestart, -58)
	subTypeStart = typestart + dds.typeDD:GetWidth() - 20

	dds.subTypeDD = createDropdown(dds.subType_dd)
	dds.subTypeDD:SetPoint("TOPLEFT", subTypeStart, -58)
	slotStart = subTypeStart + dds.subTypeDD:GetWidth() - 20

	dds.slotDD = createDropdown(dds.slot_dd)
	dds.slotDD:SetPoint("TOPLEFT", slotStart, -58)

	local minStart = slotStart + dds.slotDD:GetWidth()

	dds.minLvlBox =
		CreateFrame("EditBox", "GiveAwayHelperLvlMin", GiveAwayHelper.mainFrame.ScrollChild, "InputBoxTemplate")
	dds.minLvlBox:SetAutoFocus(false)
	dds.minLvlBox:SetFontObject("GameFontHighlightSmall")
	dds.minLvlBox:SetHeight(22)
	dds.minLvlBox:SetWidth(40)
	dds.minLvlBox:SetJustifyH("RIGHT")
	dds.minLvlBox:EnableMouse(true)
	dds.minLvlBox:SetMaxLetters(6)
	dds.minLvlBox:SetTextInsets(0, 5, 2, 0)
	dds.minLvlBox:SetText(1)
	dds.minLvlBox:HookScript("OnTextChanged", function(frame)
		local value = frame:GetText()
		local num = tonumber(value)
		if num == nil then
			num = 0
		end
		num = math.floor(num)
		num = GiveAwayHelper.Min(num, 60)
		num = GiveAwayHelper.Max(num, 0)
		frame:SetText(num)
		GiveAwayHelper.minLvl = num
		GiveAwayHelper.ShowItems()
	end)
	dds.minLvlBox:SetPoint("TOPLEFT", GiveAwayHelper.mainFrame.ScrollChild, minStart, -60)
	minStart = minStart + dds.minLvlBox:GetWidth() + 15

	dds.minLvl_title = dds.minLvlBox:CreateFontString("minLvl_title", "OVERLAY", "GameFontNormal")
	dds.minLvl_title:SetPoint("TOPLEFT", -3, 15)
	dds.minLvl_title:SetText("Min Lvl")

	dds.maxLvlBox =
		CreateFrame("EditBox", "GiveAwayHelperLvlMax", GiveAwayHelper.mainFrame.ScrollChild, "InputBoxTemplate")
	dds.maxLvlBox:SetPoint("TOPLEFT", GiveAwayHelper.mainFrame.ScrollChild, minStart, -60)

	dds.maxLvl_title = dds.maxLvlBox:CreateFontString("maxLvl_title", "OVERLAY", "GameFontNormal")
	dds.maxLvl_title:SetPoint("TOPLEFT", -3, 15)
	dds.maxLvl_title:SetText("Max Lvl")
	dds.maxLvlBox:SetAutoFocus(false)
	dds.maxLvlBox:SetFontObject("GameFontHighlightSmall")
	dds.maxLvlBox:SetHeight(22)
	dds.maxLvlBox:SetWidth(40)
	dds.maxLvlBox:SetJustifyH("RIGHT")
	dds.maxLvlBox:EnableMouse(true)
	dds.maxLvlBox:SetMaxLetters(6)
	dds.maxLvlBox:SetTextInsets(0, 5, 2, 0)
	dds.maxLvlBox:SetText(60)
	dds.maxLvlBox:HookScript("OnTextChanged", function(frame)
		local value = frame:GetText()
		local num = tonumber(value)
		if num == nil then
			num = 0
		end
		num = math.floor(num)
		num = GiveAwayHelper.Min(num, 60)
		num = GiveAwayHelper.Max(num, 0)
		GiveAwayHelper.maxLvl = num
		GiveAwayHelper.ShowItems()
		frame:SetText(num)
	end)

	GiveAwayHelper.searchBox =
		CreateFrame("EditBox", "GiveAwayHelperSearch", GiveAwayHelper.mainFrame.ScrollChild, "InputBoxTemplate")
	GiveAwayHelper.searchBox:SetAutoFocus(false)
	GiveAwayHelper.searchBox:SetFontObject("GameFontHighlight")
	GiveAwayHelper.searchBox:SetHeight(30)
	GiveAwayHelper.searchBox:SetWidth(minStart)
	GiveAwayHelper.searchBox:SetJustifyH("LEFT")
	GiveAwayHelper.searchBox:EnableMouse(true)
	GiveAwayHelper.searchBox:SetMaxLetters(80)
	GiveAwayHelper.searchBox:SetTextInsets(0, 5, 2, 0)
	GiveAwayHelper.searchBox:HookScript("OnTextChanged", function(frame)
		local value = frame:GetText()
		GiveAwayHelper.search = value
		GiveAwayHelper.ShowItems()
	end)
	GiveAwayHelper.searchBox:SetPoint("TOPLEFT", GiveAwayHelper.mainFrame.ScrollChild, 45, -15)
	GiveAwayHelper.search_title = GiveAwayHelper.searchBox:CreateFontString("minLvl_title", "OVERLAY", "GameFontNormal")
	GiveAwayHelper.search_title:SetPoint("TOPLEFT", -3, 12)
	GiveAwayHelper.search_title:SetText("Item Search" .. " (" .. #GiveAwayHelper.filteredItems .. ")")
end

GiveAwayHelper.showButtonText = function()
	if GiveAwayHelper.Show then
		return "Hide Giveaway Helper"
	else
		return "Show Giveaway Helper"
	end
end

GiveAwayHelper.toggleShow = function()
	GiveAwayHelper.Show = not GiveAwayHelper.Show
	GiveAwayHelper.toggleButton:SetText(GiveAwayHelper.showButtonText())
	if GiveAwayHelper.Show then
		GiveAwayHelper.mainFrame:Show()
		GiveAwayHelper.PrintListButton:SetText("Print To: " .. GiveAwayHelperDB.CHANNEL)
		GiveAwayHelper.GetAllItems()
		GiveAwayHelper.CreateInputs()
		GiveAwayHelper.ShowItems()
	else
		GiveAwayHelper.mainFrame:Hide()
	end
end

GiveAwayHelper.toggleButton = CreateFrame("Button", "EzAssignToggleButton", MailFrame, "GameMenuButtonTemplate")
GiveAwayHelper.toggleButton:SetText(GiveAwayHelper.showButtonText())
GiveAwayHelper.toggleButton:SetSize(160, 22)
GiveAwayHelper.toggleButton:SetPoint("TOPRIGHT", MailFrame, "TOPRIGHT", 0, 22)
GiveAwayHelper.toggleButton:HookScript("OnClick", GiveAwayHelper.toggleShow)

GiveAwayHelper.PrintListButton =
	CreateFrame("Button", "GiveawayPrintListButton", GiveAwayHelper.mainFrame, "GameMenuButtonTemplate")
GiveAwayHelper.PrintListButton:SetSize(150, 22)
GiveAwayHelper.PrintListButton:SetPoint("TOPRIGHT", GiveAwayHelper.mainFrame, "TOPRIGHT", 0, 22)
GiveAwayHelper.PrintListButton:HookScript("OnClick", function()
	GiveAwayHelper.printFiltered()
end)

SlashCmdList["CHAN"] = GiveAwayHelper.setChannel
SlashCmdList["LIST"] = GiveAwayHelper.GetMailByCat
SlashCmdList["CATS"] = GiveAwayHelper.PrintCats
SlashCmdList["GRAB"] = GiveAwayHelper.SearchForItem
SlashCmdList["RESET"] = GiveAwayHelper.resetVars
SlashCmdList["HELP"] = GiveAwayHelper.PrintHelp
SlashCmdList["DB"] = GiveAwayHelper.PrintDB
SlashCmdList["BANKALTS"] = GiveAwayHelper.bankAlts
SlashCmdList["NOTES"] = GiveAwayHelper.notes

Filters = {
	plate = {
		type = "Armor",
		subType = "Plate",
		order = 1,
	},
	mail = {
		type = "Armor",
		subType = "Mail",
		order = 2,
	},
	leather = {
		type = "Armor",
		subType = "Leather",
		order = 3,
	},
	cloth = {
		type = "Armor",
		subType = "Cloth",
		order = 4,
	},
	cloaks = {
		type = "Miscellaneous",
		subType = "Cloaks",
		order = 5,
	},
	offhands = {
		type = "Miscellaneous",
		subType = "Offhands",
		order = 6,
	},
	necks = {
		type = "Miscellaneous",
		subType = "Necklaces",
		order = 7,
	},
	rings = {
		type = "Miscellaneous",
		subType = "Rings",
		order = 8,
	},
	trinkets = {
		type = "Miscellaneous",
		subType = "Trinkets",
		order = 9,
	},
	shields = {
		type = "Armor",
		subType = "Shields",
		order = 10,
	},
	wands = {
		type = "Weapon",
		subType = "Wands",
		order = 11,
	},
	bows = {
		type = "Weapon",
		subType = "Bows",
		order = 12,
	},
	crossbows = {
		type = "Weapon",
		subType = "Crossbows",
		order = 13,
	},
	guns = {
		type = "Weapon",
		subType = "Guns",
		order = 14,
	},
	fist = {
		type = "Weapon",
		subType = "Fist Weapons",
		order = 15,
	},
	polearms = {
		type = "Weapon",
		subType = "Polearms",
		order = 16,
	},
	staves = {
		type = "Weapon",
		subType = "Staves",
		order = 17,
	},
	daggers = {
		type = "Weapon",
		subType = "Daggers",
		order = 18,
	},
	swords1h = {
		type = "Weapon",
		subType = "One-Handed Swords",
		order = 19,
	},
	axes1h = {
		type = "Weapon",
		subType = "One-Handed Axes",
		order = 20,
	},
	maces1h = {
		type = "Weapon",
		subType = "One-Handed Maces",
		order = 21,
	},
	swords2h = {
		type = "Weapon",
		subType = "Two-Handed Swords",
		order = 22,
	},
	axes2h = {
		type = "Weapon",
		subType = "Two-Handed Axes",
		order = 23,
	},
	maces2h = {
		type = "Weapon",
		subType = "Two-Handed Maces",
		order = 24,
	},
	enchanting = {
		type = "Recipe",
		subType = "Enchanting",
		order = 25,
	},
	alchemy = {
		type = "Recipe",
		subType = "Alchemy",
		order = 26,
	},
	blacksmithing = {
		type = "Recipe",
		subType = "Blacksmithing",
		order = 27,
	},
	engineering = {
		type = "Recipe",
		subType = "Engineering",
		order = 28,
	},
	leatherworking = {
		type = "Recipe",
		subType = "Leatherworking",
		order = 29,
	},
	tailoring = {
		type = "Recipe",
		subType = "Tailoring",
		order = 30,
	},
	books = {
		type = "Recipe",
		subType = "Book",
		order = 31,
	},
}

local function trimStringBeforeHyphen(inputString)
	local result = string.match(inputString, "^(.-)-")
	return result or inputString
end

local function myChatFilter(self, _, msg, _, _, _, author)
	local shortName = trimStringBeforeHyphen(author)
	if string.lower(self.name) ~= "claims" then
		return false
	end

	if GiveAwayHelperDB.BankAlts[string.lower(shortName)] ~= nil then
		return true
	end
	if string.find(msg, "%[") == nil or string.find(msg, "%]") == nil then
		return true
	end
	return false
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", myChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", myChatFilter)

GiveAwayHelper.Min = function(a, b)
	if a < b then
		return a
	else
		return b
	end
end

GiveAwayHelper.Max = function(a, b)
	if a > b then
		return a
	else
		return b
	end
end

GiveAwayHelper.printTableValues = function(tbl, indent)
	indent = indent or 0

	for key, value in pairs(tbl) do
		if type(value) == "table" then
			print(string.rep("  ", indent) .. key .. " (table):")
			GiveAwayHelper.printTableValues(value, indent + 1)
		else
			print(string.rep("  ", indent) .. key .. ": " .. tostring(value))
		end
	end
end

GiveAwayHelper.PrintDB = function()
	print("-----------------------")
	GiveAwayHelper.printTableValues(GiveAwayHelperDB)
	print("-----------------------")
end

GiveAwayHelper.PrintHelp = function()
	print("----------------------------")
	print("/gaDB - view saved variables")
	print("/gaChan <channel number or GUILD> - sets the channel to send messages to")
	-- print("/gaOfficerChan <channel number> - sets the channel to send officer messages to. Includes mailbox location")
	print(
		"/gaList <cat> <levelMin optional> <levelMax optional> - lists all items in the mailbox of the given category. If levelMin and levelMax are not provided, defaults to 0-60"
	)
	print("/gaCats - lists all categories")
	print("/gaGrab <Link> - searches for and grabs the linked item")
	print(
		"/gabankalts <name> <add or remove> - adds the name to bankalt list. (names on list will not show in claims tab)"
	)
	print("To add a custom note to an item, include it within [ and ] in the mail subject.")
	print("You can also add pre-defined notes by using the following keywords:")
	GiveAwayHelper.printTableValues(GiveAwayHelperDB.Notes)
	print("/ganotes <label> <note or remove> - adds a predefined note to the list. Use 'remove' to remove a note")
	print("-----------------------")
end
