BuffCheck = BuffCheck or {}

BuffCheck.KungfuGroup = LoadLUAData("\\Interface\\BuffCheck\\KungfuGroup.dat") or {}
BuffCheck.BuffList = LoadLUAData("\\Interface\\BuffCheck\\bufflist.txt") or {}



-----------------------------------------------
-- 本地函数和变量
-----------------------------------------------
local _BuffCheck = {
	dwVersion = 0x0060a00,
	szBuildDate = "20130312",
	tSkillCache = {},
	tBuffCache = {}
}

-----------------------------------------------
-- ……
-----------------------------------------------
BuffCheckData = {
	bDPSOnlyEnable = true,
	bCheckLeftTimeEnable = true,
	nLeftTimeForCheck = 240,
	nSayChannel = PLAYER_TALK_CHANNEL.RAID,
	nCheckType = 1,
	QuickCheckType = {
		[17] = true,
		[18] = true,
		[19] = true,
		[20] = true,
		[24] = false,
		["danzhong"] = false,
		["jiaozi"] = false,
	},
}
for k, _ in pairs(BuffCheckData) do
	RegisterCustomData("BuffCheckData." .. k)
end


-- (string, number) BuffCheck.GetVersion()		-- HM的 获取字符串版本号 修改方便拿过来了
BuffCheck.GetVersion = function()
	local v = _BuffCheck.dwVersion
	local szVersion = string.format("%d.%d.%d", v/0x1000000,
		math.floor(v/0x10000)%0x100, math.floor(v/0x100)%0x100)
	if  v%0x100 ~= 0 then
		szVersion = szVersion .. "b" .. tostring(v%0x100)
	end
	return szVersion, v
end



-- (void) BuffCheck.Talk([number nChannel, ] string szText)
BuffCheck.Talk = function(nChannel,szText)
	local me = GetClientPlayer()
	if type(nChannel) == "string" then
		szText = nChannel
		nChannel = BuffCheckData.nSayChannel
	end
	local tSay = {{ type = "text", text = szText .. "\n"}}
	if nChannel == PLAYER_TALK_CHANNEL.RAID and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
		nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
	elseif nChannel == PLAYER_TALK_CHANNEL.LOCAL_SYS then
		OutputMessage("MSG_SYS", szText	.. "\n")
	else
		me.Talk(nChannel,"",tSay)
	end
end

-- (void) BuffCheck.Confirm(string szMsg, func fnAction, func fnCancel[, string szSure[, string szCancel]])
BuffCheck.Confirm = function(szMsg, fnAction, fnCancel, szSure, szCancel)
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 2, bRichText = true , szMessage = szMsg, szName = "BuffCheck_Confirm_"..Random(99999),
		{
			szOption = szSure or g_tStrings.STR_HOTKEY_SURE,
			fnAction = fnAction,
		}, {
			szOption = szCancel or g_tStrings.STR_HOTKEY_CANCEL,
			fnAction = fnCancel,
		},
	}
	MessageBox(tMsg)
end

-- (string) BuffCheck.GetTimeString()		-- 获取当前游戏时间的字符串
BuffCheck.GetTimeString = function()
	return FormatTime("%Y年%m月%d日 %H:%M:%S",GetCurrentTime())
end
-- (string) BuffCheck.GetKungfuName(number dwKungfuID [, number nSep])		-- 
BuffCheck.GetKungfuName = function(dwKungfuID,nSep)
	nSep = nSep or 4
	if not _BuffCheck.tSkillCache[dwKungfuID] then
		 _BuffCheck.tSkillCache[dwKungfuID] = string.sub(Table_GetSkillName(dwKungfuID,0),0,nSep)
	end
	return _BuffCheck.tSkillCache[dwKungfuID]
end

-- (string table) 
BuffCheck.GetBuffInfo = function(dwID,nLevel)
	if not _BuffCheck.tBuffCache[dwID] or not _BuffCheck.tBuffCache[dwID][nLevel] then
		local szName = Table_GetBuffName(dwID,nLevel)
		local nType = GetBuffInfo(dwID,nLevel,{}).nDetachType or 0
		_BuffCheck.tBuffCache[dwID] = {[nLevel]={dwID,nLevel,nType,szName}}
	end
	return _BuffCheck.tBuffCache[dwID][nLevel]
end


-- (table,Kobject) BuffCheck.GetMemberList()	-- GetMemberList
BuffCheck.GetMemberList = function()
	local tMemberList = {}
	if GetClientPlayer().IsInParty() then
		local hTeam = GetClientTeam()
		for i = 0, hTeam.nGroupNum - 1 do
			local tGroupInfo = hTeam.GetGroupInfo(i)
			for _, dwID in pairs(tGroupInfo.MemberList) do
				table.insert(tMemberList,dwID)
			end
		end
	end
	return tMemberList , GetClientTeam()
end

-- (void) BuffCheck.MenuTip(string str)	-- MenuTip
BuffCheck.MenuTip = function(str)
	local szText="<image>path=\"ui/Image/UICommon/Talk_Face.UITex\" frame=25 w=24 h=24</image> <text>text=" .. EncodeComponentsString(str) .." font=207 </text>"
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(szText, 450, {x, y, w, h})	
end

-----------------------------------------------
-- 装备分查询
-----------------------------------------------
BuffCheck.EquipScoreStatistic = function()
	local EquipScoreStatisticCache = {}
	local tMemberList,hTeam = BuffCheck.GetMemberList()
	for _, dwID in pairs(tMemberList) do
		local tMemberInfo = hTeam.GetMemberInfo(dwID)
		local hMember = GetPlayer(dwID)
		if hMember and tMemberInfo then
			local nEquipScore = hMember.GetTotalEquipScore()
			if nEquipScore == 0 then
				ViewInviteToPlayer(dwID)
				nEquipScore = hMember.GetTotalEquipScore()
			else
				table.insert(EquipScoreStatisticCache, { dwID = dwID, szName = tMemberInfo.szName, szKungfu = BuffCheck.GetKungfuName(tMemberInfo.dwMountKungfuID), nScore = nEquipScore })
			end
		end
	end
	local a,n = table.getn(tMemberList),table.getn(EquipScoreStatisticCache)
	BuffCheck.EquipScoreStatisticData = EquipScoreStatisticCache		
	if n < a then
		local szText = "<Text>text="..EncodeComponentsString(" 【装备分检查】 检查时间："..BuffCheck.GetTimeString().."\n") .." font=207 </text><Text>text="..EncodeComponentsString("\n 获取到了 ") .. " font=16 </text><Text>text="..EncodeComponentsString(n) .." font=2 </text><Text>text="..EncodeComponentsString(" 个玩家的装备分 这和团队总玩家数 ") .. " font=16 </text><Text>text="..EncodeComponentsString(a) .." font=2 </text><Text>text="..EncodeComponentsString(" 不匹配\n 可能是玩家不在视线范围内，也可能是首次获取数据不全。") .. "font=16 </text>"
		BuffCheck.Confirm(szText,BuffCheck.EquipScoreStatisticTalk,BuffCheck.EquipScoreStatistic,"发布统计","重新获取")
	else
		local szText = "<Text>text="..EncodeComponentsString(" 【装备分检查】 检查时间："..BuffCheck.GetTimeString().."\n") .." font=207 </text><Text>text="..EncodeComponentsString("\n 已经获取到了全团 ") .. " font=16 </text><Text>text="..EncodeComponentsString(n) .." font=2 </text><Text>text="..EncodeComponentsString(" 个玩家的装备分 ") .. "font=16 </text>"
		BuffCheck.Confirm(szText,BuffCheck.EquipScoreStatisticTalk,nil,"发布统计","取消")
	end
end

BuffCheck.EquipScoreStatisticTalk = function()
	if not BuffCheck.EquipScoreStatisticData then return end
	table.sort(BuffCheck.EquipScoreStatisticData, function(a, b) return (a.nScore > b.nScore) end)
	BuffCheck.Talk("【装备分检查结果如下】")
	for _, v in pairs(BuffCheck.EquipScoreStatisticData) do
		BuffCheck.Talk(FormatString("【<D0>】<D1>：<D2>分",v.szKungfu,v.szName,v.nScore))
	end
	BuffCheck.Talk("装备分检查发布完毕")
	OutputWarningMessage("MSG_WARNING_GREEN", "发布完毕，请查看相应的频道。",6)
end

-----------------------------------------------
-- 小吃评分
-----------------------------------------------
BuffCheck.CheckAllMember = function()
	local tScoreList = {}
	local tMemberList,hTeam = BuffCheck.GetMemberList()
	BuffCheck.Talk("【小吃评分结果如下】")
	for _,dwID in pairs(tMemberList) do
		local memberinfo = hTeam.GetMemberInfo(dwID)
		local dwKungfuID = memberinfo.dwMountKungfuID or 11
		if not BuffCheckData.bDPSOnlyEnable or BuffCheck.KungfuGroup[12][dwKungfuID] then
			local nScore = BuffCheck.GetMemberScore(dwID, memberinfo)
			table.insert(tScoreList, {dwID = dwID,szName = memberinfo.szName,nScore = nScore,szKungfuName = BuffCheck.GetKungfuName(memberinfo.dwMountKungfuID)})
		end
	end
	table.sort(tScoreList,function(a,b) return (a.nScore > b.nScore) end)
	for k = 1,#tScoreList do
		if tScoreList[k].nScore >= 0  then
			BuffCheck.Talk(FormatString("【<D0>】<D1>：<D2>分",tScoreList[k].szKungfuName,tScoreList[k].szName,tScoreList[k].nScore))
		else
			BuffCheck.Talk(FormatString("【<D0>】<D1> 目标不在视线范围内",tScoreList[k].szKungfuName,tScoreList[k].szName))
		end
	end
	BuffCheck.Talk("评分完毕。")
	OutputWarningMessage("MSG_WARNING_GREEN", "评分完毕，请查看相应的频道。",6)
end

BuffCheck.GetMemberScore = function(dwID, memberinfo)
	local member = GetPlayer(dwID)
	local nScoreTotal = 0
	if member then
		local dwKungfuID = memberinfo.dwMountKungfuID or 11
		local tBuffList = member.GetBuffList() or {}
		for _, tBuff in pairs(tBuffList) do
			for i = 1,#BuffCheck.BuffList do
				for k,tInfo in pairs(BuffCheck.BuffList[i]) do
					if tBuff.dwID == tInfo.dwID and tBuff.nLevel == tInfo.nLevel then
						if tInfo.bOn then
							local bTimeEnough = true
							if BuffCheckData.bCheckLeftTimeEnable then
								bTimeEnough = BuffCheck.CheckLeftTimeEnough(tBuff.nEndFrame)
							end
							if bTimeEnough and (tInfo.nKungfuType == 0 or (BuffCheck.KungfuGroup[tInfo.nKungfuType] and BuffCheck.KungfuGroup[tInfo.nKungfuType][dwKungfuID])) then
								nScoreTotal = nScoreTotal + tInfo.tScore[BuffCheckData.nCheckType] or tInfo.tScore[1]
							end
						end
					end
				end
			end
		end
	else
		nScoreTotal = -1
	end
	return nScoreTotal
end

-----------------------------------------------
-- 小吃缺漏
-----------------------------------------------
	
BuffCheck.QuickCheckAll = function()
	local tScoreList = {}
	local tMemberList,hTeam = BuffCheck.GetMemberList()
	BuffCheck.Talk("【小吃缺漏结果如下】")
	for _,dwID in pairs(tMemberList) do
		local memberinfo = hTeam.GetMemberInfo(dwID)
		local hPlayer = GetPlayer(dwID)
		local tClass = {
			[24] = "宴席",
			[17] = "辅助食品",
			[18] = "增强食品",
			[19] = "辅助药品",
			[20] = "增强药品",
			["danzhong"] = "膻中",
			["jiaozi"] = "饺子",
		}
		if hPlayer then
			local dwKungfuID = memberinfo.dwMountKungfuID or 11
			local tBuffList = hPlayer.GetBuffList() or {}
			if BuffCheckData.bDPSOnlyEnable and BuffCheck.KungfuGroup[34][dwKungfuID] then
				for k,_ in pairs(tClass) do
					tClass[k] = nil
				end
			end
			for _, tBuff in pairs(tBuffList) do
				local tInfo = BuffCheck.GetBuffInfo(tBuff.dwID,tBuff.nLevel)
				local bTimeEnough = true
				if BuffCheckData.bCheckLeftTimeEnable then
					bTimeEnough = BuffCheck.CheckLeftTimeEnough(tBuff.nEndFrame)
				end
				if bTimeEnough then
					if tInfo[3] == 24 then
						tClass[24] = nil
					elseif tBuff.dwID == 1171 and tBuff.nLevel==1 then
						tClass["danzhong"] = nil
					elseif tBuff.dwID == 1594 and (tBuff.nLevel==1 or tBuff.nLevel==2) then
						tClass["jiaozi"] = nil
					elseif tInfo[3] ~= 0 then
						if not BuffCheckData.bDPSOnlyEnable or not BuffCheck.KungfuGroup[34][dwKungfuID] then
							for k,v in pairs(tClass) do
								if tInfo[3] == k then
									tClass[k] = nil
									break
								end
							end
						end
					end
				end
			end
			local szText = ""
			local nScore = 0
			for k,v in pairs(tClass) do
				if BuffCheckData.QuickCheckType[k] then
					nScore = nScore + 10
					szText = szText.." "..v
				end
			end
			if nScore > 0 then
				table.insert(tScoreList, {dwID = dwID,szName = memberinfo.szName,nScore = nScore,text=FormatString("【<D0>】<D1> 缺<D2>",BuffCheck.GetKungfuName(memberinfo.dwMountKungfuID),memberinfo.szName,szText)})
			end
		else
			table.insert(tScoreList, {dwID = dwID,szName = memberinfo.szName,nScore = 1000,text=FormatString("【<D0>】<D1> 目标不在视线范围内",BuffCheck.GetKungfuName(memberinfo.dwMountKungfuID),memberinfo.szName)})
		end
	end
	table.sort(tScoreList,function(a,b) return (a.nScore < b.nScore) end)
	
	for k = 1,#tScoreList do
		BuffCheck.Talk(tScoreList[k].text)
	end
	local a,n = table.getn(tMemberList),table.getn(tScoreList)
	BuffCheck.Talk(FormatString("检查完毕 缺漏 <D0>/<D1>",n,a))
	OutputWarningMessage("MSG_WARNING_GREEN", "缺漏检查结束，请查看相应的频道。",6)
end

function BuffCheck.CheckLeftTimeEnough(nEndFrame)
	local nLeftFrame = nEndFrame - GetLogicFrameCount()
	if nLeftFrame / 16 >= BuffCheckData.nLeftTimeForCheck then
		return true
	else
		return false
	end
end

-----------------------------------------------
-- RaidGrid_CheckTeamVersion
-----------------------------------------------
BuffCheck.RaidGrid_CheckTeamVersion = function()
	if not BuffCheck.RaidGrid_CheckTeamVersionData then return end
	local tMemberList,hTeam = BuffCheck.GetMemberList()
	
	local tCache = {}
	for k, dwID in pairs(tMemberList) do
		local memberinfo = hTeam.GetMemberInfo(dwID)
		if memberinfo then
			if dwID == GetClientPlayer().dwID  or BuffCheck.RaidGrid_CheckTeamVersionData[memberinfo.szName] then
				table.insert(tCache,{szName = memberinfo.szName , dwMountKungfuID = memberinfo.dwMountKungfuID , b = true , v = BuffCheck.RaidGrid_CheckTeamVersionData[memberinfo.szName] or 10})
			else
				table.insert(tCache,{szName = memberinfo.szName , dwMountKungfuID = memberinfo.dwMountKungfuID , b = false , v = -1})
			end
		end
	end
	table.sort(tCache,function(a,b)	return (a.v > b.v) end)
	BuffCheck.Talk("【团队事件监控检查】")
	local a = table.getn(tCache)
	local n = 0
	for k, v in pairs(tCache) do
		if not v.b then
			n = n + 1
			BuffCheck.Talk(FormatString("【<D0>】<D1> 未安装",BuffCheck.GetKungfuName(v.dwMountKungfuID),v.szName))
		else
			if v.v == 10 then v.v = "检查者" end
			BuffCheck.Talk(FormatString("【<D0>】<D1>：<D2>",BuffCheck.GetKungfuName(v.dwMountKungfuID),v.szName,v.v))
		end
	end
	BuffCheck.Talk(FormatString("检查完毕 人数 <D0>/<D1>",n,a))
	BuffCheck.RaidGrid_CheckTeamVersionData = {}
end


BuffCheck.tBuffTypeNames = {
	[1] = "烹饪宴席",
	[2] = "烹饪辅助品",
	[3] = "烹饪增强品",
	[4] = "医术辅助品",
	[5] = "医术增强品",
	[6] = "其他",
}


BuffCheck.tDefaultSetForAdd = {szName="模板设置",szType="其他",bOn=true,dwID=0,nLevel=1,tScore={[1]=20}}

function BuffCheck.AddList(nIndex, szName)
	if not szName or szName == "" then
		return
	end
	for i = 1, #BuffCheck.BuffList[nIndex], 1 do
		if BuffCheck.BuffList[nIndex][i].szName == szName then
			OutputMessage("MSG_SYS", "Buff检查["..szName.."]已存在！".."\n")
			return
		end
	end
	local tNewRecord = clone(BuffCheck.tDefaultSetForAdd)
	tNewRecord.szName = szName
	tNewRecord.szType = BuffCheck.tBuffTypeNames[nIndex]
	table.insert(BuffCheck.BuffList[nIndex], tNewRecord)
	SaveLUAData("\\Interface\\BuffCheck\\bufflist.txt",BuffCheck.BuffList)
end

function BuffCheck.AddListByCopy(handleRecord, nIndex, szNewName)
	if not handleRecord then
		return
	end
	if not szNewName or szNewName == "" then
		return
	end
	for i = 1, #BuffCheck.BuffList[nIndex], 1 do
		if BuffCheck.BuffList[nIndex][i].szName == szNewName then
			OutputMessage("MSG_SYS", "Buff检查["..szNewName.."]已存在！".."\n")
			return
		end
	end
	local tNewRecord = clone(handleRecord)
	tNewRecord.szName = szNewName
	tNewRecord.szType = BuffCheck.tBuffTypeNames[nIndex]
	table.insert(BuffCheck.BuffList[nIndex], tNewRecord)
	SaveLUAData("\\Interface\\BuffCheck\\bufflist.txt",BuffCheck.BuffList)
end

function BuffCheck.SetNewName(handleRecord)
	if not handleRecord then
		return
	end
	local Recall = function(szText)
		if not szText or szText == "" then
			return
		end
		handleRecord.szName = szText
		SaveLUAData("\\Interface\\BuffCheck\\bufflist.txt",BuffCheck.BuffList)
	end
	GetUserInput("输入新名字：", Recall, nil, function() end, nil, handleRecord.szName, 31)
end

function BuffCheck.SetnLeftTimeForCheck()
	local Recall = function(szText)
		if not szText or szText == "" then
			return
		end
		local nCount = tonumber(szText)
		if not nCount then
			return
		end
		if nCount > 0 then
			BuffCheckData.nLeftTimeForCheck = nCount
		end
	end
	GetUserInput("输入新时间：", Recall, nil, function() end, nil, BuffCheckData.nLeftTimeForCheck, 31)
end


function BuffCheck.SetdwID(handleRecord)
	if not handleRecord then
		return
	end
	local Recall = function(szText)
		if not szText or szText == "" then
			return
		end
		local nCount = tonumber(szText)
		if not nCount then
			return
		end
		if nCount > 0 then
			handleRecord.dwID = nCount
			SaveLUAData("\\Interface\\BuffCheck\\bufflist.txt",BuffCheck.BuffList)
		end
	end
	GetUserInput("BuffID设置：", Recall, nil, function() end, nil, handleRecord.dwID, 31)
end

function BuffCheck.SetnScoreForBuff(handleRecord, a)
	if not handleRecord then
		return
	end
	local Recall = function(szText)
		if not szText or szText == "" then
			return
		end
		local nCount = tonumber(szText)
		if not nCount then
			return
		end
		if nCount > 0 then
			handleRecord.tScore[a] = nCount
			SaveLUAData("\\Interface\\BuffCheck\\bufflist.txt",BuffCheck.BuffList)
		end
	end
	GetUserInput("分数设置：", Recall, nil, function() end, nil, handleRecord.tScore[a], 3)
end

function BuffCheck.SetnLevel(handleRecord)
	if not handleRecord then
		return
	end
	local Recall = function(szText)
		if not szText or szText == "" then
			return
		end
		local nCount = tonumber(szText)
		if not nCount then
			return
		end
		if nCount > 0 then
			handleRecord.nLevel = nCount
			SaveLUAData("\\Interface\\BuffCheck\\bufflist.txt",BuffCheck.BuffList)
		end
	end
	GetUserInput("BuffLevel设置：", Recall, nil, function() end, nil, handleRecord.nLevel, 3)
end




function BuffCheck.GetMenuList()
	local szVersion,v  = BuffCheck.GetVersion()
	local menu = {
			szOption = "常规团队杀手",szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_LEFT",{
				szOption = "当前版本 "..szVersion.."  ".._BuffCheck.szBuildDate,bDisable = true,
			}
		}
	
	local menu_1 = {
			szOption = "【设置】小吃检查设置：",
			{
				szOption = "只检查输出内功", 
				bCheck = true, 
				bChecked = BuffCheckData.bDPSOnlyEnable, 
				fnAction = function(UserData, bCheck)
					BuffCheckData.bDPSOnlyEnable = bCheck
				end,
				fnMouseEnter = function()
					BuffCheck.MenuTip("顾名思义，MT和治疗不会被检查。")
				end,
			},
			{
				szOption = "检查小吃剩余时间",
				bCheck = true,
				bChecked = BuffCheckData.bCheckLeftTimeEnable,
				fnAction = function(UserData, bCheck)
					--## IsCtrlKeyDown() ? BuffCheck.SetnLeftTimeForCheck() : BuffCheckData.bCheckLeftTimeEnable = bCheck
					if IsCtrlKeyDown() then
						BuffCheck.SetnLeftTimeForCheck()
					else
						BuffCheckData.bCheckLeftTimeEnable = bCheck
					end
				end,
				fnMouseEnter = function()
					BuffCheck.MenuTip("按住Ctrl点击可设置时间，（当前为：" .. tostring(BuffCheckData.nLeftTimeForCheck) .. "秒）。")
				end,
				--fnAutoClose = function() return true end
			},
			{bDevide = true},
			{
				szOption = "检查膻中", bCheck = true, bChecked = BuffCheckData.QuickCheckType["danzhong"], fnAction = function(UserData, bCheck)
					BuffCheckData.QuickCheckType["danzhong"] = bCheck
				end,
				fnMouseEnter = function()
					BuffCheck.MenuTip("缺漏检查时 检查推血的Buff膻中。")
				end,
			},
			{
				szOption = "检查宴席", bCheck = true, bChecked = BuffCheckData.QuickCheckType[24], fnAction = function(UserData, bCheck)
					BuffCheckData.QuickCheckType[24] = bCheck
				end,
				fnMouseEnter = function()
					BuffCheck.MenuTip("缺漏检查时 检查宴席的Buff，不分宴席种类。")
				end,
			},
			{
				szOption = "检查烹饪辅助品", bCheck = true, bChecked = BuffCheckData.QuickCheckType[17], fnAction = function(UserData, bCheck)
					BuffCheckData.QuickCheckType[17] = bCheck
				end,
				fnMouseEnter = function()
					BuffCheck.MenuTip("缺漏检查时 检查烹饪辅助品。")
				end,
			},
			{
				szOption = "检查烹饪增强品", bCheck = true, bChecked = BuffCheckData.QuickCheckType[18], fnAction = function(UserData, bCheck)
					BuffCheckData.QuickCheckType[18] = bCheck
				end,
				fnMouseEnter = function()
					BuffCheck.MenuTip("缺漏检查时 检查烹饪增强品。")
				end,
			},
			{
				szOption = "检查医术辅助品", bCheck = true, bChecked = BuffCheckData.QuickCheckType[19], fnAction = function(UserData, bCheck)
					BuffCheckData.QuickCheckType[19] = bCheck
				end,
				fnMouseEnter = function()
					BuffCheck.MenuTip("缺漏检查时 检查医术辅助品。")
				end,
			},
			{
				szOption = "检查医术增强品", bCheck = true, bChecked = BuffCheckData.QuickCheckType[20], fnAction = function(UserData, bCheck)
					BuffCheckData.QuickCheckType[20] = bCheck
				end,
				fnMouseEnter = function()
					BuffCheck.MenuTip("缺漏检查时 检查医术增强品。")
				end,
			},
			{
				szOption = "检查饺子", bCheck = true, bChecked = BuffCheckData.QuickCheckType["jiaozi"], fnAction = function(UserData, bCheck)
					BuffCheckData.QuickCheckType["jiaozi"] = bCheck
				end,
				fnMouseEnter = function()
					BuffCheck.MenuTip("缺漏检查时 检查饺子Buff 不区分饺子种类。")
				end,
			},
			{bDevide = true}
		}
	local menu_1_1 = {
			szOption = "小吃种类设置：",
	}

	for nIndex = 1, #BuffCheck.tBuffTypeNames, 1 do
		local menu_1_1_1 = {szOption = BuffCheck.tBuffTypeNames[nIndex],}
		for i = 1, #BuffCheck.BuffList[nIndex], 1 do
			local menu_1_1_1_1 = {
				szOption = BuffCheck.BuffList[nIndex][i].szName .. "（" .. tostring(BuffCheck.BuffList[nIndex][i].tScore[1]) .. "）",
				bCheck = true,
				bChecked = BuffCheck.BuffList[nIndex][i].bOn,
				fnAction = function()
					BuffCheck.BuffList[nIndex][i].bOn = not BuffCheck.BuffList[nIndex][i].bOn
				end,
				fnMouseEnter = function(hItem)
					local x, y = hItem:GetAbsPos()
					local w, h = hItem:GetSize()
					x = x+250
					if IsCtrlKeyDown() then
						OutputBuffTip(GetClientPlayer().dwID, BuffCheck.BuffList[nIndex][i].dwID, BuffCheck.BuffList[nIndex][i].nLevel or 1, 1, false, 999, {x, y, w, h})
					elseif IsShiftKeyDown() then
						BuffCheck.BuffNotExist(BuffCheck.BuffList[nIndex][i].szName,BuffCheck.BuffList[nIndex][i].dwID, BuffCheck.BuffList[nIndex][i].nLevel or 1,{x, y, w, h})
					elseif IsAltKeyDown() then
						BuffCheck.BuffExist(BuffCheck.BuffList[nIndex][i].szName,BuffCheck.BuffList[nIndex][i].dwID, BuffCheck.BuffList[nIndex][i].nLevel or 1,{x, y, w, h})
					end
				end,
				fnAutoClose = function() return true end}
			local menu_1_1_1_1_1 = {
				szOption = "☆修改名字☆",
				bCheck = false,
				bChecked = false,
				fnMouseEnter = function()
					BuffCheck.MenuTip("修改名字不影响监控 监控只认ID和LV。")
				end,
				fnAction = function()
					BuffCheck.SetNewName(BuffCheck.BuffList[nIndex][i])
				end,
				fnAutoClose = function() return true end}
			local menu_1_1_1_1_2 = {
				szOption = "分数设置（当前为：" .. tostring(BuffCheck.BuffList[nIndex][i].tScore[1]) .. "）",
				bCheck = false,
				bChecked = false,
				fnMouseEnter = function()
					BuffCheck.MenuTip("分数设置，除非有特殊需求，否则不建议修改。")
				end,
				fnAction = function()
					BuffCheck.SetnScoreForBuff(BuffCheck.BuffList[nIndex][i],1)
				end,
				fnAutoClose = function() return true end}
			local menu_1_1_1_1_3 = {
				szOption = "BuffId（当前为：" .. tostring(BuffCheck.BuffList[nIndex][i].dwID) .. "）",
				bCheck = false,
				bChecked = false,
				fnMouseEnter = function()
					BuffCheck.MenuTip("修改Buff的ID，按住Ctrl鼠标移动到Buff下可查看。")
				end,
				fnAction = function()
					BuffCheck.SetdwID(BuffCheck.BuffList[nIndex][i])
				end,
				fnAutoClose = function() return true end}
			local menu_1_1_1_1_4 = {
				szOption = "BuffLevel（当前为：" .. tostring(BuffCheck.BuffList[nIndex][i].nLevel) .. "）",
				bCheck = false,
				bChecked = false,
				fnMouseEnter = function()
					BuffCheck.MenuTip("修改Buff的Level，按住Ctrl鼠标移动到Buff下可查看。")
				end,
				fnAction = function()
					BuffCheck.SetnLevel(BuffCheck.BuffList[nIndex][i])
				end,
				fnAutoClose = function() return true end}
				
			local menu_1_1_1_1_5 = {
				szOption = "删除该项",
				fnMouseEnter = function()
					BuffCheck.MenuTip("Delete")
				end,
				fnAction = function()
					table.remove(BuffCheck.BuffList[nIndex], i)
				end}
				
			table.insert(menu_1_1_1_1, menu_1_1_1_1_1)
			table.insert(menu_1_1_1_1, {bDevide = true} )
			table.insert(menu_1_1_1_1, menu_1_1_1_1_2)
			table.insert(menu_1_1_1_1, {bDevide = true} )
			table.insert(menu_1_1_1_1, menu_1_1_1_1_3)
			table.insert(menu_1_1_1_1, menu_1_1_1_1_4)
			table.insert(menu_1_1_1_1, {bDevide = true} )
			table.insert(menu_1_1_1_1, menu_1_1_1_1_5)
			table.insert(menu_1_1_1, menu_1_1_1_1)
		end
		table.insert(menu_1_1_1, {bDevide = true})
		local menu_1_1_1_1_6 = {
			szOption = "添加Buff",
			fnMouseEnter = function()
				BuffCheck.MenuTip("在这个分类下添加一个Buff。")
			end,
			fnAction = function()
				GetUserInput("Buff名称：", function(szText) BuffCheck.AddList(nIndex, szText) end, nil, nil, nil, nil)
			end}
		table.insert(menu_1_1_1, menu_1_1_1_1_6)
		table.insert(menu_1_1, menu_1_1_1)
	end
	local menu_3 = {
		szOption = "【设置】发布频道设置：",
		--SYS
		{szOption = "系统频道", bMCheck = true, bChecked = BuffCheckData.nSayChannel == PLAYER_TALK_CHANNEL.LOCAL_SYS, rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() BuffCheckData.nSayChannel = PLAYER_TALK_CHANNEL.LOCAL_SYS end, fnAutoClose = function() return true end},
		--近聊频道
		{szOption = g_tStrings.tChannelName.MSG_NORMAL, bMCheck = true, bChecked = BuffCheckData.nSayChannel == PLAYER_TALK_CHANNEL.NEARBY, rgb = GetMsgFontColor("MSG_NORMAL", true), fnAction = function() BuffCheckData.nSayChannel = PLAYER_TALK_CHANNEL.NEARBY end, fnAutoClose = function() return true end},
		--团队频道
		{szOption = g_tStrings.tChannelName.MSG_TEAM, bMCheck = true, bChecked = BuffCheckData.nSayChannel == PLAYER_TALK_CHANNEL.RAID, rgb = GetMsgFontColor("MSG_TEAM", true), fnAction = function() BuffCheckData.nSayChannel = PLAYER_TALK_CHANNEL.RAID end, fnAutoClose = function() return true end},
		--帮会频道
		{szOption = g_tStrings.tChannelName.MSG_GUILD, bMCheck = true, bChecked = BuffCheckData.nSayChannel == PLAYER_TALK_CHANNEL.TONG, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() BuffCheckData.nSayChannel = PLAYER_TALK_CHANNEL.TONG end, fnAutoClose = function() return true end},
	}
	table.insert(menu_1, menu_1_1)
	table.insert(menu, menu_1)
	table.insert(menu, menu_3)

	local menu_4 = {
			szOption = "【检查】小吃评分检查 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = false,
			bChecked = false,
			fnAction = function()
				if GetClientPlayer().IsInParty() then
					BuffCheck.CheckAllMember()
				else
					OutputWarningMessage("MSG_WARNING_YELLOW", "你不在队伍中，无法执行该操作。",6)
				end
			end,
			fnMouseEnter = function()
				BuffCheck.MenuTip("【小吃分数检查 专治各种坑爹货】\n100满分，低于50分说明吃的小吃不在内置列表内或不足4小吃，建议使用缺漏检查。")
			end,
			fnAutoClose = function() return true end
		}
	local menu_5 = {
			szOption = "【检查】小吃缺漏检查 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = false,
			bChecked = false,
			fnAction = function()
				if GetClientPlayer().IsInParty() then
					BuffCheck.QuickCheckAll()
				else				
					OutputWarningMessage("MSG_WARNING_YELLOW", "你不在队伍中，无法执行该操作。",6)
				end
			end,
			fnMouseEnter = function()
				BuffCheck.MenuTip("【小吃缺漏检查 专治各种浑水摸鱼】\n不分小吃好坏，符合4小吃都算通过，不在内置列表也无所谓。")
			end,
			fnAutoClose = function() return true end
		}
	local menu_6 = {
			szOption = "【检查】装备分数检查 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			fnMouseEnter = function() 
				BuffCheck.MenuTip("【装备分检查 可能会有顿卡】\n请确保所有成员都在视野范围内，否则会造成数据不完整，请执行至少2次该操作。")
			end,
			fnAction = function()
				if GetClientPlayer().IsInParty() then
					BuffCheck.EquipScoreStatistic()
				else
					OutputWarningMessage("MSG_WARNING_YELLOW", "你不在队伍中，无法执行该操作。",6)
				end
			end
		}
	table.insert(menu, {bDevide = true})
	table.insert(menu, menu_4)
	table.insert(menu, menu_5)
	table.insert(menu, menu_6)
	if RaidGrid_Base and RaidGrid_Base.CheckTeamVersion then
		local menu_7 = {
				szOption = "【检查】团队监控版本 ",
				szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
				fnMouseEnter = function() 
					BuffCheck.MenuTip("RaidGrid_Base.CheckTeamVersion")
				end,
				fnAction = function()
					if GetClientPlayer().IsInParty() then
						BuffCheck.RaidGrid_CheckTeamVersionData = {}
						--BuffCheck.Talk("【团队事件监控版本检查指令发出】")
						RaidGrid_Base.CheckTeamVersion()
						local szText = "<Text>text="..EncodeComponentsString(" 【检查】团队监控版本 检查时间："..BuffCheck.GetTimeString().."\n") .." font=207 </text><Text>text="..EncodeComponentsString("\n 已经发出获取指令 建议等待 2-3 秒后在执行发布") .. " font=16 </text>"
						BuffCheck.Confirm(szText,BuffCheck.RaidGrid_CheckTeamVersion,nil,"发布结果","取消")
					else
						OutputWarningMessage("MSG_WARNING_YELLOW", "你不在队伍中，无法执行该操作。",6)
					end
				end
			}

		table.insert(menu, menu_7)
	end
	return menu
end



RegisterEvent("LOGIN_GAME", function()
	local tMenu = {
		function()
			return {BuffCheck.GetMenuList()}
		end,
	}
	Player_AppendAddonMenu(tMenu)
end)
RegisterEvent("ON_BG_CHANNEL_MSG",function()
	local player = GetClientPlayer()
	local t = player.GetTalkData()
	if t and t[2] and RaidGrid_Base and RaidGrid_Base.CheckTeamVersion then
		if t[2].text == "ShareEventScrutinyVersion" and t[4] and player.szName == t[4].text then
			--BuffCheck.Talk(t[3].text)
			local _, _, nP,nP2,nP3 = string.find(t[3].text, "[[](.*)]版本：V(%d+).(%d+)")
			BuffCheck.RaidGrid_CheckTeamVersionData[nP] = tonumber(nP2.."."..nP3)
		end
	end
end)
