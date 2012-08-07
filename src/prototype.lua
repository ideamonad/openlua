require("common.lua")
require("list.lua")
require("set.lua")

--[[---------------------------------------------------
Rightside prototype inherits List
--]]---------------------------------------------------

Rightside = List{}
Rightside.__concat = List.__concat
Rightside.__unm = List.__unm
Rightside.__le = List.__le
Rightside.__lt = List.__lt
Rightside.__eq = List.__eq
Rightside.__index = Rightside
Rightside.__call = List.__call

function Rightside.New(t)
	local o = List.New(t)
	setmetatable(o,Rightside)
	return o
end

function Rightside:Serialize(outfile,sep)
	outfile:write("Rightside")
	self:WriteContent(outfile,sep)
end

--[[---------------------------------------------------
Rightside prototype definition end
--]]---------------------------------------------------


--[[---------------------------------------------------
Production prototype definition
prototype Production
{
	string [_ls] --产生式左部
	Rightside [_rs] --产生式右部
}
--]]---------------------------------------------------

local _ls = {}
local _rs = {}
Production = {}
Production.__index = Production

function Production.New(t)
	local prod = { [_ls] = t[1],[_rs] = t[2] }
	setmetatable(prod,Production)

	return prod
end

function Production.__call(t,...)
	return t.New(arg[1])
end

function Production:GetLeftside()
	return self[_ls]
end

function Production:GetRightside()
	return self[_rs]
end

function Production.__eq(this,other)
	if rawequal(this,other) then
		return true
	end

	return this[_ls] == other[_ls] 
		and this[_rs] == other[_rs]
end

function Production:WriteContent(outfile,sep)
	outfile:write("{")
	local sep = sep or ", "
	outfile:write('"',self[_ls],'"',sep)
	self[_rs]:Serialize(outfile)
	outfile:write("}")
end

function Production:Serialize(outfile,sep)
	outfile:write("Production")
	self:WriteContent(outfile,sep)
end

function Production:Print(sep)
	self:Serialize(io.output(),sep)
	io.output():write("\n")
end


setmetatable(Production,primogenitor_mt)

--[[---------------------------------------------------
Production prototype definition end
--]]---------------------------------------------------


--[[----------------------------------------------
prototype Item
{
	private:
	Production [_prod] --产生式
	number [_dotpos] --分隔点的位置
}
--]]----------------------------------------------

local _prod = {}
Item = {}
Item.__index = Item
local _dotpos = {}

function Item.New(ls,rs)
	local item = { [_prod] = Production{ls,rs}, [_dotpos] = 1 }
	setmetatable(item,Item)

	return item
end

function Item:DotPos()
	return self[_dotpos]
end

function Item:GetLeftside()
	return self[_prod]:GetLeftside()
end

function Item:GetRightside()
	return self[_prod]:GetRightside()
end

function Item:GetProduction()
	return self[_prod]
end

function Item:NextSymbol()
	local ns = self:GetRightside():Get(self:DotPos())
	if "empty" == ns then
		--self:Print()
		return
	else
		return ns
	end
end

function Item:Goto(symbol)
	assert(symbol)
	assert("empty" ~= symbol)

	if self:NextSymbol() ~= symbol then
		return nil
	end

	local newitem = self.New(self:GetLeftside(),self:GetRightside())
	newitem[_dotpos] = self:DotPos() + 1

	return newitem
end

function Item.__eq(this,other)
	if rawequal(this,other) then
		return true
	end

	return this[_prod] == other[_prod]
		and this[_dotpos] == other[_dotpos]
end

function Item:WriteContent(outfile,sep)
	outfile:write("{")
	local sep = sep or ", "
	self[_prod]:Serialize(outfile)
	outfile:write(sep)
	outfile:write(self:DotPos())
	outfile:write("}")
end

function Item:Serialize(outfile,sep)
	outfile:write("Item")
	self:WriteContent(outfile,sep)
end

function Item:Print(sep)
	self:Serialize(io.output(),sep)
	io.output():write("\n")
end

--clear the keys of private data
local _dotpos = nil

--[[----------------------------------------------
prototype Item end
--]]----------------------------------------------


--[[-------------------------------------------

prototype ParseTable definition
--]]-------------------------------------------

ParseTable = {}
ParseTable.__index = ParseTable
local _data = {}

function ParseTable.New()
	local res = { [_data] = {} }
	setmetatable(res,ParseTable)

	return res
end

function ParseTable:Get(i1,i2)
	if self[_data][i1] then
		return self[_data][i1][i2]
	end

	return nil
end

function ParseTable:Add(i1,i2,value)
	if self[_data][i1] then
		if self[_data][i1][i2] then
			self[_data][i1][i2]:Add(value)
		else
			self[_data][i1][i2] = Set{value}
		end
	else
		self[_data][i1] = { [i2] = Set{value} }
	end
end

function ParseTable:TraverseRows()
	return pairs(self[_data])
end

--clear the keys of private data
local _data = nil

--[[---------------------------------------------------
prototype ParseTable end
--]]---------------------------------------------------


--[[---------------------------------------------------
prototype Symbol definition
prototype Symbol
{
	public:
	number open_line -- symbol开始的行数
	number close_line -- symbol结束的行数
	List children -- 如果symbol是非终结符，该字段保存的是组成它的子symbols

	private:
	string type -- symbol的类型，对于非终结符来说，就是它们的名字，
	-- 对于终结符来说，分keymark(包括关键字、操作符、标点符号和empty)、
	-- Name、Number、Literal
	void  value -- 根据symbol的类型存储的symbol值
}
--]]---------------------------------------------------


Symbol = {}
Symbol.__index = Symbol
local _type = {}
local _value = {}

function Symbol.New(t)
	local symbol = { 
		[_type] = t[1],
		[_value] = t[2],
		open_line = t[3] or 0,
		close_line = t[4] or 0 }
	
	setmetatable(symbol,Symbol)

	return symbol
end

function Symbol:type()
	return self[_type]
end

function Symbol:name()
	local t = self[_type]
	if "keymark" == t then
		return self[_value]
	else
		return t
	end
end

function Symbol:value()
    return self[_value]
end

function Symbol:empty()
    return "keymark" == self[_type] and "empty" == self[_value]
        or "keymark" == self:get_child(1):type() and "empty" == self:get_child(1):value()
end

function Symbol:has_children()
	return nil ~= self.children
end

function Symbol:get_child(childNo)
	if self.children then
		return self.children:Get(childNo)
	end

	return nil
end

function Symbol:children_count()
	if self.children then
		return self.children:Count()
	end

	return 0
end

function Symbol:last_order_foreach(predict, operation)
	local children = self.children
	if nil ~= children then
		for _,node in children:Traverse() do
			node:last_order_foreach(predict,operation)
		end
	end
	
	if predict(self) then
		operation(self)
	end
end

function Symbol:first_order_foreach(predict, operation)
	if predict(self) then
		operation(self)
	end

	local children = self.children
	if nil ~= children then
		for _,node in children:Traverse() do
			node:first_order_foreach(predict,operation)
		end
	end
end

function Symbol:foreach(op_before_subtree, op_after_subtree)
    if op_before_subtree then
        op_before_subtree(self)
    end

    local children = self.children
    if nil ~= children then
        for _,node in children:Traverse() do
            node:foreach(op_before_subtree,op_after_subtree)
        end
    end
    
    if op_after_subtree then
        op_after_subtree(self)
    end
end

function Symbol:emit()
	local str = ""

	local children = self.children
	if nil ~= children then
		local nodestr
		for _,node in children:Traverse() do
			nodestr = node:emit()
			if "" ~= nodestr and "" ~= str then
				str = str.." "..nodestr
			else
				str = str..nodestr
			end
		end
		if "stat" == self:type()
			or "metastat" == self:type() 
			or "field" == self:type() then
			str = str.."\n"
		end
		return str
	elseif "Literal" == self:type() then
		return string.format("%q",self:value())
	elseif "keymark" == self:type()
		and "empty" == self:value() then
		--do nothing
		return ""
	else
		return self:value()
	end
end

local newlineKeymarks = Set{"end","else","elseif", "until", "}" }
local indent_spaces = 4
function Symbol:format(indent)
	local str = ""
	
	indent = indent or 0
	local indentStr = string.rep(" ",indent)
	
	if "keymark" == self:type() then
		local code = ""
		if "empty" == self:value() then
			code = ""
		else
			if newlineKeymarks:Contains(self:value()) then
				code = indentStr..self:value()
			else
				code =  self:value()
			end

			if "{" == self:value() then
				code = "{\n"
			elseif "}" == self:value() then
				code = "\n"..code
			end
		end
		
		return code
	end
	
	if "stat" == self:type() 
		or "field" == self:type() then
		str = indentStr
	end

	local children = self.children
	if nil ~= children then
		local nodestr
		for _,node in children:Traverse() do
			if "block" == node:type() then
				nodestr = node:format(indent + indent_spaces)
				if "" ~= nodestr then
					nodestr = "\n"..nodestr
				end
			elseif "optional_fieldlist" == node:type() then
				nodestr = node:format(indent + indent_spaces)
-- 				if "" ~= nodestr then
-- 					nodestr = nodestr
-- 				end
			else
				nodestr = node:format(indent)
			end

			if "" ~= nodestr and not IsSpaceStr(str)
				and "\n" ~= string.sub(str,-1) then
				str = str.." "..nodestr
			else
				str = str..nodestr
			end
		end
		
		if "stat_sep" == self:type() 
			or "fieldsep" == self:type() then
			str = str.."\n"
		end
		return str
	elseif "Literal" == self:type() then
		return str..string.format("%q",self:value())
	else
		return self:value()
	end
end

function Symbol.__call(t,...)
	return t.New(arg[1])
end

function Symbol.__eq(this,other)
	if rawequal(this,other) then
		return true
	end

	return this[_type] == other[_type]
		and this[_value] == other[_value]
end

function Symbol:WriteContent(outfile,sep)
	outfile:write("{")
	local sep = sep or ", "
	outfile:write('"',self[_type],'"')
	if nil == self[_value] then
		--
		outfile:write(', nil')
	elseif "string" == type(self[_value]) then
		outfile:write(', ','"',self[_value],'"')
	else
		outfile:write(', ',self[_value])
	end

	outfile:write(', ',self.open_line,', ',self.close_line)
	outfile:write("}")
end

function Symbol:Serialize(outfile,sep)
	outfile:write("Symbol")
	self:WriteContent(outfile,sep)
end

function Symbol:Print(sep)
	self:Serialize(io.output(),sep)
	io.output():write("\n")
end

setmetatable(Symbol,primogenitor_mt)

-- clear
local _type = nil
local _value = nil


--[[---------------------------------------------------
Symbol prototype definition end
--]]---------------------------------------------------



--[[---------------------------------------------------
IStream prototype definition
由字符串构成的输入流类型
--]]---------------------------------------------------

IStream = {}
IStream.__index = IStream

function IStream.New(data)
	local stream = {data = data[1],pos = 1}
	
	if "string" ~= type(data[1]) then
		-- should never be here
		assert(false)
	end
	setmetatable(stream,IStream)
	return stream
end

function IStream:lines()
	local function iter()
		local line,endpos
		_,endpos,line = string.find(self.data,"([^\n]*)\n",self.pos)
		if nil ~= endpos then
			self.pos = endpos + 1
		else
			_,_,line = string.find(self.data,"(.+)",self.pos)
			self.pos = string.len(self.data) + 1
		end
		return line
	end

	return iter
end

function IStream:read()
	local line,endpos
	_,endpos,line = string.find(self.data,"([^\n]*)\n",self.pos)
	if nil ~= endpos then
		self.pos = endpos + 1
	else
		_,_,line = string.find(self.data,"(.+)",self.pos)
		self.pos = string.len(self.data) + 1
	end
	return line
end

setmetatable(IStream,primogenitor_mt)

--[[---------------------------------------------------
IStream prototype definition end
--]]---------------------------------------------------