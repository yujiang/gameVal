--回合制的战斗

require "gameVal"
require "skill"

--战斗开始
function FightStart(side1,side2,obs)
	assert(side1 and side2)

	local fight = {}
	fight.side1 = side1
	fight.side2 = side2
	--观战和掠阵
	fight.observe = obs or {}

	fight.chars = {}

	for i,p in ipairs(side1) do
		table.insert(fight.chars,p)
		p.fight_data = {}
		p.fight_data.fight = fight
		p.fight_data.side = 1
	end
	for i,p in ipairs(side2) do
		table.insert(fight.chars,p)
		p.fight_data = {}
		p.fight_data.fight = fight
		p.fight_data.side = 2
	end
	for i,p in ipairs(fight.observe) do
		p.fight_data = {}
		p.fight_data.fight = fight
		p.fight_data.side = 0
	end

	fight.turn = 0
	FightCmdStart(fight)
	return fight
end

--战斗下指令
function FightCmd(fight,person,cmd)
	assert(fight.CmdStart)
	--print(fight,person.fight_data,cmd,fight.CmdStart)
	if (fight.CmdStart == true) then
		if (not person:IsDie() and person.fight_data.cmd == nil) then
			person.fight_data.cmd = cmd
			if (cmd.AtOnce == true) then --立即发生
				DoFightCmd(p)
			end
			if (AllCmded(fight)) then
				FightCmdEnd(fight)
			end
		end
	end
end

function AllCmded(fight)
	for i,p in ipairs(fight.chars) do
		if (not p:IsDie() and p.fight_data.cmd == nil) then
			return false
		end
	end
	return true
end

skill_normal_attack = 0

--出手
function comp_speed(p1,p2)
	return p1.fight_data.cmd_speed > p2.fight_data.cmd_speed
end
--战斗进行
function LoopFight(fight)
	for i,p in ipairs(fight.chars) do
		p.fight_data.cmd_speed = p:GetFightCmdSpeed()
	end
	table.sort(fight.chars,comp_speed)
	for i,p in ipairs(fight.chars) do
		if (not p:IsDie() and p.fight_data.cmd ~= nil) then
			SkillDoFight(p)
		end
	end
end

function RandSideDes(side)
	return side[math.random(#side)]
end

function OnTimer_FightCmdEnd(fight)
--如果时间到了没有出手，默认的随机攻击一个
	for i,p in ipairs(fight.side1) do
		if (p.fight_data.cmd == nil) then
			p.fight_data.cmd = {skill = skill_normal_attack,des = RandSideDes(fight.side2)}
		end
	end
	for i,p in ipairs(fight.side2) do
		if (p.fight_data.cmd == nil) then
			p.fight_data.cmd = {skill = skill_normal_attack,des = RandSideDes(fight.side1)}
		end
	end
end

--战斗下指令结束
function FightCmdEnd(fight)
	fight.CmdStart = false

	--do fight
	LoopFight(fight)

	if (FightIsFightEnd(fight)) then
		FightEnd(fight)
	else
		FightCmdStart(fight)
	end
end

--战斗下指令开始
function FightCmdStart(fight)
	fight.CmdStart = true
	fight.turn = fight.turn + 1
	for i,p in ipairs(fight.chars) do
		p.fight_data.cmd = nil
		--print(p.fight_data.cmd)
		p:OnFightTurn(fight.turn)
	end

	for i,p in ipairs(fight.observe) do
		p:OnFightTurnObs(fight.turn)
	end
end

function IsAllDie(side)
	for i,p in ipairs(side) do
		if (not p:IsDie()) then
			return false
		end
	end
	return true
end

function FightIsFightEnd(fight)
	local die1 = IsAllDie(fight.side1)
	local die2 = IsAllDie(fight.side2)
	if (die1 or die2) then
		if (die1 and die2) then
			fight.win = nil
			print("平手")
		else
			if (die1) then
				fight.win = 2
				print("2胜利")
			else
				fight.win = 1
				print("1胜利")
			end
		end
		return true
	end
	return false;
end

function IsFightEnd(fight)
	return fight.win ~= nil
end

--战斗结束
function FightEnd(fight)
	for i,p in ipairs(fight.chars) do
		p:OnFightEnd()
		p.fight_data = nil
	end
end
