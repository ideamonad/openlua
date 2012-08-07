require("common.lua")

Set = {}

local function Index(set,k)
   if "table" == type(k) then
      for element in pairs(set) do
	 if element == k then
	    -- 证明集合中存在与k相等的元素
	    return true
	 end
      end
      return nil
   else
      return rawget(set,k)
   end
end

local function NewIndex(set,k,v)
   if nil == v then
      if "table" == type(k) then
	 for element in pairs(set) do
	    if element == k then
	       -- 证明集合中存在与k相等的元素
	       rawset(set,element,nil)
	       return
	    end
	 end
      else
	 rawset(set,k,nil)
      end
   elseif true == v then
      if "table" == type(k) then
	 local bExist = false
	 for element in pairs(set) do
	    if element == k then
	       -- 证明集合中存在与k相等的元素
	       bExist = true
	       break
	    end
	 end
	 if not bExist then
	    rawset(set,k,true)
	 end
      else
	 rawset(set,k,true)
      end
   else
      -- 对一个集合的元素只能赋nil或true
      error("A set can only receive true or nil value!",2)
   end
end

local _data = {}
local _data_mt = {}
_data_mt.__index = Index
_data_mt.__newindex = NewIndex

function Set.New (t)
   local set = {[_data] = {}}
   setmetatable(set[_data],_data_mt)
   setmetatable(set, Set)
   
   for _, element in ipairs(t) do
      set[_data][element] = true
   end
   
   return set
end

function Set:Contains(e)
   return self[_data][e]
end

function Set:Traverse()
   return pairs(self[_data])
end

function Set:GetOne()
   for e in self:Traverse() do
      return e
   end

   return nil
end

local function Union (a,b)
   assert(IsType(a,Set) and IsType(b,Set),
	  "attempt to add non-set values")
   
   local res = a.New{}

   for e in a:Traverse() do
      rawset(res[_data],e,true)
   end

   if rawequal(a,b) then
      -- 如果a和b为同一个对象则返回一个与a完全相等的集合
      return res
   end

   for e in b:Traverse() do
      res[_data][e] = true 
   end
   return res
end
    
local function Intersection (a,b)
   assert(IsType(a,Set) and IsType(b,Set),
	  "attempt to intersect non-set values")

   local res = a.New{}

   if rawequal(a,b) then
      -- 如果a和b为同一个对象则构造一个与a完全相等的集合返回
      for e in a:Traverse() do
	 rawset(res[_data],e,true)
      end
      return res
   end

   for e in a:Traverse() do
      rawset(res[_data],e,b[_data][e])
   end
   return res
end

local function Subtract(a,b)
   assert(IsType(a,Set) and IsType(b,Set),
	  "attempt to subtract non-set values")
   
   local res = a.New{}

   if rawequal(a,b) then
      -- 如果a和b为同一个对象则返回一个空集合
      return res
   end

   for e in a:Traverse() do
      if not b[_data][e] then
      	 rawset(res[_data],e,true)
      end
   end
   return res
end

function Set:Count()
   assert(IsType(self,Set),
	  "Requires a set value!")
   
   local count = 0
   for each in self:Traverse() do
      count = count + 1
   end
   return count
end

function Set:Empty()
   return 0 == self:Count()
end

-- 往一个集合中添加element元素，
-- 操作完成后如果集合改变了，返回true，否则返回false
function Set:Add(element)
   if nil == element then
      return false
   end

   if self[_data][element] then
      return false
   else
      rawset(self[_data],element,true)
      return true
   end
end

function Set:Remove(element)
   if nil == element then
      return false
   end

   if self[_data][element] then
      self[_data][element] = nil
      return true
   else
      return false
   end
end

-- 把other集合中的元素合并到self中，
-- 操作完成后self如果改变了就返回true，否则返回false
function Set:Union(other)
   assert(IsType(other,Set),
	  "Requires a set value!")

   local res = false

   for e in other:Traverse() do
      if not self[_data][e] then
	 rawset(self[_data],e,true)
	 res = true
      end
   end
   
   return res
end

-- 从self中减去other集合中的元素，
-- 操作完成后self如果改变了就返回true，否则返回false
function Set:Subtract(other)
   assert(IsType(other,Set),
	  "Requires a set value!")

   local res = false

   for e in other:Traverse() do
      if self[_data][e] then
	 rawset(self[_data],e,nil)
	 res = true
      end
   end
   
   return res
end

local function LessOrEqual(this,other)
   if rawequal(this,other) then
      return true
   end

   for e in this:Traverse() do
      if not other[_data][e] then
	 return false
      end
   end
   
   return true
end

local function LessThan(this,other)
   return LessOrEqual(this,other) and
      not LessOrEqual(other,this)
end

local function Equal(this,other)
   return LessOrEqual(this,other) and
      LessOrEqual(other,this)
end

function Set:WriteContent(outfile,sep)
   outfile:write("{")
   local sep = sep or ', '
   local pre = ""
   for e in self:Traverse() do
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

function Set:Serialize(outfile,sep)
   outfile:write("Set")
   self:WriteContent(outfile,sep)
end

function Set:Print(sep)
   self:Serialize(io.output(),sep)
   io.output():write("\n")
end

function Set.__call(t,...)
   return t.New(arg[1])
end

Set.__add = Union
Set.__sub = Subtract
Set.__mul = Intersection
Set.__le = LessOrEqual
Set.__lt = LessThan
Set.__eq = Equal
Set.__index = Set


setmetatable(Set,primogenitor_mt)