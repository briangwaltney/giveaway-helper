SLASH_CHAN1 = "/gaChan"
SLASH_OFFCHAN1 = "/gaOfficerChan"
SLASH_LIST1 = "/gaList"
SLASH_CATS1 = "/gaCats"
SLASH_GRAB1 = "/gaGrab"
SLASH_HELP1 = "/gahelp"
SLASH_FRAMESTK1 = "/fs"

local CHANNEL = "7"
local OFFICER_CHANNEL = "8"

local function PrintHelp()
	print("/gaChan <channel number or GUILD> - sets the channel to send messages to")
	print("/gaOfficerChan <channel number> - sets the channel to send officer messages to. Includes mailbox location")
	print(
		"/gaList <cat> <levelMin optional> <levelMax optional> - lists all items in the mailbox of the given category. If levelMin and levelMax are not provided, defaults to 0-60"
	)
	print("/gaCats - lists all categories")
	print("/gaGrab <mail> <itemInMail> - grabs the given mail. (x, y) in officer message match the mail and item")
end

local function setChannel(channelNum)
	if channelNum == "" then
		CHANNEL = "5"
	else
		CHANNEL = channelNum
	end
	print("CHANNEL SET TO: " .. CHANNEL)
end

local function setOfficerChannel(channelNum)
	if channelNum == "" then
		OFFICER_CHANNEL = "6"
	else
		OFFICER_CHANNEL = channelNum
	end
	print("OFFICER CHANNEL SET TO: " .. OFFICER_CHANNEL)
end

local function SendMessage(msg, channel)
	if channel == "GUILD" then
		SendChatMessage(msg, "GUILD")
	else
		SendChatMessage(msg, "CHANNEL", nil, channel)
	end
end

local function GrabMail(index)
	local mail, item = strsplit(" ", index)
	TakeInboxItem(mail, item)
end

local function CatFilter(cat, itemType, itemSubType, loc)
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

local function LevelFilter(min, max, itemLevel)
	if itemLevel >= tonumber(min) and itemLevel <= tonumber(max) then
		return true
	else
		return false
	end
end

local function GetMailItems(cat)
	if cat == "" or cat == nil then
		return
	end
	local cat, lvlMin, lvlMax = strsplit(" ", cat)

	if lvlMin == nil then
		lvlMin = 0
	end
	if lvlMax == nil then
		lvlMax = 60
	end

	local numItems = GetInboxNumItems()
	local items = {}
	for i = 1, numItems do
		local _, _, _, subject, _, _, _, numItems, _, _, _, _, isGM = GetInboxHeaderInfo(i)
		if not isGM and numItems ~= nil then
			for j = 1, 20 do
				local name, itemID, _, itemCount = GetInboxItem(i, j)
				local link = GetInboxItemLink(i, j)
				if name then
					local _, _, _, _, itemMinLevel, itemType, itemSubType, _, equipLoc = GetItemInfo(itemID)
					if CatFilter(cat, itemType, itemSubType, equipLoc) then
						if LevelFilter(lvlMin, lvlMax, itemMinLevel) then
							local note = ""
							if string.find(string.lower(subject), "raid") then
								note = "(Core raider mains only)"
							end

							local mailLoc = "(" .. i .. ", " .. j .. ")"

							if items[name] ~= nil then
								items[name].itemCount = items[name].itemCount + itemCount
								if items[name].note == "" then
									items[name].note = note
								end
								items[name].mail = items[name].mail .. ", " .. mailLoc
							else
								items[name] = {
									itemName = name,
									itemLink = link,
									itemMinLevel = itemMinLevel,
									itemType = itemType,
									itemSubType = itemSubType,
									itemCount = itemCount,
									note = note,
									mail = mailLoc,
								}
							end
						end
					end
				end
			end
		end
	end

	local function sortByLevel(a, b)
		return a.itemMinLevel > b.itemMinLevel
	end

	local itemsWithoutIds = {}

	for _, item in pairs(items) do
		table.insert(itemsWithoutIds, item)
	end

	table.sort(itemsWithoutIds, sortByLevel)

	local type = cat
	local num = 0
	if Filters[cat] ~= nil then
		type = Filters[cat].subType
		num = Filters[cat].order
	end

	local startString = "---- " .. string.upper(type) .. " LEVELS: " .. lvlMin .. "-" .. lvlMax .. " ----"
	SendMessage(startString, CHANNEL)
	SendMessage(startString, OFFICER_CHANNEL)

	for _, item in pairs(itemsWithoutIds) do
		local countText = ""
		if item.itemCount > 1 then
			countText = "(x" .. item.itemCount .. ") "
		end

		local levelRange = ""
		if item.itemMinLevel == 60 then
			levelRange = "min lvl to claim: 60 "
		else
			levelRange = "min lvl to claim: " .. Max(1, item.itemMinLevel - 5) .. " "
		end

		SendMessage(item.itemLink .. " " .. countText .. " " .. levelRange .. item.note, CHANNEL)

		SendMessage(
			item.itemLink .. " " .. countText .. " " .. levelRange .. item.note .. " " .. item.mail,
			OFFICER_CHANNEL
		)
	end
	SendMessage("---- END OF SEGMENT ----", CHANNEL)
	SendMessage("---- END OF SEGMENT " .. num .. " ----", OFFICER_CHANNEL)
end

function Min(a, b)
	if a < b then
		return a
	else
		return b
	end
end

function Max(a, b)
	if a > b then
		return a
	else
		return b
	end
end

function PrintCats()
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

SlashCmdList["CHAN"] = setChannel
SlashCmdList["OFFCHAN"] = setOfficerChannel
SlashCmdList["LIST"] = GetMailItems
SlashCmdList["CATS"] = PrintCats
SlashCmdList["GRAB"] = GrabMail
SlashCmdList["HELP"] = PrintHelp

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
}

local BankAlts = {
	holdmytea = true,
	levelup = true,
	baggervance = true,
	ofthewhale = true,
}

function TrimStringBeforeHyphen(inputString)
	local result = string.match(inputString, "^(.-)-")
	return result or inputString
end

local function myChatFilter(self, event, msg, longAuthor, lang, _, author, ...)
	local shortName = TrimStringBeforeHyphen(author)
	if string.lower(self.name) ~= "claims" then
		return false
	end

	if BankAlts[string.lower(shortName)] ~= nil then
		return true
	end
	if string.find(msg, "%[") == nil or string.find(msg, "%]") == nil then
		return true
	end
	return false
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", myChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", myChatFilter)
