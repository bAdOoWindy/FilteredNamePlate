local FilteredNamePlate = FilteredNamePlate

SLASH_FilteredNamePlate1 = "/fnp"
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local GetNamePlates = C_NamePlate.GetNamePlates
local UnitName, GetUnitName = UnitName, GetUnitName
local string_find = string.find
local table_getn = table.getn
local FilterNp_EventList = FilterNp_EventList

local IS_REGISGER, IsCurOnlyShowStat, NORMAL_SYS_NP_SCALE, OrgNameWidth

local SpellcastInCurOnlyShowScale
-- NORMAL_SYS_NP_SCALE 是保存了临时变量不存档, 信息是系统当前普通的血条大小
-- SpellcastInCurOnlyShowScale 是临时变量, onlySHow的读条怪的血条比例
-- Fnp_OSScale 是存档的,它乘以NORMAL_SYS_NP_SCALE就是当前的ONlyShow怪的比例
-- Fnp_OSOtherScale是存档的,他乘以NORMAL_SYS_NP_SCALE就是当前非OnlyShow怪的比例

local AllAreaUnits
local DEFAULT_SMALL_NAMEWIDTH = 40
local DEFUALT_SPEELCAST_SCALE_SIZE = 0.8
--Fnp_Mode  仅显模式 true 过滤模式 false 暂时去掉过滤模式，其实没什么用
--Fnp_OtherNPFlag 0是默认和EUI模式 1是TidyPlate模式 2是Kui

--[[
local function insertATabValue(tab, value)
    local isExist = false;
    for pos, name in ipairs(tab) do
        if (name == value) then
            isExist = true;
        end
    end
    if not isExist then table.insert(tab, value) end;
end

local function removeATabValue(tab, value)
    for pos, name in ipairs(tab) do
        if (name == value) then
            table.remove(tab, pos)
        end
    end
end
--]]

local function printInfo()
	print("\124cFFF58CBA>>>>>>[过滤姓名板]\124r")
	local showstr = ""
	local isEnable = "不"
	if Fnp_Enable == true then
		isEnable = "是"
	end
	showstr = "\124cFFF58CBA启用状态:\124r "..isEnable.."， "
	local supportUIName = "原生/EUI"
	if Fnp_OtherNPFlag == 1 then
		supportUIName = "TidyPlate"
	elseif Fnp_OtherNPFlag == 2 then
		supportUIName = "Kui_NamePlates"
	end
	showstr = showstr.."\124cFFF58CBAUI支持类型:\124r "..supportUIName
	print(showstr)
	showstr = ""
	if Fnp_Mode ~= nil and Fnp_Mode == true then
		showstr = showstr.."\124cFFF58CBA设置模式:\124r 仅显模式".."， "
		if Fnp_ONameList ~= nil and table_getn(Fnp_ONameList) > 0 then
			showstr = showstr.."\124cFFF58CBA列表：\124r"..table.concat(Fnp_ONameList, ";")
		else
			showstr = showstr.."\124cFFF58CBA列表：\124r空"
		end
	else
		showstr = showstr.."\124cFFF58CBA设置模式:\124r 过滤模式".."， "
		if Fnp_FNameList ~= nil and table_getn(Fnp_FNameList) > 0 then
			showstr = showstr.."\124cFFF58CBA列表：\124r"..table.concat(Fnp_FNameList, ";")
		else
			showstr = showstr.."\124cFFF58CBA列表：\124r空"
		end
	end
	print(showstr)
	print("\124cFFF58CBA仅显比例:\124r "..Fnp_OSScale)
	print("\124cFFF58CBA仅显其他比例:\124r "..Fnp_OSOtherScale)
end

local function registerMyEvents(self, event, ...)
	-- 默认值修改处
	if Fnp_Enable == nil then
		Fnp_Enable = false
	end
	if Fnp_Mode == nil then
		Fnp_Mode = true
	end

	if Fnp_OtherNPFlag == nil then
		Fnp_OtherNPFlag = 0
	end

	if Fnp_ONameList == nil then
		Fnp_ONameList = {}
		table.insert(Fnp_ONameList, "邪能炸药")
	end

	if Fnp_FNameList == nil then
		Fnp_FNameList = {}
	end

	if IsCurOnlyShowStat == nil then
		IsCurOnlyShowStat = false
	end

	if AllAreaUnits == nil then
		AllAreaUnits = {}
	end

	if Fnp_OSScale == nil then Fnp_OSScale = 1.0 end
	if Fnp_OSOtherScale == nil then Fnp_OSOtherScale = 0.25 end
	OrgNameHeight = nil
	OrgNameWidth = nil
	NORMAL_SYS_NP_SCALE = nil

	if Fnp_Enable == true and IS_REGISGER == false then
		for k, v in pairs(FilterNp_EventList) do
			if k ~= "PLAYER_ENTERING_WORLD" then
				self:RegisterEvent(k,v)
			end
        end
		IS_REGISGER = true
	end
end

local function unRegisterMyEvents(self)
	if IS_REGISGER == true then
		IS_REGISGER = false
		Fnp_Enable = false
		for k, v in pairs(FilterNp_EventList) do
			if k ~= "PLAYER_ENTERING_WORLD" then
				self:UnregisterEvent(k,v)
			end
        end
	end
end

local function isMatchFilteredNameList(tName)
	if tName == nil then return false end

	if Fnp_Mode == true then
		return false
	end

	local isMatch = false
	for key, var in ipairs(Fnp_FNameList) do
		local _, ret = string_find(tName, var)
		if ret ~= nil then
			isMatch = true
			break
		end
	end
	return isMatch
end

local function isMatchOnlyShowNameList(tName)
	if tName == nil then return false end

	if Fnp_Mode == false then
		return false
	end
	local isMatch = false
	for key, var in ipairs(Fnp_ONameList) do
		local _, ret = string_find(tName, var)
		if ret ~= nil then
			isMatch = true
			break
		end
	end
	return isMatch
end

---------kkkkk---kkkkk---kkkkk-------------

local function getScaleValues(indx, frame)
	if NORMAL_SYS_NP_SCALE ~= nil then return end

	if indx == 0 then
		if frame.UnitFrame then
			NORMAL_SYS_NP_SCALE = frame.UnitFrame:GetEffectiveScale()
			if OrgNameWidth == nil then
				OrgNameWidth = frame.UnitFrame:GetWidth()
			end
		end
	elseif indx == 1 then
		NORMAL_SYS_NP_SCALE = frame.carrier:GetEffectiveScale()
	elseif indx == 2 then
		NORMAL_SYS_NP_SCALE = frame.kui:GetEffectiveScale()
	end
	SpellcastInCurOnlyShowScale = NORMAL_SYS_NP_SCALE * 0.8
	print("normalSize "..NORMAL_SYS_NP_SCALE..(" onlyshow scale ")..Fnp_OSScale..(" other scale ")..Fnp_OSOtherScale..(" onlyShowSpell scale ")..SpellcastInCurOnlyShowScale)
end

local function hideSingleUnit(frame)
	if frame == nil then return end
	print("hide "..GetUnitName(frame))
	if Fnp_OtherNPFlag == 1 then
		if frame.carrier then
			getScaleValues(1, frame)
			frame.carrier:SetScale(Fnp_OSOtherScale)
		end
	elseif Fnp_OtherNPFlag == 0 then
		if frame.UnitFrame then
			getScaleValues(0, frame)
			-- org frame.UnitFrame.name:SetWidth(DEFAULT_SMALL_NAMEWIDTH)
			-- org frame.UnitFrame.healthBar:Hide()
			-- eui
			frame.UnitFrame:SetScale(Fnp_OSOtherScale)
		end
	else
		if frame.kui then
			getScaleValues(2, frame)
			frame.kui:SetScale(Fnp_OSOtherScale)
		end
	end
end

local function showSingleUnit(frame, isOnlyShowSpellCast)
	if frame == nil then return end
	if Fnp_OtherNPFlag == 1 then
		if frame.carrier then
			getScaleValues(1, frame)
			frame.carrier:SetScale(NORMAL_SYS_NP_SCALE)
		end
	elseif Fnp_OtherNPFlag == 0 then
		if frame.UnitFrame then
			getScaleValues(0, frame)
			--org frame.UnitFrame.name:SetWidth(OrgNameWidth)
			--org  frame.UnitFrame.healthBar:Show()
			if isOnlyShowSpellCast then
				frame.UnitFrame:SetScale(SpellcastInCurOnlyShowScale)
			else
				frame.UnitFrame:SetScale(NORMAL_SYS_NP_SCALE)
			end
		end
	else
		if frame.kui then
			getScaleValues(2, frame)
			frame.kui:SetScale(NORMAL_SYS_NP_SCALE)
		end
	end
end

local function actionUnitStateAfterChanged()
	local matched = false
	if Fnp_Enable then
		if Fnp_Mode == true then -- 开启并仅显模式
			local isNullList = false
			if table_getn(Fnp_ONameList) == 0 then isNullList = true end
			for _, frame in pairs(GetNamePlates()) do
				local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
				matched = isMatchOnlyShowNameList(GetUnitName(foundUnit))
				if matched == true or isNullList == true then
					showSingleUnit(frame)
				else
					hideSingleUnit(frame)
				end
			end
		else					-- 开启并过滤模式
			for _, frame in pairs(GetNamePlates()) do
				local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
				matched = isMatchFilteredNameList(GetUnitName(foundUnit))
				if matched == true then
					hideSingleUnit(frame)
				else
					showSingleUnit(frame)
				end
			end	
		end
		registerMyEvents(FilteredNamePlate_Frame, "", "")
	else -- 已经关闭就全部显示
		for _, frame in pairs(GetNamePlates()) do
			showSingleUnit(frame)
		end
		unRegisterMyEvents(FilteredNamePlate_Frame)
	end
end

local function actionUnitAddedOnlyShowMode(...)
	local unitid = ...
	if UnitIsPlayer(unitid) then
		return
	end
	local matched = false

	-- 1. 当前Add的单位名,是否match
	local curMatch = isMatchOnlyShowNameList(UnitName(unitid))
	if curMatch == false and IsCurOnlyShowStat == true then
		--新增单位不需要仅显,但是目前处于仅显情况下, 那么,就将当前这个Hide
		for _, frame in pairs(GetNamePlates()) do
			local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
			if foundUnit and (foundUnit == unitid) then
				hideSingleUnit(frame)
				break
			end
		end
	elseif curMatch == false and IsCurOnlyShowStat == false then
	 -- 新增单位不需要仅显, 此时也没有仅显, 就不管了.
	elseif curMatch == true and IsCurOnlyShowStat == true then
		-- 新增单位是需要仅显的,而此时已经有仅显的了,于是我们什么也不用干 -- 更新，怀疑在异步调用的时候莫名奇妙被hide了这里开出来确保
		showSingleUnit(GetNamePlateForUnit(unitid))
	elseif curMatch == true and IsCurOnlyShowStat == false then
		--新增单位是需要仅显的,而此时没有已经仅显的, 于是我们就将之前的都Hide,当前这个不用处理
		for _, frame in pairs(GetNamePlates()) do
			local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
			if foundUnit and (unitid ~= foundUnit) then
				hideSingleUnit(frame)
			end
		end
		IsCurOnlyShowStat = true
	end
end

local function actionUnitAddedFilterMode(...)
	local unitid = ...
	if UnitIsPlayer(unitid) then
		return
	end
	local matched = isMatchFilteredNameList(UnitName(unitid))
	if matched == true then
		for _, frame in pairs(GetNamePlates()) do
			local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
			if foundUnit and (foundUnit == unitid) then
				hideSingleUnit(frame)
				break
			end
		end
	end
end

local function actionUnitRemovedOnlyShowMode(...)
	if IsCurOnlyShowStat == false then
		-- 当前处于没有仅显模式,表明所有血条都开着的
		return
	end
	-- 已经在仅显情况下了
		-- 1. 当前移除的单位名,是否match
	local unitid = ...
	if UnitIsPlayer(unitid) then
		return
	end
	local curMatch = isMatchOnlyShowNameList(UnitName(unitid))
	if curMatch == true then
		-- 移除单位是需要仅显的,而此时已经仅显即IsCurOnlyShowStat为true,
		--于是我们判断剩余的是否还含有,如果还有就什么也不动.如果没有了,就恢复显示,IsCurOnlyShowStat改成false
		local matched = false
		local name = ""
		for _, frame in pairs(GetNamePlates()) do
			local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
			if foundUnit then
				matched = isMatchOnlyShowNameList(GetUnitName(foundUnit))
				if matched == true then
					return
				end
			end
		end
		--没有找到,说明我们该退出了就显示
		for _, frame in pairs(GetNamePlates()) do
			local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
			if foundUnit then
				matched = isMatchOnlyShowNameList(GetUnitName(foundUnit))
				if matched == false then
					showSingleUnit(frame)
				end
			end
		end
		IsCurOnlyShowStat = false
	end
end
---------k k k---k k k---k k k-------------

local function actionUnitAdded(self, event, ...)
	-- 关闭则直接return
	-- 如果OnlyShow列表为空return
	if Fnp_Mode == true then
		actionUnitAddedOnlyShowMode(...)
	else
		actionUnitAddedFilterMode(...)
	end
end

local function actionUnitRemoved(self, event, ...)
	-- 关闭则直接return
	if Fnp_Mode == true then
		actionUnitRemovedOnlyShowMode(...)
	end
end
--[[
local function actionTargetChanged(self, event, ...)
	if Fnp_Mode == true and IsCurOnlyShowStat == true then
		local targetId = ...
		for _, frame in pairs(GetNamePlates()) do
			local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
			if foundUnit then
				matched = isMatchOnlyShowNameList(GetUnitName(foundUnit))
				if matched == false and foundUnit ~= targetId then
					hideSingleUnit(frame)
				end
			end
		end
	end
end
--]]
--local function actionUnitRemovedFilterMode(...)
	-- do nothing
--end

local function actionUnitSpellCastStartOnlyShowMode(...)
	if IsCurOnlyShowStat == false then
		-- 当前处于没有仅显模式,表明所有血条都开着的
		return
	end
	local unitid = ...
	if UnitIsPlayer(unitid) then
		return
	end
	local curName = UnitName(unitid)
	if curName == nil then return end
	local curMatch = isMatchOnlyShowNameList(curName)
	-- true的话，表明是我们要的，那么肯定是在显示了。
	if curMatch == false then --false，而且是处于isCurrentOnlyShow
		local frame = GetNamePlateForUnit(unitid)
		showSingleUnit(frame)
	end
end

local function actionUnitSpellCastStopOnlyShowMode(...)
	if IsCurOnlyShowStat == false then
		-- 当前处于没有仅显模式,表明所有血条都开着的
		return
	end
	local unitid = ...
	if UnitIsPlayer(unitid) then
		return
	end
	local curName = UnitName(unitid)
	if curName == nil then return end
	local curMatch = isMatchOnlyShowNameList(curName)
	-- true的话，表明是我们要的，那么肯定是在显示了。
	if curMatch == false then --false，而且是处于isCurrentOnlyShow
		local frame = GetNamePlateForUnit(unitid)
		hideSingleUnit(frame)
	end
end

local function actionUnitSpellCastStart(self, event, ...)
	if Fnp_Mode == true then
		actionUnitSpellCastStartOnlyShowMode(...)
	end -- filter mode no need to do
end

local function actionUnitSpellCastStop(self, event, ...)
	if Fnp_Mode == true then
		actionUnitSpellCastStopOnlyShowMode(...)
	end -- filter mode no need to do
end

local function actionAreaChanged(self, event)
	print("areaChanged> "..event)
end

FilterNp_EventList = {
	["NAME_PLATE_UNIT_ADDED"]         = actionUnitAdded,
	["NAME_PLATE_UNIT_REMOVED"]       = actionUnitRemoved,
	["UNIT_SPELLCAST_START"]          = actionUnitSpellCastStart,
	["UNIT_SPELLCAST_CHANNEL_START"]  = actionUnitSpellCastStart,
	["UNIT_SPELLCAST_STOP"]           = actionUnitSpellCastStop,
	-- ["UNIT_SPELLCAST_SUCCEEDED"]      = actionUnitSpellCastStop,
	["UNIT_SPELLCAST_CHANNEL_STOP"]   = actionUnitSpellCastStop,
	-- ["UNIT_SPELLCAST_CHANNEL_UPDATE"] = actionUnitSpellCastUpdate,
	["PLAYER_ENTERING_WORLD"]         = registerMyEvents,
	-- ["PLAYER_TARGET_CHANGED"]		  = actionTargetChanged,
	-- ["ZONE_CHANGED_NEW_AREA"]         = actionAreaChanged,
};

function FilteredNamePlate_OnEvent(self, event, ...)
	local handler = FilterNp_EventList[event]
	if handler then
	    handler(self, event, ...)
	end
end

function FilteredNamePlate_OnLoad(self)
	IS_REGISGER = false
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function FNP_ModeCheckButtonChecked(mode, checked)
	if mode == "o" then
		if checked == true then
			Fnp_Mode = true
			FilteredNamePlate_Frame_FilteredModeCheckBtn:SetChecked(false);
		else
			Fnp_Mode = false
			FilteredNamePlate_Frame_FilteredModeCheckBtn:SetChecked(true);
		end
	else
		if checked == true then
			Fnp_Mode = false
			FilteredNamePlate_Frame_OnlyShowModeCheckBtn:SetChecked(false);
		else
			Fnp_Mode = true
			FilteredNamePlate_Frame_OnlyShowModeCheckBtn:SetChecked(true);
		end
	end
	actionUnitStateAfterChanged()
end

function FNP_TidyEnableCheckButtonChecked(checkbtn, checked, flag)
	if checked then
		Fnp_OtherNPFlag = flag
		if flag == 0 then
			FilteredNamePlate_Frame_TidyEnableCheckBtn:SetChecked(false)
			FilteredNamePlate_Frame_KuiCheckBtn:SetChecked(false)
			FilteredNamePlate_Frame_OrgCheckBtn:SetChecked(true)
			FilteredNamePlate_Frame_EUIRayBtn:SetChecked(false)
		elseif flag == 1 then
			FilteredNamePlate_Frame_TidyEnableCheckBtn:SetChecked(true)
			FilteredNamePlate_Frame_KuiCheckBtn:SetChecked(false)
			FilteredNamePlate_Frame_OrgCheckBtn:SetChecked(false)
			FilteredNamePlate_Frame_EUIRayBtn:SetChecked(false)
		elseif flag == 2 then
			FilteredNamePlate_Frame_TidyEnableCheckBtn:SetChecked(false)
			FilteredNamePlate_Frame_KuiCheckBtn:SetChecked(true)
			FilteredNamePlate_Frame_OrgCheckBtn:SetChecked(false)
			FilteredNamePlate_Frame_EUIRayBtn:SetChecked(false)
		elseif flag == 3 then
			FilteredNamePlate_Frame_TidyEnableCheckBtn:SetChecked(false)
			FilteredNamePlate_Frame_KuiCheckBtn:SetChecked(false)
			FilteredNamePlate_Frame_OrgCheckBtn:SetChecked(false)
			FilteredNamePlate_Frame_EUIRayBtn:SetChecked(true)
		end
	else
		checkbtn:SetChecked(true)
	end
	print("\124cFFF58CBA修改了插件类型，请重载/reload或者/rl。\124r")
end

function FNP_EnableButtonChecked(self, checked)
	if (checked) then
		Fnp_Enable = true;
	else
		Fnp_Enable = false;
		IsCurOnlyShowStat = false
	end
	actionUnitStateAfterChanged()
end

function FNP_ModeEditBoxWritenEsc()
	local names = ""
	local first = true
	for key, var in ipairs(Fnp_ONameList) do
		if first then 
			names = var
			first = false
		else
			names = names..";"..var
		end
	end
	FilteredNamePlate_Frame_OnlyShowModeEditBox:SetText(names);

	names = ""
	first = true
	for key, var in ipairs(Fnp_FNameList) do
		if first then 
			names = var
			first = false
		else
			names = names..";"..var
		end
	end
	FilteredNamePlate_Frame_FilteredModeEditBox:SetText(names);
end

function FNP_ModeEditBoxWriten(mode, inputStr)
	if mode == "o" then
		Fnp_ONameList = {}  
		string.gsub(inputStr, '[^;]+', function(w) table.insert(Fnp_ONameList, w) end )
	else
		Fnp_FNameList = {}  
		string.gsub(inputStr, '[^;]+', function(w) table.insert(Fnp_FNameList, w) end )
	end
	actionUnitStateAfterChanged()
end

function FNP_ChangeFrameVisibility(...)
	local advanced = ...
	if advanced then
		if FilteredNamePlate_AdvancedFrame:IsVisible() then
			FilteredNamePlate_AdvancedFrame:Hide()
		else
			FilteredNamePlate_AdvancedFrame:Show()
		end
		return
	end

	if FilteredNamePlate_Frame:IsVisible() then
		FilteredNamePlate_Frame:Hide()
		FilteredNamePlate_AdvancedFrame:Hide()
		printInfo()
	else
		FilteredNamePlate_Frame:Show()
		-- FilteredNamePlate_AdvancedFrame:Show()
		if Fnp_Enable == true then
			FilteredNamePlate_Frame_EnableCheckButton:SetChecked(true);
		else
			FilteredNamePlate_Frame_EnableCheckButton:SetChecked(false);
		end

		if Fnp_OtherNPFlag == 0 then
			FilteredNamePlate_Frame_OrgCheckBtn:SetChecked(true);
		else
			FilteredNamePlate_Frame_OrgCheckBtn:SetChecked(false);
		end
		if Fnp_OtherNPFlag == 1 then
			FilteredNamePlate_Frame_TidyEnableCheckBtn:SetChecked(true);
		else
			FilteredNamePlate_Frame_TidyEnableCheckBtn:SetChecked(false);
		end

		if Fnp_OtherNPFlag == 2 then
			FilteredNamePlate_Frame_KuiCheckBtn:SetChecked(true);
		else
			FilteredNamePlate_Frame_KuiCheckBtn:SetChecked(false);
		end

		if Fnp_Mode ~= nil and Fnp_Mode == true then
			FilteredNamePlate_Frame_FilteredModeCheckBtn:SetChecked(false);
			FilteredNamePlate_Frame_OnlyShowModeCheckBtn:SetChecked(true);
		else
			FilteredNamePlate_Frame_FilteredModeCheckBtn:SetChecked(true);
			FilteredNamePlate_Frame_OnlyShowModeCheckBtn:SetChecked(false);
		end

		FilteredNamePlate_AdvancedFrame_OnlyShowScale:SetValue(Fnp_OSScale * 100)
		FilteredNamePlate_AdvancedFrame_OnlyOtherShowScale:SetValue(Fnp_OSOtherScale * 100)

		FilteredNamePlate_Frame_OnlyShowModeEditBox:SetText(table.concat(Fnp_ONameList, ";"));
		FilteredNamePlate_Frame_FilteredModeEditBox:SetText(table.concat(Fnp_FNameList, ";"));
	end
end

function SlashCmdList.FilteredNamePlate(msg)
	local lastTarget = GetBindingKey("TARGETNEARESTENEMY");
	if msg == "" then
		print("\124cFFF58CBA[过滤姓名板]\124r")
		print("\124cFFF58CBA/fnp options 或 /fnp opt \124r打开菜单")
		print("\124cFFF58CBA/fnp change 或 /fnp ch \124r快速切换开关")
		print("\124cFFF58CBA/fnp hideSpellCast 或 /fnp hsc \124r快速隐藏正在施法的怪")
	elseif msg == "options" or msg == "opt" then
		FNP_ChangeFrameVisibility()
	elseif msg == "change" or msg == "ch" then
		if Fnp_Enable == true then
			FilteredNamePlate_Frame_EnableCheckButton:SetChecked(false)
			FNP_EnableButtonChecked(FilteredNamePlate_Frame, false)
		else
			FilteredNamePlate_Frame_EnableCheckButton:SetChecked(true)
			FNP_EnableButtonChecked(FilteredNamePlate_Frame, true)
		end
	elseif msg == "hideSpellCast" or msg == "hsc" then
		actionUnitStateAfterChanged()
	end
end
