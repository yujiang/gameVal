--skill.lua

function DoFightFuc_000(p)
	local des = p.fight_data.cmd.des
	if (des ~= nil) then
		local hp = 100 + math.random(100)
		des:OnDamage(hp)
	end
end

function InitSkill()
end

--主动技能
AggressiveSkillTableFuncs =
{
--cost_func 消耗，target_func 搜索目标，fight_func 起作用,
{cost_func = CostFunc_0, target_func = TargetFunc_0, fight_func = FightFunc_0, }
}

--被动技能
PassiveSkillTableFuncs =
{
--OnFightFunc 攻击 OnDamageFunc 伤害 OnFightedFunc 被攻击 OnDamagedFunc 被伤害
}

function GetAggressiveSkillFuncs(id)
end

--战斗中出手了
function SkillDoFight(p)
	local cmd = p.fight_data.cmd
	local skill = GetAggressiveskill(cmd.skill)
	local skillfuncs = skill.funcs
	assert(skillfuncs)
	if (skillfuncs.cost_func ~= nil and not skillfuncs.cost_func(p,skill))
		return
	end
	local target = skillfuncs.target_func(p,skill)
	if (target == nil) then --比如对方已经死了
		return
	end
	skillfuncs.fight_func(p,target,skill)
end

