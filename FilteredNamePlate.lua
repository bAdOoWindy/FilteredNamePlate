local _
local L = FNP_LOCALE_TEXT
SLASH_FilteredNamePlate1 = "/fnp"
local GetNamePlateForUnit , GetNamePlates = C_NamePlate.GetNamePlateForUnit, C_NamePlate.GetNamePlates
local UnitName, GetUnitName = UnitName, GetUnitName
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local string_find = string.find

local isRegistered, isInOnlySt, isScaleInited, isErrInLoad, isNullOnlyList, isNullFilterList, isInitedDrop

local LastTimeStamps, IsKillLine1, IsKillLine2

--Fnnp_OtherNPFlag 0是默认 1是TidyPlate模式 2是Kui 3是EUI 4是NDUI. 5 EKPlate.
--curNNpFlag标记当前采用哪种缩放模式.1表SIMPLE_SCALE模式.2表示EK.0表示原生.

local curNpFlag, curNpFlag1Type

local function setCVarValues()
	SetCVar("nameplateShowEnemies", 1)
	SetCVar("nameplateShowEnemyMinions", 1)
	SetCVar("nameplateShowEnemyMinus", 1)
	SetCVar("nameplateShowAll", 1)
end

local function regHealthEvents(registed)
	if registed then
		FilteredNamePlate_Frame:RegisterEvent("UNIT_HEALTH", actionUnitHealth)
		FilteredNamePlate_Frame:RegisterEvent("UNIT_MAXHEALTH", actionUnitHealth)
	else
		FilteredNamePlate_Frame:UnregisterEvent("UNIT_HEALTH", actionUnitHealth)
		FilteredNamePlate_Frame:UnregisterEvent("UNIT_MAXHEALTH", actionUnitHealth)
	end
end

local function ClickOnMenu(info)
	FilteredNamePlate_Menu1:UnlockHighlight()
	FilteredNamePlate_Menu2:UnlockHighlight()
	FilteredNamePlate_Menu3:UnlockHighlight()
	FilteredNamePlate_Menu4:UnlockHighlight()
	FilteredNamePlate_Menu5:UnlockHighlight()

	FilteredNamePlate_Frame_EnableCheckButton:Hide()
	FilteredNamePlate_Frame_TankModCB:Hide()
	FilteredNamePlate_Frame_KilllineModCB:Hide()
	FilteredNamePlate_Frame_uitype:Hide()
	FilteredNamePlate_Frame_DropDownUIType:Hide()
	
	FilteredNamePlate_Frame_OnlyShowModeEditBox:Hide()
	FilteredNamePlate_Frame_FilteredModeEditBox:Hide()
	FilteredNamePlate_Frame_OnlyShows_Text:Hide()
	FilteredNamePlate_Frame_Filters_Text:Hide()
	FilteredNamePlate_Frame_note:Hide()

	FilteredNamePlate_Frame_SystemScale:Hide()
	FilteredNamePlate_Frame_OnlyShowScale:Hide()
	FilteredNamePlate_Frame_OnlyOtherShowScale:Hide()

	FilteredNamePlate_Frame_Slider_KL1:Hide()
	FilteredNamePlate_Frame_Slider_KL2:Hide()
	
	FilteredNamePlate_Frame_HelpIcon:Hide()
	FilteredNamePlate_Frame_ShareIcon:Hide()

	FilteredNamePlate_Frame_AuthorText:Hide()
	FilteredNamePlate_Frame_webText:Hide()
	if info == "general" then
		FilteredNamePlate_Menu1:LockHighlight()
		FilteredNamePlate_Frame_EnableCheckButton:Show()
		FilteredNamePlate_Frame_TankModCB:Show()
		FilteredNamePlate_Frame_KilllineModCB:Show()
		FilteredNamePlate_Frame_uitype:Show()
		FilteredNamePlate_Frame_DropDownUIType:Show()
	elseif info == "filter" then
		FilteredNamePlate_Menu2:LockHighlight()
		FilteredNamePlate_Frame_OnlyShowModeEditBox:Show()
		FilteredNamePlate_Frame_FilteredModeEditBox:Show()
		FilteredNamePlate_Frame_OnlyShows_Text:Show()
		FilteredNamePlate_Frame_Filters_Text:Show()
		FilteredNamePlate_Frame_note:Show()
	elseif info == "percent" then
		FilteredNamePlate_Menu3:LockHighlight()
		FilteredNamePlate_Frame_SystemScale:Show()
		FilteredNamePlate_Frame_OnlyShowScale:Show()
		FilteredNamePlate_Frame_OnlyOtherShowScale:Show()
	elseif info == "killline" then
		FilteredNamePlate_Menu4:LockHighlight()
		FilteredNamePlate_Frame_Slider_KL1:Show()
		FilteredNamePlate_Frame_Slider_KL2:Show()
	elseif info == "about" then
		FilteredNamePlate_Menu5:LockHighlight()
		FilteredNamePlate_Frame_HelpIcon:Show()
		FilteredNamePlate_Frame_ShareIcon:Show()
		FilteredNamePlate_Frame_AuthorText:Show()
		FilteredNamePlate_Frame_webText:Show()
	end
end

local function getTableCount(atab)
	local count = 0
    for pos, name in ipairs(atab) do
        count = count + 1
    end
	return count
end

local function registerMyEvents(self, event, ...)
	if isRegistered == true then return end
	if Fnp_Enable == nil then
		Fnp_Enable = false
	end
	
	if FnpEnableKeys == nil then
		FnpEnableKeys = {
			tankMod = false,
			killline = false,
		}
	end

	if FnpEnableKeys.killline then
		regHealthEvents(true)
	end

	if Fnp_OtherNPFlag == nil then
		Fnp_OtherNPFlag = 0
	end

	curNpFlag, curNpFlag1Type = FilteredNamePlate:GenCurNpFlags()

	if Fnp_ONameList == nil then
		Fnp_ONameList = {}
		table.insert(Fnp_ONameList, "邪能炸药")
	end

	if Fnp_FNameList == nil then
		Fnp_FNameList = {}
	end

	if isInOnlySt == nil then
		isInOnlySt = false
	end

	LastTimeStamps = {
		heal = 0,
	}

	FilteredNamePlate:InitSavedScaleList()

	IsKillLine1 = FnpEnableKeys.killline and (Fnp_SavedScaleList.killline1 < 100)
	IsKillLine2 = FnpEnableKeys.killline and (Fnp_SavedScaleList.killline2 >= 0.01)

	isNullOnlyList = false
	isNullFilterList = false
	if getTableCount(Fnp_ONameList) == 0 then isNullOnlyList = true end
	if getTableCount(Fnp_FNameList) == 0 then isNullFilterList = true end

	isScaleInited = false

	if Fnp_Enable == true then
		FilteredNamePlate.isSettingChanged = false
		for k, v in pairs(FilteredNamePlate.FilterNp_EventList) do
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
		for k, v in pairs(FilteredNamePlate.FilterNp_EventList) do
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
local hideSwitchSingleUnit = {
	[0] = function(frame) --orig
		if frame == nil then return end
		if frame.UnitFrame then
			frame.UnitFrame.name:SetWidth(FilteredNamePlate.curScaleList.name.small)
			if frame.UnitFrame.healthBar then frame.UnitFrame.healthBar:Hide() end
			frame.UnitFrame.castBar:SetHeight(FilteredNamePlate.curScaleList.bars.cast_midHeight)
		end
	end,
	[1] = function(frame) -- all the scaled one
		if frame == nil then return end
		if frame[curNpFlag1Type] then
			frame[curNpFlag1Type]:SetScale(FilteredNamePlate.curScaleList.small)
		end
	end,
	[2] = function(frame) --ek number
		if frame == nil then return end
		if frame.UnitFrame then
			frame.UnitFrame.name:SetWidth(FilteredNamePlate.curScaleList.SMALLW)
			frame.UnitFrame.name:SetHeight(FilteredNamePlate.curScaleList.SMALLH)
			if frame.UnitFrame.healthperc then
				frame.UnitFrame.healthperc:SetFont(FilteredNamePlate.curScaleList.fontFace, FilteredNamePlate.curScaleList.small_perc_font, FilteredNamePlate.curScaleList.fontFlag)
			end
		end
	end,
	[3] = function(frame) --sheStack
		if frame == nil then return end
		if frame.ouf then
			if frame.ouf.Name then
				frame.ouf.Name:SetFont(FilteredNamePlate.curScaleList.fontFace, FilteredNamePlate.curScaleList.small_name_font, FilteredNamePlate.curScaleList.fontFlag)
			end
			if frame.ouf.Health then frame.ouf.Health:Hide() end
		end
	end,
	[4] = function(frame) --cbl
		if frame == nil then return end
		if frame.UnitFrame then
			frame.UnitFrame.name:SetWidth(FilteredNamePlate.curScaleList.NAME_SMALLW)
			if frame.UnitFrame.healthBar then frame.UnitFrame.healthBar:SetScale(FilteredNamePlate.curScaleList.small_scale) end
			frame.UnitFrame.castBar:SetHeight(FilteredNamePlate.curScaleList.mid_scale)
		end
	end,
}

--isOnlyShowSpellCast 的情况下，就代表是仅显模式。并且该怪是非仅显目标而且施法了！
local showSwitchSingleUnit = {
	[0] = function(frame, isOnlyShowSpellCast, restore, isOnlyUnit)
		if frame and frame.UnitFrame then
			if restore == true then
				frame.UnitFrame.name:SetWidth(FilteredNamePlate.curScaleList.name.SYSTEM)
				if frame.UnitFrame.healthBar then
					frame.UnitFrame.healthBar:Show()
					frame.UnitFrame.healthBar:SetHeight(FilteredNamePlate.curScaleList.bars.HEAL_SYS_HEIGHT)
				end
				frame.UnitFrame.castBar:SetHeight(FilteredNamePlate.curScaleList.bars.CAST_SYS_HEIGHT)
			elseif isOnlyShowSpellCast == false then
				frame.UnitFrame.name:SetWidth(FilteredNamePlate.curScaleList.name.normal)
				if frame.UnitFrame.healthBar then
					frame.UnitFrame.healthBar:Show()
					if isOnlyUnit then
						frame.UnitFrame.healthBar:SetHeight(FilteredNamePlate.curScaleList.bars.heal_onlyHeight)
					else
						frame.UnitFrame.healthBar:SetHeight(FilteredNamePlate.curScaleList.bars.heal_normalHeight)
					end
				end
				frame.UnitFrame.castBar:SetHeight(FilteredNamePlate.curScaleList.bars.CAST_SYS_HEIGHT)
			else
				frame.UnitFrame.name:SetWidth(FilteredNamePlate.curScaleList.name.middle)
				frame.UnitFrame.castBar:SetHeight(FilteredNamePlate.curScaleList.bars.cast_midHeight)
				--frame.UnitFrame.healthBar:Show()
			end
		end
	end,
	[1] = function(frame, isOnlyShowSpellCast, restore, isOnlyUnit)
		if frame and frame[curNpFlag1Type] then
			if restore == true then
				frame[curNpFlag1Type]:SetScale(FilteredNamePlate.curScaleList.SYSTEM)
			elseif isOnlyShowSpellCast == false then
				if isOnlyUnit == true then
					frame[curNpFlag1Type]:SetScale(FilteredNamePlate.curScaleList.only)
				else
					frame[curNpFlag1Type]:SetScale(FilteredNamePlate.curScaleList.normal)
				end
			else
				frame[curNpFlag1Type]:SetScale(FilteredNamePlate.curScaleList.middle)
			end
		end
	end,
	[2] = function(frame, isOnlyShowSpellCast, restore, isOnlyUnit)
		if frame and frame.UnitFrame then
			if restore == true then
				frame.UnitFrame.name:SetWidth(FilteredNamePlate.curScaleList.SYSTEMW)
				frame.UnitFrame.name:SetHeight(FilteredNamePlate.curScaleList.SYSTEMH)
				if frame.UnitFrame.healthperc then
					frame.UnitFrame.healthperc:SetFont(FilteredNamePlate.curScaleList.fontFace, FilteredNamePlate.curScaleList.PERC_FONT, FilteredNamePlate.curScaleList.fontFlag)
				end
			elseif isOnlyShowSpellCast == false then
				frame.UnitFrame.name:SetWidth(FilteredNamePlate.curScaleList.SYSTEMW)
				if frame.UnitFrame.healthperc then
					if isOnlyUnit then
						frame.UnitFrame.healthperc:SetFont(FilteredNamePlate.curScaleList.fontFace, FilteredNamePlate.curScaleList.only_perc_font, FilteredNamePlate.curScaleList.fontFlag)
					else
						frame.UnitFrame.healthperc:SetFont(FilteredNamePlate.curScaleList.fontFace, FilteredNamePlate.curScaleList.normal_perc_font, FilteredNamePlate.curScaleList.fontFlag)
					end
				end
			else
				if frame.UnitFrame.healthperc then
					frame.UnitFrame.healthperc:SetFont(FilteredNamePlate.curScaleList.fontFace, FilteredNamePlate.curScaleList.mid_perc_font, FilteredNamePlate.curScaleList.fontFlag)
				end
				--frame.UnitFrame.healthBar:Show()
			end
		end
	end,
	[3] = function(frame, isOnlyShowSpellCast, restore, isOnlyUnit)
		if frame and frame.ouf then
			if restore == true then
				frame.ouf.Name:SetFont(FilteredNamePlate.curScaleList.fontFace, FilteredNamePlate.curScaleList.NAME_FONT, FilteredNamePlate.curScaleList.fontFlag)
				frame.ouf.Health:Show()
			elseif isOnlyShowSpellCast == false then
				frame.ouf.Health:Show()
				if isOnlyUnit then
					frame.ouf.Name:SetFont(FilteredNamePlate.curScaleList.fontFace, FilteredNamePlate.curScaleList.only_name_font, FilteredNamePlate.curScaleList.fontFlag)
				else
					frame.ouf.Name:SetFont(FilteredNamePlate.curScaleList.fontFace, FilteredNamePlate.curScaleList.normal_name_font, FilteredNamePlate.curScaleList.fontFlag)
				end
			else
				frame.ouf.Name:SetFont(FilteredNamePlate.curScaleList.fontFace, FilteredNamePlate.curScaleList.mid_name_font, FilteredNamePlate.curScaleList.fontFlag)
			end
		end
	end,
	[4] = function(frame, isOnlyShowSpellCast, restore, isOnlyUnit)
		if frame and frame.UnitFrame then
			if restore == true then
				frame.UnitFrame.name:SetWidth(FilteredNamePlate.curScaleList.NAME_SYSTEMW)
				if frame.UnitFrame.healthBar then
					frame.UnitFrame.healthBar:SetScale(FilteredNamePlate.curScaleList.SYS_SCALE)
				end
				frame.UnitFrame.castBar:SetScale(FilteredNamePlate.curScaleList.SYS_SCALE)
			elseif isOnlyShowSpellCast == false then
				frame.UnitFrame.name:SetWidth(FilteredNamePlate.curScaleList.NAME_SYSTEMW)
				if frame.UnitFrame.healthBar then
					if isOnlyUnit then
						frame.UnitFrame.healthBar:SetScale(FilteredNamePlate.curScaleList.only_scale)
					else
						frame.UnitFrame.healthBar:SetScale(FilteredNamePlate.curScaleList.nor_scale)
					end
				end
				frame.UnitFrame.castBar:SetScale(FilteredNamePlate.curScaleList.SYS_SCALE)
			else
				frame.UnitFrame.name:SetWidth(FilteredNamePlate.curScaleList.NAME_SYSTEMW)
				frame.UnitFrame.healthBar:SetScale(FilteredNamePlate.curScaleList.mid_scale)
				--frame.UnitFrame.healthBar:Show()
			end
		end
	end,
}

function FilteredNamePlate:actionUnitStateAfterChanged()
	IsKillLine1 = FnpEnableKeys.killline and (Fnp_SavedScaleList.killline1 < 100)
	IsKillLine2 = FnpEnableKeys.killline and (Fnp_SavedScaleList.killline2 >= 0.01)
	-- TODO 添加血量变化
	local lastNp = curNpFlag
	curNpFlag, curNpFlag1Type = FilteredNamePlate:GenCurNpFlags()
	if not (curNpFlag == lastNp) then --UI类型有变
		-- 需要有怪在周围重新 重新获取一下
		isScaleInited = false
		print(FNP_LOCALE_TEXT.FNP_CHANGED_UITYPE)
		return
	end

	isScaleInited = FilteredNamePlate:initScaleValues(curNpFlag, isScaleInited)
	local matched = false
	local matched2 = false
	setCVarValues()
	isInOnlySt = false
	if Fnp_Enable == true then
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
					local foundUnit = (frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)) or (frame.unitFrame and frame.unitFrame.unit)
					if foundUnit then matched2 = isMatchedNameList(Fnp_FNameList, GetUnitName(foundUnit)) end
				end
				if matched2 == true then
					hideSwitchSingleUnit[curNpFlag](frame)
				else
					showSwitchSingleUnit[curNpFlag](frame, false, false, false) -- 全是普通情况
				end
			else
				local foundUnit = (frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)) or (frame.unitFrame and frame.unitFrame.unit)
				matched = false
				if foundUnit then matched = isMatchedNameList(Fnp_ONameList, GetUnitName(foundUnit)) end
				if matched == true then
					isHide = true
					break
				end
			end
		end
		if isHide == true then
			isInOnlySt = true
			for _, frame in pairs(GetNamePlates()) do
				local foundUnit = (frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)) or (frame.unitFrame and frame.unitFrame.unit)
				matched = false
				if foundUnit then matched = isMatchedNameList(Fnp_ONameList, GetUnitName(foundUnit)) end
				if matched == true then
					-- 仅显模式仅显的怪
					showSwitchSingleUnit[curNpFlag](frame, false, false, true)
				else
					if UnitIsPlayer(foundUnit) == false then hideSwitchSingleUnit[curNpFlag](frame) end
				end
			end
		else
			for _, frame in pairs(GetNamePlates()) do
				-- 普通模式
				showSwitchSingleUnit[curNpFlag](frame, false, false, false)
			end	
		end
		-- registerMyEvents(FilteredNamePlate_Frame, "", "")
	else -- 已经关闭功能就全部显示
		for _, frame in pairs(GetNamePlates()) do
			local foundUnit = (frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)) or (frame.unitFrame and frame.unitFrame.unit)
			if foundUnit then
				-- disable 还原了！
				showSwitchSingleUnit[curNpFlag](frame, false, true, false)
			end
		end
		-- unRegisterMyEvents(FilteredNamePlate_Frame)
	end
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
	if curOnlyMatch == false and isInOnlySt == true then
		--新增单位不需要仅显,但是目前处于仅显情况下, 那么,就将当前这个Hide
		local frame = GetNamePlateForUnit(unitid)
		local foundUnit = (frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)) or (frame.unitFrame and frame.unitFrame.unit)
		if UnitIsPlayer(foundUnit) == false then hideSwitchSingleUnit[curNpFlag](frame) end
	elseif curOnlyMatch == false and isInOnlySt == false then
		-- 新增单位不需要仅显, 此时也没有仅显, 就不管了.现在我们将当前的效果展示出来
		local frame = GetNamePlateForUnit(unitid)
		local foundUnit = (frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)) or (frame.unitFrame and frame.unitFrame.unit)
		if UnitIsPlayer(foundUnit) == false then showSwitchSingleUnit[curNpFlag](GetNamePlateForUnit(unitid), false, false, false) end
	elseif curOnlyMatch == true and isInOnlySt == true then
		-- 新增单位是需要仅显的,而此时已经有仅显的了,于是我们什么也不用干 -- 更新，怀疑在异步调用的时候莫名奇妙被hide了这里开出来确保
		showSwitchSingleUnit[curNpFlag](GetNamePlateForUnit(unitid), false, false, true)
	elseif curOnlyMatch == true and isInOnlySt == false then
		--新增单位是需要仅显的,而此时不是仅显, 于是我们就将之前的都Hide,当前这个不用处理
		for _, frame in pairs(GetNamePlates()) do
			local foundUnit = (frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)) or (frame.unitFrame and frame.unitFrame.unit)
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
		isInOnlySt = true
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
			local foundUnit = (frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)) or (frame.unitFrame and frame.unitFrame.unit)
			if foundUnit then
				matched = isMatchedNameList(Fnp_ONameList, GetUnitName(foundUnit))
				if matched == true then
					return --have & return
				end
			end
		end
		--没有找到,说明我们该退出了就显示
		for _, frame in pairs(GetNamePlates()) do
			local foundUnit = (frame.namePlateUnitToken or (frame.UnitFrame and frame.UnitFrame.unit)) or (frame.unitFrame and frame.unitFrame.unit)
			if foundUnit then
				matched = isMatchedNameList(Fnp_ONameList, GetUnitName(foundUnit))
				if matched == false then
					-- 退出仅显模式， 说明这些都是普通
					if UnitIsPlayer(foundUnit) == false then showSwitchSingleUnit[curNpFlag](frame, false, false, false) end
				end
			end
		end
		isInOnlySt = false
	end
end
---------k k k---k k k---k k k-------------

local function actionUnitAdded(self, event, ...)
	if isScaleInited == false then
		isScaleInited = FilteredNamePlate:initScaleValues(curNpFlag, isScaleInited)
		setCVarValues()
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
	if Fnp_Enable == false then return end
	if isNullOnlyList == true and isNullFilterList == true then
		return
	end

	local unitid = ...
	if UnitIsPlayer(unitid) then
		return
	end
	actionUnitAddedForce(unitid)
end

local function actionUnitRemoved(self, event, ...)
	--这里不需要判断是否为空
	-- if isNullOnlyList == true and isNullFilterList == true then
	--	return
	-- end
	if isInOnlySt == false then
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
	if isInOnlySt == false then
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
	if isInOnlySt == false then
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

local function actionUnitHealth(self, event, ...)
	local unitid = ...
	if UnitIsPlayer(unitid) then
		return
	end
	local ts = GetTime()
	if (LastTimeStamps.heal + 0.2) >= ts then
		return
	end
	LastTimeStamps.heal = ts
	local perc = (UnitHealth("target") * 100) / UnitHealthMax("target")
	print(UnitHealthMax("target").."changed! "..unitid..GetUnitName(unitid)..perc)
	if UnitHealthMax("target") > 0 then
		local isKill = false
		if IsKillLine1 and perc >= Fnp_SavedScaleList.killline1 then
			isKill = true
		end
		if IsKillLine2 and perc >= Fnp_SavedScaleList.killline2 then
			isKill = true
		end
		local frame = GetNamePlateForUnit(unitid)
		if isKill then
			showSwitchSingleUnit[curNpFlag](frame, false, false, true)
		else
			--TODO 这个刷新可能太频繁了。恢复显示机制。
		end
	end
end

FilteredNamePlate.FilterNp_EventList = {
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
	local handler = FilteredNamePlate.FilterNp_EventList[event]
	if handler then
	    handler(self, event, ...)
	end
end

function FilteredNamePlate_OnLoad()
	isRegistered = false
	isErrInLoad = false
	FilteredNamePlate_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function FilteredNamePlate:AvailabilityDropDown_OnShow(frame)
	if isInitedDrop == nil or isInitedDrop == false then
		local function DropDown_OnClick(val)
			UIDropDownMenu_SetSelectedValue(FilteredNamePlate_Frame_DropDownUIType, val)
			UIDropDownMenu_SetText(FilteredNamePlate_Frame_DropDownUIType, FilteredNamePlate.UITypeList[val])
			if Fnp_OtherNPFlag == val then return end
			Fnp_OtherNPFlag = val

			FilteredNamePlate:ChangedSavedScaleList(val)

			FilteredNamePlate_Frame_OnlyShowScale:SetValue(Fnp_SavedScaleList.only * 100)
			FilteredNamePlate.isSettingChanged = true
			FilteredNamePlate_Frame_reloadUIBtn:Show()
			FilteredNamePlate_Frame_takeEffectBtn:Show()
		end

		local function initWithDropDown()
			local self = FilteredNamePlate
			local info = {}
			local i = 0
			for i=0,#FilteredNamePlate.UITypeCheckList do
				FilteredNamePlate.UITypeCheckList[i] = false
			end
			FilteredNamePlate.UITypeCheckList[Fnp_OtherNPFlag] = true
			i = 0
			for i = 0,#FilteredNamePlate.UITypeList do
				info.text = FilteredNamePlate.UITypeList[i]
				info.value = i
				info.checked = FilteredNamePlate.UITypeCheckList[i]
				info.keepShownOnClick = false
				info.func = function(_, self, val) DropDown_OnClick(val) end
				info.arg1 = self
				info.arg2 = i
				UIDropDownMenu_AddButton(info)
			end
		end
		UIDropDownMenu_Initialize(frame, initWithDropDown)
		isInitedDrop = true
	end
	UIDropDownMenu_SetText(frame, FilteredNamePlate.UITypeList[Fnp_OtherNPFlag])
end

function FilteredNamePlate:FNP_EnableButtonChecked(frame, checked, ...)
	if frame then
		if FilteredNamePlate_Frame == nil then return end
		if not FilteredNamePlate_Frame:IsShown() then return end
		local info = ...
		if info == "killline" then
			FnpEnableKeys.killline = checked
			IsKillLine1 = FnpEnableKeys.killline and (Fnp_SavedScaleList.killline1 < 100)
			IsKillLine2 = FnpEnableKeys.killline and (Fnp_SavedScaleList.killline2 >= 0.01)
			if FnpEnableKeys.killline then
				FilteredNamePlate_Menu4:Enable() -- modify --
				--TODO 添加血量变化
			else
				FilteredNamePlate_Menu4:Disable() -- modify --
			end
			regHealthEvents(FnpEnableKeys.killline)
		elseif info == "tank" then
			FnpEnableKeys.tankMod = checked
		end
		return
	end
	Fnp_Enable = checked
	FilteredNamePlate:actionUnitStateAfterChanged()
end

function FilteredNamePlate:FNP_ModeEditBoxWritenEsc()
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

function FilteredNamePlate:FNP_ModeEditBoxWriten(mode, inputStr)
	if mode == "o" then
		Fnp_ONameList = {}
		string.gsub(inputStr, '[^;]+', function(w) table.insert(Fnp_ONameList, w) end )
	else
		Fnp_FNameList = {}
		string.gsub(inputStr, '[^;]+', function(w) table.insert(Fnp_FNameList, w) end )
	end
end

function FilteredNamePlate:FNP_ChangeFrameVisibility(...)
	local info = ...
	if info == nil then
		if FilteredNamePlate_Frame:IsVisible() then
			FilteredNamePlate_Frame:Hide()
			FilteredNamePlate_Menu:Hide()
		else
			local oldChange = FilteredNamePlate.isSettingChanged
			FilteredNamePlate_Frame_reloadUIBtn:Hide()
			FilteredNamePlate_Frame_EnableCheckButton:SetChecked(Fnp_Enable);
			FilteredNamePlate_Frame_TankModCB:SetChecked(FnpEnableKeys.tankMod);
			FilteredNamePlate_Frame_KilllineModCB:SetChecked(FnpEnableKeys.killline);

			FilteredNamePlate_Frame_OnlyShowScale:SetValue(Fnp_SavedScaleList.only * 100)
			FilteredNamePlate_Frame_OnlyOtherShowScale:SetValue(Fnp_SavedScaleList.small * 100)
			FilteredNamePlate_Frame_SystemScale:SetValue(Fnp_SavedScaleList.normal * 100)

			FilteredNamePlate_Frame_Slider_KL1:SetValue(Fnp_SavedScaleList.killline1 * 100)
			FilteredNamePlate_Frame_Slider_KL2:SetValue(Fnp_SavedScaleList.killline2 * 100)

			FilteredNamePlate_Frame_OnlyShowModeEditBox:SetText(table.concat(Fnp_ONameList, ";"));
			FilteredNamePlate_Frame_FilteredModeEditBox:SetText(table.concat(Fnp_FNameList, ";"));

			if FnpEnableKeys.killline then
				FilteredNamePlate_Menu4:Enable() -- modify --
			else
				FilteredNamePlate_Menu4:Disable() -- modify --
			end

			if oldChange == false then
				FilteredNamePlate_Frame_takeEffectBtn:Hide()
			end
			FilteredNamePlate_Frame:Show()
			FilteredNamePlate_Menu:Show()
		end
	else
		ClickOnMenu(info)
	end
end

function SlashCmdList.FilteredNamePlate(msg)
	if msg == "" then
		print(L.FNP_PRINT_HELP0)
		print(L.FNP_PRINT_HELP1)
		print(L.FNP_PRINT_HELP2)
		print(L.FNP_PRINT_HELP3)
	elseif msg == "options" or msg == "opt" then
		FilteredNamePlate:FNP_ChangeFrameVisibility()
	elseif msg == "change" or msg == "ch" then
		if Fnp_Enable == true then
			FilteredNamePlate_Frame_EnableCheckButton:SetChecked(false)
			FilteredNamePlate:FNP_EnableButtonChecked(FilteredNamePlate_Frame, false)
		else
			FilteredNamePlate_Frame_EnableCheckButton:SetChecked(true)
			FilteredNamePlate:FNP_EnableButtonChecked(FilteredNamePlate_Frame, true)
		end
	elseif msg == "refresh" then
		FilteredNamePlate:actionUnitStateAfterChanged()
	elseif msg == "test" then
		for _, frame in pairs(GetNamePlates()) do
			if frame then
				FilteredNamePlate.printTable(frame.UnitFrame)
				break
			end
		end
	end
end
