local _, Questra = ...

local HBD = Questra.HBD

local portalDataCollector --Quick tool for collecting new portal data in the required format. So much faster this way!
function Questra:GetOrCreatePortalDataCollector()
	if not portalDataCollector then
		local panel = CreateFrame("Frame", "PortalDataCollector", UIParent, "BackdropTemplate")
		panel:SetSize(300, 200)
		panel:SetPoint("Center", UIParent)
		
		panel:EnableMouse(true)
		panel:SetScript("OnMouseDown", function()
			panel:SetMovable(true)
			panel:StartMoving()
		end)
		panel:SetScript("OnMouseUP", function()
			panel:StopMovingOrSizing()
			panel:SetMovable(false)
		end)
		
		panel:SetFrameStrata("Low")
		panel:SetFrameLevel(1)

		panel:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			tileEdge = true,
			tileSize = 32,
			edgeSize = 16,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})

		panel:SetBackdropColor(0,0,0)

		panel.Set = CreateFrame("Button", panel:GetName().."Set", panel, "UIMenuButtonStretchTemplate")

		panel.Set:SetSize(125, 25)
		panel.Set:SetPoint("TopLeft", 5, -5)
	
		panel.Set:SetText("Set Origin")
	
		panel.Clear = CreateFrame("Button", panel:GetName().."ClearButton", panel, "UIMenuButtonStretchTemplate")
		panel.Clear:SetText("Clear")
		panel.Clear:SetSize(125, 25)
		panel.Clear:SetPoint("TopLeft", panel.Set, "TopRight", 5, 0)
		local t = CreateFrame("EditBox", "PortalDataCollectorDisplay", panel, "InputBoxScriptTemplate")
		t:SetAutoFocus(false)
		t:SetPoint("TopLeft", 5 , -30)
		t:SetPoint("BottomRight", -5, 5)
		t:SetHighlightColor(.5,1,.5)
		t:SetClampedToScreen(true)
		t:SetJustifyH("LEFT")
		t:SetJustifyV("BOTTOM")
		t:SetAutoFocus(false)
		t:SetMovable(true)
		t:SetMultiLine(true)
		t:SetFrameStrata("LOW")
		t:SetFrameLevel(10)
		t:SetFixedFrameStrata(true)
		t:SetFontObject("GameFontNormal")

		t:SetScript("OnKeyDown", function(_, key)
			if key == "DELETE" then
				ReloadUI()
			end
		end)

		panel.Clear:SetScript("OnClick" , function() t:SetText("") end)

		local o = ""
		local d = "{}"
		

		
		panel.Set:SetScript("OnClick", function()
			local x, y, id = Questra.GetPlayerPosition()
			
			if o == "" then
				o = [[tooltip = "",
            origin = {
                x = ]]..x..[[,
                y = ]]..y..[[,
                mapID = ]]..id..[[,
            }]]
				d = "{}"
				panel.Set:SetText("Set Destination")
			else
				d = [[{
                x = ]]..x..[[,
                y = ]]..y..[[,
                mapID = ]]..id..[[,
            }]]
				panel.Set:SetText("Set Origin")
			end

			local text = [[{
            ]]..o..[[,
            destination = ]]..d..[[ 
        },]]


			t:SetText(text)
			if o ~= "" and d ~= "{}" then
				o, d = "", "{}"
			end
		end)

		panel.close = CreateFrame("Button", panel:GetName().."Close", panel, "UIPanelCloseButton")
		panel.close:SetPoint("TopRight")
		
		portalDataCollector = t
	end
	return portalDataCollector
end

do --portal  transit system!
	local storedIDs = {}
	local mapOverrides = { --maps that must be considered there own world map for portal reasons
		[875] = true,
		[876] = true,
		[619] = true,
		[424] = true,
		[1355] = true,
		[905] = true,
		[948] = true,
		[12] = true,
		[13] = true,
		[113] = true,
		[1543] = true,
		[203] = true,
		[1670] = true,
		--[1671] = true,
	}	
	local function GetZoneIDs(baseID, noOveride) --get parent zone IDS for baseID
		if baseID and not storedIDs[baseID] then
			local _ids = {baseID}
			local info = C_Map.GetMapInfo(baseID)
			local count 
			while info do
				local parentInfo = C_Map.GetMapInfo(info.parentMapID)
				if parentInfo then
					if (info.parentMapID and tContains(_ids, info.parentMapID) or (parentInfo.mapType == Enum.UIMapType.Cosmic)) then
						break --we've hit a repeat id or the cosmic map
					end
					 if (not noOveride and not mapOverrides[info.mapID]) 
					 and ((parentInfo.mapType ~= Enum.UIMapType.World) 
					 and (parentInfo.mapType ~= Enum.UIMapType.Cosmic))
					 and not tContains(_ids, info.parentMapID) then
					
						local _ = info.parentMapID and tinsert(_ids, info.parentMapID)
					end
				end
				info = parentInfo
			end
			storedIDs[baseID] = _ids --store it, so we don't have to dig for this ID again
		end
		return baseID and storedIDs[baseID] or {}--return then stored id
	end
	Questra.GetZoneIDs = GetZoneIDs

	--List all known portals(no "alliance specific" data has been collected yet.)
	local networkLocations = {
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.37890044201114,
				mapID = 85,
				x = 0.50135588842975,
			},
			origin = {
				y = 0.57890164852142,
				x = 0.33675336837769,
				mapID = 619,
			},
		}, -- [1]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.5475,
				x = 0.2089,
				mapID = 1670,
			},
		}, -- [2]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.098700038554703,
				x = 0.63762695780944,
				mapID = 1530,
			},
		}, -- [3]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.14021435795428,
				x = 0.28511899099554,
				mapID = 371,
			},
		}, -- [4]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.41296159312871,
				x = 0.46663798048915,
				mapID = 630,
			},
		}, -- [5]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.2395178315967,
				x = 0.55211635002278,
				mapID = 627,
			},
		}, -- [6]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.267044943523,
				x = 0.58198599758397,
				mapID = 74,
			},
		}, -- [7]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.24446088576159,
				x = 0.63479490345888,
				mapID = 198,
			},
		}, -- [8]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.25476156859977,
				x = 0.55301410416057,
				mapID = 125,
			},
		}, -- [9]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.70166727701823,
				x = 0.73611111111111,
				mapID = 1163,
			},
		}, -- [10]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.53103871944398,
				x = 0.50934902393179,
				mapID = 207,
			},
		}, -- [11]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.48866477166798,
				x = 0.56823639354067,
				mapID = 111,
			},
		}, -- [12]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.51649872833174,
				x = 0.60789520263672,
				mapID = 624,
			},
		}, -- [13]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.49464972688152,
				x = 0.89232424936608,
				mapID = 100,
			},
		}, -- [14]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.89813858019974,
				mapID = 85,
				x = 0.57103620194035,
			},
			origin = {
				y = 0.18680549839493,
				x = 0.58536847841333,
				mapID = 110,
			},
		}, -- [15]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.39140493181188,
				mapID = 85,
				x = 0.4764620014373,
			},
			origin = {
				y = 0.79655785617416,
				x = 0.56321089764031,
				mapID = 245,
			},
		}, -- [16]
		{
			tooltip = "Portal to Orgrimmar",
			destination = {
				y = 0.37890044201114,
				mapID = 85,
				x = 0.50135588842975,
			},
			origin = {
				y = 0.53492878438869,
				x = 0.73593721339996,
				mapID = 241,
			},
		}, -- [17]
		{
			tooltip = "Portal to HellFire Peninsula, Outland",
			destination = {
				y = 0.49560798548094,
				mapID = 100,
				x = 0.89162719838972,
			},
			origin = {
				y = 0.17035557881295,
				x = 0.85221381072501,
				mapID = 90,
			},
		}, -- [18]
		{
			tooltip = "Portal to Zuldazar",
			destination = {
				y = 0.68583374023438,
				mapID = 1163,
				x = 0.70333319769965,
			},
			origin = {
				y = 0.62772743942331,
				x = 0.4727348470357,
				mapID = 1355,
			},
		}, -- [19]
		{
			tooltip = "Banshee's Wail to Drustvar",
			destination = {
				y = 0.43693684881455,
				mapID = 896,
				x = 0.20607681440632,
			},
			origin = {
				y = 0.62980799772618,
				x = 0.58454345381237,
				mapID = 862,
			},
		}, -- [20]
		{
			tooltip = "Banshee's Wail to Stormsong Valley",
			destination = {
				y = 0.31070487254826,
				mapID = 942,
				x = 0.51058783027949,
			},
			origin = {
				y = 0.62980799772618,
				x = 0.58454345381237,
				mapID = 862,
			},
		}, -- [21]
		{
			tooltip = "Banshee's Wail to Tiragarde Sound",
			destination = {
				y = 0.51159193712012,
				mapID = 895,
				x = 0.88203434638142,
			},
			origin = {
				y = 0.62980799772618,
				x = 0.58454345381237,
				mapID = 862,
			},
		}, -- [22]
		{
			tooltip = "Portal to Nazjatar",
			destination = {
				y = 0.6262505365728,
				mapID = 1355,
				x = 0.47193758468472,
			},
			origin = {
				y = 0.85333353678385,
				x = 0.62999979654948,
				mapID = 1163,
			},
		}, -- [23]
		{
			tooltip = "Portal to Silithus",
			destination = {
				y = 0.44943381928406,
				mapID = 81,
				x = 0.41537530710609,
			},
			origin = {
				y = 0.85416666666667,
				x = 0.73611111111111,
				mapID = 1163,
			},
		}, -- [24]
		{
			tooltip = "Portal to Thunder Bluff",
			destination = {
				y = 0.1687186758094,
				mapID = 88,
				x = 0.22214766105373,
			},
			origin = {
				y = 0.775,
				x = 0.73666653103299,
				mapID = 1163,
			},
		}, -- [25]
		{
			tooltip = "Portal to Silvermoon City",
			destination = {
				y = 0.19238329952114,
				mapID = 110,
				x = 0.58264465141624,
			},
			origin = {
				y = 0.62250061035156,
				x = 0.73944430881076,
				mapID = 1163,
			},
		}, -- [26]
		{
			tooltip = "Greasy Eel to Mechagon",
			destination = {
				y = 0.21320900152281,
				mapID = 1462,
				x = 0.75731763870321,
			},
			origin = {
				y = 0.87604148782861,
				x = 0.41825685012782,
				mapID = 1165,
			},
		}, -- [27]
		{
			tooltip = "Portal to Dalaran, Crystalsong Forest",
			destination = {
				y = 0.467831174332,
				mapID = 125,
				x = 0.55915854190679,
			},
			origin = {
				y = 0.91711090955257,
				x = 0.56224005120374,
				mapID = 85,
			},
		}, -- [28]
		{
			tooltip = "Portal to Jade Forest",
			destination = {
				y = 0.13982759669818,
				mapID = 371,
				x = 0.2855772268634,
			},
			origin = {
				y = 0.9226301536912,
				x = 0.57460081297161,
				mapID = 85,
			},
		}, -- [29]
		{
			tooltip = "Portal to Zuldazar",
			destination = {
				y = 0.68583374023438,
				mapID = 1163,
				x = 0.70333319769965,
			},
			origin = {
				y = 0.91348896151172,
				x = 0.5858117364355,
				mapID = 85,
			},
		}, -- [30]
		{
			tooltip = "Portal to Azsuna",
			destination = {
				y = 0.41362162170844,
				mapID = 630,
				x = 0.46817071748393,
			},
			origin = {
				y = 0.89537901076584,
				x = 0.58885869565217,
				mapID = 85,
			},
		}, -- [31]
		{
			tooltip = "Portal to Warspear, Ashran (Lower Pathfinder's Den)",
			destination = {
				y = 0.4973742659755,
				mapID = 624,
				x = 0.56951995849609,
			},
			origin = {
				y = 0.9204,
				x = 0.5517,
				mapID = 85,
			},
		}, -- [32]
		{
			tooltip = "Portal to Shattrath (Lower Pathfinder's Den)",
			destination = {
				y = 0.49210974806648,
				mapID = 111,
				x = 0.53003551136364,
			},
			origin = {
				y = 0.9164,
				x = 0.5751,
				mapID = 85,
			},
		}, -- [33]
		{
			tooltip = "Portal to Silvermoon City",
			destination = {
				y = 0.19238329952114,
				mapID = 110,
				x = 0.58264465141624,
			},
			origin = {
				y = 0.88218457597122,
				x = 0.55982527847646,
				mapID = 85,
			},
		}, -- [34]
		{
			tooltip = "Portal to Cavern of Times (Lower Pathfinder's Den)",
			destination = {
				y = 0.28302714070312,
				mapID = 74,
				x = 0.5460492553501,
			},
			origin = {
				y = 0.9258,
				x = 0.5641,
				mapID = 85,
			},
		}, -- [35]
		{
			tooltip = "Portal to Undercity",
			destination = {
				y = 0.16332547124834,
				mapID = 90,
				x = 0.84585550612658,
			},
			origin = {
				y = 0.55594681212568,
				x = 0.50745008758534,
				mapID = 85,
			},
		}, -- [36]
		{
			tooltip = "Portal to Uldum",
			destination = {
				y = 0.34247656465072,
				mapID = 1527,
				x = 0.54895175722124,
			},
			origin = {
				y = 0.38545449836978,
				x = 0.48876521514553,
				mapID = 85,
			},
		}, -- [37]
		{
			tooltip = "Portal to Uldum",
			destination = {
				y = 0.34247656465072,
				mapID = 249,
				x = 0.54895175722124,
			},
			origin = {
				y = 0.38545449836978,
				x = 0.48876521514553,
				mapID = 85,
			},
		}, -- [38]
		{
			tooltip = "Portal to Vashj'ir",
			destination = {
				y = 0.60947867366724,
				mapID = 204,
				x = 0.51370135161043,
			},
			origin = {
				y = 0.36544725152611,
				x = 0.49221473005749,
				mapID = 85,
			},
		}, -- [39]
		{
			tooltip = "Portal to Deepholm",
			destination = {
				y = 0.52942107099127,
				mapID = 207,
				x = 0.5059176514649,
			},
			origin = {
				y = 0.36311887139568,
				x = 0.50808255479698,
				mapID = 85,
			},
		}, -- [40]
		{
			tooltip = "Portal to Hyjal",
			destination = {
				y = 0.2337236134106,
				mapID = 198,
				x = 0.63486551497068,
			},
			origin = {
				y = 0.38278114574241,
				x = 0.5111870620733,
				mapID = 85,
			},
		}, -- [41]
		{
			tooltip = "Portal to Twilight Highlands",
			destination = {
				y = 0.53393293284393,
				mapID = 241,
				x = 0.73631666027462,
			},
			origin = {
				y = 0.39450947374272,
				x = 0.50227581521739,
				mapID = 85,
			},
		}, -- [42]
		{
			tooltip = "Portal to Tol Barad",
			destination = {
				y = 0.62372974957755,
				mapID = 245,
				x = 0.44771604383759,
			},
			origin = {
				y = 0.39287103860618,
				x = 0.47387486525332,
				mapID = 85,
			},
		}, -- [43]
		{
			tooltip = "Portal to Zuldazar",
			destination = {
				y = 0.64583333333333,
				mapID = 1163,
				x = 0.68277757432726,
			},
			origin = {
				y = 0.4520574119515,
				x = 0.41601595868837,
				mapID = 81,
			},
		}, -- [44]
		{
			tooltip = "Banshee's Wail to Zuldazar",
			destination = {
				y = 0.62495129448905,
				mapID = 862,
				x = 0.58402363790205,
			},
			origin = {
				y = 0.43340743614875,
				x = 0.20602456086601,
				mapID = 896,
			},
		}, -- [45]
		{
			tooltip = "Banshee's Wail to Zuldazar",
			destination = {
				y = 0.62495129448905,
				mapID = 862,
				x = 0.58402363790205,
			},
			origin = {
				y = 0.51185500686031,
				x = 0.87841985717018,
				mapID = 895,
			},
		}, -- [46]
		{
			tooltip = "Banshee's Wail to Zuldazar",
			destination = {
				y = 0.62495129448905,
				mapID = 862,
				x = 0.58402363790205,
			},
			origin = {
				y = 0.24462557170856,
				x = 0.51955369973581,
				mapID = 942,
			},
		}, -- [47]
		{
			tooltip = "Greasy Eel to Zuldazar",
			destination = {
				y = 0.87433673840999,
				mapID = 1165,
				x = 0.41751074550264,
			},
			origin = {
				y = 0.22668496550168,
				x = 0.75500752005348,
				mapID = 1462,
			},
		}, -- [48]
		{
			tooltip = "Portal to Oribos",
			destination = {
				y = 0.50311940044438,
				x = 0.20336391437309,
				mapID = 1670,
			},
			origin = {
				y = 0.87839019431731,
				x = 0.58328186758893,
				mapID = 85,
			},
		}, -- [49]
		{
			tooltip = "Zeppelin to Warsong Hold, Borean Tundra",
			destination = {
				y = 0.5354,
				mapID = 114,
				x = 0.4129,
			},
			origin = {
				y = 0.6168,
				x = 0.4525,
				mapID = 85,
			},
			hidden = true,
		}, -- [50]
		{
			tooltip = "Zeppelin to Orgrimmar",
			destination = {
				y = 0.6168,
				x = 0.4525,
				mapID = 85,
			},
			origin = {
				y = 0.5354,
				mapID = 114,
				x = 0.4129,
			},
			hidden = true,
		}, -- [51]
		{
			tooltip = "Waystone to Oribos",
			destination = {
				y = 0.5031,
				x = 0.1924,
				mapID = 1670,
			},
			origin = {
				y = 0.4217,
				x = 0.4237,
				mapID = 1543,
			},
		}, -- [52]
		{
			tooltip = "Pad to Ring of Fates",
			destination = {
				y = 0.50293573502007,
				x = 0.47113152833524,
				mapID = 1670,
			},
			origin = {
				y = 0.51546868982912,
				x = 0.43374996185303,
				mapID = 1671,
			},
		}, -- [53]
		{
			tooltip = "Pad to Ring of Transference",
			destination = {
				y = 0.51546868982912,
				x = 0.43374996185303,
				mapID = 1671,
			},
			origin = {
				y = 0.50293573502007,
				x = 0.47113152833524,
				mapID = 1670,
			},
		}, -- [54]
		{
			tooltip = "Pad to Ring of Transference",
			destination = {
				y = 0.42007819746433,
				x = 0.49375,
				mapID = 1671,
			},
			origin = {
				y = 0.42440375931766,
				x = 0.52091740132836,
				mapID = 1670,
			},
		}, -- [55]
		{
			tooltip = "Pad to Ring of Fates",
			destination = {
				y = 0.42440375931766,
				x = 0.52091740132836,
				mapID = 1670,
			},
			origin = {
				y = 0.42007819746433,
				x = 0.49375,
				mapID = 1671,
			},
		}, -- [56]
		{
			tooltip = "Pad to Ring of Fates",
			destination = {
				y = 0.50366972477064,
				x = 0.5714373387328,
				mapID = 1670,
			},
			origin = {
				y = 0.51617192913591,
				x = 0.55656242370605,
				mapID = 1671,
			},
		}, -- [57]
		{
			tooltip = "Pad to Ring of Transference",
			destination = {
				y = 0.51617192913591,
				x = 0.55656242370605,
				mapID = 1671,
			},
			origin = {
				y = 0.50366972477064,
				x = 0.5714373387328,
				mapID = 1670,
			},
		}, -- [58]
		{
			tooltip = "Pad to Ring of Transference",
			destination = {
				y = 0.60921867194773,
				x = 0.49515628814697,
				mapID = 1671,
			},
			origin = {
				y = 0.57853219968463,
				x = 0.52067281273891,
				mapID = 1670,
			},
		}, -- [59]
		{
			tooltip = "Pad to Ring of Fates",
			destination = {
				y = 0.57853219968463,
				x = 0.52067281273891,
				mapID = 1670,
			},
			origin = {
				y = 0.60921867194773,
				x = 0.49515628814697,
				mapID = 1671,
			},
		}, -- [60]
		{
			tooltip = "Ring of Transference",
			destination = {
				y = 0.4098,
				x = 0.4495,
				mapID = 1543,
			},
			origin = {
				y = 0.5,
				mapID = 1671,
				x = 0.5,
			},
		}, -- [61]
		{
            tooltip = "Zeppelin to Grom'gol, Stranglethorn Vale",
            origin = {
                x = 0.5257326850521,
                y = 0.53059286002728,
                mapID = 85,
            },
            destination = {
                x = 0.37157316998738,
                y = 0.52526279985909,
                mapID = 50,
            } 
        },
		{
			tooltip = "Zeppelin to Orgrimmar",
            destination = {
                x = 0.5257326850521,
                y = 0.53059286002728,
                mapID = 85,
            },
            origin = {
                x = 0.37157316998738,
                y = 0.52526279985909,
                mapID = 50,
            } 
        },
	
	}
	
	Questra.Zeppelins = {}
	
	do --Add internal reference for each portal's index
		for i, b in pairs(networkLocations) do
			if strfind(b.tooltip, "Zeppelin") then
				Questra.Zeppelins[b.tooltip] = b
			end
			b.index = i
		end
	end
	
	--Sort portal list into 2 lists. Saves time later, as this info is needed every time.
	local portalsBy; do
		portalsBy = {
			originMapID = {},
			destinationMapID = {},
		}


	

		--Portals starting on each map, based on originMapID
		for portalID, portalData in pairs(networkLocations) do
			for i, mapID in pairs(GetZoneIDs(portalData.origin.mapID)) do
				portalsBy.originMapID[mapID] = portalsBy.originMapID[mapID] or {}
				if mapID~= 946 and not tContains(portalsBy.originMapID[mapID], portalID) then
					tinsert(portalsBy.originMapID[mapID], portalID)
				end
			end
		end

		--Portals leading to each map, based on destinationMapID
		for portalID, portalData in pairs(networkLocations) do
			for i, mapID in pairs(GetZoneIDs(portalData.destination.mapID)) do
				portalsBy.destinationMapID[mapID] = portalsBy.destinationMapID[mapID] or {}
				if mapID ~= 946 and not tContains(portalsBy.destinationMapID[mapID], portalID) then
					tinsert(portalsBy.destinationMapID[mapID], portalID)
				end
			end
		end
	end



	local function GetPortalByID(portalID)
		return networkLocations[portalID]
	end

	Questra.portalPins = {}
	for originID, portals in pairs(portalsBy.originMapID) do
		Questra.portalPins[originID] = Questra.portalPins[originID] or {}
		for  i, portalID in pairs(portals) do
			local port = GetPortalByID(portalID)
			
			local pinInfo = {
				atlasName = "teleportationnetwork-32x32",
				name = port.tooltip,
				nodeID = originID.."_"..portalID,
				faction = port.faction or 0,
			}
			
			local viewed_wX, viewed_wY = HBD:TranslateZoneCoordinates(port.origin.x, port.origin.y, port.origin.mapID, originID, true)
			
			pinInfo.position = CreateVector2D(viewed_wX, viewed_wY)
			pinInfo.position.mapID = originID
			pinInfo.hidden = port.hidden
			pinInfo.destination = port.destination
			
			pinInfo.linkedUiMapID = port.destination.mapID
			
			pinInfo.portal = port
			
			tinsert(Questra.portalPins[originID], pinInfo)
		end
	end

	local function GetPortals(mapID, UseDestList)
		local list = UseDestList and portalsBy.destinationMapID or portalsBy.originMapID
		local mapIDS = GetZoneIDs(mapID)
		local portals = list[mapID]
		return mapIDS, (portals and #portals > 0) and portals or list[mapIDS[#mapIDS]]
	end
	
	local function GetGateway(destinationPortalList, originMapID, potentialPortals, m, numJumpsRequired, originPortalID, optionsFound)
		--there were no direct portals available, digging deeper.
		if trace then
			--store this mapID, so we only try looking it up once.
			trace[originMapID] = true
		end
		local originMapIDs,  originPortalList = GetPortals(originMapID)
		if originPortalList then
			for i, possibleOriginPortalID in pairs(originPortalList) do
				if tContains(destinationPortalList, possibleOriginPortalID) then
					if not tContains(potentialPortals, originPortalID or possibleOriginPortalID) then
						tinsert(potentialPortals, {originPortalID or possibleOriginPortalID, numJumpsRequired})
						optionsFound = true --options have been found
					end
				elseif not optionsFound then
					--if no options have been found, keep digging
					local portal = GetPortalByID(possibleOriginPortalID)
					
					if (not trace or (not trace[portal.destination.mapID]))
					and (not numJumpsRequired or (numJumpsRequired <= 3)) then
						GetGateway(destinationPortalList, portal.destination.mapID, potentialPortals, trace, (numJumpsRequired or 1) + 1 or {}, originPortalID or possibleOriginPortalID, optionsFound)
					end
				end		
			end
		end
	end

	local noPotentialPortals = {
		--dungeons don't allow coords or waypoints
		[Enum.UIMapType.Dungeon] = true,
	}
	
	local storedTransit = {}

	local potentialPortals = {}--reusable; Collect multiple portal options
	function Questra:GetPortal(destinationMapID)
		--[[Simplified Explanation:
				1. Get a list of portals leading to destination and a list of portals of available at origin
				2. check if any portals available at origin are on the destinationPortalList
				3. If no direct portal is found, look for portals that lead to other portals that can get to destination
				4. if any portalOptions are found, sort by fewest jumps required
				5. Store best option for future recall
				6. Return the result.
		--]]
	
		--Get player's current location
		local x, y, originMapID = Questra.GetPlayerPosition()
	
		local metric = destinationMapID..originMapID
	
		--Clean the table for reuse
		wipe(potentialPortals)
		
		--1. Get parent mapIDs and possible portals
			--Convert simple OriginMapID into a list of all parentMapIDs, and get the desired portalOptions
		local destinationMapIDS, destinationPortalList = GetPortals(destinationMapID, true)--portals that lead to destination
		local originMapIDs, originPortalList = GetPortals(originMapID) --portals that start at origin

		do --Makes sure origin and destination are not the same and are not on same world and/or continent
			if (destinationPortalList and #destinationPortalList < 1) --no  portals that lead to destination
			or (not destinationPortalList)
			or (not originMapIDs)
			or (destinationMapID and tContains(originMapIDs, destinationMapID)) --origin on same world/continent as destination
			or (originMapID and tContains(destinationMapIDS, originMapID)) --destination on same world/continent as origin
			or originMapID == destinationMapID then --portal is destination
				noPotentialPortals[metric] = true
				return
			end

			for _,mapID in pairs(originMapIDs) do
				if  tContains(destinationMapIDS, mapID) then --origin on same world/continent as destination
					noPotentialPortals[metric] = true
					return
				end
			end
		end

		--check if this origin/destination combination has been looked up before, and return the stored result.
		if noPotentialPortals[metric] then
			--Origin to destination have been checked before and no options were available.
			return 
		elseif storedTransit[metric] then
			--Origin to destination have been checked before and options were available.
			return storedTransit[metric]
		end
		
		do --2. Try to find a one hop portal that leads directly from origin to destination
			local optionsFound
			for i, originPortalID in pairs(originPortalList) do
				if tContains(destinationPortalList, originPortalID) then
					if not tContains(potentialPortals, originPortalID) then
						tinsert(potentialPortals, {originPortalID, 1})
						-- a one hop portal has been found
						optionsFound = true
					end
				end		
			end

			if not optionsFound then
				--3. If no portal has been found above, dig a little deeper
				GetGateway(destinationPortalList, originMapID, potentialPortals, {})
			end
		end
		
		table.sort(potentialPortals, function(a, b)
			--4. sort potentialPortals by fewest number of jumps required
			return a[2] > b[2]
		end)
		
		--5. Store whether this origin/destination combo has a portal option
		if #potentialPortals < 1 then
			noPotentialPortals[metric] = true
		else
			storedTransit[metric] = GetPortalByID(potentialPortals[#potentialPortals][1])
		end
		
		--6. Return the resul
		return potentialPortals and GetPortalByID(potentialPortals[#potentialPortals][1])
	end
end

do --flight recommendations
	--Track combined distance from player to nearest flight  point, and the destination's nearest flight point
	--compare difference of player's distance to destination to flight distance
	--if flight is shorter distance, recommend it.

	local storedIDs = {}
	local function GetZoneIDs(baseID) --get parent zone IDS for baseID
		if baseID and not storedIDs[baseID] then
			local _ids = {baseID}

			local info = C_Map.GetMapInfo(baseID)
			local count 
			while info do
				local parentInfo = C_Map.GetMapInfo(info.parentMapID)
				if parentInfo then
					if (info.parentMapID and tContains(_ids, info.parentMapID) or (parentInfo.mapType == Enum.UIMapType.Cosmic)) then
						break --we've hit a repeat id or the cosmic map
					end
					 if (parentInfo.mapType ~= Enum.UIMapType.Cosmic)then
					
						local _ = info.parentMapID and tinsert(_ids, info.parentMapID)
					end
				end
				info = parentInfo
			end
			storedIDs[baseID] = _ids --store it, so we don't have to dig for this ID again
		end
		return baseID and storedIDs[baseID] or {}--return then stored id
	end
	
	local function ShouldShowTaxiNode(factionGroup, taxiNodeInfo)
		if taxiNodeInfo.faction == Enum.FlightPathFaction.Horde then
			return factionGroup == "Horde";
		end

		if taxiNodeInfo.faction == Enum.FlightPathFaction.Alliance then
			return factionGroup == "Alliance";
		end
		
		if taxiNodeInfo.faction == Enum.FlightPathFaction.Neutral then
			return true
		end
		
		return true
	end
	
	
	-- function doTHIS()
		-- FlightMapFrame.oldOnEvent = FlightMapFrame:GetScript("OnEvent")
		-- FlightMapFrame:SetScript("OnEvent", function(self, event, ...)
			-- print(self, event, ...)
			-- return FlightMapFrame:oldOnEvent(self, event, ...)
		-- end)
	
	-- end

	local destStore = {}
	local one
	local noFlyList = {}
	
	local storedNodes = {}
	
	local unlearnedPoints = {
		
	
	}
	
	local function getNearestFlightPoint(mapID, x,  y)
		local ClosestFlightDist, ClosestFlight = math.huge

		local nodesToStore = (FlightMapFrame and FlightMapFrame:IsShown()) and C_TaxiMap.GetAllTaxiNodes(mapID)
		if nodesToStore then
			storedNodes[mapID] = nodesToStore
		end
		unlearnedPoints[mapID] = unlearnedPoints[mapID] or {}
		
		local nodes = storedNodes[mapID] or C_TaxiMap.GetTaxiNodesForMap(mapID)		
		
		if nodes and (#nodes > 0) then
			for index, taxiNodeInfo in pairs(nodes) do
				if taxiNodeInfo.name then
					if ShouldShowTaxiNode(UnitFactionGroup("player"), taxiNodeInfo) then
						if taxiNodeInfo.position then
							if nodesToStore then
								unlearnedPoints[mapID][taxiNodeInfo.name] = TaxiNodeGetType(index)
							end
							if (unlearnedPoints[mapID][taxiNodeInfo.name] ~= "DISTANT") or (unlearnedPoints[mapID][taxiNodeInfo.name] ~= "NONE") then
								local compDist = HBD:GetZoneDistance(mapID, x, y, mapID, taxiNodeInfo.position.x, taxiNodeInfo.position.y)
								if ClosestFlightDist > compDist then
									ClosestFlightDist, ClosestFlight = compDist, taxiNodeInfo
									taxiNodeInfo.position.mapID = mapID
								end
							end
						end
					end
				end
			end			
		end
		return ClosestFlight, ClosestFlightDist
	end
	
	local noFly = {}
	function  Questra:GetFlight(destinationID, destX, destY)
		if UnitOnTaxi("player") then return  end
		local x, y, originID = Questra.GetPlayerPosition()
		
		local metric = originID..destinationID
		
		if noFly[metric] then
			return 
		end
		
		local oIDS = GetZoneIDs(originID)
		
		if not oIDS then
			return
		end
		
		local isAzeroth = tContains(oIDS, 947)
		local dIDS 
		if isAzeroth then
			oIDS = Questra.GetZoneIDs(originID) --Azeroth does not allow flights between continents, use similar function from portal system
			dIDS = Questra.GetZoneIDs(destinationID)
		else
			dIDS = GetZoneIDs(destinationID)
		end
		
		if not dIDS then
			return
		end
		
		--if tContains(oIDS, destinationID)
		--or tContains(dIDS, originID)
		if originID == destinationID then
			return
		end
				
		local sameWorld
		for i, oid in pairs(oIDS) do
			if oid and tContains(dIDS, oid) then
				sameWorld = true
			end
		end
		if sameWorld then
			local factionGroup = UnitFactionGroup("player")
			
			if not destStore[destinationID..destX..destY] then
				--destination is static, so look it up and save it
				destStore[destinationID..destX..destY] = {getNearestFlightPoint(destinationID, destX, destY)}
			end
			
			local nearestDestFlight,   nearestDestFlightDist   = unpack(destStore[destinationID..destX..destY])
			local nearestOriginFlight, nearestOriginFlightDist = getNearestFlightPoint(originID, x, y)

			if not nearestDestFlight then
				local mapInfo = C_Map.GetMapInfo(destinationID)
				local nodes = storedNodes[originID] or C_TaxiMap.GetTaxiNodesForMap(originID)
			--	local nearestDestFlight,   nearestDestFlightDist
					
				for index, taxiNodeInfo in pairs(nodes) do
					if taxiNodeInfo.name == mapInfo.name then
						nearestDestFlight = taxiNodeInfo
 						nearestDestFlightDist = HBD:GetZoneDistance(mapID, x, y, mapID, taxiNodeInfo.position.x, taxiNodeInfo.position.y) or 0
						if not destStore[destinationID..destX..destY] then
							--destination is static, so look it up and save it
							destStore[destinationID..destX..destY] = {nearestDestFlight, nearestDestFlightDist}
						end
					end
				end
			end


			if nearestOriginFlight and nearestDestFlight and nearestOriginFlight.name ~= nearestDestFlight.name then
				local dist = nearestOriginFlightDist + nearestDestFlightDist
				local fullDist = HBD:GetZoneDistance(destinationID, destX, destY, originID, x, y) or math.huge
				
				if dist < (fullDist + 2000)then
					--flight is faster
					if (FlightMapFrame and FlightMapFrame:IsShown()) then
						if not one then
							one = true
							Questra:PingAnywhere("flight", nearestDestFlight.position.x, nearestDestFlight.position.y, nearestDestFlight.position.mapID)
						end
					else
						one = nil
					end					

										
					return {origin = {
							x = nearestOriginFlight.position.x,
							y = nearestOriginFlight.position.y,
							mapID = nearestOriginFlight.position.mapID,
						},
						tooltip = "Flight from "..nearestOriginFlight.name.. " to "..nearestDestFlight.name,
					}
				end
			else

			
				noFly[metric] = true
			end
		end
	end
end


do --to do: combine portal and flight point recommendations to offer transit itineraries
	function Questra:GetAlternateWaypoints(dX, dY, dID)
		local _dX, _dY, _dID = dX, dY, dID
		local portalAvailable
		if Questra:GetTracked() and Questra:GetTracked().allowPortals == true then
			portalAvailable = _dID and Questra:GetPortal(_dID)
			if portalAvailable then
				_dX = portalAvailable.origin.x
				_dY = portalAvailable.origin.y
				_dID = portalAvailable.origin.mapID
			end
		end

		local flightAvailable
		if Questra:GetTracked() and Questra:GetTracked().allowFlights == true then
			flightAvailable = Questra:GetFlight(_dID, _dX, _dY) --not completely ready: sometimes inaccurate
			if flightAvailable then
				_dX = flightAvailable.origin.x
				_dY = flightAvailable.origin.y
				_dID = flightAvailable.origin.mapID
			elseif not portalAvailable then
			end
		end

		if (dX ~= _dX or dY ~= _dY or dID ~= _dID) then
			if not Questra.portalSense then
				Questra.possibleWaypont = flightAvailable or portalAvailable
				Questra.TrackerScrollButton.AltRouteFlasher.flashAnimation:Play()
				Questra.TrackerScrollButton.AltRouteFlasher:Show()
				Questra.TrackerScrollButton.AltRouteFlasher.flash:Show()
			else
				Questra.possibleWaypont= nil
				Questra.TrackerScrollButton.AltRouteFlasher.flashAnimation:Stop()
				Questra.TrackerScrollButton.AltRouteFlasher:Hide()
				Questra.TrackerScrollButton.AltRouteFlasher.flash:Hide()
				return _dX, _dY, _dID
			end
		else
			Questra.possibleWaypont= nil
			Questra.portalSense = nil
			Questra.TrackerScrollButton.AltRouteFlasher.flashAnimation:Stop()
			Questra.TrackerScrollButton.AltRouteFlasher:Hide()
			Questra.TrackerScrollButton.AltRouteFlasher.flash:Hide()
		end
		return dX, dY, dID
	end
end