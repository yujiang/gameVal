--[[this file use to automation generate gameValue designed by a csv file(Excel export)
I had wirtten this before£¬but lua only 200 lines, and just one day work
--]]

g_csv = {}
g_csv_name = {}

function csv_read_line(line,i)
	local name,des,func = string.match(line,"(.+)\t(.+)\t(.+)")
	--print(name,des,func)
	local t = {}
	t.name = name
	t.des = des
	t.funcname = func
	t.fathers = {}
	t.childs = {}
	g_csv_name[name] = i
	return t;
end

function insert_table_onlyone(t,value)
	for _,j in ipairs(t) do
		if (j == value) then
			return
		end
	end
	table.insert(t,value)
end

function csv_set_father(index,father)
	insert_table_onlyone(g_csv[index].fathers,father)
	insert_table_onlyone(g_csv[father].childs,index)
end

function bind_func(index,t,file)
	--[[if (kind == 2) then return level*1.5 else return level*2 end
	-->	function (val) if (val[2] == 2) then return val[1]*1.5 else return val[1]*2 end  end--]]
	if (#t.funcname > 1) then  --not '0'
		local s = t.funcname
		for token in string.gmatch(s,"val_([%w_]+)") do
			local f = g_csv_name[token]
			if (f == nil) then
				error("not find token ["..token.."] at ".. s)
			end
			csv_set_father(index,f)
		end

		for _,j in ipairs(t.fathers) do
			local src = "val_"..g_csv[j].name
			local des = "val["..j.."]"
			s = string.gsub(s,src,des)
		end

		s = t.name.." = function (val) " .. s .. " end,\n"
		--loadstring not good than require -- for error info
		file:write(s)
	end
end

function csv_remove_child(f,c)
	for i,j in ipairs(g_csv[f].childs) do
		if (j == c) then
			table.remove(g_csv[f].childs,i)
			break
		end
	end
	for i,j in ipairs(g_csv[c].fathers) do
		if (j == f) then
			table.remove(g_csv[c].fathers,i)
			break
		end
	end
end

function csv_is_child(f,c)
	for i,j in ipairs(g_csv[f].childs) do
		if (j == c) then
			return true
		end
	end
	return false
end

function csv_is_child_recursive(f,c)
	if (csv_is_child(f,c)) then
		return true
	end
	for _,k in ipairs(g_csv[c].fathers) do
		if (csv_is_child_recursive(f,k)) then
			return true;
		end
	end
	return false;
end

function csv_read(csv)
	local line = 1
	for l in io.lines(csv) do
		t = csv_read_line(l,line)
		table.insert(g_csv,t)
		--g_csv[line] = t
		line = line + 1
	end

	local file = io.open("val_func.lua","w")
	file:write("val_func = {\n")
	for i,t in ipairs(g_csv) do
		bind_func(i,t,file)
	end
	file:write("}")
	file:close()
	require("val_func")
	for _,t in ipairs(g_csv) do
		if (#t.funcname > 1) then  --not '0'
			t.func = val_func[t.name]
			assert(t.func ~= nil)
		end
	end

	--remove redundancy relationship£¬a-->b,c b-->c simplfy to: a-->b b-->c so less function call
	for f,t in ipairs(g_csv) do
		rm = {}
		for i,j in ipairs(t.childs) do --for all child if any (chlld->father) also is child then remove this child
			for _,k in ipairs(g_csv[j].fathers) do
				if csv_is_child_recursive(f,k) then
					rm[i] = j
					break
				end
			end
		end
		for i,j in pairs(rm) do
			print(f,t.name,i,j,g_csv[j].name," can reduced!")
			csv_remove_child(f,j)
		end
	end
end

function make_table_size(t,size,value)
	for i=1,size do
		table.insert(t,value)
	end
end

function csv_init(person)
	person.val = {}
	make_table_size(person.val,#g_csv,0)
end

function update_value(person,index)
	assert(g_csv[index].func ~= nil)
	--print(index,g_csv[index].name)
	person.val[index] = g_csv[index].func(person.val);
	for _,j in ipairs(g_csv[index].childs) do
		update_value(person,j)
	end
end

function csv_change_value(person,index,value)
	assert(g_csv[index].func == nil)
	person.val[index] = value
	for _,j in ipairs(g_csv[index].childs) do
		update_value(person,j)
	end
end

function csv_change_value_byname(person,name,value)
	return csv_change_value(person,g_csv_name[name],value)
end


function csv_print_val(person)
	print("csv_print_val(person)")
	for i,j in ipairs(person.val) do
		if (j ~= 0) then
			print(g_csv[i].name.." = "..j)
		end
	end
end

function csv_print()
	for i,t in ipairs(g_csv) do
		s = ""
		for i,j in ipairs(t.childs) do
			s = s..j..","
		end
		f = ""
		for i,j in ipairs(t.fathers) do
			f = f..j..","
		end
		print (i,t.name,t.func,s,f)
	end
end

function test()
	csv_read("test.csv")
	p = {}
	csv_init(p)
	csv_print_val(p)
	csv_change_value(p,1,10)
	csv_print_val(p)
	csv_change_value_byname(p,"level",8)
	csv_print_val(p)
end
test()
