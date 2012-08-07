require("common.lua")

Stack = {}

local _data = {}

function Stack.New(t)
   local obj = { [_data] = {} }
   setmetatable(obj, Stack)

   for _,e in ipairs(t) do
      table.insert(obj[_data],1,e)
   end

   return obj
end

function Stack:Count()
   assert(IsType(self,Stack),
	  "Stack.Count requires a stack value!")
   
   return table.getn(self[_data])
end

function Stack:Get(pos)
   -- 栈顶的位置始终是1
   return self[_data][self:Count() - pos + 1]
end

function Stack:Top()
   return self:Get(1)
end

function Stack:Bottom()
   return self:Get(self:Count())
end

function Stack:Push(v)
   table.insert(self[_data],v)
end

function Stack:Pop()
   return table.remove(self[_data])
end

function Stack:Empty()
   return self:Count() == 0
end

function Stack:Traverse()
   local i = 0
   local n = self:Count()
   local function iterator()
      i = i + 1
      if i <= n then
	 return i, self:Get(i)
      else
	 return
      end
   end

   return iterator
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

function Stack:WriteContent(outfile,sep)
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

function Stack:Serialize(outfile,sep)
   assert(IsType(self,Stack),
	  "Stack.Serialize requires a stack value!")

   outfile:write("Stack")
   self:WriteContent(outfile,sep)
end

function Stack:Print (sep)
   self:Serialize(io.output(),sep)
   io.output():write("\n")
end


function Stack.__call(t,...)
   return t.New(arg[1])
end

Stack.__le = LessOrEqual
Stack.__lt = LessThan
Stack.__eq = Equal
Stack.__index = Stack

setmetatable(Stack,primogenitor_mt)