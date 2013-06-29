BuffCheck = BuffCheck or {}

BuffCheck.KungfuGroup = LoadLUAData("\\Interface\\BuffCheck\\KungfuGroup.dat") or {}
BuffCheck.BuffList = LoadLUAData("\\Interface\\BuffCheck\\bufflist.txt") or {}

-----------------------------------------------
-- ���غ����ͱ���
-----------------------------------------------
local _BuffCheck = {
	dwVersion = 0x0080000,
	szBuildDate = "20130630",
	tSkillCache = {},
	tBuffCache = {}
}

-----------------------------------------------
-- ����
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
		["jiaozi"] = false,
	},
}
for k, _ in pairs(BuffCheckData) do
	RegisterCustomData("BuffCheckData." .. k)
end


-- (string, number) BuffCheck.GetVersion()		-- HM�� ��ȡ�ַ����汾�� �޸ķ����ù�����
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

-- (string) BuffCheck.GetTimeString()		-- ��ȡ��ǰ��Ϸʱ����ַ���
BuffCheck.GetTimeString = function()
	return FormatTime("%Y��%m��%d�� %H:%M:%S",GetCurrentTime())
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
-- Ӧ�ó�ʲôҩ����С�Է���

-- �㵱ǰӦ�óԵ�Сҩ����Table
-- 2=��⿸���Ʒ 3=�����ǿƷ 4=ҽ������Ʒ 5=ҽ����ǿƷ
-- [�ڹ�ID] [����] [itemID]
-----------------------------------------------
-- �����ñ�
BuffCheck.Food = {
	--�⹦
	[10026] = { -- ��ѩ
		[2] = {5,19442}, --������ɫ
		[3] = {5,19456}, --��Ч��ɫ
		[4] = {5,19516}, --������ɫ
		[5] = {5,19528}, --��Ч��ɫ
	},
	[10224] = { -- ����
		[2] = {5,19442}, --������ɫ
		[3] = {5,19456}, --��Ч��ɫ
		[4] = {5,19516}, --������ɫ
		[5] = {5,19528}, --��Ч��ɫ
	},
	[10268] = { -- GB?�д�����
		[2] = {5,19442}, --������ɫ
		[3] = {5,19456}, --��Ч��ɫ
		[4] = {5,19516}, --������ɫ
		[5] = {5,19528}, --��Ч��ɫ
	},
	[10144] = { -- ��ˮ
		[2] = {5,19444}, --����ɫ
		[3] = {5,19456}, --��Ч��ɫ
		[4] = {5,19518}, --����ɫ
		[5] = {5,19528}, --��Ч��ɫ
	},
	[10145] = { -- ɽ�ӽ���
		[2] = {5,19444}, --����ɫ
		[3] = {5,19456}, --��Ч��ɫ
		[4] = {5,19518}, --����ɫ
		[5] = {5,19528}, --��Ч��ɫ
	},
	[10015] = { -- ̫��
		[2] = {5,19444}, --����ɫ
		[3] = {5,19456}, --��Ч��ɫ
		[4] = {5,19518}, --����ɫ
		[5] = {5,19528}, --��Ч��ɫ
	},
	-- �ڹ�
	[10242] = { -- 10242 ��Ӱʥ��
		[2] = {5,19443}, --Ԫ����ɫ
		[3] = {5,19455}, --��Ч��ɫ
		[4] = {5,19517}, --Ԫ����ɫ
		[5] = {5,19527}, --��Ч��ɫ
	},	
	[10175] = { -- 10175 ����
		[2] = {5,19441}, --������ɫ
		[3] = {5,19455}, --��Ч��ɫ
		[4] = {5,19515}, --������ɫ
		[5] = {5,19527}, --��Ч��ɫ
	},
	[10003] = { -- �׽
		[2] = {5,19443}, --Ԫ����ɫ
		[3] = {5,19455}, --��Ч��ɫ
		[4] = {5,19517}, --Ԫ����ɫ
		[5] = {5,19527}, --��Ч��ɫ
	},
	[10014] = { -- ����
		[2] = {5,19441}, --������ɫ
		[3] = {5,19455}, --��Ч��ɫ
		[4] = {5,19515}, --������ɫ
		[5] = {5,19527}, --��Ч��ɫ
	},
	[10081] = { -- ����
		[2] = {5,19441}, --������ɫ
		[3] = {5,19455}, --��Ч��ɫ
		[4] = {5,19515}, --������ɫ
		[5] = {5,19527}, --��Ч��ɫ
	},
	[10225] = { -- ����
		[2] = {5,19443}, --Ԫ����ɫ
		[3] = {5,19456}, --��Ч��ɫ
		[4] = {5,19517}, --Ԫ����ɫ
		[5] = {5,19528}, --��Ч��ɫ
	},
	[10021] = { -- ����
		[2] = {5,19444}, --Ԫ����ɫ
		[3] = {5,19455}, --��Ч��ɫ
		[4] = {5,19517}, --Ԫ����ɫ
		[5] = {5,19527}, --��Ч��ɫ
	},	
}




BuffCheck.Notice = function()
	local szName = "[]"
	local me = GetClientPlayer()
	local tab = {2,3,4,5}
	local tMemberList,hTeam = BuffCheck.GetMemberList()
	for _, dwID in pairs(tMemberList) do
		local tMemberInfo = hTeam.GetMemberInfo(dwID)
		local t = {{type = "text", text = "��Ϊһ���ϸ����ְҵ���µĺܷ�ɧ��"..BuffCheck.GetKungfuName(tMemberInfo.dwMountKungfuID).." �����Ҫ��\n"}}
		me.Talk(PLAYER_TALK_CHANNEL.WHISPER,tMemberInfo.szName,t)
		if BuffCheck.Food[tMemberInfo.dwMountKungfuID] then
			for k,v in pairs(tab) do
				local t = {
					{type = "text", text = BuffCheck.tBuffTypeNames[v]},
					{type = "iteminfo", text = szName, version = GLOBAL.CURRENT_ITEM_VERSION, tabtype = BuffCheck.Food[tMemberInfo.dwMountKungfuID][v][1], index = BuffCheck.Food[tMemberInfo.dwMountKungfuID][v][2]},
				}
				me.Talk(PLAYER_TALK_CHANNEL.WHISPER,tMemberInfo.szName,t)
			end
		else
			local t = {{type = "text", text = "�Ҳ�Ҫ�����Сҩ ��Ѿ�ĸ��Һúô�"}}
			me.Talk(PLAYER_TALK_CHANNEL.WHISPER,tMemberInfo.szName,t)
		end
	end
end



-----------------------------------------------
-- װ���ֲ�ѯ
-----------------------------------------------
BuffCheck.EquipScoreStatistic = function()
	local EquipScoreStatisticCache = {}
	local tMemberList,hTeam = BuffCheck.GetMemberList()
	local Delay = 1
	for _, dwID in pairs(tMemberList) do
		local tMemberInfo = hTeam.GetMemberInfo(dwID)
		local hMember = GetPlayer(dwID)
		if hMember and tMemberInfo then
			local nEquipScore = hMember.GetTotalEquipScore()
			if HM and HM.DelayCall then
				if nEquipScore == 0 then
					Delay = Delay + 1
					HM.DelayCall(5 * Delay,function()
						ViewInviteToPlayer(dwID)
					end)
					HM.DelayCall(300 * Delay,function()
						nEquipScore = hMember.GetTotalEquipScore()
						BuffCheck.Talk(PLAYER_TALK_CHANNEL.LOCAL_SYS,"[DEBUG]��"..tMemberInfo.szName..nEquipScore)
						table.insert(EquipScoreStatisticCache, { dwID = dwID, szName = tMemberInfo.szName, szKungfu = BuffCheck.GetKungfuName(tMemberInfo.dwMountKungfuID), nScore = nEquipScore })
					end)
				else
					table.insert(EquipScoreStatisticCache, { dwID = dwID, szName = tMemberInfo.szName, szKungfu = BuffCheck.GetKungfuName(tMemberInfo.dwMountKungfuID), nScore = nEquipScore })
				end
			else
				if nEquipScore == 0 then
					ViewInviteToPlayer(dwID)
				else
					table.insert(EquipScoreStatisticCache, { dwID = dwID, szName = tMemberInfo.szName, szKungfu = BuffCheck.GetKungfuName(tMemberInfo.dwMountKungfuID), nScore = nEquipScore })
				end
			end
		end
	end
	if HM and HM.DelayCall then
		BuffCheck.Talk(PLAYER_TALK_CHANNEL.LOCAL_SYS,"[BuffCheck] ��������Ժ�... \n�������ʾ���ȡ�")
		HM.DelayCall(350 * Delay,function()
			--BuffCheck.Talk("[Delay]��"..Delay)
			local a,n = table.getn(tMemberList),table.getn(EquipScoreStatisticCache)
			BuffCheck.EquipScoreStatisticData = EquipScoreStatisticCache		
			BuffCheck.EquipScoreStatisticTalk(n,a)
		end)
	else
		local a,n = table.getn(tMemberList),table.getn(EquipScoreStatisticCache)
		BuffCheck.EquipScoreStatisticData = EquipScoreStatisticCache		
		if n < a then
			local szText = "<Text>text="..EncodeComponentsString(" ��װ���ּ�顿 ���ʱ�䣺"..BuffCheck.GetTimeString().."\n") .." font=207 </text><Text>text="..EncodeComponentsString("\n ��ȡ���� ") .. " font=16 </text><Text>text="..EncodeComponentsString(n) .." font=2 </text><Text>text="..EncodeComponentsString(" ����ҵ�װ���� ����Ŷ�������� ") .. " font=16 </text><Text>text="..EncodeComponentsString(a) .." font=2 </text><Text>text="..EncodeComponentsString(" ��ƥ��\n ��������Ҳ������߷�Χ�ڣ�Ҳ�������״λ�ȡ���ݲ�ȫ��") .. "font=16 </text>"
			BuffCheck.Confirm(szText,BuffCheck.EquipScoreStatisticTalk,BuffCheck.EquipScoreStatistic,"����ͳ��","���»�ȡ")
		else
			local szText = "<Text>text="..EncodeComponentsString(" ��װ���ּ�顿 ���ʱ�䣺"..BuffCheck.GetTimeString().."\n") .." font=207 </text><Text>text="..EncodeComponentsString("\n �Ѿ���ȡ����ȫ�� ") .. " font=16 </text><Text>text="..EncodeComponentsString(n) .." font=2 </text><Text>text="..EncodeComponentsString(" ����ҵ�װ���� ") .. "font=16 </text>"
			BuffCheck.Confirm(szText,BuffCheck.EquipScoreStatisticTalk,nil,"����ͳ��","ȡ��")
		end
	end
end

BuffCheck.EquipScoreStatisticTalk = function(n,a)
	if not BuffCheck.EquipScoreStatisticData then return end
	table.sort(BuffCheck.EquipScoreStatisticData, function(a, b) return (a.nScore > b.nScore) end)
	BuffCheck.Talk("��װ���ּ�������¡�")
	for _, v in pairs(BuffCheck.EquipScoreStatisticData) do
		BuffCheck.Talk(FormatString("��<D0>��<D1>��<D2>��",v.szKungfu,v.szName,v.nScore))
	end
	if n and a then
		BuffCheck.Talk(FormatString("�Ѽ��<D0>/<D1>�� ���಻�ڷ�Χ��",n,a))
	end
	BuffCheck.Talk("װ���ּ�鷢�����")
	OutputWarningMessage("MSG_WARNING_GREEN", "������ϣ���鿴��Ӧ��Ƶ����",6)
end

-----------------------------------------------
-- С������
-----------------------------------------------
BuffCheck.CheckAllMember = function()
	local tScoreList = {}
	local tMemberList,hTeam = BuffCheck.GetMemberList()
	BuffCheck.Talk("��С�����ֽ�����¡�")
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
			BuffCheck.Talk(FormatString("��<D0>��<D1>��<D2>��",tScoreList[k].szKungfuName,tScoreList[k].szName,tScoreList[k].nScore))
		else
			BuffCheck.Talk(FormatString("��<D0>��<D1> Ŀ�겻�����߷�Χ��",tScoreList[k].szKungfuName,tScoreList[k].szName))
		end
	end
	BuffCheck.Talk("������ϡ�")
	OutputWarningMessage("MSG_WARNING_GREEN", "������ϣ���鿴��Ӧ��Ƶ����",6)
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
-- С��ȱ©
-----------------------------------------------
	
BuffCheck.QuickCheckAll = function()
	local tScoreList = {}
	local tMemberList,hTeam = BuffCheck.GetMemberList()
	BuffCheck.Talk("��С��ȱ©������¡�")
	for _,dwID in pairs(tMemberList) do
		local memberinfo = hTeam.GetMemberInfo(dwID)
		local hPlayer = GetPlayer(dwID)
		local tClass = {
			[24] = "��ϯ",
			[17] = "����ʳƷ",
			[18] = "��ǿʳƷ",
			[19] = "����ҩƷ",
			[20] = "��ǿҩƷ",
			["jiaozi"] = "����",
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
				table.insert(tScoreList, {dwID = dwID,szName = memberinfo.szName,nScore = nScore,text=FormatString("��<D0>��<D1> ȱ<D2>",BuffCheck.GetKungfuName(memberinfo.dwMountKungfuID),memberinfo.szName,szText)})
			end
		else
			table.insert(tScoreList, {dwID = dwID,szName = memberinfo.szName,nScore = 1000,text=FormatString("��<D0>��<D1> Ŀ�겻�����߷�Χ��",BuffCheck.GetKungfuName(memberinfo.dwMountKungfuID),memberinfo.szName)})
		end
	end
	table.sort(tScoreList,function(a,b) return (a.nScore < b.nScore) end)
	
	for k = 1,#tScoreList do
		BuffCheck.Talk(tScoreList[k].text)
	end
	local a,n = table.getn(tMemberList),table.getn(tScoreList)
	BuffCheck.Talk(FormatString("������ ȱ© <D0>/<D1>",n,a))
	OutputWarningMessage("MSG_WARNING_GREEN", "ȱ©����������鿴��Ӧ��Ƶ����",6)
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
	BuffCheck.Talk("���Ŷ��¼���ؼ�顿")
	local a = table.getn(tCache)
	local n = 0
	for k, v in pairs(tCache) do
		if not v.b then
			n = n + 1
			BuffCheck.Talk(FormatString("��<D0>��<D1> δ��װ",BuffCheck.GetKungfuName(v.dwMountKungfuID),v.szName))
		else
			if v.v == 10 then v.v = "�����" end
			BuffCheck.Talk(FormatString("��<D0>��<D1>��<D2>",BuffCheck.GetKungfuName(v.dwMountKungfuID),v.szName,v.v))
		end
	end
	BuffCheck.Talk(FormatString("������ ���� <D0>/<D1>",n,a))
	BuffCheck.RaidGrid_CheckTeamVersionData = {}
end


-----------------------------------------------
-- FightState
-----------------------------------------------
BuffCheck.CheckFightState = function()
	local tFightState = {}
	local tMemberList,hTeam = BuffCheck.GetMemberList()
	for _, dwID in pairs(tMemberList) do
		local tMemberInfo = hTeam.GetMemberInfo(dwID)
		if tMemberInfo then
			local player = GetPlayer(dwID)
			if player then
				local bFightState = player.bFightState
				table.insert(tFightState, { dwID = dwID, szName = tMemberInfo.szName, szKungfu = BuffCheck.GetKungfuName(tMemberInfo.dwMountKungfuID), bFightState = bFightState })
			else
				table.insert(tFightState, { dwID = dwID, szName = tMemberInfo.szName, szKungfu = BuffCheck.GetKungfuName(tMemberInfo.dwMountKungfuID), bFightState = 2 })
			end
		end
	end
	BuffCheck.Talk("��ս��״̬��顿")
	local a = table.getn(tFightState)
	local n = 0
	for k, v in pairs(tFightState) do
		if v.bFightState then
			n = n + 1
			if v.bFightState == 2 then
				BuffCheck.Talk(FormatString("��<D0>��<D1>��<D2> ���ڷ�Χ��",v.szKungfu,v.szName,v.v))
			else
				BuffCheck.Talk(FormatString("��<D0>��<D1>��<D2> ս����",v.szKungfu,v.szName,v.v))
			end
		end
	end
	BuffCheck.Talk(FormatString("������ ���� <D0>/<D1>",n,a))
end





BuffCheck.tBuffTypeNames = {
	[1] = "�����ϯ",
	[2] = "��⿸���Ʒ",
	[3] = "�����ǿƷ",
	[4] = "ҽ������Ʒ",
	[5] = "ҽ����ǿƷ",
	[6] = "����",
}


BuffCheck.tDefaultSetForAdd = {szName="ģ������",szType="����",bOn=true,dwID=0,nLevel=1,tScore={[1]=20}}

function BuffCheck.AddList(nIndex, szName)
	if not szName or szName == "" then
		return
	end
	for i = 1, #BuffCheck.BuffList[nIndex], 1 do
		if BuffCheck.BuffList[nIndex][i].szName == szName then
			OutputMessage("MSG_SYS", "Buff���["..szName.."]�Ѵ��ڣ�".."\n")
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
			OutputMessage("MSG_SYS", "Buff���["..szNewName.."]�Ѵ��ڣ�".."\n")
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
	GetUserInput("���������֣�", Recall, nil, function() end, nil, handleRecord.szName, 31)
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
	GetUserInput("������ʱ�䣺", Recall, nil, function() end, nil, BuffCheckData.nLeftTimeForCheck, 31)
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
	GetUserInput("BuffID���ã�", Recall, nil, function() end, nil, handleRecord.dwID, 31)
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
	GetUserInput("�������ã�", Recall, nil, function() end, nil, handleRecord.tScore[a], 3)
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
	GetUserInput("BuffLevel���ã�", Recall, nil, function() end, nil, handleRecord.nLevel, 3)
end




function BuffCheck.GetMenuList()
	local szVersion,v  = BuffCheck.GetVersion()
	local menu = {
			szOption = "�����Ŷ�ɱ��",szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_LEFT",{
				szOption = "��ǰ�汾 "..szVersion.."  ".._BuffCheck.szBuildDate,bDisable = true,
			}
		}
	
	local menu_1 = {
			szOption = "�����á�С�Լ�����ã�",
			{
				szOption = "ֻ�������ڹ�", 
				bCheck = true, 
				bChecked = BuffCheckData.bDPSOnlyEnable, 
				fnAction = function(UserData, bCheck)
					BuffCheckData.bDPSOnlyEnable = bCheck
				end,
				fnMouseEnter = function()
					BuffCheck.MenuTip("����˼�壬MT�����Ʋ��ᱻ��顣")
				end,
			},
			{
				szOption = "���С��ʣ��ʱ��",
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
					BuffCheck.MenuTip("��סCtrl���������ʱ�䣬����ǰΪ��" .. tostring(BuffCheckData.nLeftTimeForCheck) .. "�룩��")
				end,
				--fnAutoClose = function() return true end
			},
			{bDevide = true},
			{
				szOption = "�����ϯ", bCheck = true, bChecked = BuffCheckData.QuickCheckType[24], fnAction = function(UserData, bCheck)
					BuffCheckData.QuickCheckType[24] = bCheck
				end,
				fnMouseEnter = function()
					BuffCheck.MenuTip("ȱ©���ʱ �����ϯ��Buff��������ϯ���ࡣ")
				end,
			},
			{
				szOption = "�����⿸���Ʒ", bCheck = true, bChecked = BuffCheckData.QuickCheckType[17], fnAction = function(UserData, bCheck)
					BuffCheckData.QuickCheckType[17] = bCheck
				end,
				fnMouseEnter = function()
					BuffCheck.MenuTip("ȱ©���ʱ �����⿸���Ʒ��")
				end,
			},
			{
				szOption = "��������ǿƷ", bCheck = true, bChecked = BuffCheckData.QuickCheckType[18], fnAction = function(UserData, bCheck)
					BuffCheckData.QuickCheckType[18] = bCheck
				end,
				fnMouseEnter = function()
					BuffCheck.MenuTip("ȱ©���ʱ ��������ǿƷ��")
				end,
			},
			{
				szOption = "���ҽ������Ʒ", bCheck = true, bChecked = BuffCheckData.QuickCheckType[19], fnAction = function(UserData, bCheck)
					BuffCheckData.QuickCheckType[19] = bCheck
				end,
				fnMouseEnter = function()
					BuffCheck.MenuTip("ȱ©���ʱ ���ҽ������Ʒ��")
				end,
			},
			{
				szOption = "���ҽ����ǿƷ", bCheck = true, bChecked = BuffCheckData.QuickCheckType[20], fnAction = function(UserData, bCheck)
					BuffCheckData.QuickCheckType[20] = bCheck
				end,
				fnMouseEnter = function()
					BuffCheck.MenuTip("ȱ©���ʱ ���ҽ����ǿƷ��")
				end,
			},
			{
				szOption = "������", bCheck = true, bChecked = BuffCheckData.QuickCheckType["jiaozi"], fnAction = function(UserData, bCheck)
					BuffCheckData.QuickCheckType["jiaozi"] = bCheck
				end,
				fnMouseEnter = function()
					BuffCheck.MenuTip("ȱ©���ʱ ������Buff �����ֽ������ࡣ")
				end,
			},
			{bDevide = true}
		}
	local menu_1_1 = {
			szOption = "С���������ã�",
	}

	for nIndex = 1, #BuffCheck.tBuffTypeNames, 1 do
		local menu_1_1_1 = {szOption = BuffCheck.tBuffTypeNames[nIndex],}
		for i = 1, #BuffCheck.BuffList[nIndex], 1 do
			local menu_1_1_1_1 = {
				szOption = BuffCheck.BuffList[nIndex][i].szName .. "��" .. tostring(BuffCheck.BuffList[nIndex][i].tScore[1]) .. "��",
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
				szOption = "���޸����֡�",
				bCheck = false,
				bChecked = false,
				fnMouseEnter = function()
					BuffCheck.MenuTip("�޸����ֲ�Ӱ���� ���ֻ��ID��LV��")
				end,
				fnAction = function()
					BuffCheck.SetNewName(BuffCheck.BuffList[nIndex][i])
				end,
				fnAutoClose = function() return true end}
			local menu_1_1_1_1_2 = {
				szOption = "�������ã���ǰΪ��" .. tostring(BuffCheck.BuffList[nIndex][i].tScore[1]) .. "��",
				bCheck = false,
				bChecked = false,
				fnMouseEnter = function()
					BuffCheck.MenuTip("�������ã��������������󣬷��򲻽����޸ġ�")
				end,
				fnAction = function()
					BuffCheck.SetnScoreForBuff(BuffCheck.BuffList[nIndex][i],1)
				end,
				fnAutoClose = function() return true end}
			local menu_1_1_1_1_3 = {
				szOption = "BuffId����ǰΪ��" .. tostring(BuffCheck.BuffList[nIndex][i].dwID) .. "��",
				bCheck = false,
				bChecked = false,
				fnMouseEnter = function()
					BuffCheck.MenuTip("�޸�Buff��ID����סCtrl����ƶ���Buff�¿ɲ鿴��")
				end,
				fnAction = function()
					BuffCheck.SetdwID(BuffCheck.BuffList[nIndex][i])
				end,
				fnAutoClose = function() return true end}
			local menu_1_1_1_1_4 = {
				szOption = "BuffLevel����ǰΪ��" .. tostring(BuffCheck.BuffList[nIndex][i].nLevel) .. "��",
				bCheck = false,
				bChecked = false,
				fnMouseEnter = function()
					BuffCheck.MenuTip("�޸�Buff��Level����סCtrl����ƶ���Buff�¿ɲ鿴��")
				end,
				fnAction = function()
					BuffCheck.SetnLevel(BuffCheck.BuffList[nIndex][i])
				end,
				fnAutoClose = function() return true end}
				
			local menu_1_1_1_1_5 = {
				szOption = "ɾ������",
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
			szOption = "���Buff",
			fnMouseEnter = function()
				BuffCheck.MenuTip("��������������һ��Buff��")
			end,
			fnAction = function()
				GetUserInput("Buff���ƣ�", function(szText) BuffCheck.AddList(nIndex, szText) end, nil, nil, nil, nil)
			end}
		table.insert(menu_1_1_1, menu_1_1_1_1_6)
		table.insert(menu_1_1, menu_1_1_1)
	end
	local menu_3 = {
		szOption = "�����á�����Ƶ�����ã�",
		--SYS
		{szOption = "ϵͳƵ��", bMCheck = true, bChecked = BuffCheckData.nSayChannel == PLAYER_TALK_CHANNEL.LOCAL_SYS, rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() BuffCheckData.nSayChannel = PLAYER_TALK_CHANNEL.LOCAL_SYS end, fnAutoClose = function() return true end},
		--����Ƶ��
		{szOption = g_tStrings.tChannelName.MSG_NORMAL, bMCheck = true, bChecked = BuffCheckData.nSayChannel == PLAYER_TALK_CHANNEL.NEARBY, rgb = GetMsgFontColor("MSG_NORMAL", true), fnAction = function() BuffCheckData.nSayChannel = PLAYER_TALK_CHANNEL.NEARBY end, fnAutoClose = function() return true end},
		--�Ŷ�Ƶ��
		{szOption = g_tStrings.tChannelName.MSG_TEAM, bMCheck = true, bChecked = BuffCheckData.nSayChannel == PLAYER_TALK_CHANNEL.RAID, rgb = GetMsgFontColor("MSG_TEAM", true), fnAction = function() BuffCheckData.nSayChannel = PLAYER_TALK_CHANNEL.RAID end, fnAutoClose = function() return true end},
		--���Ƶ��
		{szOption = g_tStrings.tChannelName.MSG_GUILD, bMCheck = true, bChecked = BuffCheckData.nSayChannel == PLAYER_TALK_CHANNEL.TONG, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() BuffCheckData.nSayChannel = PLAYER_TALK_CHANNEL.TONG end, fnAutoClose = function() return true end},
	}
	table.insert(menu_1, menu_1_1)
	table.insert(menu, menu_1)
	table.insert(menu, menu_3)

	local menu_4 = {
			szOption = "����顿С�����ּ�� ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = false,
			bChecked = false,
			fnAction = function()
				BuffCheck.KeyDown(1)
			end,
			fnMouseEnter = function()
				BuffCheck.MenuTip("��С�Է������ ר�θ��ֿӵ�����\n100���֣�����50��˵���Ե�С�Բ��������б��ڻ���4С�ԣ�����ʹ��ȱ©��顣")
			end,
			fnAutoClose = function() return true end
		}
	local menu_5 = {
			szOption = "����顿С��ȱ©��� ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = false,
			bChecked = false,
			fnAction = function()
				BuffCheck.KeyDown(2)
			end,
			fnMouseEnter = function()
				BuffCheck.MenuTip("��С��ȱ©��� ר�θ��ֻ�ˮ���㡿\n����С�Ժû�������4С�Զ���ͨ�������������б�Ҳ����ν��")
			end,
			fnAutoClose = function() return true end
		}
	local menu_6 = {
			szOption = "����顿װ��������� ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			fnMouseEnter = function() 
				BuffCheck.MenuTip("��װ���ּ�� ���ܻ��жٿ���\n��ȷ�����г�Ա������Ұ��Χ�ڣ������������ݲ���������ִ������2�θò�����")
			end,
			fnAction = function()
				BuffCheck.KeyDown(3)

			end
		}
	table.insert(menu, {bDevide = true})
	table.insert(menu, menu_4)
	table.insert(menu, menu_5)
	table.insert(menu, menu_6)
	if RaidGrid_Base and RaidGrid_Base.CheckTeamVersion then
		local menu_7 = {
				szOption = "����顿�ŶӼ�ذ汾 ",
				szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
				fnMouseEnter = function() 
					BuffCheck.MenuTip("RaidGrid_Base.CheckTeamVersion")
				end,
				fnAction = function()
					BuffCheck.KeyDown(4)
				end
			}

		table.insert(menu, menu_7)
	end
	local menu_8 = {
			szOption = "����顿ս��״̬��� ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			fnMouseEnter = function() 
				BuffCheck.MenuTip("��ս��״̬��顿\n ����ս��״̬��������� ����Ѿ�Ĳ�����")
			end,
			fnAction = function()
				BuffCheck.KeyDown(5)
			end
		}
	table.insert(menu, menu_8)
	local menu_9 ={bDevide = true}
	local menu_10 = {
			szOption = "���������������ǳ�ɶ ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=33;szLayer = "ICON_RIGHT",
			fnMouseEnter = function() 
				BuffCheck.MenuTip("���Ǹ������ǳ�ɶ����Ҫ�ĵĻ��Լ���һ��BuffCheck.lua")
			end,
			fnAction = function()
				BuffCheck.KeyDown(6)
			end
		}
	table.insert(menu, menu_9)
	table.insert(menu, menu_10)
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
			local _, _, nP,nP2,nP3 = string.find(t[3].text, "[[](.*)]�汾��V(%d+).(%d+)")
			BuffCheck.RaidGrid_CheckTeamVersionData[nP] = tonumber(nP2.."."..nP3)
		end
	end
end)

-----------------------------------------------
-- AddBinding
-----------------------------------------------


BuffCheck.KeyDown = function(n)
	if GetClientPlayer().IsInParty() then
		if n == 1 then
			BuffCheck.CheckAllMember()
		end
		if n == 2 then
			BuffCheck.QuickCheckAll()
		end
		if n == 3 then
			BuffCheck.EquipScoreStatistic()
		end
		if n == 4 then
			BuffCheck.Talk(PLAYER_TALK_CHANNEL.LOCAL_SYS,"[BuffCheck] ��������Ժ�... ʱ��ȡ�����ж�����")
			BuffCheck.RaidGrid_CheckTeamVersionData = {}
			RaidGrid_Base.CheckTeamVersion()
			if HM and HM.DelayCall then
				HM.DelayCall(50*32,BuffCheck.RaidGrid_CheckTeamVersion)
			else
			local szText = "<Text>text="..EncodeComponentsString(" ����顿�ŶӼ�ذ汾 ���ʱ�䣺"..BuffCheck.GetTimeString().."\n") .." font=207 </text><Text>text="..EncodeComponentsString("\n �Ѿ�������ȡָ�� ����ȴ� 2-3 �����ִ�з���") .. " font=16 </text>"
				BuffCheck.Confirm(szText,BuffCheck.RaidGrid_CheckTeamVersion,nil,"�������","ȡ��")
			end
		end
		if n == 5 then
			BuffCheck.CheckFightState()
		end
		if n == 6 then
			BuffCheck.Notice()
		end
	else				
		OutputWarningMessage("MSG_WARNING_YELLOW", "�㲻�ڶ����У��޷�ִ�иò�����",6)
	end
end


Hotkey.AddBinding("CheckAllMember", "С�����ּ��", "BuffCheck",function()
	BuffCheck.KeyDown(1)
end,nil)
Hotkey.AddBinding("QuickCheckAll", "С��ȱ©���", "",function()
	BuffCheck.KeyDown(2)
end,nil)
Hotkey.AddBinding("EquipScoreStatistic", "װ���������", "",function()
	BuffCheck.KeyDown(3)
end,nil)
Hotkey.AddBinding("test", "�ŶӲ�����", "",function()
	BuffCheck.KeyDown(4)
end,nil)
Hotkey.AddBinding("CheckFightState", "ս��״̬���", "",function()
	BuffCheck.KeyDown(5)
end,nil)