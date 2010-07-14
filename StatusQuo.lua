local aname, atbl = ...
local addon = CreateFrame("Frame", aname) --Addon obj in the global namespace key aname
atbl.addon = addon
addon:RegisterEvent("ADDON_LOADED")

--Functions which we use a lot
local EnumerateFrames = EnumerateFrames
--make easier to type vars, yes the string. bit is hard.
local fmt = string.format

-- Register statusbar textures with SM
local SM = LibStub:GetLibrary("LibSharedMedia-3.0")
SM:Register("statusbar", "BantoBar", "Interface\\AddOns\\StatusQuo\\Textures\\banto")
SM:Register("statusbar", "Smooth", "Interface\\AddOns\\StatusQuo\\Textures\\smooth")
SM:Register("statusbar", "Perl", "Interface\\AddOns\\StatusQuo\\Textures\\perl")
SM:Register("statusbar", "Glaze", "Interface\\AddOns\\StatusQuo\\Textures\\glaze")
SM:Register("statusbar", "Cilo", "Interface\\AddOns\\StatusQuo\\Textures\\cilo")
SM:Register("statusbar", "Charcoal", "Interface\\AddOns\\StatusQuo\\Textures\\Charcoal")
SM:Register("statusbar", "Steel", "Interface\\AddOns\\StatusQuo\\Textures\\Steel")
SM:Register("statusbar", "Glamour7", "Interface\\AddOns\\StatusQuo\\Textures\\Glamour7")

local mtindex = getmetatable(CreateFrame("StatusBar")).__index
local rawSetTexture = mtindex.SetStatusBarTexture


local function SetTexture(bar)
	rawSetTexture(bar, SM:Fetch("statusbar", addon.db.defaulttex))
end
local function dummy() end

local lastframe -- the last frame we met.
local otype
local function TextureStatusBars(f)
	local f = EnumerateFrames(f)
	while f do
		otype = f:GetObjectType()
		if otype ~= "Button" then
			if otype == "StatusBar" then
				SetTexture(f)
				f.SetStatusBarTexture = dummy
			end
			lastframe = f
		end
		f = EnumerateFrames(f)
 	end
end

local function TextureNewStatusBars()
	TextureStatusBars(lastframe)
end



local function SetUpDB(self, defaults)
	if not StatusQuo2DB then
		StatusQuo2DB = {}
	end
	self.db = setmetatable(StatusQuo2DB, {__index = defaults})
end

--OnEnable
addon:SetScript("OnEvent" , function(self, _, addonname)
	SetUpDB(self, {
		defaulttex = "Smooth"
	})
	
	mtindex.SetStatusBarTexture = dummy
	hooksecurefunc("CreateFrame", TextureNewStatusBars)
	do
		local numchildren = 0
		self:SetScript("OnUpdate", function(self, el)
			if WorldFrame:GetNumChildren() > numchildren then
				TextureNewStatusBars()
				numchildren = WorldFrame:GetNumChildren()
			end
		end)
	end
	
	--Clean Up for the garbage collection monster
	self:SetScript("OnEvent", nil)
	self:UnregisterEvent("ADDON_LOADED")
end)

--Options stuff
function addon:SetDefaultTexture(texname)
	self.db.defaulttex = texname
	TextureStatusBars()
end

--Slash Commands	
local L = setmetatable(StatusQuo_Locale or {}, {__index = function(t, k)
	t[k] = k
	return k
end})
StatusQuo_Locale = nil

local function Lvararg(arg1, ...) if arg1 then return L[arg1], Lvararg(...) end end

local function printf(msg, ...)
	if ... then
		msg = L[msg]:format(Lvararg(...))
	else msg = L[msg]
	end
	print(("|cff00F5FFStatusQuo: |r%s"):format(msg))
end

local function printslash(cmd, msg, ...)
	if ... then
		msg = L[msg]:format(Lvararg(...))
	else msg = L[msg]
	end
	print((" - |cFFFF9933%s|r: %s"):format(cmd, msg))
end

local function printhelp()
	printf([[Commands (/sq, /statusq, /squo or /statusquo)]])
	printslash("reset", "Resets all Settings for StatusQuo")
	printslash("deftex <texture>", "Set the texture used by StatusQuo (|cff00F5FF%s|r)", addon.db.defaulttex)
	printslash("list", "List all the textures available to StatusQuo")
	printslash("options", "Open the options menu.")
end

--last ditch attempt to finding a matching texture
local function FindTexture(tex)
	for i, name in ipairs(SM:List("statubar")) do
		if name:lower() == tex then
			return name
		end
	end
end

SlashCmdList["STATUSQUO"] = function(msg)
	local a, b = msg:match("(%S+)%s*(%S*)")
	if a then
		a = a:lower()
		if a == "reset" then
			wipe(addon.db)
			TextureStatusBars()
			printf("Reset DB")
		elseif a == "defaulttex" or a == "deftex" or a == "dtex" or a == "tex" then
			local tex = (SM:IsValid("statusbar", b) and b) or FindTexture(b:lower())
			if not tex then
				printf("\"%s\" is not a valid texture, type /sq list for a list of valid Texture names", b)
			else
				addon:SetDefaultTexture(b)
				printf("Default texture set to %s", b or "")
			end
		elseif a == "list" then
			printf("Known Textures:")
			--Vodoo magic going on here
			local largestname, slength = 0
			for name, tex in pairs(SM:HashTable("statusbar")) do
				slength = #name
				if slength > largestname then
					largestname = slength
				end
			end
			largestname = largestname
			for name, tex in pairs(SM:HashTable("statusbar")) do 
				print("|cffffff00"..name.."|r  "..string.rep(" ", (largestname - #name)).."   |T"..tex..":0:10|t")
			end
		elseif a == "options" or a == "option" or a == "config" then
			InterfaceOptionsFrame_OpenToCategory(addon.panel)
		else
			printhelp()
		end
	else
		InterfaceOptionsFrame_OpenToCategory(addon.panel)
	end
end


SLASH_STATUSQUO1 = "/statusquo"
SLASH_STATUSQUO2 = "/squo"
SLASH_STATUSQUO3 = "/statusq"
SLASH_STATUSQUO4 = "/sq"
