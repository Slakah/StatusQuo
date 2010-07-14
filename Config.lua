local addon = StatusQuo

local Update
local function LoadOptions(panel)
	local db = addon.db
	
	local title, sub = LibStub("tekKonfig-Heading").new(panel, "StatusQuo", "Select the Texture used by StatusQuo")
	--CreateScrollFrame function
	local CreateScrollFrame; do
		--Scroll Scripts
		local function Scroll_OnMouseWheel(self, d) self.bar:SetValue(self.bar:GetValue() - ((self.bar:GetHeight() / 2) * d)) end
		
		local function Scroll_OnVerticalScroll(self, offset)
			local scrollbar = self.bar
			scrollbar:SetValue(offset)
			local min, max = scrollbar:GetMinMaxValues()
			if offset == 0 then
				scrollbar.up:Disable()
			else
				scrollbar.up:Enable()
			end
			if floor(offset) == floor(max) then
				scrollbar.down:Disable()
			else
				scrollbar.down:Enable()
			end
		end
		
		local function Scroll_OnScrollRangeChanged(self, xrange, yrange)
			local scrollbar = self.bar
			if not yrange then
				yrange = self:GetVerticalScrollRange()
			end
			scrollbar:SetMinMaxValues(0, yrange)
			scrollbar:SetValue(scrollbar:GetValue() > yrange and yrange or scrollbar:GetValue())
			if floor(yrange) == 0 then
				scrollbar:Hide()
				scrollbar:GetThumbTexture():Hide()
			else
				scrollbar:Show()
				scrollbar:GetThumbTexture():Show()
			end
		end
		--Scrollbar Scripts
		local function Scrollbar_OnValueChanged(self, val) self:GetParent():SetVerticalScroll(val) end
		--UpButtonScripts
		local function UpButton_OnClick(self)
			local parent = self:GetParent()
			parent:SetValue(parent:GetValue() - (parent:GetHeight() / 2))
			PlaySound("UChatScrollButton")
		end
		--DownButtonScripts
		local function DownButton_OnClick(self)
			local parent = self:GetParent()
			parent:SetValue(parent:GetValue() + (parent:GetHeight() / 2))
			PlaySound("UChatScrollButton")
		end
		
		function CreateScrollFrame(parent, ...)
			local scroll = CreateFrame("ScrollFrame", nil, parent)
			scroll:SetPoint(...)
			scroll:EnableMouseWheel(true)
			scroll:SetScript("OnMouseWheel", Scroll_OnMouseWheel)
			scroll:SetScript("OnVerticalScroll", Scroll_OnVerticalScroll)
			scroll:SetScript("OnScrollRangeChanged", Scroll_OnScrollRangeChanged)

			local scrollbar = CreateFrame("Slider", nil, scroll)
			scrollbar:Hide()
			scrollbar:SetWidth(16)
			scrollbar:SetMinMaxValues(0, 0)
			scrollbar:SetPoint("TOPRIGHT", 0, -11)
			scrollbar:SetPoint("BOTTOMRIGHT", 0, 11)
			scrollbar:SetScript("OnValueChanged", Scrollbar_OnValueChanged)
			scroll.bar = scrollbar
			
			local up = CreateFrame("Button", nil, scrollbar, "UIPanelScrollUpButtonTemplate")
			up:SetPoint("BOTTOM", scrollbar, "TOP", 0, -5)
			up:SetScript("OnClick", UpButton_OnClick)
			up:Disable()
			scrollbar.up = up
			
			local down = CreateFrame("Button", nil, scrollbar, "UIPanelScrollDownButtonTemplate")
			down:SetPoint("TOP", scrollbar, "BOTTOM", 0, 5)
			down:SetScript("OnClick", DownButton_OnClick)
			scrollbar.down = down

			
			local scrollchild = CreateFrame("Frame", nil, scroll)
			scrollchild:SetPoint("TOP")
			scrollchild:SetHeight(10); scrollchild:SetWidth(10)
			scrollchild:SetPoint("RIGHT", -10)
			
			scroll:SetScrollChild(scrollchild)
			scrollchild:Show()
			scroll.scrollchild = scrollchild
			
			scrollbar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
			local thumb = scrollbar:GetThumbTexture()
			thumb:SetWidth(16) thumb:SetHeight(24)
			thumb:SetTexCoord(1/4, 3/4, 1/8, 7/8)
			scrollbar:SetThumbTexture(thumb)
			
			return scroll, scrollchild
		end
	end
	
	local scroll, child = CreateScrollFrame(panel, "TOPLEFT", sub, "TOPLEFT", 20, -20)
	scroll:SetPoint("BOTTOMRIGHT", -20, 20)

	
	local SM = LibStub("LibSharedMedia-3.0")
	local rows;do
		local function Button_OnClick(self)
			local parent = self:GetParent()
			if parent.select then
				parent.select:UnlockHighlight()
			end
			self:LockHighlight()
			parent.select = self
			addon:SetDefaultTexture(self:GetText())
		end
		
		local function Button_Create(i, ...)
			local button = CreateFrame("button", nil, child)
			button:SetPoint("RIGHT", scroll, "RIGHT", -16, 0)
			button:SetPoint(...)
			button:SetHeight(30)
			button:Show()
			
			local tex = button:CreateTexture()
			if i % 3 == 0 then
				tex:SetVertexColor(0.2, 0.9, 0.2)
			elseif i % 2 == 0 then
				tex:SetVertexColor(0.2, 0.2, 0.9)
			else
				tex:SetVertexColor(0.9, 0.2, 0.2)
			end
			tex:SetAllPoints()
			button.tex = tex
			
			button:SetNormalFontObject("GameFontNormal")
			button:SetHighlightFontObject("GameFontHighlight")
			button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD") --Interface\\Buttons\\UI-PlusButton-Hilight
			
			button:SetScript("OnClick", Button_OnClick)
			return button
		end
		
		rows = setmetatable({}, {__index = function(t, i)
			local button = Button_Create(i, "TOPLEFT", t[i-1], "BOTTOMLEFT")
			t[i] = button
			return button
		end})
		rows[1] = Button_Create(1, "TOPLEFT")
	end
		
	function Update()
		local i = 1
		if child.select then child.select:UnlockHighlight() end
		for name, tex in pairs(SM:HashTable("statusbar")) do
			local button = rows[i]
			button:SetText(name)
			button.tex:SetTexture(tex)
			if name == addon.db.defaulttex then
				child.select = button
				button:LockHighlight()
			end
			i = i + 1
		end
	end
	Update()
	panel:SetScript("OnShow", Update)
end


local panel = CreateFrame("Frame", nil, UIParent)
panel.name = "StatusQuo"
panel:Hide()
panel:SetScript("OnShow", LoadOptions)

InterfaceOptions_AddCategory(panel)

panel.default = function() -- incase someone clicks reset all to defaults
	wipe(addon.db)
	if Update then Update() end
end

addon.panel = panel

