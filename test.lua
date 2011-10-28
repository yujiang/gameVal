require "gameVal"
require "person"
require "turnFight"

function test()
	local p = {}
	csv_init(p,csv_read("person.csv","person"))
	csv_print_val(p)
	csv_change_value(p,1,10)
	csv_print_val(p)
	--csv_change_value_byname(p,"level",8)
	csv_init(p,csv_read("npc.csv","npc"))
	csv_change_value(p,val_level,8)
	csv_print_val(p)
end

function test_fight1v1()
	local t = csv_read("person.csv","person")
	local p1 = init_person("p1",t,10)
	local p2 = init_person("p2",t,20)
	local s1 = {}
	table.insert(s1,p1)
	local s2 = {}
	table.insert(s2,p2)

	fight = FightStart(s1,s2)
	while (not IsFightEnd(fight)) do
		FightCmd(fight,p1,{skill=0,des=p2})
		FightCmd(fight,p2,{skill=0,des=p1})
	end

end

--test_fight1v1()
test()
