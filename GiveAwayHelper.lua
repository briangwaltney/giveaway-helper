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
	if Filters[cat] ~= nil then
		type = Filters[cat].subType
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
	SendMessage("---- END OF SEGMENT ----", OFFICER_CHANNEL)
	SendMessage("---- END OF SEGMENT ----", CHANNEL)
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
		local x = {
			type = val.type,
			subType = val.subType,
			key = cat,
		}
		table.insert(withoutKeys, x)
	end
	local function sortByType(a, b)
		return a.type < b.type
	end
	table.sort(withoutKeys, sortByType)
	for _, val in pairs(withoutKeys) do
		print(val.key)
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
	},
	mail = {
		type = "Armor",
		subType = "Mail",
	},
	leather = {
		type = "Armor",
		subType = "Leather",
	},
	cloth = {
		type = "Armor",
		subType = "Cloth",
	},
	shields = {
		type = "Armor",
		subType = "Shields",
	},
	offhands = {
		type = "Armor",
		subType = "Miscellaneous",
	},
	librams = {
		type = "Armor",
		subType = "Librams",
	},
	idols = {
		type = "Armor",
		subType = "Idol",
	},
	totems = {
		type = "Armor",
		subType = "Totem",
	},
	sigils = {
		type = "Armor",
		subType = "Sigil",
	},
	relics = {
		type = "Armor",
		subType = "Relic",
	},
	axes2h = {
		type = "Weapon",
		subType = "Two-Handed Axes",
	},
	maces2h = {
		type = "Weapon",
		subType = "Two-Handed Maces",
	},
	swords2h = {
		type = "Weapon",
		subType = "Two-Handed Swords",
	},
	polearms = {
		type = "Weapon",
		subType = "Polearms",
	},
	axes1h = {
		type = "Weapon",
		subType = "One-Handed Axes",
	},
	maces1h = {
		type = "Weapon",
		subType = "One-Handed Maces",
	},
	swords1h = {
		type = "Weapon",
		subType = "One-Handed Swords",
	},
	daggers = {
		type = "Weapon",
		subType = "Daggers",
	},
	wands = {
		type = "Weapon",
		subType = "Wands",
	},
	bows = {
		type = "Weapon",
		subType = "Bows",
	},
	crossbows = {
		type = "Weapon",
		subType = "Crossbows",
	},
	guns = {
		type = "Weapon",
		subType = "Guns",
	},
	staves = {
		type = "Weapon",
		subType = "Staves",
	},
	fist = {
		type = "Weapon",
		subType = "Fist Weapons",
	},
	rings = {
		type = "Miscellaneous",
		subType = "Rings",
	},
	necks = {
		type = "Miscellaneous",
		subType = "Necklaces",
	},
	trinkets = {
		type = "Miscellaneous",
		subType = "Trinkets",
	},
	cloaks = {
		type = "Miscellaneous",
		subType = "Cloaks",
	},
	enchanting = {
		type = "Recipe",
		subType = "Enchanting",
	},
	alchemy = {
		type = "Recipe",
		subType = "Alchemy",
	},
	blacksmithing = {
		type = "Recipe",
		subType = "Blacksmithing",
	},
	engineering = {
		type = "Recipe",
		subType = "Engineering",
	},
	leatherworking = {
		type = "Recipe",
		subType = "Leatherworking",
	},
	tailoring = {
		type = "Recipe",
		subType = "Tailoring",
	},
}

local BankAlts = {
	holdmytea = true,
	levelup = true,
	baggervance = true,
}

local function myChatFilter(self, event, msg, longAuthor, lang, _, author, ...)
	if self.name ~= "claims" then
		return false
	end
	if BankAlts[string.lower(author)] ~= nil then
		return true
	end
	if string.find(msg, "%[") == nil or string.find(msg, "%]") == nil then
		return true
	end
	return false
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", myChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", myChatFilter)
