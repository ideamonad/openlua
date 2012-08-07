--[[----------------------------------------------
Õë¶Ôlist.luaµÄ²âÊÔ´úÂë
--]]----------------------------------------------

dofile("list.lua")

local empty = List{}
assert(empty:Count() == 0)
local number1 = List{1979}
assert(number1:Count() == 1)
assert(number1:Get(1) == 1979)
local string1 = List{"djf"}
assert(string1:Count() == 1)
assert(string1:Get(1) == "djf")
local bool2 = List{true,false}
assert(bool2:Count() == 2)
assert(bool2:Get(1) == true)
assert(bool2:Get(2) == false)

local list2 = List{1,1,1979,1979,"soloist","soloist"}
assert(list2:Count() == 6)
assert(list2:Get(3) == list2:Get(4))
assert(list2:Get(4) == 1979)
assert(list2:Get(5) == list2:Get(6))
assert(list2:Get(6) == "soloist")

local list3 = List{List{3,5},List{3,5},"temp",1840}
assert(list3:Count() == 4);
assert(list3:Get(1) == list3:Get(2))
assert(list3:Get(2) == List{3,5});
assert(list3:Last() == 1840)
assert(list3:Find(List{3,5}) == 1)
assert(list3:Find(List{3,5},2) == 2)
assert(list3:Find("temp") == 3)
assert(list3:Sub(3) == List{"temp",1840})
assert(list3:Sub(2,3) == List{List{3,5},"temp"})

local other = List{1979,{4,5},{4,5}}
assert(other:Count() == 3)


-- test relational operations

local function TestLess(list1,list2)
   assert(list1 ~= list2)
   assert(list2 ~= list1)
   assert(list1 <= list2)
   assert(list2 >= list1)
   assert(list1 < list2)
   assert(list2 > list1)
   assert(not (list1 >= list2))
   assert(not (list1 > list2))
   assert(not (list2 <= list1))
   assert(not (list2 < list1))
   assert(list1:Count() < list2:Count())
end

local function TestLessOrEqual(list1,list2)
   assert(list1 <= list2)
   assert(list2 >= list1)
   assert(not (list1 > list2))
   assert(not (list2 < list1))
   assert(list1:Count() <= list2:Count())
end

local function TestEqual(list1,list2)
   assert(list1 == list2)
   assert(list2 == list1)
   assert(list1 <= list2)
   assert(list1 >= list2)
   assert(list2 <= list1)
   assert(list2 >= list1)
   assert(not (list1 > list2))
   assert(not (list1 < list2))
   assert(not (list2 > list1))
   assert(not (list2 < list1))
   assert(list1:Count() == list2:Count())
end

local function TestNotEqual(list1,list2)
   assert(list1 ~= list2)
   assert(list2 ~= list1)
   assert(not (list1 == list2))
   assert(not (list2 == list1))
end

TestEqual(empty,List{})
TestEqual(empty,empty)
TestLess(empty,number1)
TestLess(empty,string1)
TestLess(empty,bool2)
TestNotEqual(number1,string1)
TestNotEqual(string1,bool2)
TestNotEqual(number1,bool2)

TestNotEqual(List{3,4,5},List{3,5,4})

local list4 = List{1,"temp","temp",List{3,5},1979}
TestEqual(list4,list4)
local list5 = List{1,"temp","temp",List{3,5}}
TestEqual(list5,list5)
TestLess(list5,list4)
local list6 = List{1,"temp","temp",List{3,5},1979,List{"djf","yaoyao"}}
TestEqual(list6,list6)
TestLess(list4,list6)
TestLess(list5,list6)
local list7 = List{"temp","temp"}
TestNotEqual(list7,list6)

-- test list arithmatic operations

local function TestIdentity(list)
   local empty = List{}
   TestEqual(list,list..empty)
   TestEqual(list,empty..list)
   TestEqual(empty,-empty)
   TestEqual(list,-(-list))
end

local function TestArith(o1,o2)
   local c1 = o1..o2
   assert(c1:Count() == o1:Count() + o2:Count())
   local c2 = (-o2)..(-o1)
   TestEqual(-c1,c2)
end

TestIdentity(empty)
TestIdentity(number1)
TestIdentity(string1);
TestIdentity(bool2)

local a1 = List{56,78,"you"}
local a2 = List{"you",33,"we"}
local a3 = List{56,78,"you","you",33,"we"}
local a4 = List{"we",33,"you","you",78,56}
TestIdentity(a1)
TestIdentity(a2)
TestIdentity(a3)
TestArith(a1,a2)
TestEqual(a1..a2,a3)
TestEqual(-a3,a4)


local b1 = List{List{5,7,9,"temp"},58}
local b2 = List{List{5,7,9},100,"djf"}
local b3 = List{List{5,7,9,"temp"},58,List{5,7,9},100,"djf"}
local b4 = List{List{5,7,9},100,"djf",List{5,7,9,"temp"},58}
TestIdentity(b1)
TestIdentity(b2)
TestEqual(b1..b2,b3)
TestEqual(b2..b1,b4)
assert(b4:Find(List{5,7,9,"temp"}) == 4)
assert(b4:Find(List{5,7,9,"temp"},4) == 4)
assert(b4:Find(List{5,7,9,"temp"},88) == nil)
assert(b4:Find(77) == nil)

for i,e in b3:Traverse() do
   assert(e == b3:Get(i))
end