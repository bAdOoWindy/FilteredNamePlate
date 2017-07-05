local _
local _G = _G
FilteredNamePlate = {}
local L = FNP_LOCALE_TEXT
local FilteredNamePlate = FilteredNamePlate

SLASH_FilteredNamePlate1 = "/fnp"
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local GetNamePlates = C_NamePlate.GetNamePlates
local UnitName, GetUnitName = UnitName, GetUnitName
local string_find = string.find
local FilterNp_EventList = FilterNp_EventList

local isRegistered, inOnlyShowSt, isScaleInited, isErrInLoad, isNullOnlyList, isNullFilterList

local curScaleList, curOrigScaleList, curEkScaleList

local SPELL_SCALE = 0.5

--Fnnp_OtherNPFlag 0是默认 1是TidyPlate模式 2是Kui 3是EUI 4是NDUI. 5 EKPlate.
--curNNpFlag标记当前采用哪种缩放模式.1表SIMPLE_SCALE模式.2表示EK.0表示原生.
local curNpFlag, curNpFlag1Type
local SIMPLE_SCALE_NAME = {
	TIDY = "carrier",
	KUI = "kui",
	EUI_RAYUI = "UnitFrame",
    NDUI = "unitFrame",
}

local function getCurFrameTypeByFlag(flag)
	if flag == 1 then
		return SIMPLE_SCALE_NAME.TIDY
	elseif flag == 2 then
		return SIMPLE_SCALE_NAME.KUI
	elseif flag == 3 then
		return SIMPLE_SCALE_NAME.EUI_RAYUI
	elseif flag == 4 then
		return SIMPLE_SCALE_NAME.NDUI
	end
	return "UnitFrame"
end

local function getTableCount(atab)
	local count = 0
    for pos, name in ipairs(atab) do
        count = count + 1
    end
	return count
end

--Fnp_Mode  仅显模式 true 过滤模式 false 暂时去掉过滤模式，其实没什么用

local function initFnp_SavedScaleList_only(curFlag)
	if curFlag == 0 then
		Fnp_SavedScaleList.only = 1.4
	elseif curFlag == 1 then
		Fnp_SavedScaleList.only = 1.35
	elseif curFlag == 2 then
		Fnp_SavedScaleList.only = 1.5
	else
		Fnp_SavedScaleList.only = 1.45
	end
end

local function registerMyEvents(self, event, ...)
	if isRegistered == true then return end
	if Fnp_Enable == nil then
		Fnp_Enable = false
	end

	if Fnp_OtherNPFlag == nil then
		Fnp_OtherNPFlag = 0
	end

	--curNpFlag = Fnp_OtherNPFlag
	if Fnp_OtherNPFlag == 0 then
		curNpFlag = 0
	elseif Fnp_OtherNPFlag == 5 then
		curNpFlag = 2
	else
		curNpFlag = 1
	end

	curNpFlag1Type = getCurFrameTypeByFlag(Fnp_OtherNPFlag)

	if Fnp_ONameList == nil then
		Fnp_ONameList = {}
		table.insert(Fnp_ONameList, "邪能炸药")
	end

	if Fnp_FNameList == nil then
		Fnp_FNameList = {}
	end

	if inOnlyShowSt == nil then
		inOnlyShowSt = false
	end

	if Fnp_SavedScaleList == nil then
		Fnp_SavedScaleList = {
			normal = 1,
			small = 0.20,
			only = 1.45,
		}
		initFnp_SavedScaleList_only(Fnp_OtherNPFlag)
	else -- V4 update to V5
		if Fnp_SavedScaleList.only == nil then initFnp_SavedScaleList_only(Fnp_OtherNPFlag) end
	end

	isNullOnlyList = false
	isNullFilterList = false
	if getTableCount(Fnp_ONameList) == 0 then isNullOnlyList = true end
	if getTableCount(Fnp_FNameList) == 0 then isNullFilterList = true end

	isScaleInited = false

	if Fnp_Enable == true then
		FilteredNamePlate.isSettingChanged = false
		for k, v in pairs(FilterNp_EventList) do
			if k ~= "PLAYER_ENTERING_WORLD" then
				self:RegisterEvent(k,v)
			end
        end
		isRegistered = true
	end
end

local function unRegisterMyEvents(self)
	if isRegistered == true then
		isRegistered = false
		Fnp_Enable = false
		for k, v in pairs(FilterNp_EventList) do
			if k ~= "PLAYER_ENTERING_WORLD" then
				self:UnregisterEvent(k,v)
			end
        end
	end
end

local function isMatchedNameList(tabList, tName)
	if tName == nil then return false end

	local isMatch = false
	for key, var in ipairs(tabList) do
		local _, ret = string_find(tName, var)
		if ret ~= nil then
			isMatch = true
			break
		end
	end
	return isMatch
end

---------kkkkk---kkkkk---kkkkk-------------
local function reinitScaleValues()
	if curNpFlag == 1 then
		curScaleList.normal = curScaleList.SYSTEM * Fnp_SavedScaleList.normal
		curScaleList.small = curScaleList.normal * Fnp_SavedScaleList.small
		curScaleList.middle = curScaleList.normal * SPELL_SCALE
		curScaleList.only = curScaleList.SYSTEM * Fnp_SavedScaleList.only
	elseif curNpFlag == 0 then
		curOrigScaleList.name.normal = curOrigScaleList.name.SYSTEM
		curOrigScaleList.name.small = curOrigScaleList.name.normal * Fnp_SavedScaleList.small
		curOrigScaleList.name.middle = curOrigScaleList.name.small
		if curOrigScaleList.name.small < 30 then
			curOrigScaleList.name.small = 30
			curOrigScaleList.name.middle = 30
		end
		curOrigScaleList.bars.heal_normalHeight = curOrigScaleList.bars.HEAL_SYS_HEIGHT * Fnp_SavedScaleList.normal;
		curOrigScaleList.bars.heal_onlyHeight = curOrigScaleList.bars.HEAL_SYS_HEIGHT * Fnp_SavedScaleList.only;
		curOrigScaleList.bars.cast_midHeight = curOrigScaleList.bars.CAST_SYS_HEIGHT * SPELL_SCALE;
	elseif curNpFlag == 2 then
		curEkScaleList.normal_perc_font = curEkScaleList.PERC_FONT * Fnp_SavedScaleList.normal
		curEkScaleList.only_perc_font = curEkScaleList.PERC_FONT * Fnp_SavedScaleList.only
		curEkScaleList.mid_perc_font = curEkScaleList.normal_perc_font * SPELL_SCALE
		curEkScaleList.small_perc_font = curEkScaleList.normal_perc_font * Fnp_SavedScaleList.small
	end
end


local function initScaleValues()
	-- if isScaleInited == true then 尝试注释掉这里 TODO
	--	reinitScaleValues()
	--	return
	-- end

	for _, frame in pairs(GetNamePlates()) do
		local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
		if foundUnit then
			curScaleList = { -- 一种原始保存,三种不同状态下的scale value
			SYSTEM = 0.78,
			normal = 1.0,
			small = 0.20,
			middle = SPELL_SCALE,
			only = 1.45,
			};
			curOrigScaleList = {
				name = {
					SYSTEM = 130,
					normal = 130,
					small = 40,
					middle = 40,
				},
				bars = {
					HEAL_SYS_HEIGHT = 10.8,
					heal_normalHeight = 10.8,
					heal_onlyHeight = 15.0,
					CAST_SYS_HEIGHT = 10.8,
					cast_midHeight = 5.4
				}
			}
			curEkScaleList = {
				SYSTEMW = 130,
				SMALLW = 40,
				SYSTEMH = 100,
				SMALLH = 20,

				PERC_FONT = 18,
				normal_perc_font = 18,
				only_perc_font = 10,
				mid_perc_font = 15,
				small_perc_font = 8,
			}
			local sys = 0
			if curNpFlag == 0 then --Orig
				if frame.UnitFrame then
					sys = 1
					curOrigScaleList.name.SYSTEM = frame.UnitFrame:GetWidth()
					if frame.UnitFrame.healthBar then
						curOrigScaleList.bars.HEAL_SYS_HEIGHT = frame.UnitFrame.healthBar:GetHeight()
					end
					if frame.UnitFrame.castBar then
						curOrigScaleList.bars.CAST_SYS_HEIGHT = frame.UnitFrame.castBar:GetHeight()
					end
				end
			elseif curNpFlag == 2 then -- ek
				if frame.UnitFrame then
					sys = 1
					curEkScaleList.SYSTEMW = frame.UnitFrame.name:GetWidth()
					curEkScaleList.SYSTEMH = frame.UnitFrame.name:GetHeight()
					if frame.UnitFrame.healthperc then
						local _,size,_ = frame.UnitFrame.healthperc:GetFont()
						curEkScaleList.PERC_FONT = size
					end
				end
			else -- 1~4
				if frame[curNpFlag1Type] then
					sys = frame[curNpFlag1Type]:GetEffectiveScale()
				end
			end
			if sys > 0.01 then -- it's a real info
				curScaleList.SYSTEM = sys
				reinitScaleValues()
				isScaleInited = true
				break
			end
		end
	end
end

local hideSwitchSingleUnit = {
	[0] = function(frame) --orig
		if frame == nil then return end
		if frame.UnitFrame then
			frame.UnitFrame.name:SetWidth(curOrigScaleList.name.small)
			if frame.UnitFrame.healthBar then frame.UnitFrame.healthBar:Hide() end
			frame.UnitFrame.castBar:SetHeight(curOrigScaleList.bars.cast_midHeight)
		end
	end,
	[1] = function(frame) -- all the scaled one
		if frame == nil then return end
		if frame[curNpFlag1Type] then
			frame[curNpFlag1Type]:SetScale(curScaleList.small)
		end
	end,
	[2] = function(frame) --ek
		if frame == nil then return end
		if frame.UnitFrame then
			frame.UnitFrame.name:SetWidth(curEkScaleList.SMALLW)
			frame.UnitFrame.name:SetHeight(curEkScaleList.SMALLH)
			if frame.UnitFrame.healthperc then
				local face, size, flag = frame.UnitFrame.healthperc:GetFont()
				frame.UnitFrame.healthperc:SetFont(face, curEkScaleList.small_perc_font, flag)
			end
		end
	end,
}

--isOnlyShowSpellCast 的情况下，就代表是仅显模式。并且该怪是非仅显目标而且施法了！
local showSwitchSingleUnit = {
	[0] = function(frame, isOnlyShowSpellCast, restore, isOnlyUnit)
		if frame and frame.UnitFrame then
			if restore == true then
				frame.UnitFrame.name:SetWidth(curOrigScaleList.name.SYSTEM)
				if frame.UnitFrame.healthBar then
					frame.UnitFrame.healthBar:Show()
					frame.UnitFrame.healthBar:SetHeight(curOrigScaleList.bars.HEAL_SYS_HEIGHT)
				end
				frame.UnitFrame.castBar:SetHeight(curOrigScaleList.bars.CAST_SYS_HEIGHT)
			elseif isOnlyShowSpellCast == false then
				frame.UnitFrame.name:SetWidth(curOrigScaleList.name.normal)
				if frame.UnitFrame.healthBar then
					frame.UnitFrame.healthBar:Show()
					if isOnlyUnit then
						frame.UnitFrame.healthBar:SetHeight(curOrigScaleList.bars.heal_onlyHeight)
					else
						frame.UnitFrame.healthBar:SetHeight(curOrigScaleList.bars.heal_normalHeight)
					end
				end
				frame.UnitFrame.castBar:SetHeight(curOrigScaleList.bars.CAST_SYS_HEIGHT)
				
			else
				frame.UnitFrame.name:SetWidth(curOrigScaleList.name.middle)
				frame.UnitFrame.castBar:SetHeight(curOrigScaleList.bars.cast_midHeight)
				--frame.UnitFrame.healthBar:Show()
			end
		end
	end,
	[1] = function(frame, isOnlyShowSpellCast, restore, isOnlyUnit)
		if frame and frame[curNpFlag1Type] then
			if restore == true then
				frame[curNpFlag1Type]:SetScale(curScaleList.SYSTEM)
			elseif isOnlyShowSpellCast == false then
				if isOnlyUnit == true then
					frame[curNpFlag1Type]:SetScale(curScaleList.only)
				else
					frame[curNpFlag1Type]:SetScale(curScaleList.normal)
				end
			else
				frame[curNpFlag1Type]:SetScale(curScaleList.middle)
			end
		end
	end,
	[2] = function(frame, isOnlyShowSpellCast, restore, isOnlyUnit)
		if frame and frame.UnitFrame then
			if restore == true then
				frame.UnitFrame.name:SetWidth(curEkScaleList.SYSTEMW)
				frame.UnitFrame.name:SetHeight(curEkScaleList.SYSTEMH)
				if frame.UnitFrame.healthperc then
					local face, size, flag = frame.UnitFrame.healthperc:GetFont()
					frame.UnitFrame.healthperc:SetFont(face, curEkScaleList.PERC_FONT, flag)
				end
			elseif isOnlyShowSpellCast == false then
				frame.UnitFrame.name:SetWidth(curEkScaleList.SYSTEMW)
				if frame.UnitFrame.healthperc then
					local face, size, flag = frame.UnitFrame.healthperc:GetFont()
					if isOnlyUnit then
						frame.UnitFrame.healthperc:SetFont(face, curEkScaleList.only_perc_font, flag)
					else
						frame.UnitFrame.healthperc:SetFont(face, curEkScaleList.normal_perc_font, flag)
					end
				end
			else
				if frame.UnitFrame.healthperc then
					local face, size, flag = frame.UnitFrame.healthperc:GetFont()
					frame.UnitFrame.healthperc:SetFont(face, curEkScaleList.mid_perc_font, flag)
				end
				--frame.UnitFrame.healthBar:Show()
			end
		end
	end,
}

function FilteredNamePlate.actionUnitStateAfterChanged()
    --FilteredNamePlate.printSavedScaleList(Fnp_SavedScaleList)
	--curNpFlag = Fnp_OtherNPFlag
	if Fnp_OtherNPFlag == 0 then
		curNpFlag = 0
	elseif Fnp_OtherNPFlag == 5 then
		curNpFlag = 2
	else
		curNpFlag = 1
	end
	curNpFlag1Type = getCurFrameTypeByFlag(Fnp_OtherNPFlag)

	initScaleValues()
	local matched = false
	local matched2 = false
	if Fnp_Enable == true then
		inOnlyShowSt = false
		--仅显
		isNullOnlyList = false
		if getTableCount(Fnp_ONameList) == 0 then isNullOnlyList = true end
		--过滤
		isNullFilterList = false
		if getTableCount(Fnp_FNameList) == 0 then isNullFilterList = true end
		local isHide = false
		for _, frame in pairs(GetNamePlates()) do
			if isNullOnlyList == true then
				matched2 = false
				if isNullFilterList == false then
					local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
					matched2 = isMatchedNameList(Fnp_FNameList, GetUnitName(foundUnit))
				end
				if matched2 == true then
					hideSwitchSingleUnit[curNpFlag](frame)
				else
					showSwitchSingleUnit[curNpFlag](frame, false, false, false) -- 全是普通情况
				end
			else
				local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
				matched = isMatchedNameList(Fnp_ONameList, GetUnitName(foundUnit))
				if matched == true then
					isHide = true
					break
				end
			end
		end
		if isHide == true then
			for _, frame in pairs(GetNamePlates()) do
				local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
				matched = isMatchedNameList(Fnp_ONameList, GetUnitName(foundUnit))
				if matched == true then
					-- 仅显模式仅显的怪
					showSwitchSingleUnit[curNpFlag](frame, false, false, true)
				else
					if UnitIsPlayer(foundUnit) == false then hideSwitchSingleUnit[curNpFlag](frame) end
				end
			end
			inOnlyShowSt = true
		else
			for _, frame in pairs(GetNamePlates()) do
				-- 普通模式
				showSwitchSingleUnit[curNpFlag](frame, false, false, false)
			end	
		end
		-- registerMyEvents(FilteredNamePlate_Frame, "", "")
	else -- 已经关闭功能就全部显示
		for _, frame in pairs(GetNamePlates()) do
			local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
			if foundUnit then
				-- disable 还原了！
				showSwitchSingleUnit[curNpFlag](frame, false, true, false)
			end
		end
		inOnlyShowSt = false
		-- unRegisterMyEvents(FilteredNamePlate_Frame)
	end
end

local function getNamePlateFromPlatesById(unitid)
	for _, frame in pairs(GetNamePlates()) do
		local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
		if foundUnit and (foundUnit == unitid) then
			return frame
		end
	end
	return nil
end

local function actionUnitAddedForce(unitid)
	local addedname = UnitName(unitid)
	-- 0. 当前Add的单位名,是否match filter
	local curFilterMatch = false
	if isNullFilterList == false then curFilterMatch = isMatchedNameList(Fnp_FNameList, addedname) end
	if curFilterMatch == true then
		local frame = GetNamePlateForUnit(unitid)
		hideSwitchSingleUnit[curNpFlag](frame)
		return
	end
	-- 1. 当前add的单位名,是否match
	local curOnlyMatch = isMatchedNameList(Fnp_ONameList, addedname)
	if curOnlyMatch == false and inOnlyShowSt == true then
		--新增单位不需要仅显,但是目前处于仅显情况下, 那么,就将当前这个Hide TODO 这里改成直接用自己,而不是用GetNamePlates
		-- local frame = getNamePlateFromPlatesById(unitid)
		local frame = GetNamePlateForUnit(unitid)
		local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
		if UnitIsPlayer(foundUnit) == false then hideSwitchSingleUnit[curNpFlag](frame) end
	elseif curOnlyMatch == false and inOnlyShowSt == false then
		-- 新增单位不需要仅显, 此时也没有仅显, 就不管了.现在我们将当前的效果展示出来
		local frame = GetNamePlateForUnit(unitid)
		local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
		if UnitIsPlayer(foundUnit) == false then showSwitchSingleUnit[curNpFlag](GetNamePlateForUnit(unitid), false, false, false) end
	elseif curOnlyMatch == true and inOnlyShowSt == true then
		-- 新增单位是需要仅显的,而此时已经有仅显的了,于是我们什么也不用干 -- 更新，怀疑在异步调用的时候莫名奇妙被hide了这里开出来确保
		showSwitchSingleUnit[curNpFlag](GetNamePlateForUnit(unitid), false, false, true)
	elseif curOnlyMatch == true and inOnlyShowSt == false then
		--新增单位是需要仅显的,而此时不是仅显, 于是我们就将之前的都Hide,当前这个不用处理
		for _, frame in pairs(GetNamePlates()) do
			local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
			if foundUnit then
				-- TODO 判断是否是正在读条
				if (unitid == foundUnit) then
					-- 刚刚进入仅显模式！这个是仅显单位，那么将他变大一些
					showSwitchSingleUnit[curNpFlag](frame, false, false, true)
				else
					if UnitIsPlayer(foundUnit) == false then hideSwitchSingleUnit[curNpFlag](frame) end
				end
			end
		end
		inOnlyShowSt = true
	end
end

local function actionUnitRemovedForce(unitid)
	-- 1. 当前移除的单位名,是否match
	local curOnlyMatch = isMatchedNameList(Fnp_ONameList, UnitName(unitid))
	if curOnlyMatch == true then
		-- 移除单位是需要仅显的,而此时肯定已经仅显,
		--于是我们判断剩余的是否还含有,如果还有就什么也不动.如果没有了,就恢复显示
		local matched = false
		local name = ""
		for _, frame in pairs(GetNamePlates()) do
			local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
			if foundUnit then
				matched = isMatchedNameList(Fnp_ONameList, GetUnitName(foundUnit))
				if matched == true then
					return --have & return
				end
			end
		end
		--没有找到,说明我们该退出了就显示
		for _, frame in pairs(GetNamePlates()) do
			local foundUnit = frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)
			if foundUnit then
				matched = isMatchedNameList(Fnp_ONameList, GetUnitName(foundUnit))
				if matched == false then
					-- 退出仅显模式， 说明这些都是普通
					if UnitIsPlayer(foundUnit) == false then showSwitchSingleUnit[curNpFlag](frame, false, false, false) end
				end
			end
		end
		inOnlyShowSt = false
	end
end
---------k k k---k k k---k k k-------------

local function actionUnitAdded(self, event, ...)
	if isScaleInited == false then
		initScaleValues()
	end
	
	if isScaleInited == false then
		if isErrInLoad == false then
			isErrInLoad = true
			print(L.FNP_PRINT_ERROR_UITYPE)
			print(L.FNP_PRINT_ERROR_UITYPE)
			print(L.FNP_PRINT_ERROR_UITYPE)
		end
		return
	end
	if isNullOnlyList == true and isNullFilterList == true then
		return
	end

	local unitid = ...
	if UnitIsPlayer(unitid) then
		return
	end
	if Fnp_Enable == false then return end
	actionUnitAddedForce(unitid)
end

local function actionUnitRemoved(self, event, ...)
	--这里不需要判断是否为空
	-- if isNullOnlyList == true and isNullFilterList == true then
	--	return
	-- end
	if inOnlyShowSt == false then
		-- 当前处于没有仅显模式,表明所有血条都开着的
		return
	end
	local unitid = ...
	if UnitIsPlayer(unitid) then
		return
	end
	actionUnitRemovedForce(unitid)
end
--[[
local function actionTargetChanged(self, event, ...)
end
--]]

local function actionUnitSpellCastStartOnlyShowMode(...)
	if inOnlyShowSt == false then
		-- 当前处于没有仅显模式,表明所有血条都开着的
		return
	end
	local unitid = ...
	if UnitIsPlayer(unitid) then
		return
	end
	local curName = UnitName(unitid)
	if curName == nil then return end
	local curMatch = isMatchedNameList(Fnp_ONameList, curName)
	-- true的话，表明是我们要的，那么肯定是在显示了。就不管了
	if curMatch == false then 
		local frame = GetNamePlateForUnit(unitid)
		--仅显模式，非仅显怪施法啦！我们放到到miiddle大小
		showSwitchSingleUnit[curNpFlag](frame, true, false, false)
	end
end

local function actionUnitSpellCastStopOnlyShowMode(...)
	if inOnlyShowSt == false then
		-- 当前处于没有仅显模式,表明所有血条都开着的
		return
	end
	local unitid = ...
	if UnitIsPlayer(unitid) then
		return
	end
	local curName = UnitName(unitid)
	if curName == nil then return end
	local curMatch = isMatchedNameList(Fnp_ONameList, curName)
	-- true的话，表明是我们要的，那么肯定是在显示了。
	if curMatch == false then --false，而且是处于isCurrentOnlyShow
		local frame = GetNamePlateForUnit(unitid)
		hideSwitchSingleUnit[curNpFlag](frame)
	end
end

local function actionUnitSpellCastStart(self, event, ...)
	actionUnitSpellCastStartOnlyShowMode(...)
end

local function actionUnitSpellCastStop(self, event, ...)
	actionUnitSpellCastStopOnlyShowMode(...)
end

--[[
local function actionAreaChanged(self, event)
	-- print("areaChanged> "..event)
end --]]

FilterNp_EventList = {
	["NAME_PLATE_UNIT_ADDED"]         = actionUnitAdded,
	["NAME_PLATE_UNIT_REMOVED"]       = actionUnitRemoved,

	["UNIT_SPELLCAST_START"]          = actionUnitSpellCastStart,
	["UNIT_SPELLCAST_CHANNEL_START"]  = actionUnitSpellCastStart,
	["UNIT_SPELLCAST_STOP"]           = actionUnitSpellCastStop,
	["UNIT_SPELLCAST_CHANNEL_STOP"]   = actionUnitSpellCastStop,

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
	isRegistered = false
	isErrInLoad = false
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function FilteredNamePlate.FNP_UITypeChanged(checkbtn, checked, flag)
	if checked then
		if Fnp_OtherNPFlag == flag then
			return
		end
		Fnp_OtherNPFlag = flag
		initFnp_SavedScaleList_only(flag)
		FilteredNamePlate_Frame_OnlyShowScale:SetValue(Fnp_SavedScaleList.only * 100)
		FilteredNamePlate_Frame_tidyCheckBtn:SetChecked(false)
		FilteredNamePlate_Frame_KuiCheckBtn:SetChecked(false)
		FilteredNamePlate_Frame_OrgCheckBtn:SetChecked(false)
		FilteredNamePlate_Frame_EUIRayBtn:SetChecked(false)
		FilteredNamePlate_Frame_NDUIBtn:SetChecked(false)
		FilteredNamePlate_Frame_EKBtn:SetChecked(false)
		if flag == 0 then
			FilteredNamePlate_Frame_OrgCheckBtn:SetChecked(true)
		elseif flag == 1 then
			FilteredNamePlate_Frame_tidyCheckBtn:SetChecked(true)
		elseif flag == 2 then
			FilteredNamePlate_Frame_KuiCheckBtn:SetChecked(true)
		elseif flag == 3 then
			FilteredNamePlate_Frame_EUIRayBtn:SetChecked(true)
		elseif flag == 4 then
			FilteredNamePlate_Frame_NDUIBtn:SetChecked(true)
		elseif flag == 5 then
			FilteredNamePlate_Frame_EKBtn:SetChecked(true)
		end
	else
		checkbtn:SetChecked(true)
		if Fnp_OtherNPFlag == flag then
			return
		end
	end
	print(L.FNP_PRINT_UITYPE_CHANGED)
end

function FilteredNamePlate.FNP_EnableButtonChecked(self, checked)
	if (checked) then
		Fnp_Enable = true;
	else
		Fnp_Enable = false;
	end
	FilteredNamePlate.actionUnitStateAfterChanged()
end

function FilteredNamePlate.FNP_ModeEditBoxWritenEsc()
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

function FilteredNamePlate.FNP_ModeEditBoxWriten(mode, inputStr)
	if mode == "o" then
		Fnp_ONameList = {}  
		string.gsub(inputStr, '[^;]+', function(w) table.insert(Fnp_ONameList, w) end )
	else
		Fnp_FNameList = {}  
		string.gsub(inputStr, '[^;]+', function(w) table.insert(Fnp_FNameList, w) end )
	end
end

function FilteredNamePlate.FNP_ChangeFrameVisibility(...)
	if FilteredNamePlate_Frame:IsVisible() then
		FilteredNamePlate_Frame:Hide()
	else
		local oldChange = FilteredNamePlate.isSettingChanged
		FilteredNamePlate_Frame:Show()
		FilteredNamePlate_Frame_reloadUIBtn:Hide()
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
			FilteredNamePlate_Frame_tidyCheckBtn:SetChecked(true);
		else
			FilteredNamePlate_Frame_tidyCheckBtn:SetChecked(false);
		end

		if Fnp_OtherNPFlag == 2 then
			FilteredNamePlate_Frame_KuiCheckBtn:SetChecked(true);
		else
			FilteredNamePlate_Frame_KuiCheckBtn:SetChecked(false);
		end

		if Fnp_OtherNPFlag == 3 then
			FilteredNamePlate_Frame_EUIRayBtn:SetChecked(true);
		else
			FilteredNamePlate_Frame_EUIRayBtn:SetChecked(false);
		end
		if Fnp_OtherNPFlag == 4 then
			FilteredNamePlate_Frame_NDUIBtn:SetChecked(true);
		else
			FilteredNamePlate_Frame_NDUIBtn:SetChecked(false);
		end
		if Fnp_OtherNPFlag == 5 then
			FilteredNamePlate_Frame_EKBtn:SetChecked(true);
		else
			FilteredNamePlate_Frame_EKBtn:SetChecked(false);
		end
		--[[
		if Fnp_Mode ~= nil and Fnp_Mode == true then
			FilteredNamePlate_Frame_FilteredModeCheckBtn:SetChecked(false);
			FilteredNamePlate_Frame_OnlyShowModeCheckBtn:SetChecked(true);
		else
			FilteredNamePlate_Frame_FilteredModeCheckBtn:SetChecked(true);
			FilteredNamePlate_Frame_OnlyShowModeCheckBtn:SetChecked(false);
		end --]]

		FilteredNamePlate_Frame_OnlyShowScale:SetValue(Fnp_SavedScaleList.only * 100)
		FilteredNamePlate_Frame_OnlyOtherShowScale:SetValue(Fnp_SavedScaleList.small * 100)
		FilteredNamePlate_Frame_SystemScale:SetValue(Fnp_SavedScaleList.normal * 100)

		FilteredNamePlate_Frame_OnlyShowModeEditBox:SetText(table.concat(Fnp_ONameList, ";"));
		FilteredNamePlate_Frame_FilteredModeEditBox:SetText(table.concat(Fnp_FNameList, ";"));

		if oldChange == false then
			FilteredNamePlate_Frame_takeEffectBtn:Hide()
		end
	end
end

function SlashCmdList.FilteredNamePlate(msg)
	if msg == "" then
		print(L.FNP_PRINT_HELP0)
		print(L.FNP_PRINT_HELP1)
		print(L.FNP_PRINT_HELP2)
		print(L.FNP_PRINT_HELP3)
	elseif msg == "options" or msg == "opt" then
		FilteredNamePlate.FNP_ChangeFrameVisibility()
	elseif msg == "change" or msg == "ch" then
		if Fnp_Enable == true then
			FilteredNamePlate_Frame_EnableCheckButton:SetChecked(false)
			FilteredNamePlate.FNP_EnableButtonChecked(FilteredNamePlate_Frame, false)
		else
			FilteredNamePlate_Frame_EnableCheckButton:SetChecked(true)
			FilteredNamePlate.FNP_EnableButtonChecked(FilteredNamePlate_Frame, true)
		end
	elseif msg == "refresh" then
		FilteredNamePlate.actionUnitStateAfterChanged()
	end
end
