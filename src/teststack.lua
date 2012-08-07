--[[----------------------------------------------
Õë¶Ôstack.luaµÄ²âÊÔ´úÂë
--]]----------------------------------------------

dofile("stack.lua")

local empty = Stack{}
assert(empty:Count() == 0)
assert(nil == empty:Top())
assert(nil == empty:Pop())
local number1 = Stack{1979}
assert(number1:Count() == 1)
assert(number1:Get(1) == 1979)
assert(1979 == number1:Top())
local string1 = Stack{"djf"}
assert(string1:Count() == 1)
assert(string1:Get(1) == "djf")
local bool2 = Stack{true,false}
assert(bool2:Count() == 2)
assert(bool2:Get(1) == true)
assert(bool2:Get(2) == false)
assert(bool2:Top() == true)

local stack2 = Stack{1,1,1979,1979,"soloist","soloist"}
assert(stack2:Count() == 6)
assert(stack2:Get(3) == stack2:Get(4))
assert(stack2:Get(4) == 1979)
assert(stack2:Get(5) == stack2:Get(6))
assert(stack2:Get(6) == "soloist")

local stack3 = Stack{Stack{3,5},Stack{3,5},"temp",1840}
assert(stack3:Count() == 4);
assert(stack3:Get(1) == stack3:Get(2))
assert(stack3:Get(2) == Stack{3,5});


local other = Stack{1979,{4,5},{4,5}}
assert(other:Count() == 3)


-- test relational operations

local function TestLess(stack1,stack2)
   assert(stack1 ~= stack2)
   assert(stack2 ~= stack1)
   assert(stack1 <= stack2)
   assert(stack2 >= stack1)
   assert(stack1 < stack2)
   assert(stack2 > stack1)
   assert(not (stack1 >= stack2))
   assert(not (stack1 > stack2))
   assert(not (stack2 <= stack1))
   assert(not (stack2 < stack1))
   assert(stack1:Count() < stack2:Count())
end

local function TestLessOrEqual(stack1,stack2)
   assert(stack1 <= stack2)
   assert(stack2 >= stack1)
   assert(not (stack1 > stack2))
   assert(not (stack2 < stack1))
   assert(stack1:Count() <= stack2:Count())
end

local function TestEqual(stack1,stack2)
   assert(stack1 == stack2)
   assert(stack2 == stack1)
   assert(stack1 <= stack2)
   assert(stack1 >= stack2)
   assert(stack2 <= stack1)
   assert(stack2 >= stack1)
   assert(not (stack1 > stack2))
   assert(not (stack1 < stack2))
   assert(not (stack2 > stack1))
   assert(not (stack2 < stack1))
   assert(stack1:Count() == stack2:Count())
end

local function TestNotEqual(stack1,stack2)
   assert(stack1 ~= stack2)
   assert(stack2 ~= stack1)
   assert(not (stack1 == stack2))
   assert(not (stack2 == stack1))
end

local function TestIdentity(stk, element)
   local temp = {}
   for _,e in stk:Traverse() do
      table.insert(temp,e)
   end
   local stk2 = Stack.New(temp)
   assert(element == stk:Pop(stk:Push(element)))
   assert(stk2 == stk)
end

TestEqual(empty,Stack{})
TestEqual(empty,empty)
TestLess(empty,number1)
TestLess(empty,string1)
TestLess(empty,bool2)
TestNotEqual(number1,string1)
TestNotEqual(string1,bool2)
TestNotEqual(number1,bool2)

TestNotEqual(Stack{3,4,5},Stack{3,5,4})

local stack4 = Stack{1,"temp","temp",Stack{3,5},1979}
TestEqual(stack4,stack4)
local stack5 = Stack{1,"temp","temp",Stack{3,5}}
TestEqual(stack5,stack5)
TestLess(stack5,stack4)
local stack6 = Stack{1,"temp","temp",Stack{3,5},1979,Stack{"djf","yaoyao"}}
TestEqual(stack6,stack6)
TestLess(stack4,stack6)
TestLess(stack5,stack6)
local stack7 = Stack{"temp","temp"}
TestNotEqual(stack7,stack6)

TestIdentity(stack4,Stack{7,8,9})