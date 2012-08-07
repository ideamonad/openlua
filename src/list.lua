require("common.lua")

List = {}

local _data = {}

function List.New(t)
   local obj = { [_data] = {} }
   setmetatable(obj, List)
   
   for _,e in ipairs(t) do
      obj:Append(e)
   end
   
   return obj
end

function List:Get(pos)
   return self[_data][pos]
end

function List:Last()
   local count = table.getn(self[_data])
   return self[_data][count]
end

function List:First()
   return self[_data][1]
end

function List:Append(v)
   table.insert(self[_data],v)
end

function List:InsertHead(v)
   table.insert(self[_data],1,v)
end

function List:Remove(pos)
   return table.remove(self[_data],pos)
end

function List:Traverse()
   return ipairs(self[_data])
end

-- 逆序遍历
function List:RTraverse()
   local i = self:Count() + 1
   
   local function iterator()
      i = i - 1
      if 1 <= i then
	 return i,self:Get(i)
      end
      return nil
   end

   return iterator
end

function List:Count()
   assert(IsType(self,List),
	  "List.Count requires a list value!")
   
   return table.getn(self[_data])
end

function List:Find(element,beg)
   local start = beg or 1
   for i = start,self:Count() do
      if element == self[_data][i] then
	 return i
      end
   end

   return nil
end

function List:Sub(first,last)
   local res = self.New{}

   local last = last or self:Count()

   for i = first,last do
      res:Append(self:Get(i))
   end

   return res
end

local function Concatenate(a,b)
   if not IsType(a,List) or
      not IsType(b,List) then
      -- error的第二个参数表明这个错误是由Concatenate的调用者引起的，
      -- 而不是Union函数本身的错
      error("Attempt to concatenate non-list values", 2)
   end

   local res = a.New{}

   for _,v in a:Traverse() do 
      res:Append(v)
   end
   
   for _,v in b:Traverse() do
      res:Append(v)
   end
   
   return res
end
    
local function Inverse(a)
   local res = a.New{}

   local len = a:Count()
   local data = a[_data]
   
   for i = len,1,-1 do
      res:Append(data[i])
   end

   return res
end

function List:Empty()
   return self:Count() == 0
end

local function LessOrEqual(this,other)
   if rawequal(this,other) then
      return true
   end

   if not rawequal(getmetatable(this),
		   getmetatable(other)) then
      --如果metatable不为同一个表，说明是不同类对象
      --则认为不相等
      return false
   end

   for i,element in this:Traverse() do
      if element ~= other:Get(i) then
	 return false
      end
   end
   
   return true
end

local function LessThan(this,other)
   --完全依照定义的实现
   --return LessOrEqual(this,other) and
   --   not LessOrEqual(other,this)
   
   --注重效率的实现
   return LessOrEqual(this,other) and
      this:Count() < other:Count()
end

local function Equal(this,other)
   --完全依照定义的实现
   --return LessOrEqual(this,other) and
   --   LessOrEqual(other,this)

   --注重效率的实现
   return LessOrEqual(this,other) and
      this:Count() == other:Count()
end

function List:WriteContent(outfile,sep)
   outfile:write("{")
   local sep = sep or ', '
   local pre = ""
   for i,e in self:Traverse() do
      outfile:write(pre)
      if true == e then
	 outfile:write("true")
      elseif false == e then
	 outfile:write("false")
      elseif "string" == type(e) then
	 outfile:write('"',e,'"')
      elseif "table" == type(e) and
	 nil ~= e.Serialize then
	 e:Serialize(outfile)
      else
	 outfile:write(e)
      end
      pre = sep
   end

   outfile:write("}")

end

function List:Serialize(outfile,sep)
   assert(IsType(self,List),
	  "List.Serialize requires a list value!")

   outfile:write("List")
   self:WriteContent(outfile,sep)
end

function List:Print (sep)
   self:Serialize(io.output(),sep)
   io.output():write("\n")
end


function List.__call(t,...)
   return t.New(arg[1])
end

List.__concat = Concatenate
List.__unm = Inverse
List.__le = LessOrEqual
List.__lt = LessThan
List.__eq = Equal
List.__index = List


setmetatable(List,primogenitor_mt)