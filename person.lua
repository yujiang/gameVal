require "gameVal"

--person.lua
local oo = require "loop.base"

local Person = oo.class{}

function Person:OnFightTurn(turn)
	--for npc do ai!
	print(self.name,turn,self:GetHP())
end

function Person:OnFightEnd()
	--for npc do ai!
	print(self.name,turn,'OnFightEnd')
end

function Person:OnFightTurnObs(turn)
	--for npc do ai!
	print(self.name,'OnFightTurnObs')
end

function Person:IsDie()
	return self:GetHP() <= 0
end

function Person:GetHP()
	return csv_get_value(self,val_life)
end

function Person:SetHP(value)
	return csv_set_value(self,val_life,value)
end

function Person:OnDamage(hp)
	self:SetHP(self:GetHP() - hp)
end

function Person:Init()
	self:SetHP(csv_get_value(self,val_life_max))
end

--得到当前指令的speed
function Person:GetFightCmdSpeed()
	return 10
end

function init_person(n,csv,level)
	local p = Person{name = n}
	csv_init(p,csv)
	csv_change_value(p,val_level,level)
	p:Init()
	return p
end
