--[[this file use to automation generate gameValue designed by a csv file(Excel export)
I had wirtten this before£¬but lua only 200 lines, and just one day work
--]]


function csv_read_line(line,i,names)
	local name,chinese,func = string.match(line,"(.-),(.-),(.+)")
	--print(name,chinese,func)
	local t = {}
	t.name = name
	t.chinese = chinese

	local num = tonumber(func)
	if(num == nil) then
		t.funcname = func
	else
		t.init_value = num
	end

	t.fathers = {}
	t.childs = {}
	names[name] = i
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

function csv_set_father(csv,index,father)
	insert_table_onlyone(csv[index].fathers,father)
	insert_table_onlyone(csv[father].childs,index)
end

function bind_func(csv,index,t,file)
	--[[if (kind == 2) then return level*1.5 else return level*2 end
	-->	function (val) if (val[2] == 2) then return val[1]*1.5 else return val[1]*2 end  end--]]
	if (t.funcname) then  --not '0'
		local s = t.funcname
		for token in string.gmatch(s,"val_([%w_]+)") do
			local f = csv.csv_name[token]
			if (f == nil) then
				error("not find token ["..token.."] at ".. s)
			end
			csv_set_father(csv,index,f)
		end

		for _,j in ipairs(t.fathers) do
			local src = "val_"..csv[j].name
			local des = "val["..j.."]"
			s = string.gsub(s,src,des)
		end

		s = t.name.." = function (val) " .. s .. " end,\n"
		--loadstring not good than require -- for error info
		file:write(s)
	end
end

function csv_remove_child(csv,f,c)
	for i,j in ipairs(csv[f].childs) do
		if (j == c) then
			table.remove(csv[f].childs,i)
			break
		end
	end
	for i,j in ipairs(csv[c].fathers) do
		if (j == f) then
			table.remove(csv[c].fathers,i)
			break
		end
	end
end

function csv_is_child(csv,f,c)
	for i,j in ipairs(csv[f].childs) do
		if (j == c) then
			return true
		end
	end
	return false
end

function csv_is_child_recursive(csv,f,c)
	if (csv_is_child(csv,f,c)) then
		return true
	end
	for _,k in ipairs(csv[c].fathers) do
		if (csv_is_child_recursive(csv,f,k)) then
			return true;
		end
	end
	return false;
end

function get_father_level(csv,i)
	local t = csv[i]
	if (t.fathers == nil or #t.fathers == 0) then
		return 0
	end
	local level = 0
	for _,f in ipairs(t.fathers) do
		local l = get_father_level(csv,f)
		if (l > level) then
			level = l
		end
	end
	return level + 1
end

function csv_read(csv_file,csv_name)
	local firstline = 1
	local line = 1
	local csv = {}
	csv.csv_name = {}
	for l in io.lines(csv_file) do
		if (firstline == 1) then
			firstline  = 0
		else
			t = csv_read_line(l,line,csv.csv_name)
			table.insert(csv,t)
			line = line + 1
		end
	end

	local tempfile = csv_name.."_val_func.lua"

	local file = io.open(tempfile,"w")
	--print(tempfile,file)

	file:write("--begin val\n")
	for i,t in ipairs(csv) do
		--print(i,t.name)
		file:write("val_"..t.name.." = "..i.."\n")
	end
	file:write("--end val\n\n")

	file:write("return {\n")
	for i,t in ipairs(csv) do
		bind_func(csv,i,t,file)
	end
	file:write("}")
	file:close()

	csv.table_func = dofile(tempfile)

	for _,t in ipairs(csv) do
		if (t.funcname) then  --not '0'
			t.func = csv.table_func[t.name]
			assert(t.func ~= nil)
		end
	end

	--remove redundancy relationship£¬a-->b,c b-->c simplfy to: a-->b b-->c so less function call
	for f,t in ipairs(csv) do
		local rm = {}
		for i,j in ipairs(t.childs) do --for all child if any (chlld->father) also is child then remove this child
			for _,k in ipairs(csv[j].fathers) do
				if csv_is_child_recursive(csv,f,k) then
					rm[i] = j
					break
				end
			end
		end
		for i,j in pairs(rm) do
			print(f,t.name,i,j,csv[j].name," can reduced!")
			csv_remove_child(csv,f,j)
		end
	end

	csv.inits = {};
	for level = 1,#csv do
		for i,t in ipairs(csv) do
			if (get_father_level(csv,i) == level) then
				table.insert(csv.inits,i)
			end
		end
	end

	return csv
end

function make_table_size(t,size,value)
	for i=1,size do
		table.insert(t,value)
	end
end

function csv_init(person,csv)
	local val = {}
	person.val = val
	person.val.csv = csv
	make_table_size(person.val,#csv,0)

	for i,t in ipairs(csv) do
		if (t.init_value ~= nil and t.init_value ~= 0) then
			val[i] = t.init_value
			--csv_change_value(person,i,t.init_value)
		end
	end

	for _,i in ipairs(csv.inits) do
		val[i] = csv[i].func(val)
	end

end

function update_value(person,index,father)
	local csv = person.val.csv
	assert(csv[index].func ~= nil)
	local val = person.val
	val[index] = csv[index].func(val);
	print(father.. " -> " .. index,csv[index].name.." = "..val[index])
	for _,j in ipairs(csv[index].childs) do
		update_value(person,j,index)
	end
end

function csv_change_value(person,index,value)
	local csv = person.val.csv
	assert(csv[index].func == nil)
	person.val[index] = value
	print("csv_change_value",index,csv[index].name.." = "..value)
	for _,j in ipairs(csv[index].childs) do
		update_value(person,j,index)
	end
	print("csv_change_value end",index,value)
end

function csv_get_value(person,index)
	return person.val[index]
end

function csv_set_value(person,index,value)
	person.val[index] = value
end

function csv_print_val(person)
	print("csv_print_val(person)",person)
	local csv = person.val.csv
	for i,j in ipairs(person.val) do
		if (j ~= 0) then
			print(csv[i].name.."("..csv[i].chinese ..") = "..j)
		end
	end
end

function csv_print(csv)
	for i,t in ipairs(csv) do
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

